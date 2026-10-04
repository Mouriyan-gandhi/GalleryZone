// Firestore collection layout — replaces the Drizzle schema/*.ts files
// from the Postgres version. Every collection name + document shape a
// module in this package writes to or reads from is declared here once,
// so the mapping between "what plan.md's data model calls a table" and
// "what Firestore actually calls a collection" stays in one reviewable
// place, the same job schema/*.ts did before.
//
// Design notes carried over from the Postgres schema (see git history for
// the original, fuller comments per field if you need the "why"):
//   - Money is still BIGINT-equivalent: plain `number` in paise, never a
//     float rupee amount.
//   - Append-only collections (statusEvents, ledgerEntries, auditLog) are
//     enforced by firestore.rules (`allow write: if false` for clients) +
//     this package never issuing an update/delete against them itself —
//     there's no DB-level trigger to fall back on the way Postgres's
//     CONSTRAINT TRIGGER was, so this convention is the whole guarantee.
//     Treat any code that updates a doc in one of these collections as a
//     bug. ownershipEvents is the one exception: a transfer is one doc
//     whose status moves pending -> accepted | cancelled (ownership.ts is
//     the only writer, via transferStateMachine); once settled it is
//     immutable, and it is never deleted.
//   - artistPricePaise lives in a `pricing` subcollection under each
//     artwork doc, never on the artwork doc itself — see firestore.rules'
//     own comment on why.

import type {
  ArtworkStatus,
  TransferStatus,
  HoldingStatus,
  OrderStatus,
  PenaltyStatus,
  ResaleListingStatus,
  ReviewStatus,
  SettlementStatus,
  ShipmentStatus,
  WithdrawalStatus,
} from "@galleryzone/domain";

export const userRoleValues = ["artist", "aggregator", "customer", "admin"] as const;
export type UserRole = (typeof userRoleValues)[number];

export const userStatusValues = ["pending", "active", "suspended", "blocked"] as const;
export type UserStatus = (typeof userStatusValues)[number];

export type RoleGrant = "platform_admin" | "finance_admin" | "moderation_admin";
export type ListingType = "marketplace_only" | "aggregator_only" | "marketplace_and_aggregator";
export const artworkRarityValues = ["R", "U", "O", "S"] as const;
export type ArtworkRarity = (typeof artworkRarityValues)[number];

/** Standard used to be "N" (Normal); documents ranked before the rename still carry it. */
export function normalizeRarity(value: string | null | undefined): ArtworkRarity | null {
  if (value === "N") return "S";
  return (artworkRarityValues as readonly string[]).includes(value ?? "") ? (value as ArtworkRarity) : null;
}

/**
 * The rank a buyer sees. Every painting has one: approval refuses to go live
 * without it, and a piece approved before that rule reads as Standard until an
 * admin ranks it. Admin screens use normalizeRarity, so they still show it as unranked.
 */
export function publicRank(value: string | null | undefined): ArtworkRarity {
  return normalizeRarity(value) ?? "S";
}

// --- Collection name constants -------------------------------------------------
// Firestore has no schema enforcement, so these constants are the only
// thing stopping a typo from silently creating collection "artwork"
// alongside the real "artworks".

export const Collections = {
  users: "users",
  publicProfiles: "publicProfiles",
  addresses: "addresses",
  artworks: "artworks",
  artworkNfc: "artworkNfc",
  categories: "categories",
  externalSalePenalties: "externalSalePenalties",
  physicalCoaRequests: "physicalCoaRequests",
  orders: "orders",
  payments: "payments",
  walletTopups: "walletTopups",
  earlyAccessEmails: "earlyAccessEmails",
  ledgerAccounts: "ledgerAccounts",
  ledgerEntries: "ledgerEntries",
  settlements: "settlements",
  withdrawalRequests: "withdrawalRequests",
  aggregatorHoldings: "aggregatorHoldings",
  aggregatorSales: "aggregatorSales",
  gallerySpaces: "gallerySpaces",
  buyerInvites: "buyerInvites",
  auditLog: "auditLog",
  disputes: "disputes",
  rateConfigVersions: "rateConfigVersions",
  messageThreads: "messageThreads",
  artistReviews: "artistReviews",
  resaleListings: "resaleListings",
  artistSales: "artistSales",
  supportTickets: "supportTickets",
  artistConnections: "artistConnections",
  affiliateProducts: "affiliateProducts",
} as const;

