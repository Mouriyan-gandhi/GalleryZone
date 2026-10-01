import '../../../core/api/json_utils.dart';
import '../../../core/pricing.dart' show AdvanceBasis;
import '../../models/aggregator.dart';
import '../../models/artist_network.dart';
import '../../models/artist_portal.dart';
import '../../models/artwork.dart';
import '../../models/customer.dart';
import '../../models/mou.dart';
import '../../models/pricing_rules.dart';
import '../../repositories/aggregator_repository.dart';
import 'catalog_mappers.dart';

/// Wire JSON -> models for the three portals: profiles, the MOU, penalties,
/// holdings and offers, sales, premises, messages.

String _s(Object? value, [String fallback = '']) => value is String ? value : fallback;
String? _sn(Object? value) => value is String && value.isNotEmpty ? value : null;

// --- Profiles ----------------------------------------------------------------

CustomerProfile customerProfileFromApi(Map<String, dynamic> json) => CustomerProfile(
  name: _s(json['fullName']),
  email: _s(json['email']),
  phone: _s(json['phone']),
  gstin: _sn(json['gstin']),
  // The API never returns a full account number — only a masked tail.
  bankAccountNumber: _s(json['bankAccountMasked']),
  bankIfsc: _s(json['ifsc']),
  joinedAt: isoOf(json['createdAt']),
);

FreeAccess? freeAccessFromApi(Object? value) {
  if (value is! Map) return null;
  final json = asMap(value);
  return FreeAccess(
    until: isoOf(json['until']),
    months: (json['months'] as num?)?.toInt() ?? 6,
    surveyRespondent: json['surveyRespondent'] == true,
    active: json['active'] != false,
  );
}

ArtistProfileDetails artistProfileDetailsFromApi(Map<String, dynamic> json) => ArtistProfileDetails(
  fullName: _s(json['fullName']),
  email: _s(json['email']),
  phone: _s(json['phone']),
  bio: _s(json['bio']),
  instagram: _s(json['instagram']),
  website: _s(json['website']),
  bankAccountMasked: _s(json['bankAccountMasked']),
  ifsc: _s(json['ifsc']),
  aadhaarStatus: reviewStatusFromCode(_sn(json['aadhaarStatus'])),
  aadhaarMasked: _s(json['aadhaarMasked']),
  gstin: _sn(json['gstin']),
  gstStatus: reviewStatusFromCode(_sn(json['gstStatus'])),
  pan: _sn(json['pan']),
  headline: _sn(json['headline']),
  location: _sn(json['location']),
  socialProofVideoUrl: _sn(json['socialProofVideoUrl']),
  joinedAt: isoOf(json['createdAt']),
  freeAccess: freeAccessFromApi(json['freeAccess']),
  pickupLine1: _s(json['pickupLine1']),
  pickupLine2: _s(json['pickupLine2']),
  pickupCity: _s(json['pickupCity']),
  pickupState: _s(json['pickupState']),
  pickupPincode: _s(json['pickupPincode']),
);

AggregatorProfile aggregatorProfileFromApi(Map<String, dynamic> json, {MouAcceptance? mouAcceptance}) =>
    AggregatorProfile(
      companyName: _sn(json['companyName']) ?? _s(json['fullName']),
      contactPerson: _s(json['fullName']),
      avatar: _s(json['profileImageUrl']),
      gstNumber: _s(json['gstin']),
      phone: _s(json['phone']),
      addressLine1: _s(json['pickupLine1']),
      bankAccountMasked: _s(json['bankAccountMasked']),
      ifsc: _s(json['ifsc']),
      securityDepositStatus: 'pending',
      gstStatus: reviewStatusFromCode(_sn(json['gstStatus'])),
      email: _s(json['email']),
      addressCity: _s(json['pickupCity']),
      addressState: _s(json['pickupState']),
      addressPincode: _s(json['pickupPincode']),
      aadhaarStatus: reviewStatusFromCode(_sn(json['aadhaarStatus'])),
      aadhaarMasked: _sn(json['aadhaarMasked']),
      // The coordinator block reuses profile fields: the designation lives in
      // `headline`, the contact points are the account's own.
      coordinatorDesignation: _s(json['headline']),
      coordinatorPhone: _s(json['phone']),
      coordinatorEmail: _s(json['email']),
      mouAcceptance: mouAcceptance,
    );

