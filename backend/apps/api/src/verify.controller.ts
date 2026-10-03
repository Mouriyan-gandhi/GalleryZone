// GET /v1/verify/:artworkId — the public "artwork passport" a printed QR
// code (or NFC tag) resolves to. Unauthenticated by design, so it carries
// ONLY what plan.md §12 allows on a provenance page: title, artist, product
// code, certificate, current ownership status and the transfer history as
// name snapshots. Never a price, never an email, never an address.
// packages/contracts/artwork-dto.check.ts's price-leak regex is applied to
// this DTO too (verify-dto.check.ts).

import { Controller, Get, Header, Inject, NotFoundException, Param } from "@nestjs/common";
import { getCurrentOwner, getPublicArtwork, listOwnershipEvents, loadPassportExtras, OwnershipNotFoundError, type Db, type OwnershipEvent } from "@galleryzone/db";
import type { VerifyPassportDto } from "@galleryzone/contracts";
import { Public } from "./auth/roles.decorator.ts";
import { DB } from "./db.module.ts";
import { CacheKeys, ReadCache, TTL } from "./read-cache.ts";

const iso = (t: FirebaseFirestore.Timestamp | null | undefined) => t?.toDate().toISOString() ?? null;

export function toPublicEvent(e: OwnershipEvent): VerifyPassportDto["events"][number] {
  return {
    id: e.id,
    kind: e.kind,
    status: e.status,
    fromName: e.fromName,
    toName: e.toName,
    viaSale: e.orderId !== null,
    initiatedAt: iso(e.initiatedAt) ?? new Date(0).toISOString(),
    acceptedAt: iso(e.acceptedAt),
    cancelledAt: iso(e.cancelledAt),
    displayEndsAt: iso(e.displayEndsAt),
    displayEndedAt: iso(e.displayEndedAt),
  };
}

/**
 * The public passport for one artwork, through the 60s read cache. Shared with
 * GET /v1/passport/mine so a person's own list is built from exactly what a
 * scan shows, and reads the same cached copy.
 */
export function passportFor(db: Db, cache: ReadCache, artworkId: string): Promise<VerifyPassportDto> {
  return cache.getOrFill(CacheKeys.verify(artworkId), TTL.artwork, () => buildPassport(db, artworkId));
}

async function buildPassport(db: Db, artworkId: string): Promise<VerifyPassportDto> {
  const artwork = await getPublicArtwork(db, artworkId);
  if (!artwork) throw new NotFoundException({ type: "about:blank", title: "Artwork not found", status: 404, code: "not_found" });
  let owner;
  try {
    owner = await getCurrentOwner(db, artworkId);
  } catch (error) {
    if (error instanceof OwnershipNotFoundError) throw new NotFoundException({ type: "about:blank", title: "Artwork not found", status: 404, code: "not_found" });
    throw error;
  }
  const events = await listOwnershipEvents(db, artworkId);
  const { nfcLinked, nfcLocked, lifecycle } = await loadPassportExtras(db, artworkId, events);

  // Built field-by-field: no spread of the artwork view, so a future field
  // on it can't leak here by accident.
  return {
    artworkId: artwork.id,
    productCode: artwork.productCode,
    title: artwork.title,
    artistId: artwork.artistId,
    artistName: artwork.artistName,
    category: artwork.category,
    medium: artwork.medium,
    dimensions: artwork.dimensions,
    yearCreated: artwork.yearCreated,
    images: artwork.images,
    status: artwork.status,
    coaCertificateNumber: artwork.coaCertificateNumber,
    coaIssuedAt: artwork.coaIssuedAt,
    listedAt: artwork.createdAt,
    owner: { kind: owner.kind, displayName: owner.displayName },
    events: events.map(toPublicEvent),
    // Whether a tag is linked and locked, never which chip: the UID is not public.
    nfcLinked,
    nfcLocked,
    lifecycle,
  };
}

@Controller("v1/verify")
export class VerifyController {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly cache: ReadCache,
  ) {}

  @Public()
  @Get(":artworkId")
  @Header("Cache-Control", "public, max-age=30, s-maxage=60, stale-while-revalidate=60")
  passport(@Param("artworkId") artworkId: string): Promise<VerifyPassportDto> {
    return passportFor(this.db, this.cache, artworkId);
  }
}
