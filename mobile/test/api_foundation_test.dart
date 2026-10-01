import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/api/api_client.dart';
import 'package:gallery_zone/core/api/api_error.dart';
import 'package:gallery_zone/core/api/json_utils.dart';
import 'package:gallery_zone/core/auth/firebase_rest_auth.dart';
import 'package:gallery_zone/core/auth/token_manager.dart';

import 'support/fake_http.dart';

class _MemoryStore implements RefreshTokenStore {
  String? value;
  int writes = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async {
    value = token;
    writes++;
  }

  @override
  Future<void> clear() async => value = null;
}

ApiClient _client(FakeHttp http, IdTokenSource tokens, {void Function()? onExpired}) => ApiClient(
      baseUrl: 'https://api.test/',
      idToken: tokens,
      onSessionExpired: onExpired,
      dio: http.dio(),
    );

Map<String, dynamic> _problem(int status, String code, String title, {String? detail}) => {
      'type': 'about:blank',
      'title': title,
      'status': status,
      'code': code,
      'detail': ?detail,
    };

void main() {
  group('money and timestamps on the wire', () {
    test('paise become rupees and back without drifting', () {
      expect(paiseToRupees(250000), 2500.0);
      expect(paiseToRupees(2529072), 25290.72);
      expect(rupeesToPaise(25290.72), 2529072);
      expect(rupeesToPaise(1999.99), 199999);
    });

    test('a timestamp may be ISO text or a raw Firestore object', () {
      expect(parseTimestamp('2026-09-17T13:41:28.333Z')!.toUtc().year, 2026);
      final fromFirestore = parseTimestamp({'_seconds': 1789000000, '_nanoseconds': 500000000});
      expect(fromFirestore!.millisecondsSinceEpoch, 1789000000500);
      expect(parseTimestamp(null), isNull);
      expect(parseTimestamp(''), isNull);
      expect(isoOf(null), '');
      expect(isoOrNull(null), isNull);
    });
  });

  group('ApiClient', () {
    test('sends the bearer token when signed in, and nothing when not', () async {
      final http = FakeHttp((_) => jsonBody({'ok': true}));
      await _client(http, ({bool forceRefresh = false}) async => 'tok-1').get('/v1/x');
      expect(http.requests.single.headers['Authorization'], 'Bearer tok-1');
      expect(http.requests.single.uri.toString(), 'https://api.test/v1/x');

      final anonymous = FakeHttp((_) => jsonBody({'ok': true}));
      await _client(anonymous, ({bool forceRefresh = false}) async => null).get('/v1/x');
      expect(anonymous.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('an RFC 7807 body becomes an ApiError that prefers detail over title', () async {
      final http = FakeHttp(
        (_) => jsonBody(_problem(409, 'conflict', 'Conflict', detail: 'A transfer is already pending'), status: 409),
      );
      await expectLater(
        _client(http, ({bool forceRefresh = false}) async => 't').post('/v1/x'),
        throwsA(
          isA<ApiError>()
              .having((e) => e.status, 'status', 409)
              .having((e) => e.code, 'code', 'conflict')
              .having((e) => e.message, 'message', 'A transfer is already pending')
              .having((e) => e.toString(), 'toString strips cleanly', 'Exception: A transfer is already pending'),
        ),
      );
    });

    test('no response at all is a network error with status 0', () async {
      final http = FakeHttp(offline);
      await expectLater(
        _client(http, ({bool forceRefresh = false}) async => null).get('/v1/x'),
        throwsA(isA<ApiError>().having((e) => e.isNetwork, 'isNetwork', isTrue)),
      );
    });

    test('a bare 429 is reported as rate limited', () async {
      final http = FakeHttp((_) => ResponseBody.fromString('slow down', 429));
      await expectLater(
        _client(http, ({bool forceRefresh = false}) async => null).get('/v1/x'),
        throwsA(isA<ApiError>().having((e) => e.isRateLimited, 'rate limited', isTrue)),
      );
    });

    test('a 401 refreshes the token once and retries', () async {
      var call = 0;
      final http = FakeHttp((options) {
        call++;
        return options.headers['Authorization'] == 'Bearer fresh'
            ? jsonBody({'ok': true})
            : jsonBody(_problem(401, 'unauthorized', 'Invalid or expired ID token'), status: 401);
      });
      final result = await _client(
        http,
        ({bool forceRefresh = false}) async => forceRefresh ? 'fresh' : 'stale',
      ).getMap('/v1/x');
      expect(result['ok'], isTrue);
      expect(call, 2);
    });

    test('a 401 that survives the refresh ends the session exactly once', () async {
      var expired = 0;
      final http = FakeHttp((_) => jsonBody(_problem(401, 'unauthorized', 'No'), status: 401));
      await expectLater(
        _client(http, ({bool forceRefresh = false}) async => 'whatever', onExpired: () => expired++).get('/v1/x'),
        throwsA(isA<ApiError>().having((e) => e.isUnauthorized, 'unauthorized', isTrue)),
      );
      expect(expired, 1);
      expect(http.requests.length, 2, reason: 'one try, one retry — no loop');
    });

    test('a 401 with no credential sent is not a session ending', () async {
      var expired = 0;
      final http = FakeHttp((_) => jsonBody(_problem(401, 'unauthorized', 'No'), status: 401));
      await expectLater(
        _client(http, ({bool forceRefresh = false}) async => null, onExpired: () => expired++).get('/v1/x'),
        throwsA(isA<ApiError>()),
      );
      expect(expired, 0);
    });

    test('a pre-signed upload never carries our bearer token', () async {
      final http = FakeHttp((_) => ResponseBody.fromString('', 200));
      await _client(http, ({bool forceRefresh = false}) async => 'secret').putToSignedUrl(
        'https://bucket.example/obj?sig=abc',
        [1, 2, 3],
        headers: {'Content-Type': 'image/png'},
      );
      final sent = http.requests.single;
      expect(sent.headers.containsKey('Authorization'), isFalse);
      expect(sent.uri.host, 'bucket.example');
    });
  });

  group('FirebaseRestAuth', () {
    test('sign-in reads the ids and works out when the token lapses', () async {
      final now = DateTime.utc(2026, 10, 2, 12);
      final http = FakeHttp(
        (_) => jsonBody({
          'localId': 'uid-1',
          'email': 'a@b.co',
          'idToken': 'id',
          'refreshToken': 'rt',
          'expiresIn': '3600',
        }),
      );
      final auth = FirebaseRestAuth(apiKey: 'k', dio: http.dio(), clock: () => now);
      final session = await auth.signInWithPassword('a@b.co', 'pw');
      expect(session.uid, 'uid-1');
      expect(session.expiresAt, now.add(const Duration(hours: 1)));
      expect(http.requests.single.queryParameters['key'], 'k');
      expect(http.requests.single.uri.path, endsWith('accounts:signInWithPassword'));
    });

    test('error codes become the same sentences the website shows', () async {
      Future<FirebaseAuthException> failWith(String firebaseCode) async {
        final http = FakeHttp(
          (_) => jsonBody({
            'error': {'code': 400, 'message': firebaseCode},
          }, status: 400),
        );
        try {
          await FirebaseRestAuth(apiKey: 'k', dio: http.dio()).signInWithPassword('a@b.co', 'x');
        } on FirebaseAuthException catch (e) {
          return e;
        }
        throw StateError('expected a failure');
      }

      expect((await failWith('INVALID_LOGIN_CREDENTIALS')).message, 'Invalid email or password');
      expect((await failWith('EMAIL_NOT_FOUND')).message, 'Invalid email or password');
      expect(
        (await failWith('TOO_MANY_ATTEMPTS_TRY_LATER : Access to this account has been temporarily disabled'))
            .message,
        'Too many attempts. Please wait a moment and try again.',
      );
      expect((await failWith('USER_DISABLED')).message, 'This account has been disabled.');
      expect((await failWith('SOMETHING_NEW')).message, 'Something went wrong. Please try again.');
    });

    test('offline is reported as a network error, not a wrong password', () async {
      final auth = FirebaseRestAuth(apiKey: 'k', dio: FakeHttp(offline).dio());
      await expectLater(
        auth.signInWithPassword('a@b.co', 'x'),
        throwsA(isA<FirebaseAuthException>().having((e) => e.isNetwork, 'isNetwork', isTrue)),
      );
    });

    test('refresh posts the token as a form and keeps the rotated one', () async {
      final http = FakeHttp(
        (_) => jsonBody({'id_token': 'id2', 'refresh_token': 'rt2', 'expires_in': '3600', 'user_id': 'uid-1'}),
      );
      final session = await FirebaseRestAuth(apiKey: 'k', dio: http.dio()).refresh('rt1');
      expect(session.idToken, 'id2');
      expect(session.refreshToken, 'rt2');
      expect(http.requests.single.data, 'grant_type=refresh_token&refresh_token=rt1');
    });
  });

  group('TokenManager', () {
    FirebaseSession session(String id, DateTime expires, {String refresh = 'rt'}) => FirebaseSession(
          uid: 'u',
          email: 'a@b.co',
          idToken: id,
          refreshToken: refresh,
          expiresAt: expires,
        );

    test('a fresh token is reused without touching the network', () async {
      final now = DateTime.utc(2026, 10, 2, 12);
      final http = FakeHttp((_) => throw StateError('no network call expected'));
      final manager = TokenManager(
        auth: FirebaseRestAuth(apiKey: 'k', dio: http.dio()),
        store: _MemoryStore(),
        clock: () => now,
      );
      await manager.start(session('id', now.add(const Duration(minutes: 30))), remember: true);
      expect(await manager.idToken(), 'id');
      expect(http.requests, isEmpty);
    });

    test('stale callers share one refresh', () async {
      final now = DateTime.utc(2026, 10, 2, 12);
      final http = FakeHttp(
        (_) => jsonBody({'id_token': 'new', 'refresh_token': 'rt', 'expires_in': '3600', 'user_id': 'u'}),
      );
      final manager = TokenManager(
        auth: FirebaseRestAuth(apiKey: 'k', dio: http.dio(), clock: () => now),
        store: _MemoryStore(),
        clock: () => now,
      );
      await manager.start(session('old', now.subtract(const Duration(minutes: 5))), remember: true);
      final tokens = await Future.wait([manager.idToken(), manager.idToken(), manager.idToken()]);
      expect(tokens, ['new', 'new', 'new']);
      expect(http.requests.length, 1);
    });

    test('a dead refresh token ends the session; being offline does not', () async {
      final now = DateTime.utc(2026, 10, 2, 12);
      final store = _MemoryStore()..value = 'rt';

      final dead = TokenManager(
        auth: FirebaseRestAuth(
          apiKey: 'k',
          dio: FakeHttp((_) => jsonBody({'error': {'code': 400, 'message': 'TOKEN_EXPIRED'}}, status: 400)).dio(),
        ),
        store: store,
        clock: () => now,
      );
      await dead.load();
      expect(dead.hasSession, isTrue);
      expect(await dead.idToken(), isNull);
      expect(dead.hasSession, isFalse);
      expect(store.value, isNull, reason: 'a dead token is not kept around');

      store.value = 'rt';
      final offlineManager = TokenManager(
        auth: FirebaseRestAuth(apiKey: 'k', dio: FakeHttp(offline).dio()),
        store: store,
        clock: () => now,
      );
      await offlineManager.load();
      await expectLater(
        offlineManager.idToken(),
        throwsA(isA<ApiError>().having((e) => e.isNetwork, 'isNetwork', isTrue)),
      );
      expect(offlineManager.hasSession, isTrue, reason: 'still signed in, just offline');
      expect(store.value, 'rt');
    });

    test('"keep me signed in" off keeps the session in memory only', () async {
      final now = DateTime.utc(2026, 10, 2, 12);
      final store = _MemoryStore();
      final manager = TokenManager(
        auth: FirebaseRestAuth(apiKey: 'k', dio: FakeHttp(offline).dio()),
        store: store,
        clock: () => now,
      );
      await manager.start(session('id', now.add(const Duration(hours: 1))), remember: false);
      expect(store.writes, 0);
      expect(await manager.idToken(), 'id');
      await manager.clear();
      expect(await manager.idToken(), isNull);
    });
  });
}