// --- The published rules -------------------------------------------------------

PricingRules? pricingRulesFromApi(Object? value) {
  if (value is! Map) return null;
  final json = asMap(value);
  double fraction(String key, double fallback) => (json[key] as num?)?.toDouble() ?? fallback;
  double rupees(String key, double fallback) => rupeesAt(json, key, orElse: fallback);
  return PricingRules(
    gstRate: fraction('gstRate', 0.05),
    platformMarkup: fraction('platformMarkup', 0.3),
    artistListingFeeRate: fraction('artistListingFeeRate', 0.01),
    serviceGstRate: fraction('serviceGstRate', 0.18),
    artistTdsRate: fraction('artistTdsRate', 0.001),
    artistConvenienceRate: fraction('artistConvenienceRate', 0.02),
    artistTechnologyRate: fraction('artistTechnologyRate', 0.01),
    aggregatorCommissionRate: fraction('aggregatorCommissionRate', 0.2),
    aggregatorAdvanceRate: fraction('aggregatorAdvanceRate', 0.05),
    aggregatorPriceWarnRate: fraction('aggregatorPriceWarnRate', 1),
    nfcTagCharge: rupees('nfcTagChargePaise', 100),
    subscriptionFee: rupees('subscriptionFeePaise', 1200),
    deliveryCharge: rupees('deliveryChargePaise', 2500),
    insuranceThreshold: rupees('insuranceThresholdPaise', 20000),
  );
}

// --- MOU -----------------------------------------------------------------------

MouParties mouPartiesFromApi(Object? value) {
  final json = asMap(value);
  return MouParties(
    party: MouPartyDetails.fromJson(asMap(json['party'])),
    company: MouCompanyDetails.fromJson(asMap(json['company'])),
  );
}

MouAcceptance mouAcceptanceFromApi(Map<String, dynamic> json) => MouAcceptance(
  version: _s(json['version']),
  acceptedAt: isoOf(json['acceptedAt']),
  signatureName: _s(json['signatureName']),
  signatureDataUrl: _s(json['signatureDataUrl']),
  parties: json['parties'] is Map ? mouPartiesFromApi(json['parties']) : null,
);

/// `GET …/mou` -> [MouState]. An acceptance of an older version than the one
/// in force reads as unsigned, which is what makes a newly published
/// agreement ask for a new signature.
MouState mouStateFromApi(Map<String, dynamic> json) {
  final draft = asMap(json['draft']);
  final version = _s(draft['version']);
  final acceptance = json['acceptance'];
  final signed = acceptance is Map ? mouAcceptanceFromApi(asMap(acceptance)) : null;
  return MouState(
    draft: MouDraft(
      version: version,
      parties: mouPartiesFromApi(draft['parties']),
      missing: [
        for (final key in (draft['missing'] as List? ?? const []))
          if (key is String) key,
      ],
      asOf: isoOrNull(draft['asOf']),
    ),
    acceptance: signed != null && signed.version == version ? signed : null,
  );
}

// --- Artist ---------------------------------------------------------------------

ExternalSalePenalty penaltyFromApi(Map<String, dynamic> json) => ExternalSalePenalty(
  id: _s(json['id']),
  artworkId: _s(json['artworkId']),
  artworkTitle: _s(json['artworkTitle'], 'Artwork'),
  amount: rupeesAt(json, 'amountPaise'),
  createdAt: isoOf(json['createdAt']),
  settledAt: isoOrNull(json['settledAt']),
  status: switch (json['status']) {
    'approved' => PenaltyStatus.approved,
    'waived' => PenaltyStatus.waived,
    _ => PenaltyStatus.pendingReview,
  },
  decidedAt: isoOrNull(json['decidedAt']),
  decisionNote: _sn(json['decisionNote']),
);

DeactivationRequest deactivationFromApi(Map<String, dynamic> json) => DeactivationRequest(
  id: _s(json['id']),
  userId: _s(json['userId']),
  userName: _s(json['userName']),
  reason: _s(json['reason']),
  status: switch (json['status']) {
    'approved' => DeactivationStatus.approved,
    'rejected' => DeactivationStatus.rejected,
    _ => DeactivationStatus.pending,
  },
  requestedAt: isoOf(json['requestedAt']),
  decidedAt: isoOrNull(json['decidedAt']),
  decisionNote: _sn(json['decisionNote']),
);

