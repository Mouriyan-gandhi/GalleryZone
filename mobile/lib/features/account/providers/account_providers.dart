import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_customer_repository.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/artwork_filters.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../checkout/providers/checkout_providers.dart';
import '../../marketplace/providers/marketplace_providers.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return MockCustomerRepository();
});

/// Every read below is `autoDispose`: orders, wallet balance and addresses
/// are exactly the state SAD §9.2 says is never cached client-side. Nothing
/// here is pinned in app-wide state.
final customerProfileProvider = FutureProvider.autoDispose<CustomerProfile>((ref) {
  return ref.watch(customerRepositoryProvider).getProfile();
});

final addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) {
  return ref.watch(customerRepositoryProvider).listAddresses();
});

final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final orders = await ref.watch(checkoutRepositoryProvider).listOrders();
  // Newest first — the list, the dashboard's "recent orders" and any future
  // caller all want the same order, so it's sorted once here.
  return [...orders]
    ..sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));
});

final orderProvider = FutureProvider.autoDispose.family<Order?, String>((ref, id) {
  return ref.watch(checkoutRepositoryProvider).getOrder(id);
});

/// Artwork records keyed by id. Orders, collection entries and resale
/// listings all store an `artworkId` and need the piece behind it; one
/// unfiltered read serves all of them, rather than each screen keying
/// `artworksProvider` with its own throwaway `ArtworkFilters` instance.
final artworksByIdProvider = FutureProvider.autoDispose<Map<String, Artwork>>((ref) async {
  final all = await ref.watch(artworkRepositoryProvider).list(const ArtworkFilters());
  return {for (final artwork in all) artwork.id: artwork};
});

final walletProvider = FutureProvider.autoDispose<WalletSummary>((ref) {
  return ref.watch(customerRepositoryProvider).getWallet();
});

final walletTransactionsProvider =
    FutureProvider.autoDispose<List<WalletTransaction>>((ref) {
  return ref.watch(customerRepositoryProvider).listWalletTransactions();
});

final collectionProvider = FutureProvider.autoDispose<List<CollectionItem>>((ref) {
  return ref.watch(customerRepositoryProvider).listCollection();
});

final physicalCoaRequestsProvider =
    FutureProvider.autoDispose<List<PhysicalCoaRequest>>((ref) {
  return ref.watch(customerRepositoryProvider).listPhysicalCoaRequests();
});

final resaleListingsProvider = FutureProvider.autoDispose<List<ResaleListing>>((ref) {
  return ref.watch(customerRepositoryProvider).listResaleListings();
});

final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>((ref) {
  return ref.watch(customerRepositoryProvider).listSupportTickets();
});

/// `Aarav Shah` -> `AS`. `CustomerProfile` carries no avatar field, so the
/// profile chip renders initials rather than a placeholder photo — the more
/// honest treatment of a field the data model doesn't have.
String initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();
