import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_aggregator_repository.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/aggregator_repository.dart';

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
void invalidateAggregatorSaleFlow(WidgetRef ref) {
  ref.invalidate(aggregatorDashboardProvider);
  ref.invalidate(aggregatorInventoryProvider);
  ref.invalidate(aggregatorCollectionProvider);
  ref.invalidate(aggregatorSalesProvider);
  ref.invalidate(aggregatorRemittancesDueProvider);
  ref.invalidate(aggregatorCustomersProvider);
  ref.invalidate(aggregatorWalletProvider);
  ref.invalidate(aggregatorWalletTransactionsProvider);
  ref.invalidate(aggregatorSettlementsProvider);
  ref.invalidate(aggregatorAnalyticsProvider);
  ref.invalidate(aggregatorCategoryPerformanceProvider);
}
