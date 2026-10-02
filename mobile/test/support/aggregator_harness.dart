import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/aggregator.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/repositories/aggregator_repository.dart';
import 'package:gallery_zone/features/aggregator/providers/aggregator_providers.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_account_screens.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_analytics_screen.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_dashboard_screen.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_inventory_screen.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_profile_screen.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';

import 'catalog_fixtures.dart';

/// An instant [days] days before now, as the API writes it.
String daysAgo(int days) => DateTime.now().toUtc().subtract(Duration(days: days)).toIso8601String();

AggregatorSale testSale({
  String id = 's1',
  String holdingId = 'h1',
  String artworkId = 'aw-1',
  double price = 136500,
  String buyerEmail = 'anita@example.com',
  PaymentRoute route = PaymentRoute.directToGalleryZone,
  String? remittedAt,
}) =>
    AggregatorSale(
      id: id,
      holdingId: holdingId,
      artworkId: artworkId,
      soldPrice: price,
      buyerName: 'Anita Sen',
      buyerEmail: buyerEmail,
      buyerPhone: '9845012345',
      deliveryAddress: const DeliveryAddress(line1: '14 Church Street', city: 'Bengaluru', state: 'Karnataka', pincode: '560001'),
      deliveryMode: DeliveryMode.courier,
      soldAt: daysAgo(1),
      shipmentStatus: ShipmentStatus.preparing,
      paymentRoute: route,
      remittedAt: remittedAt,
    );

AggregatorHoldingView testHolding(
  String id,
  String title, {
  HoldingStatus status = HoldingStatus.reserved,
  String? assignedAt,
}) =>
    AggregatorHoldingView(
      holding: AggregatorHolding(
        id: id,
        artworkId: 'aw-$id',
        advancePercent: 5,
        advanceAmount: 6500,
        displayPrice: 136500,
        assignedAt: assignedAt ?? daysAgo(0),
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 20)).toIso8601String(),
        status: status,
        assignmentSource: AssignmentSource.selfReserved,
        deliveryDeposit: 2500,
      ),
      artwork: fixtureArtwork(id: 'aw-$id', title: title),
    );

Widget _stub(String text) => Scaffold(body: Center(child: Text(text)));

/// Shows [at] inside the aggregator routes the account-side screens link to. Pages
/// that are not under test are stubs that say where they are.
Future<void> pumpAggregator(
  WidgetTester tester,
  AggregatorRepository repository,
  String at, {
  bool remote = true,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 3000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: at,
    routes: [
      GoRoute(path: AggregatorDashboardScreen.path, builder: (context, state) => const AggregatorDashboardScreen()),
      GoRoute(path: AggregatorAnalyticsScreen.path, builder: (context, state) => const AggregatorAnalyticsScreen()),
      GoRoute(path: AggregatorProfileScreen.path, builder: (context, state) => const AggregatorProfileScreen()),
      GoRoute(path: AggregatorGallerySpacesScreen.path, builder: (context, state) => const AggregatorGallerySpacesScreen()),
      GoRoute(path: AggregatorMessagesScreen.path, builder: (context, state) => const AggregatorMessagesScreen()),
      GoRoute(path: AggregatorSettingsScreen.path, builder: (context, state) => const AggregatorSettingsScreen()),
      GoRoute(path: AggregatorSupportScreen.path, builder: (context, state) => const AggregatorSupportScreen()),
      GoRoute(path: AggregatorBrowseScreen.path, builder: (context, state) => _stub('BROWSE PAGE')),
      GoRoute(path: '/aggregator/dashboard/mou', builder: (context, state) => _stub('MOU PAGE')),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        aggregatorRepositoryProvider.overrideWithValue(repository),
        remoteBackendProvider.overrideWithValue(remote),
        initialRoleProvider.overrideWithValue(null),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls to [finder], then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
