import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/artist_network.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/auth.dart';
import 'package:gallery_zone/data/models/customer.dart';
import 'package:gallery_zone/data/repositories/artist_network_repository.dart';
import 'package:gallery_zone/data/repositories/artist_repository.dart';
import 'package:gallery_zone/data/repositories/auth_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/artist/providers/artist_network_providers.dart';
import 'package:gallery_zone/features/artist/providers/artist_providers.dart';
import 'package:gallery_zone/features/artist/screens/artist_account_screens.dart';
import 'package:gallery_zone/features/artist/screens/artist_catalog_screens.dart';
import 'package:gallery_zone/features/artist/screens/artist_network_screen.dart';
import 'package:gallery_zone/features/artist/screens/artist_settlements_screen.dart';
import 'package:gallery_zone/features/artist/screens/artist_wallet_screen.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/catalog_fixtures.dart';

ArtistProfileDetails _profile({String bank = '•••• •••• •••• 6142', String ifsc = 'HDFC0001234', FreeAccess? free}) =>
    ArtistProfileDetails(
      fullName: 'Ananya Rao',
      email: 'ananya@example.com',
      phone: '9000000000',
      bio: '',
      instagram: '@a',
      website: '',
      bankAccountMasked: bank,
      ifsc: ifsc,
      aadhaarStatus: ReviewStatus.approved,
      aadhaarMasked: '',
      freeAccess: free,
    );

Settlement _settlement(
  String id,
  String title, {
  SettlementStatus status = SettlementStatus.processed,
  double artist = 38000,
  double aggregator = 0,
  double platform = 2000,
  String? releaseAfter,
  String? processedAt,
}) =>
    Settlement(
      id: id,
      orderId: 'ord-$id',
      artworkTitle: title,
      artistName: 'Ananya Rao',
      artistAmount: artist,
      aggregatorCommission: aggregator,
      platformRevenue: platform,
      status: status,
      createdAt: '2026-09-01T00:00:00.000Z',
      releaseAfter: releaseAfter,
      processedAt: processedAt,
    );

class _Artist implements ArtistRepository {
  _Artist({
    this.balance = 40000,
    this.profile,
    this.settlements = const [],
    this.transactions = const [],
    this.messages = const [],
    this.artworks = const [],
    this.failWithdrawalWith,
  });

  final double balance;
  final double locked = 5000;
  final ArtistProfileDetails? profile;
  final List<Settlement> settlements;
  final List<WalletTransaction> transactions;
  List<MessageThread> messages;
  final List<ArtistArtwork> artworks;
  final Object? failWithdrawalWith;

  final withdrawals = <double>[];
  final readIds = <String>[];

  @override
  Future<WalletSummary> getWallet() async => WalletSummary(balance: balance, pendingBalance: 0, lockedBalance: locked);

  @override
  Future<List<WalletTransaction>> listWalletTransactions() async => transactions;

  @override
  Future<WalletTransaction> requestWithdrawal(double amount) async {
    if (failWithdrawalWith != null) throw failWithdrawalWith!;
    withdrawals.add(amount);
    return WalletTransaction(
      id: 'w1',
      type: WalletTransactionType.withdrawal,
      label: 'Withdrawal to bank',
      amount: -amount,
      date: '2026-10-02T00:00:00.000Z',
      status: WalletTransactionStatus.pending,
    );
  }

  @override
  Future<ArtistProfileDetails> getProfile() async => profile ?? _profile();

  @override
  Future<List<Settlement>> listSettlements() async => settlements;

  @override
  Future<List<MessageThread>> listMessages() async => messages;

  @override
  Future<MessageThread> markMessageRead(String id) async {
    readIds.add(id);
    messages = [for (final m in messages) m.id == id ? m.copyWith(unread: false) : m];
    return messages.firstWhere((m) => m.id == id);
  }

  @override
  Future<List<ArtistArtwork>> listArtworks() async => artworks;

  @override
  Future<ArtistSettings> getSettings() async => const ArtistSettings(
        notifyArtworkApproved: true,
        notifyNewSale: false,
        notifyWithdrawalProcessed: true,
        notifyNewMessage: true,
      );