MessageThread messageThreadFromApi(Map<String, dynamic> json) => MessageThread(
  id: _s(json['id']),
  from: _s(json['fromLabel'] ?? json['from']),
  subject: _s(json['subject']),
  preview: _s(json['preview']),
  body: _s(json['body']),
  unread: json['unread'] == true,
  receivedAt: isoOf(json['receivedAt']),
);

// --- Aggregator -------------------------------------------------------------------

HoldingExtensionRequest? extensionRequestFromApi(Object? value) {
  if (value is! Map) return null;
  final json = asMap(value);
  return HoldingExtensionRequest(
    status: switch (json['status']) {
      'approved' => ExtensionStatus.approved,
      'declined' => ExtensionStatus.declined,
      _ => ExtensionStatus.pending,
    },
    assurance: _s(json['assurance']),
    requestedAt: isoOf(json['requestedAt']),
    decidedAt: isoOrNull(json['decidedAt']),
    note: _sn(json['note']),
    previousExpiresAt: isoOf(json['previousExpiresAt']),
  );
}

AggregatorHolding holdingFromApi(Map<String, dynamic> json) => AggregatorHolding(
  id: _s(json['id']),
  artworkId: _s(json['artworkId']),
  advancePercent: (json['advancePercent'] as num?)?.toInt() ?? 5,
  advanceAmount: rupeesAt(json, 'advancePaise'),
  displayPrice: rupeesAt(json, 'displayPricePaise'),
  assignedAt: isoOf(json['assignedAt']),
  expiresAt: isoOf(json['expiresAt']),
  status: switch (json['status']) {
    'sold_pending_settlement' => HoldingStatus.soldPendingSettlement,
    'returned' => HoldingStatus.returned,
    _ => HoldingStatus.reserved,
  },
  assignmentSource: json['assignmentSource'] == 'gz_assigned'
      ? AssignmentSource.gzAssigned
      : AssignmentSource.selfReserved,
  deliveryDeposit: rupeesAt(json, 'deliveryDepositPaise'),
  cycleMonth: (json['cycleMonth'] as num?)?.toInt() ?? 1,
  returnedAt: isoOrNull(json['returnedAt']),
  windowExtended: json['windowExtended'] == true,
  appreciated: json['appreciated'] == true,
  priceWarning: json['priceWarning'] == true,
  extensionRequest: extensionRequestFromApi(json['extensionRequest']),
);

/// A holding with the piece behind it. The API joins the public artwork on;
/// if it has gone, a neutral placeholder keeps the row drawable.
AggregatorHoldingView holdingViewFromApi(Map<String, dynamic> json) {
  final holding = holdingFromApi(json);
  final artwork = json['artwork'];
  return AggregatorHoldingView(
    holding: holding,
    artwork: artwork is Map ? artworkFromApi(asMap(artwork)) : _placeholderArtwork(holding.artworkId),
  );
}

Artwork _placeholderArtwork(String id) => Artwork(
  id: id,
  title: 'Artwork',
  artistId: '',
  artistName: '',
  verifiedArtist: false,
  category: '',
  medium: '',
  customerPrice: 0,
  thumbnailUrl: '',
  insured: false,
  status: ArtworkStatus.marketplace,
  listingType: ListingType.marketplaceAndAggregator,
  description: '',
  images: const [],
  socialProofLinks: const [],
  statusHistory: const [],
);