// Subcollection path helpers — Firestore subcollections are addressed as
// `${parentCollection}/${parentId}/${subcollectionName}`, not a top-level
// constant, so these are functions rather than strings.
export const artworkPricingCol = (artworkId: string) => `artworks/${artworkId}/pricing`;
export const artworkImagesCol = (artworkId: string) => `artworks/${artworkId}/images`;
export const artworkStatusEventsCol = (artworkId: string) => `artworks/${artworkId}/statusEvents`;
export const artworkOwnershipEventsCol = (artworkId: string) => `artworks/${artworkId}/ownershipEvents`;
export const orderStatusEventsCol = (orderId: string) => `orders/${orderId}/statusEvents`;
export const userProfileCol = (userId: string) => `users/${userId}/profile`;
export const userFinancialCol = (userId: string) => `users/${userId}/financial`;

// --- Document shapes ---------------------------------------------------------

export interface UserDoc {
  firebaseUid: string; // == the Firestore doc ID for this collection
  role: UserRole;
  status: UserStatus;
  name: string;
  email: string;
  phone: string | null;
  createdAt: FirebaseFirestore.Timestamp;
  lastLoginAt: FirebaseFirestore.Timestamp | null;
  roleGrants: string[]; // RoleGrant values, kept as string[] for forward-compat with a grant not yet in the RoleGrant union
}

export interface ProfileDoc {
  bio: string | null;
  profileImageUrl: string | null;
  headline: string | null;
  location: string | null;
  instagram: string | null;
  website: string | null;
  pan: string | null;
  gstin: string | null;
  gstStatus: ReviewStatus | null;
  aadhaarStatus: ReviewStatus | null;
  aadhaarMasked: string | null;
  bankAccountMasked: string | null;
  ifsc: string | null;
  pickupLine1: string | null;
  pickupLine2: string | null;
  pickupCity: string | null;
  pickupState: string | null;
  pickupPincode: string | null;
  earningsAbove5L: boolean;
  socialProofVideoUrl: string | null;
  companyName: string | null;
}

export interface FinancialDoc {
  bankAccountEncrypted: string | null;
}

export interface PublicProfileDoc {
  name: string;
  headline: string | null;
  bio: string | null;
  location: string | null;
  profileImageUrl: string | null;
}

export interface AddressDoc {
  userId: string;
  line1: string;
  line2: string | null;
  city: string;
  state: string;
  pincode: string;
  isDefault: boolean;
}

export interface ArtworkDoc {
  productCode: string;
  artistId: string;
  title: string;
  description: string;
  category: string;
  medium: string;
  dimensions: string | null;
  yearCreated: number | null;
  artworkType: string | null;
  listingType: ListingType;
  rarityType: ArtworkRarity | null;
  coaCertificateNumber: string | null;
  /** When the certificate number was issued (coa.ts). Null until then. */
  coaIssuedAt: FirebaseFirestore.Timestamp | null;
  /**
   * The NFC chip on this piece (nfc.ts, NFC_IMPLEMENTATION.md §3): unlinked
   * (both null), linked-unlocked (linkedAt), linked-locked (both; irreversible).
   * firestore.rules lets ANYONE read this document, so it carries only the
   * timestamps. The chip's UID and the admin override note live in
   * artworkNfc/{artworkId}, which no client can read — the doc requires the UID
   * to reach only the artist, the holding aggregator and admins.
   * Pieces from before the feature have neither field until the migration
   * script runs, so reads treat a missing one as null.
   */
  nfcLinkedAt: FirebaseFirestore.Timestamp | null;
  nfcLockedAt: FirebaseFirestore.Timestamp | null;
  /** Admin escape hatch for dispatching a piece whose tag is not locked (legacy pieces). The reason is in artworkNfc and the audit log. */
  nfcShipmentGateOverrideAt?: FirebaseFirestore.Timestamp | null;
  insuranceNumber: string | null;
  insuranceStatus: ReviewStatus | null;
  /** Artist opted into transit insurance (MOU §10). Absent on older docs = false. */
  insuranceOpted?: boolean;
  /** Painting-only sub-classification (e.g. "Abstract"). */
  paintingStyle?: string | null;
  /** Shipping/packaging facts the artist declares at submission. */
  physical?: ArtworkPhysical | null;
  editableUntil: FirebaseFirestore.Timestamp;
  createdAt: FirebaseFirestore.Timestamp;
  /** Denormalised read model (listing-projection.ts). Absent on docs written before it existed — reindex fills it. */
  listing?: ListingProjection;
}

/**
 * The private half of an artwork's NFC state, at artworkNfc/{artworkId}. Server-only
 * (the catch-all rule denies clients), the same reason the artist's price lives in
 * a pricing document and not on the artwork. Absent until a tag is first linked.
 */
