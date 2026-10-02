import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gallery_zone/core/format.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/aggregator.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/customer.dart' show WalletSummary;
import 'package:gallery_zone/data/repositories/aggregator_repository.dart';
import 'package:gallery_zone/features/aggregator/providers/aggregator_providers.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_finance_screens.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_inventory_screen.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_operations_screens.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_wallet_screen.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';

import 'support/catalog_fixtures.dart';

// --- Fixtures --------------------------------------------------------------------

String _daysAgo(int days) => DateTime.now().toUtc().subtract(Duration(days: days)).toIso8601String();

AggregatorSale _sale({
  String id = 's1',
  String holdingId = 'h1',
  String artworkId = 'aw-1',
  double price = 136500,
  String buyer = 'Anita Sen',
  String email = 'anita@example.com',
  String phone = '9845012345',
  ShipmentStatus ship = ShipmentStatus.preparing,
  PaymentRoute route = PaymentRoute.directToGalleryZone,
  DeliveryMode mode = DeliveryMode.courier,
  String? soldAt,
  String? remittedAt,
  String? dueAt,
  String? courierRef,
}) =>
    AggregatorSale(
      id: id,
      holdingId: holdingId,
      artworkId: artworkId,
      soldPrice: price,
      buyerName: buyer,
      buyerEmail: email,
      buyerPhone: phone,
      deliveryAddress: const DeliveryAddress(
        line1: '14 Church Street',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560001',
      ),
      deliveryMode: mode,
      soldAt: soldAt ?? _daysAgo(1),
      shipmentStatus: ship,
      paymentRoute: route,
      remittedAt: remittedAt,
      remitDueAt: dueAt,
      courierRef: courierRef,
    );

AggregatorHoldingView _view(
  String holdingId,
  String artworkId,
  String title, {
  HoldingStatus status = HoldingStatus.soldPendingSettlement,
}) =>
    AggregatorHoldingView(
      holding: AggregatorHolding(
        id: holdingId,
        artworkId: artworkId,
        advancePercent: 5,
        advanceAmount: 6500,
        displayPrice: 136500,
        assignedAt: '2026-09-15T00:00:00.000Z',
        expiresAt: '2026-10-15T00:00:00.000Z',
        status: status,
        assignmentSource: AssignmentSource.selfReserved,
        deliveryDeposit: 2500,
      ),
      artwork: fixtureArtwork(id: artworkId, title: title),
    );

Settlement _settlement(String orderId, String title, double commission,
        {SettlementStatus status = SettlementStatus.processed, String? processedAt}) =>
    Settlement(
      id: 'stl-$orderId',
      orderId: orderId,
      artworkTitle: title,
      artistName: 'Ananya Rao',
      artistAmount: 0,
      aggregatorCommission: commission,
      platformRevenue: 0,
      status: status,
      createdAt: '2026-09-20T00:00:00.000Z',
      processedAt: processedAt,
    );

/// An in-memory aggregator service for the sales-side screens.
class _Ops implements AggregatorRepository {
  _Ops({
    this.sales = const [],
    this.holdings = const [],
    this.commissions = const {},
    this.customers = const [],
    this.settlements = const [],
    this.due = const [],
    this.free = 50000,
  });

  List<AggregatorSale> sales;
  List<AggregatorHoldingView> holdings;
  Map<String, double> commissions;
  List<AggregatorCustomer> customers;
  List<Settlement> settlements;
  List<AggregatorSale> due;
  double free;

  final advanced = <({String id, String? ref})>[];
  final remitted = <({String id, RemitVia via})>[];
  final processed = <String>[];
  Object? failSalesWith;
  Object? failRemitWith;

  @override
  Future<List<AggregatorSale>> listSales() async {
    if (failSalesWith != null) {
      final error = failSalesWith!;
      failSalesWith = null;
      throw error;
    }
    return List.of(sales);
  }

  @override
  Future<List<AggregatorHoldingView>> listCollection() async => List.of(holdings);

  @override
  Future<Map<String, double>> saleCommissions() async => Map.of(commissions);

  @override
  Future<List<AggregatorCustomer>> listCustomers() async => List.of(customers);

  @override
  Future<List<Settlement>> listSettlements() async => List.of(settlements);