  @override
  Future<List<GallerySpacePlacement>> listGallerySpaces() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Network implements ArtistNetworkRepository {
  final List<ArtistConnection> connections = const [];

  @override
  Future<List<ArtistConnection>> listConnections(String artistId) async => connections;

  @override
  Future<ArtistRating> getRating(String artistId) async =>
      ArtistRating(artistId: artistId, average: 0, count: 0, breakdown: const {});

  @override
  Future<DeactivationRequest?> getDeactivationRequest() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements AuthRepository {
  final resets = <String>[];
  Object? failWith;

  @override
  Future<AuthAck> forgotPassword(ForgotPasswordInput input, {bool simulateError = false}) async {
    if (failWith != null) throw failWith!;
    resets.add(input.email);
    return AuthAck(email: input.email);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _show(
  WidgetTester tester,
  Widget screen, {
  required _Artist artist,
  _Network? network,
  _Auth? auth,
  bool remote = false,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        artistRepositoryProvider.overrideWithValue(artist),
        artistNetworkRepositoryProvider.overrideWithValue(network ?? _Network()),
        if (auth != null) authRepositoryProvider.overrideWithValue(auth),
        remoteBackendProvider.overrideWithValue(remote),
        initialRoleProvider.overrideWithValue(null),
      ],
      child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: screen)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

WalletTransaction _tx(String id, String label, double amount, {WalletTransactionStatus status = WalletTransactionStatus.completed}) =>
    WalletTransaction(
      id: id,
      type: amount >= 0 ? WalletTransactionType.settlement : WalletTransactionType.withdrawal,
      label: label,
      amount: amount,
      date: '2026-09-20T00:00:00.000Z',
      status: status,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
  });

  group('the settlement split', () {
    test('the total is every share, and a share is its slice of it', () {
      final settlement = _settlement('1', 'x', artist: 38000, aggregator: 4000, platform: 2000);
      expect(settlementTotal(settlement), 44000);
      expect(settlementShare(38000, 44000), 86);
      expect(settlementShare(4000, 44000), 9);
      expect(settlementShare(2000, 44000), 5);
      expect(settlementShare(10, 0), 0, reason: 'no total, no shares');
    });
  });

  group('the wallet', () {
    testWidgets('names the three figures the website does, and no longer calls the split provisional', (tester) async {
      await _show(tester, const ArtistWalletTab(), artist: _Artist());
      expect(find.text('Available balance'), findsOneWidget);
      expect(find.text('Awaiting delivery'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('₹40,000'), findsOneWidget);
      expect(find.textContaining('provisional'), findsNothing);
    });

    testWidgets('credits and debits read with their sign; a pending one says so', (tester) async {
      await _show(
        tester,
        const ArtistWalletTab(),
        artist: _Artist(
          transactions: [
            _tx('1', 'Marketplace sale settled', 38000),
            _tx('2', 'Withdrawal to bank', -10000, status: WalletTransactionStatus.pending),
            _tx('3', 'Withdrawal to bank', -500, status: WalletTransactionStatus.failed),
          ],
        ),
      );
      expect(find.text('+₹38,000'), findsOneWidget);
      expect(find.text('−₹10,000'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('20 Sept'), findsNothing);
      expect(find.text('20 Sep'), findsOneWidget, reason: 'the settled one shows its date');
    });

    testWidgets('what is on the way says when it lands, and offers no demo shortcut against the real service', (tester) async {
      final artist = _Artist(
        settlements: [
          _settlement('1', 'Monsoon', status: SettlementStatus.pending, releaseAfter: '2026-10-12T00:00:00.000Z'),
          _settlement('2', 'Dusk', status: SettlementStatus.pending),
          _settlement('3', 'Settled', status: SettlementStatus.processed),
        ],
      );
      await _show(tester, const ArtistWalletTab(), artist: artist, remote: true);
      expect(find.text('On the way to you'), findsOneWidget);
      expect(find.text('Sales clear 7 days after the artwork is delivered to the buyer.'), findsOneWidget);
      expect(find.text('Delivered — clears 12 Oct'), findsOneWidget);
      expect(find.text('Waiting for the artwork to be delivered'), findsOneWidget);
      expect(find.text('Settled'), findsNothing, reason: 'already paid, so not on the way');
      expect(find.text('Simulate delivery (demo)'), findsNothing);
    });

    testWidgets('the offline demo keeps its shortcut, since it has no courier', (tester) async {
      final artist = _Artist(settlements: [_settlement('2', 'Dusk', status: SettlementStatus.pending)]);
      await _show(tester, const ArtistWalletTab(), artist: artist);
      expect(find.text('Simulate delivery (demo)'), findsOneWidget);
    });

    testWidgets('below the minimum there is nothing to withdraw, and it says why', (tester) async {
      await _show(tester, const ArtistWalletTab(), artist: _Artist(balance: 900));
      expect(find.text('Minimum withdrawal is ₹1,000.'), findsOneWidget);
      final button = tester.widget<ButtonStyleButton>(find.ancestor(of: find.text('Withdraw'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)).first);
      expect(button.onPressed, isNull);
    });

    testWidgets('a withdrawal is a request: validated, sent, and described as one', (tester) async {
      final artist = _Artist();
      await _show(tester, const ArtistWalletTab(), artist: artist);

      await _tap(tester, find.text('Withdraw'));
      expect(find.text('Withdraw funds'), findsOneWidget);
      expect(find.text('•••• •••• •••• 6142'), findsOneWidget);
      expect(find.text('HDFC0001234'), findsOneWidget);
      expect(find.text('Minimum ₹1,000 · Available ₹40,000'), findsOneWidget);

      Future<void> enter(String text) async {
        await tester.enterText(find.widgetWithText(TextField, 'Amount (₹)'), text);
        await tester.pump();
      }

      bool canRequest() {
        final b = tester.widget<ButtonStyleButton>(find.ancestor(of: find.text('Request withdrawal'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)).first);
        return b.onPressed != null;
      }

      expect(canRequest(), isFalse, reason: 'nothing typed');
      await enter('500');
      expect(find.text('Minimum withdrawal is ₹1,000'), findsOneWidget);
      expect(canRequest(), isFalse);
      await enter('45000');
      expect(find.text('Exceeds your available balance'), findsOneWidget);
      expect(canRequest(), isFalse);
      await enter('15000');
      expect(canRequest(), isTrue);

      await tester.tap(find.text('Request withdrawal'));
      await tester.pumpAndSettle();
      expect(artist.withdrawals, [15000]);
      expect(find.text('Withdrawal requested.'), findsOneWidget);
      expect(find.text('₹15,000 will be sent to your bank account ending 6142. This typically takes 1–2 business days.'), findsOneWidget);
      expect(find.textContaining('sent to your bank account'), findsOneWidget);
    });

    testWidgets('a refusal stays in the sheet, in words', (tester) async {
      final artist = _Artist(failWithdrawalWith: Exception('Withdrawal exceeds available balance'));
      await _show(tester, const ArtistWalletTab(), artist: artist);
      await _tap(tester, find.text('Withdraw'));
      await tester.enterText(find.widgetWithText(TextField, 'Amount (₹)'), '2000');
      await tester.pump();
      await tester.tap(find.text('Request withdrawal'));
      await tester.pumpAndSettle();
      expect(find.text('Withdrawal exceeds available balance'), findsOneWidget);
      expect(find.text('Withdrawal requested.'), findsNothing);
      expect(find.text('Request withdrawal'), findsOneWidget, reason: 'still there to try again');
    });

    testWidgets('with no payout account on file it says so and points to the profile', (tester) async {
      final artist = _Artist(profile: _profile(bank: '', ifsc: ''));
      await _show(tester, const ArtistWalletTab(), artist: artist);
      await _tap(tester, find.text('Withdraw'));
      expect(find.text('No payout account on file'), findsOneWidget);
      expect(find.text('Add one'), findsOneWidget);
    });

    testWidgets('a wallet that will not load can be retried', (tester) async {
      final broken = _BrokenWallet();
      await _show(tester, const ArtistWalletTab(), artist: broken);
      expect(find.text("Couldn't load your wallet"), findsOneWidget);
      expect(find.text('The server is not reachable'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('settlements', () {
    final settlements = [
      _settlement('1', 'Monsoon, Madurai', processedAt: '2026-09-20T00:00:00.000Z', aggregator: 4000),
      _settlement('2', 'Dusk at the Ghat', status: SettlementStatus.pending),
      _settlement('3', 'Lost in the post', status: SettlementStatus.failed),
    ];

    testWidgets('lists every sale with its status in the website\'s words', (tester) async {
      await _show(tester, const ArtistSettlementsTab(), artist: _Artist(settlements: settlements));
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.text('Order ord-1'), findsOneWidget);
      expect(find.text('Processed'), findsWidgets);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Failed'), findsWidgets);
      expect(find.text('Platform fee'), findsNWidgets(3));
    });

    testWidgets('can be searched and filtered', (tester) async {
      await _show(tester, const ArtistSettlementsTab(), artist: _Artist(settlements: settlements));

      await tester.enterText(find.byType(TextField), 'ghat');
      await tester.pumpAndSettle();
      expect(find.text('Dusk at the Ghat'), findsOneWidget);
      expect(find.text('Monsoon, Madurai'), findsNothing);

      await tester.enterText(find.byType(TextField), 'ord-3');
      await tester.pumpAndSettle();
      expect(find.text('Lost in the post'), findsOneWidget, reason: 'the order id is searchable too');

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pending'));
      await tester.pumpAndSettle();
      expect(find.text('Dusk at the Ghat'), findsOneWidget);
      expect(find.text('Lost in the post'), findsNothing);
      expect(find.text('Monsoon, Madurai'), findsNothing);

      // Choosing the chosen one again clears it.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pending'));
      await tester.pumpAndSettle();
      expect(find.text('Lost in the post'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pending'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'monsoon');
      await tester.pumpAndSettle();
      expect(find.text('No settlements match'), findsOneWidget);
    });

    testWidgets('opens into the split, with each share and the order total', (tester) async {
      await _show(tester, const ArtistSettlementsTab(), artist: _Artist(settlements: settlements));
      await tester.tap(find.text('Monsoon, Madurai'));
      await tester.pumpAndSettle();

      expect(find.text('Your payout'), findsWidgets);
      expect(find.textContaining('86%'), findsOneWidget);
      expect(find.textContaining('9%'), findsOneWidget);
      expect(find.textContaining('5%'), findsOneWidget);
      expect(find.text('Order total'), findsOneWidget);
      expect(find.text('₹44,000'), findsOneWidget);
      expect(find.text('20 Sept 2026'), findsNothing);
      expect(find.text('20 Sep 2026'), findsOneWidget);
    });

    testWidgets('a settlement not yet processed says so', (tester) async {
      await _show(tester, const ArtistSettlementsTab(), artist: _Artist(settlements: settlements));
      await tester.tap(find.text('Dusk at the Ghat'));
      await tester.pumpAndSettle();
      expect(find.text('Not yet'), findsOneWidget);
    });

    testWidgets('says plainly when there are none', (tester) async {
      await _show(tester, const ArtistSettlementsTab(), artist: _Artist());
      expect(find.text('No settlements yet'), findsOneWidget);
      expect(find.text('A payout breakdown appears here once a piece sells.'), findsOneWidget);
    });
  });

  group('messages', () {
    final messages = [
      const MessageThread(
        id: 'm1',
        from: 'GalleryZone Curation Team',
        subject: 'Your artwork is live',
        preview: 'Monsoon, Madurai was approved',
        body: 'Monsoon, Madurai was approved and is now on the marketplace.',
        unread: true,
        receivedAt: '2026-09-28T00:00:00.000Z',
      ),
      const MessageThread(
        id: 'm2',
        from: 'Support',
        subject: 'Welcome',
        preview: 'Thanks for joining',
        body: 'Thanks for joining GalleryZone.',
        unread: false,
        receivedAt: '2026-09-01T00:00:00.000Z',
      ),
    ];

    testWidgets('shows the sender and a preview, and marks a message read only when it is opened', (tester) async {
      final artist = _Artist(messages: messages);
      await _show(tester, const ArtistMessagesScreen(), artist: artist);
      expect(find.text('GalleryZone Curation Team · Monsoon, Madurai was approved'), findsOneWidget);
      expect(find.text('28 Sep'), findsOneWidget);
      expect(find.text('Monsoon, Madurai was approved and is now on the marketplace.'), findsNothing);
      expect(artist.readIds, isEmpty);

      await tester.tap(find.text('Your artwork is live'));
      await tester.pumpAndSettle();
      expect(find.text('Monsoon, Madurai was approved and is now on the marketplace.'), findsOneWidget);
      expect(artist.readIds, ['m1']);

      await tester.tap(find.text('Welcome'));
      await tester.pumpAndSettle();
      expect(artist.readIds, ['m1'], reason: 'one that was already read is not marked again');
    });

    testWidgets('an empty inbox says what lands there', (tester) async {
      await _show(tester, const ArtistMessagesScreen(), artist: _Artist());
      expect(find.text('No messages'), findsOneWidget);
      expect(find.text('Updates from GalleryZone about your submissions, sales, and account will show up here.'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('shows the plan from the profile: six months, or a year for the survey list', (tester) async {
      await _show(
        tester,
        const ArtistSettingsScreen(),
        artist: _Artist(profile: _profile(free: const FreeAccess(until: '2027-03-20T00:00:00.000Z', months: 6))),
      );
      expect(find.text('Founding Artist plan'), findsOneWidget);
      expect(find.text('Free for your first six months'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.textContaining('Free until 20 March 2027, then ₹1,200/year + 18% GST (₹1,416 total).'), findsOneWidget);

      await _show(
        tester,
        const ArtistSettingsScreen(),
        artist: _Artist(
          profile: _profile(free: const FreeAccess(until: '2026-01-10T00:00:00.000Z', months: 12, surveyRespondent: true, active: false)),
        ),
      );
      expect(find.text('Free for your first year'), findsOneWidget);
      expect(find.text('Ended'), findsOneWidget);
      expect(find.textContaining('Your free period ended on 10 January 2026.'), findsOneWidget);
    });

    testWidgets('with no free period on record there is no plan card to make up', (tester) async {
      await _show(tester, const ArtistSettingsScreen(), artist: _Artist());
      expect(find.text('Founding Artist plan'), findsNothing);
    });

    testWidgets('lists the four notices by the website\'s names, as they are set', (tester) async {
      await _show(tester, const ArtistSettingsScreen(), artist: _Artist());
      expect(find.text('Artwork approved or rejected'), findsOneWidget);
      expect(find.text('New sale'), findsOneWidget);
      expect(find.text('Withdrawal processed'), findsOneWidget);
      expect(find.text('New message'), findsOneWidget);
      final switches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).map((s) => s.value).toList();
      expect(switches, [true, false, true, true]);
      expect(find.textContaining('Saved on this device.'), findsOneWidget);
    });

    testWidgets('changing the password sends a real link to the address on the account', (tester) async {
      final auth = _Auth();
      await _show(tester, const ArtistSettingsScreen(), artist: _Artist(), auth: auth);
      expect(find.textContaining('we email a link to ananya@example.com'), findsOneWidget);

      await _tap(tester, find.text('Email me a reset link'));
      expect(auth.resets, ['ananya@example.com']);
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Send it again'), findsOneWidget);
    });

    testWidgets('a failure to send is shown', (tester) async {
      final auth = _Auth()..failWith = Exception('Too many requests. Try again in a minute.');
      await _show(tester, const ArtistSettingsScreen(), artist: _Artist(), auth: auth);
      await _tap(tester, find.text('Email me a reset link'));
      expect(find.text('Too many requests. Try again in a minute.'), findsOneWidget);
      expect(find.text('Sent'), findsNothing);
    });
  });

  group('connections', () {
    testWidgets('are the website\'s panel: nothing yet, and a way to find artists', (tester) async {
      await _show(tester, const ArtistNetworkScreen(), artist: _Artist());
      expect(find.text('0 connected'), findsOneWidget);
      expect(find.textContaining('No connections yet.'), findsOneWidget);
      expect(find.text('Browse artists'), findsOneWidget);
    });

    testWidgets('collaborations are gone from the product, and from here', (tester) async {
      await _show(tester, const ArtistNetworkScreen(), artist: _Artist());
      expect(find.textContaining('ollaborat'), findsNothing);
      expect(find.text('Send proposal'), findsNothing);
    });
  });

  group('the portfolio', () {
    ArtistArtwork piece(String id, ArtworkStatus status) => ArtistArtwork(
          artwork: fixtureArtwork(id: id, title: 'Piece $id', status: status),
          artistPrice: 40000,
        );

    testWidgets('previews only what buyers can see, with no price and no buy button', (tester) async {
      await _show(
        tester,
        const PortfolioScreen(),
        artist: _Artist(
          artworks: [
            piece('1', ArtworkStatus.marketplace),
            piece('2', ArtworkStatus.draft),
            piece('3', ArtworkStatus.pendingApproval),
            piece('4', ArtworkStatus.sold),
          ],
        ),
      );
      expect(find.text('2 pieces visible to buyers'), findsOneWidget);
      expect(find.text('A preview of how your published work looks across GalleryZone.'), findsOneWidget);
      expect(find.text('Piece 1'), findsOneWidget);
      expect(find.text('Piece 4'), findsOneWidget);
      expect(find.text('Piece 2'), findsNothing);
      expect(find.text('Piece 3'), findsNothing);
      expect(find.text('Buy'), findsNothing);
      expect(find.textContaining('₹'), findsNothing);
    });

    testWidgets('says so when nothing is published', (tester) async {
      await _show(tester, const PortfolioScreen(), artist: _Artist(artworks: [piece('2', ArtworkStatus.draft)]));
      expect(find.text('Nothing published yet'), findsOneWidget);
    });
  });

  group('aggregator display', () {
    testWidgets('explains the six-month period and, with nothing placed, says so', (tester) async {
      await _show(tester, const GallerySpacesScreen(), artist: _Artist());
      expect(find.text('Where your work is physically on display right now.'), findsOneWidget);
      expect(find.textContaining('six-month listing period'), findsOneWidget);
      expect(find.text('No pieces with an aggregator yet'), findsOneWidget);
      expect(
        find.text('Artworks listed on the aggregator channel show up here once an aggregator reserves one.'),
        findsOneWidget,
      );
    });
  });
}

/// A wallet the API cannot reach.
class _BrokenWallet extends _Artist {
  @override
  Future<WalletSummary> getWallet() async => throw Exception('The server is not reachable');
}
