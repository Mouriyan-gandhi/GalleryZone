import '../models/artist_portal.dart';
import '../models/artwork.dart';
import '../models/customer.dart';
import '../models/order.dart';

/// What the artist submits from the upload screen. `artistPrice` is the
/// artist's own figure — the customer price is derived from it, and this
/// value never appears in a customer-facing payload (SAD §8.7).
class SubmitArtworkInput {
  const SubmitArtworkInput({
    required this.title,
    required this.description,
    required this.category,
    required this.medium,
    required this.artistPrice,
    required this.listingType,
    required this.insuranceOpted,
    required this.images,
    required this.asDraft,
    this.dimensions,
    this.yearCreated,
    this.nfcTagId,
  });

  final String title;
  final String description;
  final String category;
  final String medium;
  final double artistPrice;
  final ListingType listingType;
  final bool insuranceOpted;
  final List<ArtworkImage> images;

  /// Draft stays with the artist; otherwise it enters the review queue.
  final bool asDraft;

  final String? dimensions;
  final int? yearCreated;
  final String? nfcTagId;
}

/// An order for one of this artist's pieces, with what she actually receives.
class ArtistOrder {
  const ArtistOrder({required this.order, required this.artistPayout});

  final Order order;
  final double artistPayout;
}

/// An artwork of this artist's currently placed with an aggregator.
class GallerySpacePlacement {
  const GallerySpacePlacement({required this.holding, required this.artwork});

  final AggregatorHolding holding;
  final Artwork artwork;
}

/// The artist portal (SAD §3.3 Artwork Service + §3.5 Order & Wallet, artist
/// side). Mirrors `artistDashboardService.ts` plus the artist slices of
/// `messagesService`/`supportService`.
abstract class ArtistRepository {
  Future<List<ArtistKpi>> getKpis();
  Future<List<ActivityEntry>> listActivity();

  /// Returns [ArtistArtwork] — artwork plus the artist's private price. No
  /// other repository method may construct that type.
  Future<List<ArtistArtwork>> listArtworks();
  Future<Artwork> submitArtwork(SubmitArtworkInput input);

  Future<WalletSummary> getWallet();
  Future<List<WalletTransaction>> listWalletTransactions();
  Future<WalletTransaction> requestWithdrawal(double amount);

  Future<ArtistProfileDetails> getProfile();
  Future<ArtistProfileDetails> updateProfile(ArtistProfileDetails profile);
  Future<ArtistProfileDetails> updateBankDetails({
    required String accountNumber,
    required String ifsc,
  });

  Future<List<ArtistOrder>> listOrders();
  Future<List<Settlement>> listSettlements();
  Future<List<GallerySpacePlacement>> listGallerySpaces();

  Future<ArtistSettings> getSettings();
  Future<ArtistSettings> updateSettings(ArtistSettings settings);

  Future<List<MessageThread>> listMessages();
  Future<MessageThread> markMessageRead(String id);

  Future<List<SupportTicket>> listSupportTickets();
  Future<SupportTicket> submitSupportTicket({
    required String subject,
    required String message,
  });
}