  @override
  Future<List<AggregatorSale>> listRemittancesDue() async => List.of(due);

  @override
  Future<WalletSummary> getWallet() async => WalletSummary(balance: free, pendingBalance: 0, lockedBalance: 0);

  @override
  Future<AggregatorSale> advanceShipment(String saleId, {String? courierRef}) async {
    advanced.add((id: saleId, ref: courierRef));
    final current = sales.firstWhere((s) => s.id == saleId);
    final updated = current.copyWith(
      shipmentStatus: current.shipmentStatus == ShipmentStatus.preparing ? ShipmentStatus.dispatched : ShipmentStatus.delivered,
      courierRef: (courierRef != null && courierRef.isNotEmpty) ? courierRef : current.courierRef,
    );
    sales = [for (final s in sales) s.id == saleId ? updated : s];
    return updated;
  }

  @override
  Future<AggregatorSale> markRemitted(String saleId, {RemitVia via = RemitVia.wallet}) async {
    if (failRemitWith != null) throw failRemitWith!;
    remitted.add((id: saleId, via: via));
    final sale = due.firstWhere((s) => s.id == saleId);
    due = [for (final s in due) if (s.id != saleId) s];
    return sale;
  }

  @override
  Future<Settlement> processSettlement(String saleId) async {
    processed.add(saleId);
    final settlement = _settlement(saleId, 'Settled', 6000);
    settlements = [...settlements, settlement];
    return settlement;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- Harness -----------------------------------------------------------------------

Widget _stub(String text) => Scaffold(body: Center(child: Text(text)));

Future<void> _show(
  WidgetTester tester,
  _Ops ops,
  String at, {
  bool remote = true,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: at,
    routes: [
      GoRoute(path: AggregatorOrdersScreen.path, builder: (context, state) => const AggregatorOrdersScreen()),
      GoRoute(path: AggregatorCustomersScreen.path, builder: (context, state) => const AggregatorCustomersScreen()),
      GoRoute(path: AggregatorShippingScreen.path, builder: (context, state) => const AggregatorShippingScreen()),
      GoRoute(path: AggregatorSettlementsScreen.path, builder: (context, state) => const AggregatorSettlementsScreen()),
      GoRoute(path: AggregatorBrowseScreen.path, builder: (context, state) => _stub('BROWSE PAGE')),
      GoRoute(path: AggregatorWalletScreen.path, builder: (context, state) => _stub('WALLET PAGE')),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        aggregatorRepositoryProvider.overrideWithValue(ops),
        remoteBackendProvider.overrideWithValue(remote),
        initialRoleProvider.overrideWithValue(null),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
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

/// Opens a pill dropdown and chooses one of its entries.
Future<void> _pick(WidgetTester tester, String pill, String option) async {
  // Inside the dropdown only: a card's own "Dispatched" pill reads the same.
  final button = find.descendant(of: find.byType(PopupMenuButton<int>), matching: find.text(pill));
  await tester.ensureVisible(button); // the row of pills scrolls sideways
  await tester.pump();
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(PopupMenuItem<int>), matching: find.text(option)));
  await tester.pumpAndSettle();
}

void main() {
  // Three sales, three pieces.
  final holdings = [
    _view('h1', 'aw-1', 'Monsoon, Madurai'),
    _view('h2', 'aw-2', 'Bronze Dancer'),
    _view('h3', 'aw-3', 'Late Light'),
  ];

  group('orders & sales', () {
    _Ops ops3() => _Ops(
          holdings: holdings,
          commissions: {'s1': 12345, 's2': 6000, 's3': 0},
          sales: [
            _sale(id: 's1', holdingId: 'h1', artworkId: 'aw-1', buyer: 'Anita Sen', soldAt: _daysAgo(3)),
            _sale(
              id: 's2',
              holdingId: 'h2',
              artworkId: 'aw-2',
              buyer: 'Ravi Kumar',
              email: 'ravi@example.com',
              price: 90000,
              ship: ShipmentStatus.dispatched,
              route: PaymentRoute.cashAtPremises,
              dueAt: _daysAgo(-1),
              soldAt: _daysAgo(20),
            ),
            _sale(
              id: 's3',
              holdingId: 'h3',
              artworkId: 'aw-3',
              buyer: 'Meena Iyer',
              email: 'meena@example.com',
              price: 50000,
              ship: ShipmentStatus.delivered,
              route: PaymentRoute.cashAtPremises,
              remittedAt: _daysAgo(60),
              soldAt: _daysAgo(100),
            ),
          ],
        );

    testWidgets('each sale shows the piece, the buyer, the price and where the shipment is', (tester) async {
      await _show(tester, ops3(), AggregatorOrdersScreen.path);
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.text('Anita Sen'), findsOneWidget);
      expect(find.text('₹1,36,500'), findsOneWidget);
      expect(find.text('Preparing'), findsOneWidget);
      expect(find.text('Dispatched'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text(formatDay(_daysAgo(3))), findsOneWidget);
      // The website's decorative tabs filter nothing, so they are not drawn.
      expect(find.text('Reservations'), findsNothing);
    });

    testWidgets('search finds a sale by buyer, by email or by the piece', (tester) async {
      await _show(tester, ops3(), AggregatorOrdersScreen.path);
      await tester.enterText(find.byType(TextField).first, 'ravi');
      await tester.pumpAndSettle();
      expect(find.text('Bronze Dancer'), findsOneWidget);
      expect(find.text('Monsoon, Madurai'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'late light');
      await tester.pumpAndSettle();
      expect(find.text('Late Light'), findsOneWidget);
      expect(find.text('Bronze Dancer'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No sales match these filters.'), findsOneWidget);
      await _tap(tester, find.text('Clear filters'));
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.text('Bronze Dancer'), findsOneWidget);
    });

    testWidgets('filters by shipment, by date and by whether GalleryZone has been paid - and they combine', (tester) async {
      await _show(tester, ops3(), AggregatorOrdersScreen.path);

      await _pick(tester, 'All Shipment', 'Dispatched');
      expect(find.text('Bronze Dancer'), findsOneWidget);
      expect(find.text('Monsoon, Madurai'), findsNothing);
      expect(find.text('Late Light'), findsNothing);

      // Back to everything, then by date: 3, 20 and 100 days ago.
      await _pick(tester, 'Dispatched', 'All Shipment');
      await _pick(tester, 'All Dates', 'Last 7 days');
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.text('Bronze Dancer'), findsNothing);

      await _pick(tester, 'Last 7 days', 'Last 30 days');
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.text('Bronze Dancer'), findsOneWidget);
      expect(find.text('Late Light'), findsNothing);

      await _pick(tester, 'Last 30 days', 'This year');
      expect(find.text('Late Light'), findsOneWidget);

      // Cash not yet paid in is the only thing owed.
      await _pick(tester, 'All Status', 'Owed to GalleryZone');
      expect(find.text('Bronze Dancer'), findsOneWidget);
      expect(find.text('Late Light'), findsNothing, reason: 'its cash was paid in');
      expect(find.text('Monsoon, Madurai'), findsNothing, reason: 'the buyer paid GalleryZone directly');

      await _pick(tester, 'Owed to GalleryZone', 'Settled');
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.text('Late Light'), findsOneWidget);
      expect(find.text('Bronze Dancer'), findsNothing);
    });

    testWidgets('the clear button resets search and filters at once, and is off when there is nothing to clear', (tester) async {
      await _show(tester, ops3(), AggregatorOrdersScreen.path);
      Finder clear() => find.widgetWithIcon(IconButton, LucideIcons.slidersHorizontal);
      expect(tester.widget<IconButton>(clear()).onPressed, isNull);

      await _pick(tester, 'All Shipment', 'Delivered');
      await tester.enterText(find.byType(TextField).first, 'late');
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(clear()).onPressed, isNotNull);

      await _tap(tester, clear());
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.text('Bronze Dancer'), findsOneWidget);
      expect(find.text('Late Light'), findsOneWidget);
      expect(find.text('All Shipment'), findsOneWidget);
    });

    testWidgets("a sale's detail has the buyer, the address, the payment and the commission the ledger credited", (tester) async {
      await _show(tester, ops3(), AggregatorOrdersScreen.path);
      await _tap(tester, find.text('Monsoon, Madurai'));
      expect(find.text('Sold to Anita Sen for ₹1,36,500'), findsOneWidget);
      expect(find.text('anita@example.com'), findsOneWidget);
      expect(find.text('9845012345'), findsOneWidget);
      expect(find.text('Courier'), findsOneWidget);
      expect(find.text('₹12,345'), findsOneWidget, reason: 'the credited figure, not one worked out here');
      expect(find.text('Settled'), findsOneWidget);
      expect(find.text('14 Church Street, Bengaluru, Karnataka 560001'), findsOneWidget);
      expect(find.text('Courier reference'), findsNothing);
    });

    testWidgets('a cash sale not yet paid in says it is owed; a dispatched one carries its courier reference', (tester) async {
      final ops = ops3();
      ops.sales = [for (final s in ops.sales) s.id == 's2' ? s.copyWith(courierRef: 'BD-4471') : s];
      await _show(tester, ops, AggregatorOrdersScreen.path);
      await _tap(tester, find.text('Bronze Dancer'));
      expect(find.text('Owed to GalleryZone'), findsOneWidget);
      expect(find.text('BD-4471'), findsOneWidget);
      expect(find.text('₹6,000'), findsOneWidget);
    });

    testWidgets('no sales yet points back to Browse', (tester) async {
      await _show(tester, _Ops(), AggregatorOrdersScreen.path);
      expect(find.text('No sales yet'), findsOneWidget);
      await _tap(tester, find.text('Browse GalleryZone'));
      expect(find.text('BROWSE PAGE'), findsOneWidget);
    });

    testWidgets("a failed load says why and can be retried", (tester) async {
      final ops = ops3()..failSalesWith = Exception('Too many requests. Wait a moment and try again.');
      await _show(tester, ops, AggregatorOrdersScreen.path);
      expect(find.text("Couldn't load your sales"), findsOneWidget);
      expect(find.text('Too many requests. Wait a moment and try again.'), findsOneWidget);
      await _tap(tester, find.text('Try again'));
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
    });
  });