AggregatorOffer offerFromApi(Map<String, dynamic> json) => AggregatorOffer(
  artworkId: _s(json['artworkId']),
  month: (json['month'] as num?)?.toInt() ?? 1,
  offerPrice: rupeesAt(json, 'offerPricePaise'),
  marketplacePrice: rupeesAt(json, 'marketplacePricePaise'),
  advance: rupeesAt(json, 'advancePaise'),
  advanceRate: (json['advanceRate'] as num?)?.toDouble() ?? 0,
  advanceBase: rupeesAt(json, 'advanceBasePaise'),
  advanceBasis: json['advanceBasis'] == 'artist_price' ? AdvanceBasis.artistPrice : AdvanceBasis.displayPrice,
  canSetPrice: json['canSetPrice'] == true,
  daysLeftInListing: (json['daysLeftInListing'] as num?)?.toInt() ?? 0,
  deliveryCharge: rupeesAt(json, 'deliveryChargePaise'),
  payable: rupeesAt(json, 'payablePaise'),
  sellingPrice: rupeesAt(json, 'sellingPricePaise'),
  standardPrice: rupeesAt(json, 'standardPricePaise'),
  monthlyReduction: rupeesAt(json, 'monthlyReductionPaise'),
  gstRate: (json['gstRate'] as num?)?.toDouble() ?? 0.05,
  priceWarnFrom: rupeesAtOrNull(json, 'priceWarnFromPaise'),
);

ReservableArtwork reservableFromApi(Map<String, dynamic> json) =>
    ReservableArtwork(artwork: artworkFromApi(json), offer: offerFromApi(asMap(json['offer'])));

/// The API stores a delivery address as one comma-joined line
/// (`street, city, state, pincode`). Read from the END so a street that
/// itself contains commas stays in the first line.
DeliveryAddress parseDeliveryAddress(String? line) {
  final parts = (line ?? '').split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return const DeliveryAddress(line1: '', city: '', state: '', pincode: '');
  if (parts.length == 1) return DeliveryAddress(line1: parts[0], city: '', state: '', pincode: '');
  if (parts.length == 2) return DeliveryAddress(line1: parts[0], city: parts[1], state: '', pincode: '');
  if (parts.length == 3) return DeliveryAddress(line1: parts[0], city: parts[1], state: parts[2], pincode: '');
  return DeliveryAddress(
    line1: parts.sublist(0, parts.length - 3).join(', '),
    city: parts[parts.length - 3],
    state: parts[parts.length - 2],
    pincode: parts.last,
  );
}

/// The one-line form the API stores, from the pieces the form collects.
String? joinDeliveryAddress(DeliveryAddress address) {
  final joined = [address.line1, address.city, address.state, address.pincode]
      .where((part) => part.trim().isNotEmpty)
      .map((part) => part.trim())
      .join(', ');
  return joined.isEmpty ? null : joined;
}

AggregatorSale saleFromApi(Map<String, dynamic> json) => AggregatorSale(
  id: _s(json['id']),
  holdingId: _s(json['holdingId']),
  artworkId: _s(json['artworkId']),
  soldPrice: rupeesAt(json, 'soldPricePaise'),
  buyerName: _s(json['buyerName']),
  buyerEmail: _s(json['buyerEmail']),
  buyerPhone: _s(json['buyerPhone']),
  deliveryAddress: parseDeliveryAddress(_sn(json['deliveryAddress'])),
  deliveryMode: json['deliveryMode'] == 'self_pickup' ? DeliveryMode.selfPickup : DeliveryMode.courier,
  soldAt: isoOf(json['soldAt']),
  shipmentStatus: switch (json['shipmentStatus']) {
    'dispatched' => ShipmentStatus.dispatched,
    'delivered' => ShipmentStatus.delivered,
    _ => ShipmentStatus.preparing,
  },
  dispatchedAt: isoOrNull(json['dispatchedAt']),
  deliveredAt: isoOrNull(json['deliveredAt']),
  paymentRoute: json['paymentRoute'] == 'cash_at_premises'
      ? PaymentRoute.cashAtPremises
      : PaymentRoute.directToGalleryZone,
  remittedAt: isoOrNull(json['remittedAt']),
  remitDueAt: isoOrNull(json['remitDueAt']),
  remittedVia: switch (json['remittedVia']) {
    'wallet' => RemitVia.wallet,
    'bank' => RemitVia.bank,
    _ => null,
  },
  courierRef: _sn(json['courierRef']),
);

GallerySpace gallerySpaceFromApi(Map<String, dynamic> json) => GallerySpace(
  id: _s(json['id']),
  name: _s(json['name']),
  addressLine1: _s(json['addressLine1']),
  city: _s(json['city']),
  state: _s(json['state']),
  pincode: _s(json['pincode']),
  capacity: (json['capacity'] as num?)?.toInt() ?? 0,
  coordinatorName: _s(json['coordinatorName']),
);
