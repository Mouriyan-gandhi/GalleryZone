import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/data/models/auth.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:gallery_zone/core/adaptive.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/mock/mock_customer_repository.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/customer.dart';
import 'package:gallery_zone/data/models/order.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/account/providers/account_providers.dart';
import 'package:gallery_zone/features/account/widgets/customer_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Artwork _artwork(String id) => Artwork(
      id: id,
      title: 'Monsoon, Madurai',
      artistId: 'ar-1',
      artistName: 'Ananya Rao',
      verifiedArtist: true,
      category: 'painting',
      medium: 'Oil on canvas',
      customerPrice: 23400,
      thumbnailUrl: '/artworks/bird.png',
      insured: true,
      status: ArtworkStatus.sold,
      listingType: ListingType.marketplaceOnly,
      description: 'A study in rain light.',
      images: const [],
      coaCertificateNumber: 'GZ-COA-0001',
      coaIssueDate: '2025-03-04',
      socialProofLinks: const [],
      statusHistory: const [],
    );

void main() {
  late MockCustomerRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
    repository = MockCustomerRepository();
  });

  group('address book', () {
    test('seeds on first read', () async {
      final addresses = await repository.listAddresses();
      expect(addresses, hasLength(3));
      expect(addresses.first.id, 'addr-home-pune');
      expect(addresses.first.isDefault, isTrue);
    });

    test('add, update and delete round-trip through storage', () async {
      final created = await repository.addAddress(
        const Address(
          id: '',
          line1: '5 Residency Road',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560025',
          isDefault: false,
        ),
      );
      expect(created.id, isNotEmpty);
      expect(await repository.listAddresses(), hasLength(4));

      await repository.updateAddress(created.copyWith(city: 'Mysuru'));
      final updated = (await repository.listAddresses()).firstWhere((a) => a.id == created.id);
      expect(updated.city, 'Mysuru');

      await repository.deleteAddress(created.id);
      expect(await repository.listAddresses(), hasLength(3));
    });

    test('updating or deleting an unknown address fails loudly', () {
      expect(
        () => repository.deleteAddress('addr-nope'),
        throwsA(isA<Exception>()),
      );
    });
  });

  test('profile edits persist — a successful save is not silently discarded',
      () async {
    final profile = await repository.getProfile();
    expect(profile.name, 'Aarav Shah');

    await repository.updateProfile(profile.copyWith(name: 'Aarav S.'));
    expect((await repository.getProfile()).name, 'Aarav S.');

    // A second repository instance reads the same stored value.
    expect((await MockCustomerRepository().getProfile()).name, 'Aarav S.');
  });

  test('collection is exactly the delivered orders, joined to their artwork',
      () async {
    // Only `order-monsoon-madurai` is delivered in the seed set. Pinning the
    // collection to one record keeps the assertion about the join, not about
    // how many fixtures happen to ship.
    MockDb.setCollection('artworks', [_artwork('monsoon-over-madurai')], (a) => a.toJson());

    final collection = await repository.listCollection();
    expect(collection, hasLength(1));
    expect(collection.single.order.status, OrderStatus.delivered);
    expect(collection.single.artwork.id, 'monsoon-over-madurai');
  });

  test('a delivered order whose artwork is gone is skipped, not rendered blank',
      () async {
    MockDb.setCollection('artworks', <Artwork>[], (a) => a.toJson());
    expect(await repository.listCollection(), isEmpty);
  });

  group('resale', () {
    test('create then withdraw', () async {
      expect(await repository.listResaleListings(), isEmpty);

      final listing = await repository.createResaleListing(
        artworkId: 'monsoon-over-madurai',
        listedPrice: 30000,
      );
      expect(listing.status, ResaleListingStatus.active);

      final withdrawn = await repository.withdrawResaleListing(listing.id);
      expect(withdrawn.status, ResaleListingStatus.withdrawn);
      expect((await repository.listResaleListings()).single.status,
          ResaleListingStatus.withdrawn);
    });

    test('a non-positive price is rejected', () {
      expect(
        () => repository.createResaleListing(artworkId: 'aw-1', listedPrice: 0),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('support', () {
    test('submitting prepends to the seeded ticket', () async {
      expect(await repository.listSupportTickets(), hasLength(1));

      final ticket = await repository.submitSupportTicket(
        subject: '  Damaged frame  ',
        message: '  The corner arrived chipped.  ',
      );
      expect(ticket.subject, 'Damaged frame'); // trimmed
      expect(ticket.status, SupportTicketStatus.open);

      final tickets = await repository.listSupportTickets();
      expect(tickets, hasLength(2));
      expect(tickets.first.id, ticket.id);
    });

    test('empty subject or message is rejected', () {
      expect(
        () => repository.submitSupportTicket(subject: '   ', message: 'hi'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => repository.submitSupportTicket(subject: 'hi', message: '   '),
        throwsA(isA<Exception>()),
      );
    });
  });

  test('initials fall back sensibly', () {
    expect(initials('Aarav Shah'), 'AS');
    expect(initials('Aarav'), 'A');
    expect(initials(''), '');
  });

  group('window size classification', () {
    test('Material breakpoints', () {
      expect(WindowSize.fromWidth(599), WindowSize.compact);
      expect(WindowSize.fromWidth(600), WindowSize.medium);
      expect(WindowSize.fromWidth(839), WindowSize.medium);
      expect(WindowSize.fromWidth(840), WindowSize.expanded);
    });
  });

  group('customer shell navigation surface', () {
    Future<void> pumpShellAt(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/account',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                CustomerShell(navigationShell: navigationShell),
            branches: [
              for (final destination in shellDestinations)
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
          overrides: [initialRoleProvider.overrideWithValue(Role.customer)],
          child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
        ),
      );
      // The drawer's header reads the collector's name, and every mock
      // repository call sleeps 600ms — settle first, then let that land, or
      // the timer outlives the test.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    }

    testWidgets('compact uses a bottom bar', (tester) async {
      await pumpShellAt(tester, const Size(400, 900));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('expanded uses a rail instead, same destinations', (tester) async {
      await pumpShellAt(tester, const Size(1000, 900));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      // Every destination survives the swap — the surface changes, the
      // information architecture doesn't.
      for (final destination in shellDestinations) {
        expect(find.text(destination.label), findsWidgets);
      }
    });
  });
}
