import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/router/app_router.dart';
import 'package:gallery_zone/data/models/account.dart';
import 'package:gallery_zone/data/models/auth.dart';
import 'package:gallery_zone/data/repositories/auth_repository.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:gallery_zone/features/auth/role_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth implements AuthRepository {
  _Auth({this.user});

  CurrentUser? user;
  int signOuts = 0;

  @override
  Future<AuthAck> login(LoginInput input, {bool simulateError = false}) async => AuthAck(email: input.email);

  @override
  Future<AuthAck> register(RegisterInput input, {bool simulateError = false}) async => AuthAck(email: input.email);

  @override
  Future<AuthAck> forgotPassword(ForgotPasswordInput input, {bool simulateError = false}) async =>
      AuthAck(email: input.email);

  @override
  Future<AuthResult> resetPassword(ResetPasswordInput input, {bool simulateError = false}) async => const AuthResult();

  @override
  Future<AuthResult> verifyEmail({String? token, bool simulateError = false}) async => const AuthResult();

  @override
  Future<void> signOut() async => signOuts++;

  @override
  Future<void> requestAccountDeletion() async {}

  @override
  Future<CurrentUser?> resumeSession() async => user;
}

CurrentUser _user(String role) => CurrentUser(
      uid: 'u1',
      roleId: role,
      status: 'active',
      name: 'Aarav Shah',
      email: 'a@b.co',
    );

ProviderContainer _container(_Auth auth, {Role? role}) {
  final container = ProviderContainer(
    overrides: [
      initialRoleProvider.overrideWithValue(role),
      authRepositoryProvider.overrideWithValue(auth),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The role is kept in the OS keystore; in a test that is an in-memory map.
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('where a sign-in lands', () {
    test('an artist goes to the marketplace, an aggregator to their profile, a collector home', () {
      expect(landingAfterLogin(Role.artist), '/marketplace');
      expect(landingAfterLogin(Role.aggregator), '/aggregator/profile');
      expect(landingAfterLogin(Role.customer), '/account');
    });

    test('a safe next path wins over the role\'s landing', () {
      expect(landingAfterLogin(Role.artist, next: '/checkout?artworkId=aw1'), '/checkout?artworkId=aw1');
      expect(landingAfterLogin(Role.customer, next: '/transfer/aw1.ev1'), '/transfer/aw1.ev1');
    });

    test('a new account lands where the work to do is', () {
      expect(landingAfterRegister(Role.artist), '/dashboard/profile');
      expect(landingAfterRegister(Role.aggregator), '/aggregator/profile');
      expect(landingAfterRegister(Role.customer), '/account');
    });
  });

  group('next can never leave the app', () {
    test('plain app paths pass', () {
      expect(safeNextPath('/marketplace/aw1'), '/marketplace/aw1');
      expect(safeNextPath('/checkout?artworkId=aw1'), '/checkout?artworkId=aw1');
    });

    test('anything that could leave the app is dropped', () {
      for (final bad in [
        null,
        '',
        'https://evil.example/x',
        '//evil.example',
        r'/\evil.example',
        'javascript:alert(1)',
        'marketplace',
        '/ok\u0000/../x',
        '/ok\t/evil',
      ]) {
        expect(safeNextPath(bad), isNull, reason: '$bad');
      }
    });

    test('the sign-in screens themselves are not a place to return to', () {
      for (final auth in ['/login', '/register', '/forgot-password', '/reset-password?token=x', '/verify-email']) {
        expect(safeNextPath(auth), isNull, reason: auth);
      }
      expect(safeNextPath('/login/extra'), isNull);
      expect(safeNextPath('/loginish'), '/loginish', reason: 'a prefix match must not over-block');
    });
  });

  group('the router guard', () {
    test('checkout and a hand-over need an account, and bring the visitor back', () {
      expect(redirectFor(null, '/checkout?artworkId=aw1'), '/login?next=%2Fcheckout%3FartworkId%3Daw1');
      expect(redirectFor(null, '/transfer/aw1.ev1'), '/login?next=%2Ftransfer%2Faw1.ev1');
      expect(redirectFor(Role.customer, '/checkout?artworkId=aw1'), isNull);
      expect(redirectFor(Role.customer, '/transfer/aw1.ev1'), isNull);
    });

    test('browsing stays open to everyone', () {
      for (final path in ['/marketplace', '/marketplace/aw1', '/artists/a1', '/verify/aw1', '/about', '/faq']) {
        expect(redirectFor(null, path), isNull, reason: path);
      }
    });

    test('portals still bounce the wrong role home', () {
      expect(redirectFor(Role.customer, '/dashboard/artworks'), '/account');
      expect(redirectFor(null, '/aggregator/inventory'), '/login?next=%2Faggregator%2Finventory');
    });
  });

  group('the session', () {
    test('signing in remembers the role; signing out forgets everything', () async {
      final auth = _Auth();
      final container = _container(auth);
      expect(container.read(sessionProvider), isNull);

      await container.read(sessionProvider.notifier).signIn(Role.artist);
      expect(container.read(sessionProvider), Role.artist);

      await container.read(sessionProvider.notifier).signOut();
      expect(container.read(sessionProvider), isNull);
      expect(auth.signOuts, 1, reason: 'the server-side tokens are dropped too');
    });

    test('the server\'s account decides the role', () async {
      final auth = _Auth(user: _user('aggregator'));
      final container = _container(auth, role: Role.artist);
      container.read(sessionProvider.notifier).reconcile(await container.read(accountProvider.future));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(sessionProvider), Role.aggregator);
    });

    test('a session the server no longer recognises ends, and says why on the sign-in screen', () async {
      final container = _container(_Auth(), role: Role.customer);
      container.read(sessionProvider.notifier).reconcile(null);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(sessionProvider), isNull);
      expect(container.read(sessionEndedProvider), isTrue);

      await container.read(sessionProvider.notifier).signIn(Role.customer);
      expect(container.read(sessionEndedProvider), isFalse, reason: 'cleared by the next sign-in');
    });

    test('an admin account has no portal here, so a cached session for it ends', () async {
      final container = _container(_Auth(), role: Role.customer);
      container.read(sessionProvider.notifier).reconcile(_user('admin'));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(sessionProvider), isNull);
    });

    test('nothing happens when nobody is signed in', () {
      final container = _container(_Auth());
      container.read(sessionProvider.notifier).reconcile(null);
      expect(container.read(sessionEndedProvider), isFalse);
    });
  });
}
