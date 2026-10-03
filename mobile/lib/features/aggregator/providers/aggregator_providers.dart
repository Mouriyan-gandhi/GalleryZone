import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_aggregator_repository.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/mou.dart' show MouState;
import '../../../data/repositories/aggregator_repository.dart';
import '../aggregator_stats.dart';

final aggregatorRepositoryProvider = Provider<AggregatorRepository>((ref) {
  return MockAggregatorRepository();
});

/// All `autoDispose`, same rule as the other two portals: wallet balances,
/// sales and settlements are never pinned in app-wide state (SAD §9.2).
final aggregatorDashboardProvider =
    FutureProvider.autoDispose<AggregatorDashboardSummary>((ref) {
  return ref.watch(aggregatorRepositoryProvider).getDashboardSummary();
});

final aggregatorInventoryProvider =
    FutureProvider.autoDispose<List<ReservableArtwork>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).listReservableInventory();
});

final aggregatorCollectionProvider =
    FutureProvider.autoDispose<List<AggregatorHoldingView>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).listCollection();
});

/// One holding with its artwork, returned ones included - the detail page's
/// source. Null when it isn't this aggregator's.
final aggregatorHoldingProvider =
    FutureProvider.autoDispose.family<AggregatorHoldingView?, String>((ref, holdingId) {
  return ref.watch(aggregatorRepositoryProvider).getHolding(holdingId);
});

final aggregatorSalesProvider = FutureProvider.autoDispose<List<AggregatorSale>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).listSales();
});

/// Cash the aggregator is holding on GalleryZone's behalf and has not yet
/// transferred. An obligation, not an entitlement — kept apart from the
/// settlements list for exactly that reason.
final aggregatorRemittancesDueProvider =
    FutureProvider.autoDispose<List<AggregatorSale>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).listRemittancesDue();
});

/// What each sale earned, by sale id - the Commission figure on Orders and
/// Settlements, so the two can never disagree.
final aggregatorSaleCommissionsProvider = FutureProvider.autoDispose<Map<String, double>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).saleCommissions();
});

final aggregatorCustomersProvider =
    FutureProvider.autoDispose<List<AggregatorCustomer>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).listCustomers();
});

final aggregatorGallerySpacesProvider =
    FutureProvider.autoDispose<List<GallerySpace>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).listGallerySpaces();
});

final aggregatorWalletProvider = FutureProvider.autoDispose<WalletSummary>((ref) {
  return ref.watch(aggregatorRepositoryProvider).getWallet();
});

final aggregatorWalletTransactionsProvider =
    FutureProvider.autoDispose<List<WalletTransaction>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).listWalletTransactions();
});

final aggregatorSettlementsProvider = FutureProvider.autoDispose<List<Settlement>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).listSettlements();
});

final aggregatorAnalyticsProvider =
    FutureProvider.autoDispose<AggregatorAnalyticsSummary>((ref) {
  return ref.watch(aggregatorRepositoryProvider).getAnalytics();
});

final aggregatorCategoryPerformanceProvider =
    FutureProvider.autoDispose<List<CategoryPerformance>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).getCategoryPerformance();
});

final aggregatorProfileProvider = FutureProvider.autoDispose<AggregatorProfile>((ref) {
  return ref.watch(aggregatorRepositoryProvider).getProfile();
});

/// The partner agreement with the business's details filled in, and whether it
/// is signed.
final aggregatorMouStateProvider = FutureProvider.autoDispose<MouState>((ref) {
  return ref.watch(aggregatorRepositoryProvider).getMouState();
});

/// The Profile page's summary - held, sold, owed - worked out from the lists the
/// rest of the portal already loads. They start together, so it costs no extra wait.
final aggregatorStatsProvider = FutureProvider.autoDispose<AggregatorStats>((ref) async {
  final loaded = await Future.wait<Object>([
    ref.watch(aggregatorCollectionProvider.future),
    ref.watch(aggregatorSalesProvider.future),
    ref.watch(aggregatorGallerySpacesProvider.future),
    ref.watch(aggregatorWalletProvider.future),
    ref.watch(aggregatorProfileProvider.future),
    ref.watch(aggregatorSaleCommissionsProvider.future),
  ]);
  return aggregatorStatsOf(
    holdings: loaded[0] as List<AggregatorHoldingView>,
    sales: loaded[1] as List<AggregatorSale>,
    spaces: loaded[2] as List<GallerySpace>,
    wallet: loaded[3] as WalletSummary,
    profile: loaded[4] as AggregatorProfile,
    commissions: loaded[5] as Map<String, double>,
  );
});

final aggregatorSettingsProvider = FutureProvider.autoDispose<AggregatorSettings>((ref) {
  return ref.watch(aggregatorRepositoryProvider).getSettings();
});

final aggregatorMessagesProvider =
    FutureProvider.autoDispose<List<MessageThread>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).listMessages();
});

final aggregatorSupportTicketsProvider =
    FutureProvider.autoDispose<List<SupportTicket>>((ref) {
  return ref.watch(aggregatorRepositoryProvider).listSupportTickets();
});

/// Everything a sale touches, in one call. Recording a sale, advancing a
/// shipment or processing a settlement moves the holding, the sale, the
/// wallet, the customer roll-up and the KPIs at once; invalidating them
/// one-by-one at each call site is how one gets forgotten.
void invalidateAggregatorSaleFlow(WidgetRef ref) =>
    invalidateAggregatorSaleFlowIn(ProviderScope.containerOf(ref.context));

/// The same, from a container taken before an await - for a sheet or dialog
/// whose screen may be gone by the time its request returns.
void invalidateAggregatorSaleFlowIn(ProviderContainer container) {
  container
    ..invalidate(aggregatorDashboardProvider)
    ..invalidate(aggregatorInventoryProvider)
    ..invalidate(aggregatorCollectionProvider)
    ..invalidate(aggregatorHoldingProvider)
    ..invalidate(aggregatorSalesProvider)
    ..invalidate(aggregatorSaleCommissionsProvider)
    ..invalidate(aggregatorRemittancesDueProvider)
    ..invalidate(aggregatorCustomersProvider)
    ..invalidate(aggregatorWalletProvider)
    ..invalidate(aggregatorWalletTransactionsProvider)
    ..invalidate(aggregatorSettlementsProvider)
    ..invalidate(aggregatorAnalyticsProvider)
    ..invalidate(aggregatorCategoryPerformanceProvider)
    ..invalidate(aggregatorStatsProvider);
}
