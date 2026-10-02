// Admin console reads — the joined views the moderation queues, people
// table and money screens need. Admin-only by construction: these carry
// artistPricePaise, emails and phone numbers and are never served to a
// non-admin route.

import type { Firestore } from "firebase-admin/firestore";
import type { PricingRates } from "@galleryzone/domain";
import {
  Collections,
  userProfileCol,
  type ArtworkDoc,
  type ProfileDoc,
  type UserDoc,
  type UserRole,
  type WithdrawalRequestDoc,
} from "./collections.ts";
import { getArtistArtwork, type OwnerArtworkView } from "./artist-artworks.ts";
import { getWalletBalance } from "./wallets.ts";
import { getArtworkNfc } from "./nfc.ts";

export interface AdminArtworkView extends OwnerArtworkView {
  artistEmail: string | null;
  /** When an admin let this piece ship without a locked NFC tag. The reason and who are read for the single-artwork view only. */
  nfcShipmentGateOverrideAt: string | null;
  nfcShipmentGateOverrideReason: string | null;
  nfcShipmentGateOverrideBy: string | null;
}

async function withArtist(db: Firestore, view: OwnerArtworkView, artwork: ArtworkDoc, withOverrideNote = false): Promise<AdminArtworkView> {
  const [artistSnap, nfc] = await Promise.all([db.collection(Collections.users).doc(view.artistId).get(), withOverrideNote ? getArtworkNfc(db, view.id) : null]);
  const artist = artistSnap.data() as UserDoc | undefined;
  return {
    ...view,
    artistEmail: artist?.email ?? null,
    nfcShipmentGateOverrideAt: artwork.nfcShipmentGateOverrideAt?.toDate().toISOString() ?? null,
    nfcShipmentGateOverrideReason: nfc?.shipmentGateOverrideReason ?? null,
    nfcShipmentGateOverrideBy: nfc?.shipmentGateOverrideBy ?? null,
  };
}

/** Every artwork, newest first, with the owner view's detail. Filter by status client-side (statuses are few, rows are hundreds). */
export async function listArtworksForAdmin(db: Firestore, rates: PricingRates): Promise<AdminArtworkView[]> {
  const snap = await db.collection(Collections.artworks).orderBy("createdAt", "desc").get();
  const views = await Promise.all(
    snap.docs.map(async (d) => {
      const artwork = d.data() as ArtworkDoc;
      const view = await getArtistArtwork(db, artwork.artistId, d.id, rates);
      return view ? withArtist(db, view, artwork) : null;
    }),
  );
  return views.filter((v): v is AdminArtworkView => v !== null);
}

export async function getArtworkForAdmin(db: Firestore, artworkId: string, rates: PricingRates): Promise<AdminArtworkView | null> {
  const snap = await db.collection(Collections.artworks).doc(artworkId).get();
  if (!snap.exists) return null;
  const artwork = snap.data() as ArtworkDoc;
  const view = await getArtistArtwork(db, artwork.artistId, artworkId, rates);
  return view ? withArtist(db, view, artwork, true) : null;
}

export interface AdminUserView {
  id: string;
  name: string;
  email: string;
  phone: string | null;
  role: UserRole;
  status: UserDoc["status"];
  roleGrants: string[];
  createdAt: string;
  lastLoginAt: string | null;
  /** Profile facts the console moderates. Null for customers. */
  pan: string | null;
  gstin: string | null;
  gstStatus: string | null;
  aadhaarStatus: string | null;
  companyName: string | null;
  instagram: string | null;
  website: string | null;
  location: string | null;
  bankAccountMasked: string | null;
  /** The §194-O TDS flag an admin has set by hand. */
  earningsAbove5L: boolean;
}

async function toAdminUser(db: Firestore, id: string, u: UserDoc): Promise<AdminUserView> {
  const profile = u.role === "customer" ? undefined : ((await db.collection(userProfileCol(id)).doc("data").get()).data() as ProfileDoc | undefined);
  return {
    id,
    name: u.name,
    email: u.email,
    phone: u.phone ?? null,
    role: u.role,
    status: u.status,
    roleGrants: u.roleGrants ?? [],
    createdAt: u.createdAt?.toDate().toISOString() ?? new Date(0).toISOString(),
    lastLoginAt: u.lastLoginAt?.toDate().toISOString() ?? null,
    pan: profile?.pan ?? null,
    gstin: profile?.gstin ?? null,
    gstStatus: profile?.gstStatus ?? null,
    aadhaarStatus: profile?.aadhaarStatus ?? null,
    companyName: profile?.companyName ?? null,
    instagram: profile?.instagram ?? null,
    website: profile?.website ?? null,
    location: profile?.location ?? null,
    bankAccountMasked: profile?.bankAccountMasked ?? null,
    earningsAbove5L: profile?.earningsAbove5L ?? false,
  };
}