export interface ArtworkNfcDoc {
  /** 7-byte chip UID, lowercase hex, no separators. Null after an admin unlink. */
  tagUid: string | null;
  shipmentGateOverrideReason: string | null;
  shipmentGateOverrideBy: string | null;
  /** Reminder emails to lock a linked-but-unlocked tag, so each goes out once per link (nfc-reminders.ts). */
  reminder48hAt?: FirebaseFirestore.Timestamp | null;
  reminder7dAt?: FirebaseFirestore.Timestamp | null;
}

export interface ArtworkPhysical {
  weightKg: number | null;
  framing: string | null;
  format: string | null;
  hangingHardwareIncluded: boolean;
  packagingConfirmed: boolean;
}

/** Mirrors listing-projection.ts's ListingProjection (declared here to avoid an import cycle). */
export interface ListingProjection {
  status: ArtworkStatus;
  onMarketplace: boolean;
  displayPricePaise: number;
  artistName: string;
  /** From publicProfiles/{artistId}.location — an artwork has no location of its own. */
  artistLocation: string | null;
  /** Parsed from `dimensions` ("24 x 36 in") into small/medium/large by area; null when unparseable. */
  sizeBand: "small" | "medium" | "large" | null;
  coverImageUrl: string | null;
  coverThumbnailUrl: string | null;
  imageCount: number;
  updatedAt: FirebaseFirestore.Timestamp;
}

/** Lives at artworkPricingCol(id)/data — never spread into ArtworkDoc's public fields. */
export interface ArtworkPricingDoc {
  artistId: string; // duplicated so firestore.rules can check ownership without a second get()
  artistPricePaise: number;
}

export interface ArtworkImageDoc {
  url: string;
  thumbnailUrl: string | null;
  altText: string | null;
  sortOrder: number;
  storagePath: string;
}

export interface ArtworkStatusEventDoc {
  status: ArtworkStatus;
  changedBy: string | null;
  reason: string | null;
  changedAt: FirebaseFirestore.Timestamp;
}

/**
 * One transfer of legal ownership (or time-boxed display rights) of an
 * artwork. The CURRENT owner is a projection (latest accepted `ownership`
 * event's toUserId, else the artist) — never a field on ArtworkDoc.
 * Sale-triggered transfers (orderId set) are written already-accepted when
 * the order is paid; manual ones start pending and need the recipient.
 */
export interface OwnershipEventDoc {
  kind: "ownership" | "display";
  status: TransferStatus;
  fromUserId: string | null;
  toUserId: string | null;
  /** Manual transfers: the invited recipient before they have an account. Never on the public passport. */
  toEmail: string | null;
  /** Display-name snapshots so the passport needs no user reads (and no PII lookups). */
  fromName: string;
  toName: string;
  /** Set on sale-triggered transfers; makes the payment hook idempotent. */
  orderId: string | null;
  initiatedAt: FirebaseFirestore.Timestamp;
  acceptedAt: FirebaseFirestore.Timestamp | null;
  cancelledAt: FirebaseFirestore.Timestamp | null;
  displayEndsAt: FirebaseFirestore.Timestamp | null;
  displayEndedAt: FirebaseFirestore.Timestamp | null;
}

export interface CategoryDoc {
  name: string;
  slug: string;
}

/**
 * An Amazon product GalleryZone recommends, earning a commission on the sale.
 * `url` is the affiliate link exactly as Amazon issued it (it carries the
 * associate tag), so a click is always attributed. No price or rating is
 * stored: the Associates policy allows showing those only from Amazon's own
 * API, refreshed daily, and a stale price shown as current breaks it.
 * Images are Amazon's own CDN URLs, served from Amazon, never re-hosted.
 */
