import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/format.dart';
import 'package:gallery_zone/core/pricing.dart';
import 'package:gallery_zone/data/models/auth.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/mock/mock_artist_repository.dart';
import 'package:gallery_zone/data/mock/mock_artwork_repository.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/artwork_filters.dart';
import 'package:gallery_zone/data/repositories/artist_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/artist/providers/artist_providers.dart';
import 'package:gallery_zone/features/artist/screens/artist_artworks_screen.dart';
import 'package:gallery_zone/features/artist/widgets/artist_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

SubmitArtworkInput _input({bool asDraft = false, double price = 20000, String title = 'New piece'}) =>
    SubmitArtworkInput(
      title: title,
      description: 'Test piece.',
      category: 'painting',
      medium: 'Oil on Canvas',
      artistPrice: price,
      listingType: ListingType.marketplaceOnly,
      insuranceOpted: false,
      images: const [
        ArtworkImage(
          url: '/artworks/bird.png',
          thumbnailUrl: '/artworks/bird.png',
          sortOrder: 0,
          altText: 'New piece',
        ),
      ],
      asDraft: asDraft,
    );

void main() {
  late MockArtistRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
    repository = MockArtistRepository();
  });

  test('the portal shows drafts and in-review pieces; the marketplace does not',
      () async {
    final portal = await repository.listArtworks();
    expect(portal, hasLength(7));

    final browsable = await MockArtworkRepository().list(const ArtworkFilters());
    final ids = browsable.map((a) => a.id).toSet();
    // aw-3 and aw-7 are drafts, aw-2 is in review.
    expect(ids.contains('aw-1'), isTrue);
    expect(ids.contains('aw-2'), isFalse);
    expect(ids.contains('aw-3'), isFalse);
    expect(ids.contains('aw-7'), isFalse);
  });

  test('the artist price rides alongside, never inside, the artwork', () async {
    final portal = await repository.listArtworks();
    final monsoon = portal.firstWhere((entry) => entry.artwork.id == 'aw-1');

    expect(monsoon.artistPrice, 28000);
    // The customer price is the whole ladder — 30% margin, then GST inside —
    // and `Artwork` itself has no field that could leak the artist's number.
    expect(monsoon.artwork.customerPrice, displayPriceOf(28000));
    expect(monsoon.artwork.customerPrice, 38220);
  });

  group('submitting an artwork', () {
    test('lands in the review queue, not the marketplace', () async {
      final artwork = await repository.submitArtwork(_input());
      expect(artwork.status, ArtworkStatus.pendingApproval);
      expect(artwork.customerPrice, displayPriceOf(20000));
      expect(artwork.coaCertificateNumber, startsWith('GZ-COA-'));

      final browsable = await MockArtworkRepository().list(const ArtworkFilters());
      expect(browsable.map((a) => a.id), isNot(contains(artwork.id)));

      final portal = await repository.listArtworks();
      final submitted = portal.firstWhere((entry) => entry.artwork.id == artwork.id);
      expect(submitted.artistPrice, 20000);
    });

    test('a draft is marked as such', () async {
      final artwork = await repository.submitArtwork(_input(asDraft: true));
      expect(artwork.status, ArtworkStatus.draft);
    });

    test('an empty title or a zero price is rejected', () {
      expect(() => repository.submitArtwork(_input(title: '  ')), throwsA(isA<Exception>()));
      expect(() => repository.submitArtwork(_input(price: 0)), throwsA(isA<Exception>()));
    });

    test('appends to the activity feed', () async {
      final before = (await repository.listActivity()).length;
      await repository.submitArtwork(_input(title: 'Feed check'));
      final after = await repository.listActivity();
      expect(after, hasLength(before + 1));
      expect(after.first.title, contains('Feed check'));
    });
  });

  group('withdrawals', () {
    test('move the balance and record a transaction', () async {
      final before = await repository.getWallet();
      final transaction = await repository.requestWithdrawal(10000);

      expect(transaction.amount, -10000);
      expect((await repository.getWallet()).balance, before.balance - 10000);
      expect((await repository.listWalletTransactions()).first.id, transaction.id);
    });

    test('below the floor or above the balance is refused', () async {
      final wallet = await repository.getWallet();
      expect(() => repository.requestWithdrawal(999), throwsA(isA<Exception>()));
      expect(
        () => repository.requestWithdrawal(wallet.balance + 1),
        throwsA(isA<Exception>()),
      );
    });
  });

  test('bank details keep only the last four digits', () async {
    final updated = await repository.updateBankDetails(
      accountNumber: '123456789012',
      ifsc: 'HDFC0009999',
    );
    expect(updated.bankAccountMasked, '•••• •••• •••• 9012');
    expect(updated.bankAccountMasked, isNot(contains('12345678')));
    expect(updated.ifsc, 'HDFC0009999');
  });

  test('KPIs count what is actually awaiting review', () async {
    final before = await repository.getKpis();
    expect(before[2].value, '1'); // aw-2 only

    await repository.submitArtwork(_input(title: 'Another submission'));
    final after = await repository.getKpis();
    expect(after[2].value, '2');
  });

  test('opening a message marks it read', () async {
    final messages = await repository.listMessages();
    expect(messages.where((m) => m.unread), hasLength(2));

    await repository.markMessageRead(messages.first.id);
    expect((await repository.listMessages()).where((m) => m.unread), hasLength(1));
  });

  test('gallery spaces join a holding to the artist\'s own artwork', () async {
    final placements = await repository.listGallerySpaces();
    expect(placements, hasLength(1));
    expect(placements.single.artwork.id, 'aw-4');
    expect(placements.single.holding.advancePercent, 5);
  });

  testWidgets('the artworks board shows both prices — the type wall in use',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [artistRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: AppTheme.dark, home: const ArtistArtworksScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Monsoon Reverie'), findsOneWidget);
    expect(find.text('₹28,000'), findsOneWidget); // artist price
    expect(find.text(formatInr(displayPriceOf(28000))), findsOneWidget);

    // Each row now carries its channel and edit-window footer, so only the
    // first row or two fit a phone-sized viewport — scroll to a row rather
    // than asserting on one the list never built.
    await tester.scrollUntilVisible(find.text('Terracotta Study No. 4'), 240);
    expect(find.text('In review'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Portrait in Amber'), 240);
    expect(find.text('Draft'), findsWidgets);
  });

  testWidgets('the artist shell swaps its navigation surface by width',
      (tester) async {
    Future<void> pumpAt(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                ArtistShell(navigationShell: navigationShell),
            branches: [
              for (final destination in artistDestinations)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/${destination.label.toLowerCase()}',
                      builder: (context, state) => Center(child: Text(destination.label)),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          // The shell's Profile drawer reads the session, and the session
          // provider refuses to guess a role.
          overrides: [initialRoleProvider.overrideWithValue(Role.artist)],
          child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpAt(const Size(400, 900));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    // Profile is the last destination and is not a branch: it opens the
    // portal menu over whichever tab you were on.
    expect(find.text('Profile'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    await pumpAt(const Size(1000, 900));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
