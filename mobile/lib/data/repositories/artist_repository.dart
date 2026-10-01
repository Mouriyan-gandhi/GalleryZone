import '../models/artist_portal.dart';
import '../models/artwork.dart';
import '../models/customer.dart';
import '../models/mou.dart';
import '../models/pricing_rules.dart';
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
    this.physical,
    this.artworkType,
    this.paintingStyle,
    this.insuranceNumber,
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

  /// `L x W [x H] unit`, written by the form (ASCII `x`, unit `in` or `cm`) —
  /// the API derives the size band from this exact shape.
  final String? dimensions;
  final int? yearCreated;
  final String? nfcTagId;

  /// Original / limited edition / open edition / study / commission / other.
  final String? artworkType;

  /// Which painting tradition — only asked when the category is painting.
  final String? paintingStyle;

  /// The policy number pasted back from the insurer. A new or changed number
  /// goes to GalleryZone for verification.
  final String? insuranceNumber;

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

  /// One of the artist's own pieces with the private figures, or null when it
  /// isn't theirs. For the edit form, which needs image ids and the window.
  Future<ArtistArtwork?> getArtwork(String artworkId);

  /// New pictures are local file paths in [SubmitArtworkInput.images]; ones
  /// that already exist carry their server id and are kept. The list order is
  /// the display order, cover first.
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

  /// Paper-certificate requests from collectors, newest first, and the
  /// artist marking one dispatched.
  Future<List<PhysicalCoaRequest>> listPhysicalCoaRequests();
  Future<PhysicalCoaRequest> dispatchPhysicalCoa(String requestId, String courierRef);

  /// Links a physical NFC tag to a piece. Replaces any tag already linked.
  Future<Artwork> linkNfcTag(String artworkId, String nfcTagId);

  /// The artist's acceptance of the MOU version in force, or null if they have
  /// not signed it (an older version counts as unsigned).
  Future<MouAcceptance?> getMouAcceptance();

  /// The agreement's signed state: the signature on the version in force (if
  /// any) and the draft with its blanks filled from the profile.
  Future<MouState> getMouState();

  /// Signs the agreement. [signatureName] must match the account's name; the
  /// signing time is the server's. [signatureDataUrl] is the drawn signature
  /// as a PNG data URL (the offline mock accepts it empty).
  Future<MouAcceptance> acceptMou({
    required String signatureName,
    required String version,
    String signatureDataUrl = '',
  });

  /// The published commercial terms the upload ladder quotes from; null if
  /// none are in force.
  Future<PricingRules?> getPricingRules();

  Future<ArtistSettings> getSettings();
  Future<ArtistSettings> updateSettings(ArtistSettings settings);

  Future<List<MessageThread>> listMessages();
  Future<MessageThread> markMessageRead(String id);

  Future<List<SupportTicket>> listSupportTickets();
  Future<SupportTicket> submitSupportTicket({required String subject, required String message});
}
