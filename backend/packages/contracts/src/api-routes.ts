// The full v1 route table — one row per frontend-web services/*.ts method
// found in the inventory pass, mapped onto the REST endpoint apps/api will
// expose it as. This is the seed apps/api's controllers get generated
// against (Phase 1+) and what packages/contracts' OpenAPI output (once
// @nestjs/swagger or a standalone generator is wired in) is built from —
// having it as plain data means the route table can be reviewed/diffed
// without running the API at all.
//
// `authRole` is the MINIMUM role required — "public" means any request,
// including an unauthenticated one, e.g. the NFC/QR verification page.
// Every non-public route additionally needs the requester to own the
// resource (artist can only touch their own artworks) unless `scope` says
// otherwise — that ownership check is enforced in the handler, not
// expressible in this table alone.

export type HttpMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
export type AuthRole = "public" | "customer" | "artist" | "aggregator" | "admin" | "platform_admin";

export interface RouteSpec {
  method: HttpMethod;
  path: string;
  authRole: AuthRole;
  summary: string;
  /** The frontend-web services/*.ts method this replaces once Phase 6 cuts over. */
  replaces: string;
}

export const apiRoutes: readonly RouteSpec[] = [
  // --- Identity & Auth ---------------------------------------------------
  { method: "POST", path: "/v1/auth/register", authRole: "public", summary: "Create an account", replaces: "authService.register" },
  // Sign-in, password reset and email verification are Firebase client SDK
  // flows (authService.login/forgotPassword/verifyEmail) — no backend route.
  { method: "POST", path: "/v1/auth/bootstrap", authRole: "public", summary: "Create the Firestore profile for an OAuth-created Firebase user (token-verified)", replaces: "n/a — new" },
  { method: "GET", path: "/v1/auth/me", authRole: "customer", summary: "Current user's own profile, from Firestore", replaces: "n/a — new" },

  // --- Catalog / Artwork ---------------------------------------------------
  { method: "GET", path: "/v1/artworks", authRole: "public", summary: "Marketplace listing, filtered", replaces: "artworkService.list" },
  { method: "GET", path: "/v1/artworks/:id", authRole: "public", summary: "One artwork (CustomerArtworkDto)", replaces: "artworkService.get" },
  { method: "GET", path: "/v1/artists/:id", authRole: "public", summary: "Public artist profile", replaces: "artistService.get" },
  { method: "GET", path: "/v1/artists/:id/artworks", authRole: "public", summary: "One artist's listings", replaces: "artworkService.listByArtist" },
  { method: "GET", path: "/v1/verify/:artworkId", authRole: "public", summary: "NFC/QR provenance passport", replaces: "n/a — Phase 5" },
  { method: "GET", path: "/v1/passport/mine", authRole: "customer", summary: "Passports of the pieces I own, made or hold on display (customer, artist, aggregator)", replaces: "n/a — new" },
  { method: "POST", path: "/v1/artworks/:artworkId/transfers", authRole: "customer", summary: "Current owner hands over ownership / display rights", replaces: "ownershipService.initiate" },
  { method: "GET", path: "/v1/transfers/:id", authRole: "customer", summary: "One transfer (parties only)", replaces: "ownershipService.get" },
  { method: "POST", path: "/v1/transfers/:id/accept", authRole: "customer", summary: "Invited recipient accepts", replaces: "ownershipService.accept" },
  { method: "POST", path: "/v1/transfers/:id/cancel", authRole: "customer", summary: "Either party cancels while pending", replaces: "ownershipService.cancel" },
  { method: "POST", path: "/v1/transfers/:id/end-display", authRole: "customer", summary: "Owner ends a display period early", replaces: "ownershipService.endDisplay" },
  { method: "GET", path: "/v1/artist/mou", authRole: "artist", summary: "Latest signed artist MOU record + the current version's blanks filled from my profile", replaces: "artistDashboardService.getProfile().mouAcceptance" },
  { method: "POST", path: "/v1/artist/mou/accept", authRole: "artist", summary: "Sign the current artist MOU (server-timed; snapshots the filled blanks)", replaces: "artistDashboardService.acceptMou" },
  { method: "GET", path: "/v1/aggregator/mou", authRole: "aggregator", summary: "Latest signed aggregator MOU record + the current version's blanks filled from my profile", replaces: "aggregatorProfileService.getProfile().mouAcceptance" },
  { method: "POST", path: "/v1/aggregator/mou/accept", authRole: "aggregator", summary: "Sign the current aggregator MOU (server-timed; snapshots the filled blanks)", replaces: "aggregatorProfileService.acceptMou" },
  { method: "POST", path: "/v1/coa/requests", authRole: "customer", summary: "Request a signed physical certificate", replaces: "physicalCoaService.request" },
  { method: "GET", path: "/v1/coa/requests", authRole: "customer", summary: "Physical certificate requests for one artwork (?artworkId=)", replaces: "physicalCoaService.listForArtwork" },
  { method: "GET", path: "/v1/artist/coa/requests", authRole: "artist", summary: "This artist's physical certificate queue", replaces: "physicalCoaService.listForArtist" },
  { method: "POST", path: "/v1/artist/coa/requests/:id/dispatch", authRole: "artist", summary: "Mark a physical certificate dispatched", replaces: "physicalCoaService.markDispatched" },
  { method: "POST", path: "/v1/admin/artworks/:id/coa/issue", authRole: "admin", summary: "Manually issue a certificate number (idempotent)", replaces: "n/a — new" },
  { method: "POST", path: "/v1/artist/artworks", authRole: "artist", summary: "Submit a new artwork", replaces: "artistDashboardService.submitArtwork" },
  { method: "PATCH", path: "/v1/artist/artworks/:id", authRole: "artist", summary: "Edit within the edit window", replaces: "artistDashboardService.updateArtwork" },
  { method: "POST", path: "/v1/artist/artworks/:id/sold-elsewhere", authRole: "artist", summary: "Mark sold off-platform, queues penalty", replaces: "artistDashboardService.markSoldElsewhere" },
  { method: "GET", path: "/v1/artist/artworks", authRole: "artist", summary: "This artist's own listings", replaces: "artistDashboardService.listArtworks" },
  { method: "GET", path: "/v1/artist/artworks/:id", authRole: "artist", summary: "One of my artworks, owner view", replaces: "artistDashboardService.getArtwork" },

  // --- Marketplace / Orders ---------------------------------------------------
  { method: "POST", path: "/v1/orders", authRole: "customer", summary: "Create + capture a checkout", replaces: "orderService.create" },
  { method: "GET", path: "/v1/orders/:id", authRole: "customer", summary: "One order", replaces: "orderService.get" },
  { method: "GET", path: "/v1/orders", authRole: "customer", summary: "This customer's orders", replaces: "orderService.list" },
  { method: "PATCH", path: "/v1/admin/orders/:id/status", authRole: "admin", summary: "Advance order fulfillment state", replaces: "n/a — new (fulfillment gap)" },
  { method: "GET", path: "/v1/admin/orders", authRole: "admin", summary: "All orders, admin view", replaces: "adminService.listOrders" },
  { method: "GET", path: "/v1/admin/orders/:id", authRole: "admin", summary: "One order, admin view", replaces: "adminService.getOrderAdmin" },
  { method: "GET", path: "/v1/admin/addresses/:id", authRole: "admin", summary: "One address, admin view", replaces: "adminService.getAddressAdmin" },

  // --- Aggregator / Consignment ---------------------------------------------------
  { method: "GET", path: "/v1/aggregator/inventory", authRole: "aggregator", summary: "Reservable artwork this cycle", replaces: "aggregatorService.listReservableInventory" },
  { method: "POST", path: "/v1/aggregator/holdings", authRole: "aggregator", summary: "Reserve a piece, setting the price in month 1 (requires the current MOU signed and an approved GST)", replaces: "aggregatorService.reserve" },
  { method: "POST", path: "/v1/aggregator/holdings/:id/extension", authRole: "aggregator", summary: "Ask to keep a piece past its window, with an assurance it will sell", replaces: "n/a — new" },
  { method: "POST", path: "/v1/admin/holdings/:id/extension/approve", authRole: "admin", summary: "Approve an aggregator's request to keep a piece", replaces: "n/a — new" },
  { method: "POST", path: "/v1/admin/holdings/:id/extension/decline", authRole: "admin", summary: "Decline an aggregator's request to keep a piece", replaces: "n/a — new" },
  { method: "POST", path: "/v1/aggregator/holdings/:id/sale", authRole: "aggregator", summary: "Record a sale", replaces: "aggregatorService.recordSale" },
  { method: "GET", path: "/v1/aggregator/collection", authRole: "aggregator", summary: "Active + past holdings", replaces: "aggregatorService.listCollection" },
  { method: "GET", path: "/v1/aggregator/sales", authRole: "aggregator", summary: "This aggregator's sales", replaces: "aggregatorSalesService.listSales" },
  { method: "GET", path: "/v1/aggregator/sales/remittances-due", authRole: "aggregator", summary: "Cash sales not yet remitted", replaces: "aggregatorSalesService.listRemittancesDue" },
  { method: "PATCH", path: "/v1/aggregator/sales/:id/shipment", authRole: "aggregator", summary: "Advance preparing→dispatched→delivered", replaces: "aggregatorSalesService.advanceShipment" },
  { method: "POST", path: "/v1/aggregator/sales/:id/remit", authRole: "aggregator", summary: "Pay in a cash sale's full price within 2 days: from the wallet, or declare a bank transfer", replaces: "aggregatorSalesService.markRemitted" },
  { method: "POST", path: "/v1/admin/holdings/:id/pull-back", authRole: "admin", summary: "Force-recall a consigned piece", replaces: "adminService.pullBackHolding" },

  // --- Wallet / Settlement ---------------------------------------------------
  { method: "GET", path: "/v1/artist/wallet", authRole: "artist", summary: "Balance + pending settlements", replaces: "artistDashboardService.getWallet" },
  { method: "GET", path: "/v1/artist/wallet/transactions", authRole: "artist", summary: "Wallet transaction history", replaces: "artistDashboardService.listWalletTransactions" },
  { method: "POST", path: "/v1/artist/withdrawals", authRole: "artist", summary: "Request a payout (min ₹1,000)", replaces: "artistDashboardService.requestWithdrawal" },
  { method: "GET", path: "/v1/aggregator/wallet", authRole: "aggregator", summary: "Wallet: spendable balance and what is held for reservations", replaces: "aggregatorSalesService.listWallet" },
  { method: "GET", path: "/v1/aggregator/wallet/transactions", authRole: "aggregator", summary: "Wallet ledger entries: top-ups, holds, returns, commission", replaces: "aggregatorSalesService.listWalletTransactions" },
  { method: "POST", path: "/v1/aggregator/wallet/topups", authRole: "aggregator", summary: "Start a wallet top-up: opens a Razorpay order (or learn payments are simulated)", replaces: "aggregatorSalesService.addFunds" },
  { method: "POST", path: "/v1/aggregator/wallet/topups/:id/verify", authRole: "aggregator", summary: "Checkout.js callback: verify HMAC and credit the wallet", replaces: "n/a — new" },
  { method: "POST", path: "/v1/aggregator/wallet/topups/:id/simulate", authRole: "aggregator", summary: "Credit a top-up without a gateway (PAYMENTS_MODE=simulated only)", replaces: "n/a — new" },
  { method: "GET", path: "/v1/customer/wallet", authRole: "customer", summary: "Customer wallet balance", replaces: "customerWalletService.getWallet" },
  { method: "GET", path: "/v1/account/addresses", authRole: "customer", summary: "List this customer's addresses", replaces: "customerService.listAddresses" },
  { method: "POST", path: "/v1/account/addresses", authRole: "customer", summary: "Add an address", replaces: "customerService.addAddress" },
  { method: "PATCH", path: "/v1/account/addresses/:id", authRole: "customer", summary: "Edit an address", replaces: "customerService.updateAddress" },
  { method: "DELETE", path: "/v1/account/addresses/:id", authRole: "customer", summary: "Delete an address", replaces: "customerService.deleteAddress" },
  { method: "POST", path: "/v1/customer/withdrawals", authRole: "customer", summary: "Request a payout (min ₹500)", replaces: "customerWalletService.requestWithdrawal" },
  { method: "GET", path: "/v1/admin/withdrawals", authRole: "admin", summary: "Withdrawal queue", replaces: "adminService.listWithdrawals" },
  { method: "POST", path: "/v1/admin/withdrawals/:id/approve", authRole: "admin", summary: "Approve a payout", replaces: "adminService.approveWithdrawal" },
  { method: "POST", path: "/v1/admin/withdrawals/:id/reject", authRole: "admin", summary: "Reject a payout, reason required", replaces: "adminService.rejectWithdrawal" },
  { method: "GET", path: "/v1/admin/settlements", authRole: "admin", summary: "Settlement ledger view", replaces: "adminService.listSettlements" },
  { method: "POST", path: "/v1/admin/settlements/:id/retry", authRole: "admin", summary: "Retry a failed settlement", replaces: "adminService.retrySettlement" },

  // --- Trust / KYC / Insurance ---------------------------------------------------
  { method: "POST", path: "/v1/admin/moderation/kyc/:userId/approve", authRole: "admin", summary: "Approve KYC", replaces: "adminService.approveKyc" },
  { method: "POST", path: "/v1/admin/moderation/kyc/:userId/reject", authRole: "admin", summary: "Reject KYC, reason required", replaces: "adminService.rejectKyc" },
  { method: "POST", path: "/v1/artist/deactivation", authRole: "artist", summary: "Request account deactivation", replaces: "artistDashboardService.requestDeactivation" },
  { method: "POST", path: "/v1/admin/deactivation/:userId/approve", authRole: "admin", summary: "Approve deactivation (suspends user)", replaces: "adminService.decideDeactivation" },
  { method: "POST", path: "/v1/admin/deactivation/:userId/reject", authRole: "admin", summary: "Reject deactivation, note optional", replaces: "adminService.decideDeactivation" },
  { method: "GET", path: "/v1/admin/external-fees", authRole: "admin", summary: "External-sale penalty queue", replaces: "adminService.listExternalSaleFees" },
  { method: "POST", path: "/v1/admin/external-fees/:id/decide", authRole: "admin", summary: "Approve or waive a penalty", replaces: "adminService.decideExternalSaleFee" },
  { method: "POST", path: "/v1/admin/moderation/gst/:userId/approve", authRole: "admin", summary: "Approve GST", replaces: "adminService.approveGst" },
  { method: "POST", path: "/v1/admin/moderation/gst/:userId/reject", authRole: "admin", summary: "Reject GST, reason required", replaces: "adminService.rejectGst" },
  { method: "POST", path: "/v1/admin/artworks/:id/insurance/approve", authRole: "admin", summary: "Verify insurance number", replaces: "adminService.setArtworkInsuranceStatus" },
  { method: "POST", path: "/v1/admin/artworks/:id/insurance/reject", authRole: "admin", summary: "Reject insurance number", replaces: "adminService.setArtworkInsuranceStatus" },

  // --- Admin / Moderation (general) ---------------------------------------------------
  { method: "GET", path: "/v1/admin/kpis", authRole: "admin", summary: "Dashboard KPIs", replaces: "adminService.getKpis" },
  { method: "GET", path: "/v1/admin/categories", authRole: "admin", summary: "List categories", replaces: "adminService.listCategories" },
  { method: "POST", path: "/v1/admin/categories", authRole: "admin", summary: "Create a category", replaces: "adminService.createCategory" },
  { method: "PATCH", path: "/v1/admin/categories/:id", authRole: "admin", summary: "Rename a category", replaces: "adminService.updateCategory" },
  { method: "DELETE", path: "/v1/admin/categories/:id", authRole: "admin", summary: "Delete a category (rejects if in use)", replaces: "adminService.deleteCategory" },
  { method: "GET", path: "/v1/admin/artworks", authRole: "admin", summary: "All artworks, admin view", replaces: "adminService.listAllArtworks" },
  { method: "POST", path: "/v1/admin/artworks/:id/approve", authRole: "admin", summary: "Real moderation gate — pending_approval → marketplace; the body carries the required R/U/O/S rank", replaces: "adminService.approveArtwork" },
  { method: "POST", path: "/v1/admin/artworks/:id/reject", authRole: "admin", summary: "Reject, reason required", replaces: "adminService.rejectArtwork" },
  { method: "POST", path: "/v1/admin/artworks/:id/delist", authRole: "admin", summary: "Pull off the marketplace", replaces: "adminService.delistArtwork" },
  { method: "POST", path: "/v1/admin/artworks/:id/rarity", authRole: "admin", summary: "Set R/U/O/S rank (required, cannot be cleared)", replaces: "adminService.setArtworkRarity" },
  { method: "GET", path: "/v1/artist/artworks/:id/images", authRole: "artist", summary: "Images of one of my artworks", replaces: "n/a — new" },
  { method: "POST", path: "/v1/artist/artworks/:id/images/upload-url", authRole: "artist", summary: "Presigned PUT for a new image (browser uploads straight to the bucket)", replaces: "n/a — new" },
  { method: "POST", path: "/v1/artist/artworks/:id/images/upload", authRole: "artist", summary: "Upload an image through the API (fallback when the bucket blocks a browser PUT)", replaces: "n/a — new" },
  { method: "POST", path: "/v1/artist/artworks/:id/images/confirm", authRole: "artist", summary: "Record an uploaded object as an image; cover = sortOrder 0", replaces: "n/a — new" },
  { method: "DELETE", path: "/v1/artist/artworks/:id/images/:imageId", authRole: "artist", summary: "Remove an image (bucket object too)", replaces: "n/a — new" },
  { method: "PUT", path: "/v1/artist/artworks/:id/images/order", authRole: "artist", summary: "Reorder images", replaces: "n/a — new" },
  { method: "GET", path: "/v1/images/artworks/:artworkId/:file", authRole: "public", summary: "Serve an image from the private bucket, immutable-cached", replaces: "n/a — new" },
  { method: "GET", path: "/v1/artist/deactivation", authRole: "artist", summary: "My latest deactivation request", replaces: "artistDashboardService.getDeactivationRequest" },
  { method: "GET", path: "/v1/admin/deactivation", authRole: "admin", summary: "Deactivation queue", replaces: "adminService.listDeactivationRequests" },
  { method: "GET", path: "/v1/artist/penalties", authRole: "artist", summary: "My external-sale fees", replaces: "artistDashboardService.listPenalties" },
  { method: "GET", path: "/v1/aggregator/holdings", authRole: "aggregator", summary: "My holdings", replaces: "aggregatorService.listHoldings" },
  { method: "GET", path: "/v1/aggregator/holdings/:id", authRole: "aggregator", summary: "One holding", replaces: "aggregatorService.getHolding" },
  { method: "POST", path: "/v1/aggregator/holdings/:id/return", authRole: "aggregator", summary: "Unsold return — advance refunded, piece back on the marketplace", replaces: "aggregatorService.releaseHolding" },
  { method: "GET", path: "/v1/pricing-rules", authRole: "public", summary: "The pricing rules in force — markup, GST, fees", replaces: "lib/pricing constants" },
  { method: "GET", path: "/v1/artworks/:id/quote", authRole: "public", summary: "Checkout price breakdown from the rates in force", replaces: "lib/pricing.checkoutTotal" },
  { method: "GET", path: "/v1/admin/aggregators/:id/holdings", authRole: "admin", summary: "One aggregator's holdings", replaces: "adminService.getAggregatorPortfolio" },
  { method: "GET", path: "/v1/admin/artworks/:id/holding", authRole: "admin", summary: "Active holding on a piece, if any", replaces: "adminService.activeHoldingFor" },
  { method: "GET", path: "/v1/account/collection", authRole: "customer", summary: "Artworks I currently own, from the ownership ledger", replaces: "customerCollectionService.list" },
  { method: "GET", path: "/v1/me/profile", authRole: "customer", summary: "My identity, private facts and compliance states (all roles)", replaces: "artistDashboardService.getProfile, customerService.getProfile, aggregatorProfileService" },
  { method: "PATCH", path: "/v1/me/profile", authRole: "customer", summary: "Edit my profile (name, phone, bio, socials, PAN, GSTIN, bank, pickup address)", replaces: "artistDashboardService.updateProfile, customerService.updateProfile" },
  { method: "GET", path: "/v1/admin/rate-config/versions", authRole: "admin", summary: "Proposed/approved pricing rule versions", replaces: "n/a — new" },
  { method: "GET", path: "/v1/admin/rate-config/defaults", authRole: "admin", summary: "Seed pricing rules to pre-fill a proposal", replaces: "n/a — new" },
  { method: "GET", path: "/v1/artist/orders", authRole: "artist", summary: "Orders for my artworks", replaces: "artistDashboardService.listOrders" },
  { method: "GET", path: "/v1/admin/artworks/:id", authRole: "admin", summary: "One artwork, admin view", replaces: "adminService.getArtworkAdmin" },
  { method: "GET", path: "/v1/admin/users/:id", authRole: "admin", summary: "One user with profile facts", replaces: "adminService.getUser" },
  { method: "GET", path: "/v1/admin/moderation/gst", authRole: "admin", summary: "GST review queue", replaces: "adminService.listGstQueue" },
  { method: "GET", path: "/v1/admin/moderation/kyc", authRole: "admin", summary: "KYC review queue", replaces: "adminService.listKycQueue" },
  { method: "GET", path: "/v1/artists", authRole: "public", summary: "Artist directory (artists with a live listing)", replaces: "mockArtists" },
  { method: "GET", path: "/v1/stats/public", authRole: "public", summary: "Headline platform numbers for the About page", replaces: "about-stats-section fixtures" },
  { method: "POST", path: "/v1/orders/:id/payment/session", authRole: "customer", summary: "Open a gateway checkout session (Razorpay order) or learn payments are simulated", replaces: "n/a — new" },
  { method: "POST", path: "/v1/orders/:id/payment/verify", authRole: "customer", summary: "Checkout.js callback: verify HMAC and mark paid", replaces: "n/a — new" },
  { method: "POST", path: "/v1/payments/razorpay/webhook", authRole: "public", summary: "Razorpay webhook (signature-verified, idempotent)", replaces: "n/a — new" },
  { method: "POST", path: "/v1/auth/password-reset", authRole: "public", summary: "Email a branded password-reset link (always 202)", replaces: "authService.forgotPassword" },
  { method: "POST", path: "/v1/auth/resend-verification", authRole: "customer", summary: "Re-send the email verification link", replaces: "n/a — new" },
  { method: "POST", path: "/v1/admin/artworks/reindex", authRole: "admin", summary: "Rebuild every artwork's denormalised listing projection", replaces: "n/a — new" },
  { method: "POST", path: "/v1/admin/artworks/:id/reindex", authRole: "admin", summary: "Rebuild one artwork's listing projection", replaces: "n/a — new" },
  { method: "GET", path: "/v1/admin/users", authRole: "admin", summary: "All users, filterable by role", replaces: "adminService.listUsers" },
  { method: "PATCH", path: "/v1/admin/users/:id/status", authRole: "admin", summary: "Suspend/activate/block a user", replaces: "adminService.setUserStatus" },
  { method: "PATCH", path: "/v1/admin/users/:id/earnings-above-5l", authRole: "admin", summary: "TDS §194-O flag", replaces: "adminService.setEarningsAbove5L" },
  { method: "GET", path: "/v1/admin/audit-log", authRole: "admin", summary: "Full audit trail", replaces: "adminService.listAuditLog" },
  { method: "GET", path: "/v1/admin/reports", authRole: "admin", summary: "Generated finance reports", replaces: "adminService.listReports" },
  { method: "POST", path: "/v1/admin/reports", authRole: "admin", summary: "Generate a new report", replaces: "adminService.generateReport" },

  // --- Admin rules console (rate config) ---------------------------------------------------
  { method: "GET", path: "/v1/admin/rate-config", authRole: "admin", summary: "Current + pending rate versions", replaces: "adminService.getSettings" },
  { method: "POST", path: "/v1/admin/rate-config/propose", authRole: "platform_admin", summary: "Propose a rate change (2-step: propose)", replaces: "adminService.updateSettings" },
  { method: "POST", path: "/v1/admin/rate-config/:versionId/approve", authRole: "platform_admin", summary: "Approve a proposed rate change (2-step: approve)", replaces: "n/a — new" },

  // --- Gallery spaces (aggregator) ---------------------------------------------------
  { method: "GET", path: "/v1/aggregator/gallery-spaces", authRole: "aggregator", summary: "This aggregator's display spaces", replaces: "aggregatorSalesService.listGallerySpaces" },
  { method: "POST", path: "/v1/aggregator/gallery-spaces", authRole: "aggregator", summary: "Add a gallery space", replaces: "n/a — new" },

  // --- Messaging / Support (parity scope) ---------------------------------------------------
  { method: "GET", path: "/v1/messages", authRole: "artist", summary: "Inbox (parity: read+markRead only)", replaces: "messagesService.list" },
  { method: "POST", path: "/v1/messages/:id/read", authRole: "artist", summary: "Mark a message read", replaces: "messagesService.markRead" },
  { method: "GET", path: "/v1/support", authRole: "artist", summary: "This user's support tickets", replaces: "supportService.listTickets" },
  { method: "POST", path: "/v1/support", authRole: "artist", summary: "Submit a support ticket", replaces: "supportService.submitTicket" },

  // --- Resale (parity scope: seller-list-only) ---------------------------------------------------
  { method: "GET", path: "/v1/account/resale", authRole: "customer", summary: "This customer's resale listings", replaces: "customerResaleService.listListings" },
  { method: "POST", path: "/v1/account/resale", authRole: "customer", summary: "List an owned artwork for resale", replaces: "customerResaleService.createListing" },
  { method: "POST", path: "/v1/account/resale/:id/withdraw", authRole: "customer", summary: "Withdraw a resale listing", replaces: "customerResaleService.withdrawListing" },
  { method: "POST", path: "/v1/account/resale/:id/complete", authRole: "customer", summary: "Complete a resale sale, credit wallet", replaces: "customerResaleService.completeSale" },
] as const;
