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
    this.rarityType,
    this.physical,
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

  /// R / U / O / N, shown as a badge on the artist's card.
  final ArtworkRarity? rarityType;

  /// Weight, framing and packing. Required in practice once the aggregator
  /// channel is picked — see [missingForAggregator].
  final ArtworkPhysical? physical;
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

  /// Edits are refused here, not just hidden in the UI: 7 days from listing,
  /// or until the piece is bought or claimed, whichever comes first
  /// ([artworkEditState]). `patch.asDraft` is ignored — an edit never moves a
  /// piece between the draft and review queues.
  Future<Artwork> updateArtwork({required String artworkId, required SubmitArtworkInput patch});

  /// "Sold on another platform": the piece leaves every GalleryZone channel
  /// at once and can't be relisted, and a fee of [externalSalePenaltyRate] of
  /// its listed price is queued against the artist's next listing.
  Future<Artwork> markSoldElsewhere(String artworkId);

  /// Sends a saved draft into the review queue. Nothing else moves a piece
  /// out of `draft`, so without this a draft is a dead end.
  Future<Artwork> submitForReview(String artworkId);

  Future<List<ExternalSalePenalty>> listPenalties();

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

  /// The artist's acceptance of the MOU, or null if they have not accepted
  /// any version yet.
  /// Paper-certificate requests from collectors, newest first, and the
  /// artist marking one dispatched.
  Future<List<PhysicalCoaRequest>> listPhysicalCoaRequests();
  Future<PhysicalCoaRequest> dispatchPhysicalCoa(String requestId, String courierRef);

  Future<MouAcceptance?> getMouAcceptance();
  Future<MouAcceptance> acceptMou(String version);

  Future<ArtistSettings> getSettings();
  Future<ArtistSettings> updateSettings(ArtistSettings settings);

  Future<List<MessageThread>> listMessages();
  Future<MessageThread> markMessageRead(String id);

  Future<List<SupportTicket>> listSupportTickets();
  Future<SupportTicket> submitSupportTicket({required String subject, required String message});
}