  group('customers', () {
    final customers = [
      // As the service hands them over: biggest spender first.
      const AggregatorCustomer(buyerName: 'Meena Iyer', buyerEmail: 'meena@example.com', buyerPhone: '9000000002', orderCount: 1, totalSpend: 500000),
      const AggregatorCustomer(buyerName: 'Ravi Kumar', buyerEmail: 'ravi@example.com', buyerPhone: '9000000003', orderCount: 2, totalSpend: 250000),
      const AggregatorCustomer(buyerName: 'Anita Sen', buyerEmail: 'zed@example.com', buyerPhone: '9000000001', orderCount: 3, totalSpend: 90000),
    ];

    double top(WidgetTester tester, String name) => tester.getTopLeft(find.text(name)).dy;

    testWidgets('one card per buyer, biggest spender first', (tester) async {
      await _show(tester, _Ops(customers: customers), AggregatorCustomersScreen.path);
      expect(find.text('3 orders'), findsOneWidget);
      expect(find.text('1 order'), findsOneWidget);
      expect(find.text('₹5,00,000'), findsOneWidget);
      expect(top(tester, 'Meena Iyer'), lessThan(top(tester, 'Ravi Kumar')));
      expect(top(tester, 'Ravi Kumar'), lessThan(top(tester, 'Anita Sen')));
    });

    testWidgets('search by name or email', (tester) async {
      await _show(tester, _Ops(customers: customers), AggregatorCustomersScreen.path);
      await tester.enterText(find.byType(TextField).first, 'zed@');
      await tester.pumpAndSettle();
      expect(find.text('Anita Sen'), findsOneWidget);
      expect(find.text('Ravi Kumar'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'nobody');
      await tester.pumpAndSettle();
      expect(find.text('No customers match'), findsOneWidget);
    });

    testWidgets('a sort ascends, then descends, then clears - as the website\'s table does', (tester) async {
      await _show(tester, _Ops(customers: customers), AggregatorCustomersScreen.path);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Name'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Name ↑'), findsOneWidget);
      expect(top(tester, 'Anita Sen'), lessThan(top(tester, 'Meena Iyer')));
      expect(top(tester, 'Meena Iyer'), lessThan(top(tester, 'Ravi Kumar')));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Name ↑'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Name ↓'), findsOneWidget);
      expect(top(tester, 'Ravi Kumar'), lessThan(top(tester, 'Anita Sen')));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Name ↓'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Name'), findsOneWidget);
      expect(top(tester, 'Meena Iyer'), lessThan(top(tester, 'Anita Sen')), reason: 'back to biggest spender first');

      await tester.tap(find.widgetWithText(ChoiceChip, 'Orders'));
      await tester.pumpAndSettle();
      expect(top(tester, 'Meena Iyer'), lessThan(top(tester, 'Ravi Kumar')), reason: '1 order, then 2, then 3');
      expect(top(tester, 'Ravi Kumar'), lessThan(top(tester, 'Anita Sen')));
    });

    testWidgets('no buyers yet', (tester) async {
      await _show(tester, _Ops(), AggregatorCustomersScreen.path);
      expect(find.text('No customers yet'), findsOneWidget);
    });
  });

  group('shipping', () {
    testWidgets('pieces to collect, then deliveries to make', (tester) async {
      final ops = _Ops(
        holdings: [
          _view('h9', 'aw-9', 'Waiting One', status: HoldingStatus.reserved),
          _view('h1', 'aw-1', 'Monsoon, Madurai'),
        ],
        sales: [_sale()],
      );
      await _show(tester, ops, AggregatorShippingScreen.path);
      expect(find.text('Inbound'), findsOneWidget);
      expect(find.text('Waiting One'), findsOneWidget);
      expect(find.text('Due for pickup'), findsOneWidget);
      expect(find.text('Outbound'), findsOneWidget);
      expect(find.text('Monsoon, Madurai'), findsOneWidget, reason: 'the outbound card is named for the piece');
      expect(find.text('Anita Sen · Courier'), findsOneWidget);
      expect(find.text('14 Church Street, Bengaluru, Karnataka 560001'), findsOneWidget);
    });

    testWidgets('nothing in either list says so', (tester) async {
      await _show(tester, _Ops(), AggregatorShippingScreen.path);
      expect(find.text('Nothing inbound'), findsOneWidget);
      expect(find.text('No outbound shipments yet'), findsOneWidget);
    });

    testWidgets('dispatching a courier sale asks for the reference, and sends it', (tester) async {
      final ops = _Ops(holdings: holdings, sales: [_sale()]);
      await _show(tester, ops, AggregatorShippingScreen.path);
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Mark dispatched'));
      expect(find.text('Courier reference (optional)'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, ' BD-4471 ');
      await _tap(tester, find.widgetWithText(FilledButton, 'Mark dispatched'));
      expect(ops.advanced, [(id: 's1', ref: 'BD-4471')]);
      expect(find.text('Shipment marked dispatched'), findsOneWidget);
      expect(find.text('Anita Sen · BD-4471'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Mark delivered'), findsOneWidget);
    });

    testWidgets('a reference is optional, and closing the question cancels the dispatch', (tester) async {
      final ops = _Ops(holdings: holdings, sales: [_sale()]);
      await _show(tester, ops, AggregatorShippingScreen.path);

      await _tap(tester, find.widgetWithText(OutlinedButton, 'Mark dispatched'));
      await _tap(tester, find.text('Cancel'));
      expect(ops.advanced, isEmpty);

      await _tap(tester, find.widgetWithText(OutlinedButton, 'Mark dispatched'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Mark dispatched'));
      expect(ops.advanced, [(id: 's1', ref: '')]);
    });

    testWidgets('a self-pickup sale has no courier, so nothing to ask', (tester) async {
      final ops = _Ops(holdings: holdings, sales: [_sale(mode: DeliveryMode.selfPickup)]);
      await _show(tester, ops, AggregatorShippingScreen.path);
      expect(find.text('Anita Sen · Self pickup'), findsOneWidget);
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Mark dispatched'));
      expect(find.text('Courier reference (optional)'), findsNothing);
      expect(ops.advanced, [(id: 's1', ref: null)]);
    });

    testWidgets('delivering needs no question, and a delivered sale is done', (tester) async {
      final ops = _Ops(holdings: holdings, sales: [_sale(ship: ShipmentStatus.dispatched, courierRef: 'BD-4471')]);
      await _show(tester, ops, AggregatorShippingScreen.path);
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Mark delivered'));
      expect(ops.advanced, [(id: 's1', ref: null)]);
      expect(find.text('Done'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  group('settlements', () {
    AggregatorSale cash(String id, String buyer, double price, {required String dueAt, String soldAt = '2026-09-29T00:00:00.000Z'}) =>
        _sale(id: id, buyer: buyer, price: price, route: PaymentRoute.cashAtPremises, dueAt: dueAt, soldAt: soldAt);

    testWidgets('cash owed leads, with the total, when each is due and which are late', (tester) async {
      final ops = _Ops(
        due: [
          cash('s1', 'Ravi Kumar', 90000, dueAt: _daysAgo(3)),
          cash('s2', 'Meena Iyer', 40000, dueAt: _daysAgo(-1)),
        ],
        free: 500000,
      );
      await _show(tester, ops, AggregatorSettlementsScreen.path);
      expect(find.text('Owed to GalleryZone'), findsOneWidget);
      expect(find.text('₹1,30,000'), findsOneWidget);
      expect(find.textContaining('within 2 days'), findsOneWidget);
      expect(find.text('Overdue by 3 days'), findsOneWidget);
      expect(find.textContaining('· due'), findsOneWidget, reason: 'only the one not yet late says when it is due');
      expect(find.text('Pay from wallet'), findsNWidgets(2));
      expect(find.text('Mark transferred'), findsNWidgets(2));
    });

    testWidgets('a sale past its due date by less than a day is just "Overdue"', (tester) async {
      final late = DateTime.now().toUtc().subtract(const Duration(hours: 5)).toIso8601String();
      await _show(tester, _Ops(due: [cash('s1', 'Ravi Kumar', 90000, dueAt: late)], free: 500000), AggregatorSettlementsScreen.path);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.textContaining('Overdue by'), findsNothing);
    });

    testWidgets('the wallet cannot pay what it cannot cover, and says how much to add', (tester) async {
      final ops = _Ops(due: [cash('s1', 'Ravi Kumar', 90000, dueAt: _daysAgo(-1))], free: 30000);
      await _show(tester, ops, AggregatorSettlementsScreen.path);
      expect(find.text('Add ₹60,000 to your wallet first to pay from it.'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Pay from wallet')).onPressed, isNull);
      // A bank transfer needs no balance.
      expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Mark transferred')).onPressed, isNotNull);

      await _tap(tester, find.text('Open Earnings & Wallet'));
      expect(find.text('WALLET PAGE'), findsOneWidget);
    });

    testWidgets('paying from the wallet asks first, then pays that sale and no other', (tester) async {
      final ops = _Ops(
        due: [cash('s1', 'Ravi Kumar', 90000, dueAt: _daysAgo(-1)), cash('s2', 'Meena Iyer', 40000, dueAt: _daysAgo(-1))],
        free: 500000,
      );
      await _show(tester, ops, AggregatorSettlementsScreen.path);

      await _tap(tester, find.widgetWithText(FilledButton, 'Pay from wallet').first);
      expect(find.text('Pay from your wallet?'), findsOneWidget);
      expect(find.textContaining('₹90,000 is taken from your free wallet balance'), findsOneWidget);
      await _tap(tester, find.text('Not yet'));
      expect(ops.remitted, isEmpty);

      await _tap(tester, find.widgetWithText(FilledButton, 'Pay from wallet').first);
      await _tap(tester, find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Pay from wallet')));
      expect(ops.remitted, [(id: 's1', via: RemitVia.wallet)]);
      expect(find.text('Paid from your wallet'), findsOneWidget);
      expect(find.text('Ravi Kumar'), findsNothing, reason: 'paid in, so no longer owed');
      expect(find.text('Meena Iyer'), findsOneWidget);
    });

    testWidgets('"Mark transferred" is by bank - not the wallet, which is what the old button silently did', (tester) async {
      final ops = _Ops(due: [cash('s1', 'Ravi Kumar', 90000, dueAt: _daysAgo(-1))], free: 500000);
      await _show(tester, ops, AggregatorSettlementsScreen.path);
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Mark transferred'));
      expect(find.text('Mark as transferred?'), findsOneWidget);
      expect(find.textContaining("transferred ₹90,000 to GalleryZone's bank account"), findsOneWidget);
      await _tap(tester, find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Mark transferred')));
      expect(ops.remitted, [(id: 's1', via: RemitVia.bank)]);
      expect(find.text('Marked as transferred'), findsOneWidget);
    });

    testWidgets('a refusal from the service is shown and the sale stays owed', (tester) async {
      final ops = _Ops(due: [cash('s1', 'Ravi Kumar', 90000, dueAt: _daysAgo(-1))], free: 500000)
        ..failRemitWith = Exception('Your wallet has ₹0 free and this sale is ₹90,000. Add ₹90,000 to your wallet, then pay it in.');
      await _show(tester, ops, AggregatorSettlementsScreen.path);
      await _tap(tester, find.widgetWithText(FilledButton, 'Pay from wallet'));
      await _tap(tester, find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Pay from wallet')));
      expect(find.textContaining('Your wallet has ₹0 free'), findsOneWidget);
      expect(find.text('Ravi Kumar'), findsOneWidget);
    });

    testWidgets('nothing owed draws no card at all', (tester) async {
      await _show(tester, _Ops(settlements: [_settlement('s1', 'Monsoon, Madurai', 12345, processedAt: '2026-09-21T00:00:00.000Z')]), AggregatorSettlementsScreen.path);
      expect(find.text('Owed to GalleryZone'), findsNothing);
      expect(find.text('Commission settlements'), findsOneWidget);
    });

    testWidgets('each settlement shows the commission, when it was created and when it was processed', (tester) async {
      final ops = _Ops(
        sales: [_sale(id: 's1'), _sale(id: 's2')],
        settlements: [
          _settlement('s1', 'Monsoon, Madurai', 12345, processedAt: '2026-09-21T00:00:00.000Z'),
          _settlement('s2', 'Bronze Dancer', 6000, status: SettlementStatus.pending),
        ],
      );
      await _show(tester, ops, AggregatorSettlementsScreen.path);
      expect(find.text('₹12,345'), findsOneWidget);
      expect(find.text('₹6,000'), findsOneWidget);
      expect(find.text('Sale s1'), findsOneWidget);
      expect(find.text('20 Sep 2026'), findsNWidgets(2));
      expect(find.text('21 Sep 2026'), findsOneWidget);
      expect(find.text('Not yet'), findsOneWidget);
    });

    testWidgets('search by artwork and filter by status', (tester) async {
      final ops = _Ops(
        settlements: [
          _settlement('s1', 'Monsoon, Madurai', 12345, processedAt: '2026-09-21T00:00:00.000Z'),
          _settlement('s2', 'Bronze Dancer', 6000, status: SettlementStatus.pending),
        ],
      );
      await _show(tester, ops, AggregatorSettlementsScreen.path);

      await tester.enterText(find.byType(TextField).first, 'bronze');
      await tester.pumpAndSettle();
      expect(find.text('Bronze Dancer'), findsOneWidget);
      expect(find.text('Monsoon, Madurai'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Processed'));
      await tester.pumpAndSettle();
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.text('Bronze Dancer'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Failed'));
      await tester.pumpAndSettle();
      expect(find.text('No settlements match'), findsOneWidget);
    });

    testWidgets('against the real service there is no "simulate" - GalleryZone settles', (tester) async {
      final ops = _Ops(sales: [_sale(id: 's9')]);
      await _show(tester, ops, AggregatorSettlementsScreen.path);
      expect(find.text('Simulate settlement'), findsNothing);
      expect(find.text('Awaiting settlement'), findsNothing);
    });

    testWidgets('the offline demo can still run a sale through settlement', (tester) async {
      final ops = _Ops(sales: [_sale(id: 's9')]);
      await _show(tester, ops, AggregatorSettlementsScreen.path, remote: false);
      expect(find.text('Awaiting settlement'), findsOneWidget);
      await _tap(tester, find.text('Simulate settlement'));
      expect(ops.processed, ['s9']);
      expect(find.text('Settlement processed'), findsOneWidget);
      expect(find.text('Awaiting settlement'), findsNothing);
    });

    testWidgets('nothing at all yet', (tester) async {
      await _show(tester, _Ops(), AggregatorSettlementsScreen.path);
      expect(find.text('No settlements yet'), findsOneWidget);
    });
  });
}