export async function listUsersForAdmin(db: Firestore, role?: UserRole): Promise<AdminUserView[]> {
  let query = db.collection(Collections.users) as FirebaseFirestore.Query;
  if (role) query = query.where("role", "==", role);
  const snap = await query.get();
  const users = await Promise.all(snap.docs.map((d) => toAdminUser(db, d.id, d.data() as UserDoc)));
  return users.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export async function getUserForAdmin(db: Firestore, id: string): Promise<AdminUserView | null> {
  const snap = await db.collection(Collections.users).doc(id).get();
  return snap.exists ? toAdminUser(db, id, snap.data() as UserDoc) : null;
}

export interface AdminWithdrawalView {
  id: string;
  userId: string;
  userName: string;
  userRole: UserRole;
  amountPaise: number;
  bankAccountMasked: string | null;
  walletBalancePaise: number;
  status: WithdrawalRequestDoc["status"];
  requestedAt: string;
  processedAt: string | null;
}

/** All withdrawal requests, pending first then newest. */
export async function listWithdrawalsForAdmin(db: Firestore): Promise<AdminWithdrawalView[]> {
  const snap = await db.collection(Collections.withdrawalRequests).get();
  const rows = await Promise.all(
    snap.docs.map(async (d) => {
      const w = d.data() as WithdrawalRequestDoc;
      const [userSnap, profileSnap, balance] = await Promise.all([
        db.collection(Collections.users).doc(w.userId).get(),
        db.collection(userProfileCol(w.userId)).doc("data").get(),
        getWalletBalance(db, "artist_payable", w.userId),
      ]);
      const user = userSnap.data() as UserDoc | undefined;
      const profile = profileSnap.data() as ProfileDoc | undefined;
      return {
        id: d.id,
        userId: w.userId,
        userName: user?.name ?? w.userId,
        userRole: user?.role ?? "artist",
        amountPaise: w.amountPaise,
        bankAccountMasked: profile?.bankAccountMasked ?? null,
        walletBalancePaise: balance.balancePaise,
        status: w.status,
        requestedAt: w.requestedAt?.toDate().toISOString() ?? new Date(0).toISOString(),
        processedAt: w.processedAt?.toDate().toISOString() ?? null,
      };
    }),
  );
  const rank = (s: string) => (s === "pending" ? 0 : 1);
  return rows.sort((a, b) => rank(a.status) - rank(b.status) || b.requestedAt.localeCompare(a.requestedAt));
}

/** Artists/aggregators whose GST or KYC is waiting on a decision. */
export async function listModerationQueue(db: Firestore, kind: "gst" | "kyc"): Promise<AdminUserView[]> {
  const users = await listUsersForAdmin(db);
  const field = kind === "gst" ? "gstStatus" : "aadhaarStatus";
  return users.filter((u) => (u.role === "artist" || u.role === "aggregator") && u[field] === "submitted");
}

export interface AdminKpiView {
  totalUsers: number;
  totalArtworks: number;
  liveArtworks: number;
  pendingApprovalArtworks: number;
  pendingWithdrawals: number;
  pendingGst: number;
  pendingKyc: number;
  totalOrders: number;
  paidOrders: number;
  gmvPaise: number;
}

/** One pass over the projection + a few counts — no per-artwork reads. */
export async function adminKpis(db: Firestore): Promise<AdminKpiView> {
  const [users, artworks, pendingWithdrawals, orders, gst, kyc] = await Promise.all([
    db.collection(Collections.users).count().get(),
    db.collection(Collections.artworks).select("listing.status").get(),
    db.collection(Collections.withdrawalRequests).where("status", "==", "pending").count().get(),
    db.collection(Collections.orders).select("status", "totalPaise").get(),
    listModerationQueue(db, "gst"),
    listModerationQueue(db, "kyc"),
  ]);
  let live = 0;
  let pending = 0;
  for (const d of artworks.docs) {
    const status = (d.data() as { listing?: { status?: string } }).listing?.status;
    if (status === "marketplace") live += 1;
    if (status === "pending_approval") pending += 1;
  }
  const PAID = new Set(["paid", "confirmed", "packed", "transit", "delivered"]);
  let paid = 0;
  let gmv = 0;
  for (const d of orders.docs) {
    const o = d.data() as { status: string; totalPaise: number };
    if (PAID.has(o.status)) {
      paid += 1;
      gmv += o.totalPaise;
    }
  }
  return {
    totalUsers: users.data().count,
    totalArtworks: artworks.size,
    liveArtworks: live,
    pendingApprovalArtworks: pending,
    pendingWithdrawals: pendingWithdrawals.data().count,
    pendingGst: gst.length,
    pendingKyc: kyc.length,
    totalOrders: orders.size,
    paidOrders: paid,
    gmvPaise: gmv,
  };
}
