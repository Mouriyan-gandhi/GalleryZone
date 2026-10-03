import { http, isApiError, API_URL } from "@/lib/api";
import type { OwnershipTransfer, TransferKind, TransferStatus } from "@/types/artwork";

// The public artwork passport (GET /v1/verify/:artworkId) — what a printed
// QR / NFC tag resolves to. No auth; carries name snapshots only, never a
// price or a contact detail (the backend's verify-dto.check.ts enforces
// that), so it is safe to render for anyone who scans.

export interface VerifyPassport {
  artworkId: string;
  productCode: string;
  title: string;
  artistId: string;
  artistName: string;
  category: string;
  medium: string;
  dimensions: string | null;
  yearCreated: number | null;
  images: { url: string; thumbnailUrl: string | null; altText: string | null; sortOrder: number }[];
  status: string;
  coaCertificateNumber: string | null;
  coaIssuedAt: string | null;
  listedAt: string;
  owner: { kind: "artist" | "collector"; displayName: string };
  events: PassportEvent[];
  /** A physical tag is linked to the piece. The chip's own ID is never public. */
  nfcLinked: boolean;
  /** The tag was locked read-only for good, so it can't be rewritten to point elsewhere. */
  nfcLocked: boolean;
  /** Everything that happened to the piece, oldest first. */
  lifecycle: LifecycleEntry[];
}

export type LifecycleKind =
  | "created"
  | "approved"
  | "listed"
  | "placed_with_gallery"
  | "returned_from_gallery"
  | "sold_marketplace"
  | "sold_at_gallery"
  | "transferred"
  | "displayed"
  | "delivered";

/**
 * One step in a piece's life. `location` is a place only for the artist and a gallery; for a
 * collector or GalleryZone it is always null (a collector's home is private) and the server's
 * types cannot say otherwise.
 */
export interface LifecycleEntry {
  id: string;
  kind: LifecycleKind;
  at: string;
  actor: { kind: "artist" | "gallery" | "collector" | "platform"; displayName: string };
  location: { city: string; state: string; country: string } | null;
  note: string | null;
}

export interface PassportEvent {
  id: string;
  kind: TransferKind;
  status: TransferStatus;
  fromName: string;
  toName: string;
  viaSale: boolean;
  initiatedAt: string;
  acceptedAt: string | null;
  cancelledAt: string | null;
  displayEndsAt: string | null;
  displayEndedAt: string | null;
}

/** Passport events -> the OwnershipTransfer shape the existing history UI renders. */
export function passportEventToTransfer(
  e: PassportEvent,
  passport: Pick<VerifyPassport, "artworkId" | "title">,
): OwnershipTransfer {
  return {
    id: e.id,
    artworkId: passport.artworkId,
    artworkTitle: passport.title,
    fromName: e.fromName,
    toName: e.toName,
    // Public view: the invite address is never exposed.
    toEmail: "",
    initiatedAt: e.initiatedAt,
    acceptedAt: e.acceptedAt,
    cancelledAt: e.cancelledAt,
    status: e.status,
    kind: e.kind,
    displayEndsAt: e.displayEndsAt,
    displayEndedAt: e.displayEndedAt,
  };
}

export const verifyService = {
  get: async (artworkId: string): Promise<VerifyPassport | undefined> => {
    try {
      return await http.get<VerifyPassport>(`/v1/verify/${encodeURIComponent(artworkId)}`);
    } catch (error) {
      if (isApiError(error, 404)) return undefined;
      throw error;
    }
  },

  /** Server-side variant for generateMetadata — plain fetch, no auth, never throws. */
  getForMetadata: async (artworkId: string): Promise<VerifyPassport | null> => {
    try {
      const res = await fetch(`${API_URL}/v1/verify/${encodeURIComponent(artworkId)}`, { next: { revalidate: 60 } });
      return res.ok ? ((await res.json()) as VerifyPassport) : null;
    } catch {
      return null;
    }
  },
};
