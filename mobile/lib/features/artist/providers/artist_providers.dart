import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_artist_repository.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/artist_repository.dart';

final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  return MockArtistRepository();
});

/// All `autoDispose`, same rule as everywhere else: wallet balance, orders
/// and settlements are never pinned in app-wide state (SAD §9.2).
final artistKpisProvider = FutureProvider.autoDispose<List<ArtistKpi>>((ref) {
  return ref.watch(artistRepositoryProvider).getKpis();
});

final artistActivityProvider = FutureProvider.autoDispose<List<ActivityEntry>>((ref) {
  return ref.watch(artistRepositoryProvider).listActivity();
});

final artistArtworksProvider = FutureProvider.autoDispose<List<ArtistArtwork>>((ref) {
  return ref.watch(artistRepositoryProvider).listArtworks();
});

final artistWalletProvider = FutureProvider.autoDispose<WalletSummary>((ref) {
  return ref.watch(artistRepositoryProvider).getWallet();
});

final artistWalletTransactionsProvider =
    FutureProvider.autoDispose<List<WalletTransaction>>((ref) {
  return ref.watch(artistRepositoryProvider).listWalletTransactions();
});

final artistProfileDetailsProvider = FutureProvider.autoDispose<ArtistProfileDetails>((ref) {
  return ref.watch(artistRepositoryProvider).getProfile();
});

final artistOrdersProvider = FutureProvider.autoDispose<List<ArtistOrder>>((ref) {
  return ref.watch(artistRepositoryProvider).listOrders();
});

final artistSettlementsProvider = FutureProvider.autoDispose<List<Settlement>>((ref) {
  return ref.watch(artistRepositoryProvider).listSettlements();
});

final artistGallerySpacesProvider =
    FutureProvider.autoDispose<List<GallerySpacePlacement>>((ref) {
  return ref.watch(artistRepositoryProvider).listGallerySpaces();
});

final artistSettingsProvider = FutureProvider.autoDispose<ArtistSettings>((ref) {
  return ref.watch(artistRepositoryProvider).getSettings();
});

final artistMessagesProvider = FutureProvider.autoDispose<List<MessageThread>>((ref) {
  return ref.watch(artistRepositoryProvider).listMessages();
});

final artistSupportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>((ref) {
  return ref.watch(artistRepositoryProvider).listSupportTickets();
});
