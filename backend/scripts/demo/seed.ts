import { writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { getAuth } from "firebase-admin/auth";
import { Timestamp } from "firebase-admin/firestore";
import {
  Collections,
  artworkStatusEventsCol,
  createDb,
  grantRole,
  orderStatusEventsCol,
  userProfileCol,
  type Db,
} from "../../packages/db/src/index.ts";
import { accounts, busyArtistArtworks, categories, imageSizes, longNameArtistArtworks, PASSWORD, type AccountKey, type ArtworkSeed } from "./demo-data.ts";
import { healthCheck, register, request, resetEmulators, signIn, type DemoAccount } from "./api.ts";
import { makePaintingPng } from "./png.ts";

const projectId = process.env.FIREBASE_PROJECT_ID;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
if (!firestoreHost || !authHost || !projectId?.startsWith("demo-")) {
  console.error(
    "Refusing to seed: FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST must be set, and FIREBASE_PROJECT_ID must start with demo-. This script is for local emulators only.",
  );
  process.exit(1);
}
if (!/^(127\.0\.0\.1|localhost):/.test(firestoreHost) || !/^(127\.0\.0\.1|localhost):/.test(authHost)) {
  console.error("Refusing to seed: both emulator hosts must point to localhost or 127.0.0.1.");
  process.exit(1);
}

// An emulator run never needs credentials. Removing these process-local values
// makes it impossible for this script to read a service-account key by mistake.
delete process.env.GOOGLE_APPLICATION_CREDENTIALS;
delete process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

type AccountMap = Record<AccountKey, DemoAccount>;
type ArtworkView = { id: string; title: string; status: string; images: { url: string }[]; insuranceStatus?: string | null };
type HoldingView = { id: string; artworkId: string; displayPricePaise: number; status: string };

const DAY = 86_400_000;
const now = () => new Date();
const daysAgo = (days: number) => new Date(Date.now() - days * DAY);
const daysFromNow = (days: number) => new Date(Date.now() + days * DAY);
const log = (message: string) => console.log(`[demo:seed] ${message}`);

function artistPriceForDisplay(displayPricePaise: number): number {
  const approximate = Math.round(displayPricePaise / 1.365);
  for (let candidate = Math.max(1, approximate - 20); candidate <= approximate + 20; candidate += 1) {
    if (Math.round(Math.round(candidate * 1.3) * 1.05) === displayPricePaise) return candidate;
  }
  return approximate;
}

async function assertEmpty(db: Db): Promise<void> {
  const [collections, authUsers] = await Promise.all([db.listCollections(), getAuth().listUsers(1)]);
  if (collections.length || authUsers.users.length) {
    throw new Error(`Reset verification failed: ${collections.length} Firestore collection(s), ${authUsers.users.length} Auth user(s) remain`);
  }
}

async function createAccounts(db: Db): Promise<AccountMap> {
  const registered = {} as Record<AccountKey, { uid: string; email: string }>;
  for (const account of accounts) {
    const uid = await register({ email: account.email, password: PASSWORD, name: account.name, role: account.role });
    registered[account.key] = { uid, email: account.email };
    await getAuth().updateUser(uid, { emailVerified: true });
  }

  for (const key of ["admin", "admin2"] as const) {
    const uid = registered[key].uid;
    await db.collection(Collections.users).doc(uid).update({ role: "admin" });
    await grantRole(db, uid, "platform_admin");
    const authUser = await getAuth().getUser(uid);
    await getAuth().setCustomUserClaims(uid, { ...(authUser.customClaims ?? {}), role: "admin", grants: ["platform_admin"] });
  }

  const result = {} as AccountMap;
  for (const account of accounts) {
    const { uid, email } = registered[account.key];
    result[account.key] = { uid, email, token: await signIn(email, PASSWORD) };
  }

  for (const account of Object.values(result)) {
    await request(`/v1/admin/users/${account.uid}/status`, { method: "PATCH", token: result.admin.token, body: { status: "active" } });
  }
  return result;
}

async function seedProfiles(db: Db, users: AccountMap): Promise<void> {
  await request("/v1/me/profile", {
    method: "PATCH",
    token: users.artist.token,
    body: {
      phone: "9876543210",
      headline: "Contemporary painter of place, memory and monsoon light",
      bio: "Aanya Deshmukh works between Pune and the Konkan coast. Her layered paintings combine field drawings, oral histories and the visual language of everyday domestic objects. Her practice has been shown in artist-led spaces across Maharashtra and is collected by first-time and established collectors alike.",
      location: "Pune, Maharashtra",
      instagram: "aanya.deskhmukh.studio",
      website: "aanyadeshmukh.art",
      socialProofVideoUrl: "https://video.example.test/aanya-studio-visit-2026",
      pan: "ABCDE1234F",
      gstin: "27ABCDE1234F1Z5",
      bankAccountNumber: "501237894612",
      ifsc: "HDFC0001234",
      pickupLine1: "Studio 14, Prabhat Road",
      pickupLine2: "Near Film Institute Gate",
      pickupCity: "Pune",
      pickupState: "Maharashtra",
      pickupPincode: "411004",
    },
  });
  await request("/v1/me/profile", {
    method: "PATCH",
    token: users.artist2.token,
    body: {
      phone: "9123456780",
      headline: "Painter, printmaker and patient observer of coastal weather",
      bio: "Raghunath Venkataramanan-Iyer builds slow, research-led images from notebooks kept across Kerala's coast and railway towns. His archive includes family photographs, ticket stubs, pigment tests and interviews with boat builders. A longer account of the ongoing project, including working notes and an intentionally long link for layout testing, is available at https://archive.raghunath-venkataramanan-iyer.example.test/research/monsoon-atlas/field-notes-and-conservation-records/volume-seven.",
      location: "Thiruvananthapuram, Kerala",
      instagram: "raghunath.v.iyer",
      website: "raghunath-venkataramanan-iyer.example.test",
      pan: "AAACR5055K",
      gstin: "32AAACR5055K1Z2",
    },
  });
  await request("/v1/me/profile", {
    method: "PATCH",
    token: users.aggregator.token,
    body: {
      phone: "9988776655",
      headline: "A neighbourhood gallery for ambitious modern and contemporary Indian art",
      bio: "Kala Ghar Gallery presents rotating exhibitions, collector previews and artist conversations from its Bandra West rooms.",
      location: "Bandra West, Mumbai",
      companyName: "Kala Ghar Gallery Private Limited",
      website: "kalaghar.example.test",
      gstin: "27AAECK1234L1Z7",
      bankAccountNumber: "743829105678",
      ifsc: "ICIC0000471",
      pickupLine1: "18 Chapel Road",
      pickupCity: "Mumbai",
      pickupState: "Maharashtra",
      pickupPincode: "400050",
    },
  });
  await request("/v1/me/profile", {
    method: "PATCH",
    token: users.collector.token,
    body: {
      phone: "9765432108",
      bio: "Collector of contemporary Indian works on paper, textile and small-format painting.",
      location: "Bengaluru, Karnataka",
      bankAccountNumber: "620491738561",
      ifsc: "SBIN0003355",
    },
  });

  await request("/v1/artist/mou/accept", { method: "POST", token: users.artist.token, body: { version: "v2026.2", signatureName: "Aanya Deshmukh" } });
  await request("/v1/aggregator/mou/accept", {
    method: "POST",
    token: users.aggregator.token,
    body: { version: "v2026.2", signatureName: "Kala Ghar Gallery, Bandra West, Mumbai" },
  });
  await request("/v1/support", {
    method: "POST",
    token: users.artist.token,
    body: { subject: "Courier packaging for an oversized canvas", message: "Please advise whether the 48-inch work should ship in a reinforced crate or an archival tube." },
  });

  for (const key of ["artist", "artist2", "aggregator"] as const) {
    await db.collection(userProfileCol(users[key].uid)).doc("data").set({ aadhaarStatus: "submitted", aadhaarMasked: `XXXX XXXX ${key === "artist" ? "4821" : key === "artist2" ? "7319" : "1142"}` }, { merge: true });
  }
  await request(`/v1/admin/moderation/kyc/${users.artist.uid}/approve`, { method: "POST", token: users.admin.token, body: {} });
  await request(`/v1/admin/moderation/gst/${users.artist.uid}/approve`, { method: "POST", token: users.admin.token, body: {} });
  await request(`/v1/admin/moderation/kyc/${users.artist2.uid}/reject`, { method: "POST", token: users.admin.token, body: { reason: "Address proof image is cropped; please upload the full document." } });
  await request(`/v1/admin/moderation/gst/${users.artist2.uid}/reject`, { method: "POST", token: users.admin.token, body: { reason: "Trade name does not match the submitted profile." } });
}

async function seedSettings(users: AccountMap): Promise<void> {
  for (const name of categories) {
    await request("/v1/admin/categories", { method: "POST", token: users.admin.token, body: { name, slug: name.toLowerCase().replaceAll(" ", "-") } });
  }
  const defaults = await request<{ rates: Record<string, unknown> }>("/v1/admin/rate-config/defaults", { token: users.admin.token });
  const proposal = await request<{ versionId: string }>("/v1/admin/rate-config/propose", {
    method: "POST",
    token: users.admin.token,
    body: { rates: defaults.rates, effectiveFrom: daysAgo(1).toISOString(), reason: "Initial approved pricing rules for the local screenshot demo dataset." },
  });
  await request(`/v1/admin/rate-config/${proposal.versionId}/approve`, { method: "POST", token: users.admin2.token, body: {} });
}

async function createArtwork(token: string, seed: ArtworkSeed, index: number): Promise<{ artwork: ArtworkView; imageUrl: string }> {
  let artwork = await request<ArtworkView>("/v1/artist/artworks", {
    method: "POST",
    token,
    body: {
      title: seed.title,
      description: seed.description,
      category: seed.category,
      medium: seed.medium,
      dimensions: seed.dimensions,
      yearCreated: seed.yearCreated,
      artistPricePaise: artistPriceForDisplay(seed.displayPricePaise),
      listingType: seed.listingType,
      mode: "draft",
      artworkType: seed.artworkType ?? null,
      paintingStyle: seed.paintingStyle ?? null,
      insuranceOpted: seed.displayPricePaise >= 2_000_000,
      insuranceNumber: seed.insuranceNumber ?? null,
      nfcTagId: `GZ-NFC-DEMO-${String(index + 1).padStart(4, "0")}`,
      physical: {
        weightKg: Number((1.4 + (index % 8) * 0.75).toFixed(2)),
        framing: index % 3 === 0 ? "Natural ash float frame" : index % 3 === 1 ? "Unframed, archival rolled shipment" : "Matte black aluminium frame",
        format: index % 2 ? "Portrait" : "Landscape",
        hangingHardwareIncluded: index % 2 === 0,
        packagingConfirmed: true,
      },
    },
  });
  const [width, height] = imageSizes[index % imageSizes.length]!;
  const png = makePaintingPng(width, height, `${seed.title}:${index}`);
  const image = await request<{ url: string }>(`/v1/artist/artworks/${artwork.id}/images/upload`, {
    method: "POST",
    token,
    body: png,
    headers: { "Content-Type": "image/png", "X-Alt-Text": encodeURIComponent(`${seed.title} by the demo artist`) },
  });
  artwork = await request<ArtworkView>(`/v1/artist/artworks/${artwork.id}`, { token });
  return { artwork, imageUrl: image.url };
}

async function seedArtworks(db: Db, users: AccountMap): Promise<{ busy: ArtworkView[]; long: ArtworkView[]; imageUrl: string }> {
  const busy: ArtworkView[] = [];
  const long: ArtworkView[] = [];
  let firstImageUrl = "";
  for (let i = 0; i < busyArtistArtworks.length; i += 1) {
    const created = await createArtwork(users.artist.token, busyArtistArtworks[i]!, i);
    if (!firstImageUrl) firstImageUrl = created.imageUrl;
    if (i !== 0) {
      created.artwork = await request<ArtworkView>(`/v1/artist/artworks/${created.artwork.id}`, { method: "PATCH", token: users.artist.token, body: { mode: "review" } });
    }
    busy.push(created.artwork);
    log(`artwork ${i + 1}/${busyArtistArtworks.length + longNameArtistArtworks.length}: ${created.artwork.title}`);
  }
  for (let i = 0; i < longNameArtistArtworks.length; i += 1) {
    const created = await createArtwork(users.artist2.token, longNameArtistArtworks[i]!, i + busyArtistArtworks.length);
    created.artwork = await request<ArtworkView>(`/v1/artist/artworks/${created.artwork.id}`, { method: "PATCH", token: users.artist2.token, body: { mode: "review" } });
    long.push(created.artwork);
    log(`artwork ${busy.length + i + 1}/${busyArtistArtworks.length + longNameArtistArtworks.length}: ${created.artwork.title}`);
  }

  await request(`/v1/admin/artworks/${busy[2]!.id}/reject`, { method: "POST", token: users.admin.token, body: { reason: "Please provide a clearer reverse-side photograph and confirm the final dimensions." } });
  for (const artwork of [...busy.slice(3), ...long]) {
    await request(`/v1/admin/artworks/${artwork.id}/approve`, { method: "POST", token: users.admin.token, body: {} });
  }
  for (let i = 3; i < busy.length; i += 4) {
    await request(`/v1/admin/artworks/${busy[i]!.id}/rarity`, { method: "POST", token: users.admin.token, body: { rarity: ["R", "U", "O", "N"][i % 4] } });
  }
  await request(`/v1/admin/artworks/${busy[4]!.id}/insurance/approve`, { method: "POST", token: users.admin.token, body: {} });
  await request(`/v1/admin/artworks/${busy[5]!.id}/insurance/reject`, { method: "POST", token: users.admin.token, body: { reason: "The policy number could not be verified with the insurer." } });
  await request(`/v1/admin/artworks/${busy[6]!.id}/delist`, { method: "POST", token: users.admin.token, body: {} });

  const penalties: { penaltyId: string }[] = [];
  for (const artwork of busy.slice(7, 10)) {
    penalties.push(await request<{ penaltyId: string }>(`/v1/artist/artworks/${artwork.id}/sold-elsewhere`, { method: "POST", token: users.artist.token, body: {} }));
  }
  await request(`/v1/admin/external-fees/${penalties[1]!.penaltyId}/decide`, { method: "POST", token: users.admin.token, body: { decision: "approved", note: "Fee confirmed after reviewing the artist's external invoice." } });
  await request(`/v1/admin/external-fees/${penalties[2]!.penaltyId}/decide`, { method: "POST", token: users.admin.token, body: { decision: "waived", note: "Sale pre-dated the GalleryZone listing agreement." } });

  for (let i = 0; i < [...busy, ...long].length; i += 1) {
    const artwork = [...busy, ...long][i]!;
    await db.collection(Collections.artworks).doc(artwork.id).update({ createdAt: Timestamp.fromDate(daysAgo(2 + ((i * 7) % 88))) });
  }
  return { busy, long, imageUrl: firstImageUrl };
}

async function seedCollector(db: Db, users: AccountMap, artworks: ArtworkView[]) {
  const home = await request<{ id: string }>("/v1/account/addresses", {
    method: "POST",
    token: users.collector.token,
    body: { line1: "42, 5th Main, Indiranagar", line2: "Near the Metro station", city: "Bengaluru", state: "Karnataka", pincode: "560038", isDefault: true },
  });
  await request("/v1/account/addresses", {
    method: "POST",
    token: users.collector.token,
    body: { line1: "Villa 9, Riverside Enclave", line2: "Whitefield Main Road", city: "Bengaluru", state: "Karnataka", pincode: "560066", isDefault: false },
  });

  const orders: string[] = [];
  for (let i = 0; i < 4; i += 1) {
    const result = await request<{ orderId: string }>("/v1/orders", {
      method: "POST",
      token: users.collector.token,
      body: { artworkId: artworks[10 + i]!.id, addressId: home.id, idempotencyKey: `demo-checkout-${i}-${artworks[10 + i]!.id}` },
    });
    await request(`/v1/orders/${result.orderId}/simulate-payment`, { method: "POST", token: users.collector.token, body: {} });
    orders.push(result.orderId);
  }
  await request(`/v1/admin/orders/${orders[1]}/status`, { method: "PATCH", token: users.admin.token, body: { to: "confirmed" } });
  for (const status of ["confirmed", "packed", "transit"] as const) {
    await request(`/v1/admin/orders/${orders[2]}/status`, { method: "PATCH", token: users.admin.token, body: { to: status } });
  }
  for (const status of ["confirmed", "packed", "transit", "delivered"] as const) {
    await request(`/v1/admin/orders/${orders[3]}/status`, { method: "PATCH", token: users.admin.token, body: { to: status } });
  }

  const coaPending = await request<{ id: string }>("/v1/coa/requests", {
    method: "POST",
    token: users.collector.token,
    body: { artworkId: artworks[10]!.id, delivery: { line1: "42, 5th Main, Indiranagar", city: "Bengaluru", state: "Karnataka", pincode: "560038" } },
  });
  const coaDispatched = await request<{ id: string }>("/v1/coa/requests", {
    method: "POST",
    token: users.collector.token,
    body: { artworkId: artworks[11]!.id, delivery: { line1: "42, 5th Main, Indiranagar", city: "Bengaluru", state: "Karnataka", pincode: "560038" } },
  });
  await request(`/v1/artist/coa/requests/${coaDispatched.id}/dispatch`, { method: "POST", token: users.artist.token, body: { courierRef: "BLUEDART-785621904-IN" } });

  const transfer = await request<{ id: string }>(`/v1/artworks/${artworks[12]!.id}/transfers`, {
    method: "POST",
    token: users.collector.token,
    body: { kind: "ownership", toName: "Zoya Menon", toEmail: users.friend.email },
  });
  await request("/v1/account/resale", { method: "POST", token: users.collector.token, body: { artworkId: artworks[10]!.id, listedPricePaise: 21_500_000 } });
  const soldResale = await request<{ id: string }>("/v1/account/resale", { method: "POST", token: users.collector.token, body: { artworkId: artworks[11]!.id, listedPricePaise: 29_900_000 } });
  await request(`/v1/account/resale/${soldResale.id}/complete`, { method: "POST", token: users.collector.token, body: {} });
  await request("/v1/support", { method: "POST", token: users.collector.token, body: { subject: "Framing advice for my new acquisition", message: "Could you confirm whether museum glass is recommended for the work on paper in order GZ demo?" } });

  const deliveredAt = daysAgo(12);
  await db.collection(Collections.orders).doc(orders[3]!).update({ createdAt: Timestamp.fromDate(daysAgo(24)) });
  const deliveredEvents = await db.collection(orderStatusEventsCol(orders[3]!)).where("status", "==", "delivered").get();
  for (const event of deliveredEvents.docs) await event.ref.update({ changedAt: Timestamp.fromDate(deliveredAt) });

  const orderDocs = await Promise.all(orders.map((id) => db.collection(Collections.orders).doc(id).get()));
  const settlementStatuses = ["pending", "failed", "pending", "processed"] as const;
  for (let i = 0; i < orders.length; i += 1) {
    const order = orderDocs[i]!.data() as { totalPaise: number };
    await db.collection(Collections.settlements).add({
      orderId: orders[i],
      holdingId: null,
      artistId: users.artist.uid,
      artistAmountPaise: Math.round(order.totalPaise * 0.7),
      aggregatorCommissionPaise: null,
      platformRevenuePaise: Math.round(order.totalPaise * 0.2),
      status: settlementStatuses[i],
      releaseAfter: Timestamp.fromDate(i === 3 ? daysAgo(5) : daysFromNow(3 + i)),
      createdAt: Timestamp.fromDate(daysAgo(20 - i * 3)),
      processedAt: i === 3 ? Timestamp.fromDate(daysAgo(4)) : null,
    });
  }
  void coaPending;
  return { orders, transferId: transfer.id };
}

async function seedAggregator(db: Db, users: AccountMap, artworks: ArtworkView[]) {
  await request("/v1/aggregator/gallery-spaces", {
    method: "POST",
    token: users.aggregator.token,
    body: { name: "Kala Ghar Main Gallery", addressLine1: "18 Chapel Road, Bandra West", city: "Mumbai", state: "Maharashtra", pincode: "400050", capacity: 42, coordinatorName: "Sonal Merchant" },
  });
  await request("/v1/aggregator/gallery-spaces", {
    method: "POST",
    token: users.aggregator.token,
    body: { name: "The Viewing Room at Pali Hill", addressLine1: "7 Nargis Dutt Road", city: "Mumbai", state: "Maharashtra", pincode: "400052", capacity: 18, coordinatorName: "Aditya Fernandes" },
  });

  const holdings: HoldingView[] = [];
  for (const artwork of artworks.slice(14, 20)) {
    holdings.push(await request<HoldingView>("/v1/aggregator/holdings", { method: "POST", token: users.aggregator.token, body: { artworkId: artwork.id } }));
  }
  const repriced = await request<HoldingView>(`/v1/aggregator/holdings/${holdings[2]!.id}/price`, {
    method: "POST",
    token: users.aggregator.token,
    body: { displayPricePaise: holdings[2]!.displayPricePaise + 500_000 },
  });

  const saleDirect = await request<{ saleId: string }>(`/v1/aggregator/holdings/${holdings[2]!.id}/sale`, {
    method: "POST",
    token: users.aggregator.token,
    body: { holdingId: holdings[2]!.id, soldPricePaise: repriced.displayPricePaise, buyerName: "Devika Shah", buyerEmail: "devika.shah@example.test", buyerPhone: "9820011223", deliveryMode: "courier", paymentRoute: "direct_to_galleryzone", deliveryAddress: "Altamount Road, Mumbai" },
  });
  const saleCashDue = await request<{ saleId: string }>(`/v1/aggregator/holdings/${holdings[3]!.id}/sale`, {
    method: "POST",
    token: users.aggregator.token,
    body: { holdingId: holdings[3]!.id, soldPricePaise: holdings[3]!.displayPricePaise, buyerName: "Ishaan Mehta", buyerEmail: "ishaan.mehta@example.test", deliveryMode: "self_pickup", paymentRoute: "cash_at_premises" },
  });
  const saleCashRemitted = await request<{ saleId: string }>(`/v1/aggregator/holdings/${holdings[4]!.id}/sale`, {
    method: "POST",
    token: users.aggregator.token,
    body: { holdingId: holdings[4]!.id, soldPricePaise: holdings[4]!.displayPricePaise, buyerName: "Ananya and Rohit Kapoor", buyerEmail: "kapoor.collection@example.test", buyerPhone: "9892987654", deliveryMode: "courier", paymentRoute: "cash_at_premises", deliveryAddress: "Juhu Tara Road, Mumbai" },
  });
  await request(`/v1/aggregator/sales/${saleDirect.saleId}/shipment`, { method: "PATCH", token: users.aggregator.token, body: { to: "dispatched", courierRef: "DTDC-GZ-2026-4418" } });
  await request(`/v1/aggregator/sales/${saleDirect.saleId}/shipment`, { method: "PATCH", token: users.aggregator.token, body: { to: "delivered", courierRef: "DTDC-GZ-2026-4418" } });
  await request(`/v1/aggregator/sales/${saleCashDue.saleId}/shipment`, { method: "PATCH", token: users.aggregator.token, body: { to: "dispatched", courierRef: "SELF-PICKUP-ACK-191" } });
  await request(`/v1/aggregator/sales/${saleCashRemitted.saleId}/shipment`, { method: "PATCH", token: users.aggregator.token, body: { to: "dispatched", courierRef: "BLUEDART-40622915" } });
  await request(`/v1/aggregator/sales/${saleCashRemitted.saleId}/shipment`, { method: "PATCH", token: users.aggregator.token, body: { to: "delivered", courierRef: "BLUEDART-40622915" } });
  await request(`/v1/aggregator/sales/${saleCashRemitted.saleId}/remit`, { method: "POST", token: users.aggregator.token, body: {} });
  await request(`/v1/aggregator/holdings/${holdings[5]!.id}/return`, { method: "POST", token: users.aggregator.token, body: {} });

  await db.collection(Collections.aggregatorHoldings).doc(holdings[0]!.id).update({
    cycleMonth: 2,
    assignedAt: Timestamp.fromDate(daysAgo(58)),
    expiresAt: Timestamp.fromDate(daysFromNow(17)),
  });
  await db.collection(Collections.aggregatorSales).doc(saleDirect.saleId).update({ soldAt: Timestamp.fromDate(daysAgo(31)), deliveredAt: Timestamp.fromDate(daysAgo(22)) });
  await request("/v1/support", { method: "POST", token: users.aggregator.token, body: { subject: "Add an artwork to the October collector preview", message: "Please confirm the insurance paperwork required for our Pali Hill viewing room." } });
  return { holdings, saleIds: [saleDirect.saleId, saleCashDue.saleId, saleCashRemitted.saleId] };
}

async function seedWalletAndQueues(users: AccountMap): Promise<void> {
  const completed = await request<{ withdrawalId: string }>("/v1/artist/withdrawals", { method: "POST", token: users.artist.token, body: { amountPaise: 1_500_000 } });
  const rejected = await request<{ withdrawalId: string }>("/v1/artist/withdrawals", { method: "POST", token: users.artist.token, body: { amountPaise: 1_250_000 } });
  await request("/v1/artist/withdrawals", { method: "POST", token: users.artist.token, body: { amountPaise: 2_000_000 } });
  await request(`/v1/admin/withdrawals/${completed.withdrawalId}/approve`, { method: "POST", token: users.admin.token, body: {} });
  await request(`/v1/admin/withdrawals/${rejected.withdrawalId}/reject`, { method: "POST", token: users.admin.token, body: {} });
}

async function seedDirectOnlyFixtures(db: Db, users: AccountMap): Promise<void> {
  const messages = [
    [users.artist.uid, "GalleryZone Curatorial Team", "Your monsoon series is live", "Collectors can now discover the newly approved works.", "We have featured three works from your monsoon series in this week's editorial selection.", true, 3],
    [users.aggregator.uid, "Partner Operations", "October placement window", "Six works are available for your upcoming collector preview.", "Your reservation window is open. Please review delivery deposits and confirm wall capacity before adding more works.", true, 8],
    [users.collector.uid, "Collector Care", "Care guide for your collection", "A few simple steps will protect works on paper during the monsoon.", "Keep works away from direct sunlight and allow air circulation behind framed paper pieces.", false, 18],
  ] as const;
  for (const [userId, fromLabel, subject, preview, body, unread, age] of messages) {
    await db.collection(Collections.messageThreads).add({ userId, fromLabel, subject, preview, body, unread, receivedAt: Timestamp.fromDate(daysAgo(age)) });
  }

  const ledger = await db.collection(Collections.ledgerEntries).get();
  for (let i = 0; i < ledger.docs.length; i += 1) {
    await ledger.docs[i]!.ref.update({ createdAt: Timestamp.fromDate(daysAgo(1 + ((i * 5) % 80))) });
  }
  const artworkDocs = await db.collection(Collections.artworks).get();
  for (let i = 0; i < artworkDocs.docs.length; i += 1) {
    const events = await db.collection(artworkStatusEventsCol(artworkDocs.docs[i]!.id)).orderBy("changedAt", "asc").get();
    const oldestAgeDays = 88 - ((i * 2) % 68);
    for (let j = 0; j < events.docs.length; j += 1) {
      await events.docs[j]!.ref.update({ changedAt: Timestamp.fromDate(daysAgo(Math.max(1, oldestAgeDays - j))) });
    }
  }
}

async function verify(users: AccountMap, expectedRoles: Record<AccountKey, string>, imageUrl: string) {
  const marketplace = await request<{ total: number; artworks: unknown[]; facets: { priceRangePaise: { min: number; max: number } | null } }>("/v1/artworks?pageSize=60");
  const artist = await request<{ artworks: ArtworkView[] }>("/v1/artist/artworks", { token: users.artist.token });
  const artistOrders = await request<{ orders: unknown[] }>("/v1/artist/orders", { token: users.artist.token });
  const artistPenalties = await request<{ penalties: unknown[] }>("/v1/artist/penalties", { token: users.artist.token });
  const artistCoa = await request<{ status: string }[]>("/v1/artist/coa/requests", { token: users.artist.token });
  const artistWallet = await request<{ balancePaise: number; lockedPaise: number }>("/v1/artist/wallet", { token: users.artist.token });
  const artistTransactions = await request<{ transactions: unknown[] }>("/v1/artist/wallet/transactions", { token: users.artist.token });
  const artistMessages = await request<unknown[]>("/v1/messages", { token: users.artist.token });
  const artistSupport = await request<unknown[]>("/v1/support", { token: users.artist.token });
  const longArtist = await request<{ artworks: ArtworkView[] }>("/v1/artist/artworks", { token: users.artist2.token });
  const collection = await request<{ items: unknown[] }>("/v1/account/collection", { token: users.collector.token });
  const collectorOrders = await request<unknown[]>("/v1/orders", { token: users.collector.token });
  const collectorAddresses = await request<unknown[]>("/v1/account/addresses", { token: users.collector.token });
  const collectorResale = await request<unknown[]>("/v1/account/resale", { token: users.collector.token });
  const collectorWallet = await request<{ balancePaise: number }>("/v1/customer/wallet", { token: users.collector.token });
  const collectorMessages = await request<unknown[]>("/v1/messages", { token: users.collector.token });
  const collectorSupport = await request<unknown[]>("/v1/support", { token: users.collector.token });
  const holdings = await request<{ holdings: HoldingView[] }>("/v1/aggregator/holdings", { token: users.aggregator.token });
  const aggregatorInventory = await request<{ artworks: unknown[] }>("/v1/aggregator/inventory", { token: users.aggregator.token });
  const aggregatorSales = await request<unknown[]>("/v1/aggregator/sales", { token: users.aggregator.token });
  const remittancesDue = await request<unknown[]>("/v1/aggregator/sales/remittances-due", { token: users.aggregator.token });
  const gallerySpaces = await request<unknown[]>("/v1/aggregator/gallery-spaces", { token: users.aggregator.token });
  const aggregatorMessages = await request<unknown[]>("/v1/messages", { token: users.aggregator.token });
  const aggregatorSupport = await request<unknown[]>("/v1/support", { token: users.aggregator.token });
  const adminArtworks = await request<{ artworks: ArtworkView[] }>("/v1/admin/artworks", { token: users.admin.token });
  const adminUsers = await request<{ users: { gstStatus: string | null; aadhaarStatus: string | null }[] }>("/v1/admin/users", { token: users.admin.token });
  const kyc = await request<{ users: unknown[] }>("/v1/admin/moderation/kyc", { token: users.admin.token });
  const gst = await request<{ users: unknown[] }>("/v1/admin/moderation/gst", { token: users.admin.token });
  const withdrawals = await request<{ withdrawals: { status: string }[] }>("/v1/admin/withdrawals", { token: users.admin.token });
  const fees = await request<{ status: string }[]>("/v1/admin/external-fees", { token: users.admin.token });
  const settlements = await request<{ status: string }[]>("/v1/admin/settlements", { token: users.admin.token });
  const categoriesRead = await request<unknown[]>("/v1/admin/categories", { token: users.admin.token });
  const rateVersions = await request<{ versions: unknown[] }>("/v1/admin/rate-config/versions", { token: users.admin.token });

  const roles: Record<string, string> = {};
  for (const [key, user] of Object.entries(users) as [AccountKey, DemoAccount][]) {
    const me = await request<{ role: string }>("/v1/auth/me", { token: user.token });
    roles[key] = me.role;
    if (me.role !== expectedRoles[key]) throw new Error(`Role verification failed for ${user.email}: expected ${expectedRoles[key]}, got ${me.role}`);
    if (!(await getAuth().getUser(user.uid)).emailVerified) throw new Error(`Email verification flag is false for ${user.email}`);
  }
  const signedInAgain = await signIn(users.collector.email, PASSWORD);
  if (!signedInAgain) throw new Error("Final Auth emulator sign-in did not return a token");

  const image = await fetch(imageUrl, { signal: AbortSignal.timeout(20_000) });
  const imageType = image.headers.get("content-type") ?? "";
  if (!image.ok || !imageType.startsWith("image/")) throw new Error(`Image verification failed: ${image.status} ${imageType}`);
  await image.body?.cancel();

  const pendingArtworks = adminArtworks.artworks.filter((a) => a.status === "pending_approval").length;
  const insurancePending = adminArtworks.artworks.filter((a) => a.insuranceStatus === "submitted").length;
  if (marketplace.total < 15 || artist.artworks.length < 14 || collection.items.length < 4 || holdings.holdings.length < 5) {
    throw new Error(`Count verification failed: marketplace=${marketplace.total}, artist=${artist.artworks.length}, collection=${collection.items.length}, holdings=${holdings.holdings.length}`);
  }
  if (!pendingArtworks || !insurancePending || !kyc.users.length || !gst.users.length || !withdrawals.withdrawals.some((w) => w.status === "pending") || !fees.length) {
    throw new Error("One or more admin moderation queues are empty");
  }
  const requiredNonEmpty = {
    artistOrders: artistOrders.orders,
    artistPenalties: artistPenalties.penalties,
    artistCoa,
    artistTransactions: artistTransactions.transactions,
    artistMessages,
    artistSupport,
    collectorOrders,
    collectorAddresses,
    collectorResale,
    collectorMessages,
    collectorSupport,
    aggregatorInventory: aggregatorInventory.artworks,
    aggregatorSales,
    remittancesDue,
    gallerySpaces,
    aggregatorMessages,
    aggregatorSupport,
    settlements,
    categories: categoriesRead,
    rateVersions: rateVersions.versions,
  };
  for (const [name, rows] of Object.entries(requiredNonEmpty)) {
    if (!rows.length) throw new Error(`Portal verification failed: ${name} is empty`);
  }
  const hasStates = (values: (string | null)[], required: string[]) => required.every((state) => values.includes(state));
  if (!hasStates(adminUsers.users.map((u) => u.aadhaarStatus), ["submitted", "approved", "rejected"])) throw new Error("KYC states do not include submitted, approved and rejected");
  if (!hasStates(adminUsers.users.map((u) => u.gstStatus), ["submitted", "approved", "rejected"])) throw new Error("GST states do not include submitted, approved and rejected");
  if (!hasStates(adminArtworks.artworks.map((a) => a.insuranceStatus ?? null), ["submitted", "approved", "rejected"])) throw new Error("Insurance states do not include submitted, approved and rejected");
  if (!hasStates(withdrawals.withdrawals.map((w) => w.status), ["pending", "completed", "rejected"])) throw new Error("Withdrawal states do not include pending, completed and rejected");
  if (!hasStates(fees.map((f) => f.status), ["pending_review", "approved", "waived"])) throw new Error("External-fee states do not include pending, approved and waived");
  if (!hasStates(settlements.map((s) => s.status), ["pending", "processed", "failed"])) throw new Error("Settlement states do not include pending, processed and failed");
  if (artistCoa.filter((r) => r.status === "requested").length !== 1 || artistCoa.filter((r) => r.status === "dispatched").length !== 1) throw new Error("Physical COA verification did not find one pending and one dispatched request");
  if (longArtist.artworks.length < 4 || artistWallet.balancePaise <= 0 || artistWallet.lockedPaise <= 0 || collectorWallet.balancePaise <= 0) throw new Error("One or more populated portal balances/lists failed verification");
  if (marketplace.facets.priceRangePaise?.min !== 450_000 || Math.abs(marketplace.facets.priceRangePaise.max - 125_000_000) > 1) throw new Error(`Marketplace price range is wrong: ${JSON.stringify(marketplace.facets.priceRangePaise)}`);
  return {
    publicArtworks: marketplace.total,
    busyArtistArtworks: artist.artworks.length,
    collectorCollection: collection.items.length,
    aggregatorHoldings: holdings.holdings.length,
    marketplacePriceRangePaise: marketplace.facets.priceRangePaise,
    moderation: { artworkPending: pendingArtworks, insurancePending, kycPending: kyc.users.length, gstPending: gst.users.length, withdrawals: withdrawals.withdrawals.length, externalFees: fees.length },
    roles,
    image: { status: image.status, contentType: imageType },
    authPasswordSignIn: true,
  };
}

async function main(): Promise<void> {
  log("checking the already-running API");
  await healthCheck();
  log(`resetting Firestore and Auth emulators for ${projectId}`);
  await resetEmulators(projectId);
  const { db, close } = createDb(projectId);
  await assertEmpty(db);

  try {
    const users = await createAccounts(db);
    await seedProfiles(db, users);
    await seedSettings(users);
    const artworkSeed = await seedArtworks(db, users);
    const collector = await seedCollector(db, users, artworkSeed.busy);
    const aggregator = await seedAggregator(db, users, artworkSeed.busy);
    await seedWalletAndQueues(users);
    await seedDirectOnlyFixtures(db, users);

    // Reindexing clears the API's 60-second in-process read cache after the wipe
    // and rebuilds every listing from fresh emulator reads.
    await request("/v1/admin/artworks/reindex", { method: "POST", token: users.admin.token, body: {} });
    const expectedRoles = Object.fromEntries(accounts.map((a) => [a.key, a.key === "admin" || a.key === "admin2" ? "admin" : a.role])) as Record<AccountKey, string>;
    const verification = await verify(users, expectedRoles, artworkSeed.imageUrl);
    const ids = {
      approvedArtworkId: artworkSeed.busy[20]!.id,
      busyArtistId: users.artist.uid,
      aggregatorId: users.aggregator.uid,
      customerId: users.collector.uid,
      orderIdPerRole: { customer: collector.orders[0], artist: collector.orders[1], admin: collector.orders[2] },
      aggregatorHoldingId: aggregator.holdings[0]!.id,
      pendingTransferId: collector.transferId,
      reservableArtworkId: artworkSeed.busy[20]!.id,
      editableArtworkId: artworkSeed.busy[0]!.id,
      verification,
      generatedAt: now().toISOString(),
    };
    await writeFile(resolve(dirname(fileURLToPath(import.meta.url)), "ids.json"), `${JSON.stringify(ids, null, 2)}\n`, "utf8");
    log(`complete: ${JSON.stringify(verification)}`);
  } finally {
    await close();
  }
}

await main().catch((error) => {
  console.error(`[demo:seed] FAILED: ${error instanceof Error ? error.stack ?? error.message : String(error)}`);
  process.exitCode = 1;
});