export interface AffiliateProductDoc {
  url: string;
  asin: string | null;
  title: string;
  brand: string | null;
  category: string;
  images: string[];
  active: boolean;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface ExternalSalePenaltyDoc {
  artworkId: string;
  amountPaise: number;
  status: PenaltyStatus;
  createdAt: FirebaseFirestore.Timestamp;
  decidedAt: FirebaseFirestore.Timestamp | null;
  decisionNote: string | null;
  settledAt: FirebaseFirestore.Timestamp | null;
}

export interface PhysicalCoaRequestDoc {
  artworkId: string;
  requestedByUserId: string;
  requestedAt: FirebaseFirestore.Timestamp;
  deliveryLine1: string;
  deliveryCity: string;
  deliveryState: string;
  deliveryPincode: string;
  status: "requested" | "dispatched";
  dispatchedAt: FirebaseFirestore.Timestamp | null;
  courierRef: string | null;
}

export interface OrderDoc {
  artworkId: string;
  customerId: string;
  addressId: string;
  displayPricePaise: number;
  gstPaise: number;
  deliveryChargePaise: number;
  convenienceFeePaise: number;
  /** 18% service GST on the convenience fee — zero while that fee is zero. */
  convenienceGstPaise: number;
  totalPaise: number;
  status: OrderStatus;
  rateConfigVersionId: string;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface OrderStatusEventDoc {
  status: OrderStatus;
  changedAt: FirebaseFirestore.Timestamp;
}

export interface PaymentDoc {
  orderId: string;
  provider: string;
  providerPaymentId: string | null;
  /** The gateway's own order id (Razorpay order_…), set when a checkout session is opened. */
  providerOrderId?: string | null;
  method: string | null;
  amountPaise: number;
  idempotencyKey: string;
  status: string;
  rawWebhookPayload: unknown;
  createdAt: FirebaseFirestore.Timestamp;
}

/** One Razorpay top-up of an aggregator's wallet. Server-only: the catch-all rule denies clients. */
export interface WalletTopupDoc {
  userId: string;
  amountPaise: number;
  status: "pending" | "paid" | "failed";
  /** The gateway's own order id (Razorpay order_…), set when checkout opens. */
  providerOrderId: string | null;
  providerPaymentId: string | null;
  method: string | null;
  createdAt: FirebaseFirestore.Timestamp;
  paidAt: FirebaseFirestore.Timestamp | null;
}

export type LedgerAccountType =
  | "artist_payable"
  | "aggregator_payable"
  | "aggregator_held"
  | "customer_wallet"
  | "platform_revenue"
  | "razorpay_escrow"
  | "gst_payable"
  | "tds_payable";

export interface LedgerAccountDoc {
  type: LedgerAccountType;
  ownerId: string | null;
}

export interface LedgerEntryDoc {
  transactionId: string;
  accountId: string;
  amountPaise: number;
  reason: string;
  relatedOrderId: string | null;
  relatedHoldingId: string | null;
  idempotencyKey: string; // enforced unique via idempotencyKey-as-doc-ID, see ledger-repository.ts
  createdAt: FirebaseFirestore.Timestamp;
}

export interface SettlementDoc {
  orderId: string | null;
  holdingId: string | null;
  artistId: string;
  artistAmountPaise: number;
  aggregatorCommissionPaise: number | null;
  platformRevenuePaise: number;
  status: SettlementStatus;
  releaseAfter: FirebaseFirestore.Timestamp;
  createdAt: FirebaseFirestore.Timestamp;
  processedAt: FirebaseFirestore.Timestamp | null;
}

export interface WithdrawalRequestDoc {
  userId: string;
  amountPaise: number;
  status: WithdrawalStatus;
  requestedAt: FirebaseFirestore.Timestamp;
  processedAt: FirebaseFirestore.Timestamp | null;
}

export interface AggregatorHoldingDoc {
  artworkId: string;
  aggregatorId: string;
  cycleMonth: number;
  advancePercent: number;
  advanceAmountPaise: number;
  deliveryDepositPaise: number | null;
  /** What the customer sees: sellingPricePaise plus GST. */
  displayPricePaise: number;
  /**
   * The price before GST. Month 1: what the aggregator chose when reserving,
   * never below GalleryZone's offer. Later months: GalleryZone's price, fixed.
   * Absent on holdings from before 30 Sep 2026: displayPricePaise less GST.
   */
  sellingPricePaise?: number;
  /** Month 1 only: priced above GalleryZone's offer. Decides when the next aggregator's monthly drops start. Absent = false. */
  appreciated?: boolean;
  /** Priced far enough above the offer (aggregatorPriceWarnRate) that GalleryZone was warned. */
  priceWarning?: boolean;
  assignmentSource: "self_reserved" | "gz_assigned";
  assignedAt: FirebaseFirestore.Timestamp;
  expiresAt: FirebaseFirestore.Timestamp;
  windowExtended: boolean;
  status: HoldingStatus;
  returnedAt: FirebaseFirestore.Timestamp | null;
  /** The latest request to keep the piece past its window. Only the latest is kept; decisions are also in the audit log. */
  extensionRequest?: HoldingExtensionRequest;
}

export interface HoldingExtensionRequest {
  requestedAt: FirebaseFirestore.Timestamp;
  /** The aggregator's assurance that the piece will sell. */
  assurance: string;
  status: "pending" | "approved" | "declined";
  decidedAt: FirebaseFirestore.Timestamp | null;
  /** The admin who decided. Null when the window ended before anyone did. */
  decidedBy: string | null;
  note: string | null;
  /** Where the window ended before this request, so a decision can show what changed. */
  previousExpiresAt: FirebaseFirestore.Timestamp;
}

/**
 * One artist sale, kept for §194-O: what counted towards the ₹5 lakh
 * financial-year line and what was withheld on it. Written in the same
 * transaction as the sale's ledger entries (artist-sales.ts), its id is the
 * sale's idempotency key, and it is server-only (firestore.rules denies
 * clients), so nothing here can reach a buyer.
 */
export interface ArtistSaleDoc {
  artistId: string;
  /** Financial year, e.g. "2026-27". */
  fyKey: string;
  channel: "marketplace" | "aggregator";
  artistPricePaise: number;
  tdsPaise: number;
  /** What the sale credited to the artist's payable, after every deduction. */
  netPaise: number;
  orderId: string | null;
  holdingId: string | null;
  soldAt: FirebaseFirestore.Timestamp;
}

export interface AggregatorSaleDoc {
  holdingId: string;
  artworkId: string;
  soldPricePaise: number;
  buyerName: string;
  buyerEmail: string;
  buyerPhone: string | null;
  deliveryAddress: string | null;
  deliveryMode: "courier" | "self_pickup";
  paymentRoute: "direct_to_galleryzone" | "cash_at_premises";
  remittedAt: FirebaseFirestore.Timestamp | null;
  /** Cash sales: when the full price is due at GalleryZone. Absent on sales recorded before there was a deadline. */
  remitDueAt?: FirebaseFirestore.Timestamp | null;
  /** How the price was paid in: from the aggregator's wallet here, or by transfer to GalleryZone's bank. */
  remittedVia?: "wallet" | "bank" | null;
  shipmentStatus: ShipmentStatus;
  dispatchedAt: FirebaseFirestore.Timestamp | null;
  deliveredAt: FirebaseFirestore.Timestamp | null;
  courierRef: string | null;
  soldAt: FirebaseFirestore.Timestamp;
}

export interface GallerySpaceDoc {
  aggregatorId: string;
  name: string;
  addressLine1: string;
  city: string;
  state: string;
  pincode: string;
  capacity: number | null;
  coordinatorName: string | null;
}

export interface BuyerInviteDoc {
  email: string;
  name: string;
  artworkId: string;
  soldPricePaise: number;
  soldAt: FirebaseFirestore.Timestamp;
  source: string;
  claimedAt: FirebaseFirestore.Timestamp | null;
}

export interface AuditLogDoc {
  adminId: string;
  action: string;
  entityType: string;
  entityId: string;
  entityLabel: string | null;
  detail: unknown;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface DisputeDoc {
  orderId: string | null;
  artworkId: string | null;
  raisedByUserId: string;
  reason: string;
  status: string;
  createdAt: FirebaseFirestore.Timestamp;
  resolvedAt: FirebaseFirestore.Timestamp | null;
  resolutionNote: string | null;
}

export interface RateConfigVersionDoc {
  rates: unknown; // PricingRates, kept untyped here to avoid a domain<->db circular import; cast at the call site
  effectiveFrom: FirebaseFirestore.Timestamp;
  proposedBy: string;
  proposedAt: FirebaseFirestore.Timestamp;
  approvedBy: string | null;
  approvedAt: FirebaseFirestore.Timestamp | null;
  // Redundant with `approvedBy !== null` but real: Firestore can't
  // combine a "field != null" filter with an orderBy on a different field
  // without an awkward composite-index workaround, so getActiveVersion()
  // filters on this plain boolean instead.
  approved: boolean;
  reason: string;
}

export interface MessageThreadDoc {
  userId: string;
  fromLabel: string;
  subject: string;
  preview: string;
  body: string;
  unread: boolean;
  receivedAt: FirebaseFirestore.Timestamp;
}

export interface ArtistReviewDoc {
  artistId: string;
  reviewerName: string;
  rating: number;
  comment: string;
  artworkId: string | null;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface ResaleListingDoc {
  sellerId: string;
  artworkId: string;
  listedPricePaise: number;
  status: ResaleListingStatus;
  listedAt: FirebaseFirestore.Timestamp;
}

export interface SupportTicketDoc {
  userId: string;
  subject: string;
  message: string;
  status: "open" | "answered" | "closed";
  createdAt: FirebaseFirestore.Timestamp;
}

export interface ArtistConnectionDoc {
  requesterId: string;
  recipientId: string;
  status: "pending" | "accepted" | "declined";
  message: string | null;
  requestedAt: FirebaseFirestore.Timestamp;
  respondedAt: FirebaseFirestore.Timestamp | null;
}
