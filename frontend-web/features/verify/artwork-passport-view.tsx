"use client";

import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft, Nfc } from "lucide-react";
import { CUSTODY_PARTY_LABEL, resolveCustody } from "@/types/artwork";
import { useArtwork } from "@/hooks/useArtwork";
import { useArtistProfile } from "@/hooks/useArtistProfile";
import { useVerifyPassport } from "@/hooks/useVerify";
import { DownloadCoaButton } from "@/features/coa/download-coa-button";
import { ArtworkPassportCard } from "./artwork-passport-card";
import { ArtworkQr } from "./artwork-qr";
import { OwnershipHistory } from "./ownership-history";
import { ProvenanceTimeline } from "./provenance-timeline";

// Public page a scanned QR / NFC tag lands on. The artwork facts come from
// the listing DTO; the CURRENT OWNER and the transfer chain come from the
// public passport (GET /v1/verify/:id), which is a projection of the
// backend's ownership event log — the artist until the first sale, then
// whoever the last accepted transfer went to.
export function ArtworkPassportView({ artworkId }: { artworkId: string }) {
  const { data: artwork, isLoading } = useArtwork(artworkId);
  const { data: passport, isLoading: passportLoading } = useVerifyPassport(artworkId);
  const { data: artist } = useArtistProfile(artwork?.artistId ?? "");

  if (isLoading || passportLoading) {
    return (
      <div className="mx-auto w-full max-w-2xl px-6 py-14 text-center text-sm text-muted-foreground">
        Loading passport…
      </div>
    );
  }

  if (!artwork) {
    notFound();
  }

  // The marketplace listing doesn't carry the certificate; the passport does.
  const coaCertificateNumber = passport?.coaCertificateNumber ?? "";
  const coaIssueDate = passport?.coaIssuedAt ?? "";

  const custody = resolveCustody(artwork);
  // The ledger wins over the status-derived guess once we have it.
  const ownerName =
    passport?.owner.displayName ??
    custody.legalOwnerName ??
    CUSTODY_PARTY_LABEL[custody.legalOwner];
  const coverImage =
    [...artwork.images].sort((a, b) => a.sortOrder - b.sortOrder)[0]?.url ??
    artwork.thumbnailUrl;

  return (
    <div className="mx-auto w-full max-w-2xl px-6 py-14 lg:py-20">
      <Link
        href={`/marketplace/${artwork.id}`}
        className="inline-flex items-center gap-1.5 text-xs font-medium text-muted-foreground transition-colors hover:text-gold-bright"
      >
        <ArrowLeft className="size-3.5" strokeWidth={2} />
        Back to listing
      </Link>

      <div className="mt-8">
        <ArtworkPassportCard
          title={artwork.title}
          artistName={artwork.artistName}
          coverImageUrl={coverImage}
          coaCertificateNumber={coaCertificateNumber}
          coaIssueDate={coaIssueDate}
        />
      </div>

      {passport?.nfcLinked && (
        <p className="mx-auto mt-6 flex max-w-md items-center justify-center gap-2 text-xs text-muted-foreground">
          <Nfc className="size-3.5 text-gold-bright" strokeWidth={1.75} />
          {passport.nfcLocked ? "Physical tag linked and locked" : "Physical tag linked, not yet locked"}
        </p>
      )}

      {/* Ownership, custody and location are three independent facts about a
          physical artwork — the passport shows all three rather than one
          collapsed "owner". */}
      <dl className="mx-auto mt-10 grid max-w-md grid-cols-3 gap-3 text-center">
        <div className="rounded-lg border border-border bg-card px-3 py-3">
          <dt className="text-[11px] tracking-wide text-muted-foreground uppercase">
            Owner
          </dt>
          <dd className="mt-1 text-sm font-medium text-foreground">
            {ownerName}
          </dd>
        </div>
        <div className="rounded-lg border border-border bg-card px-3 py-3">
          <dt className="text-[11px] tracking-wide text-muted-foreground uppercase">
            Held by
          </dt>
          <dd className="mt-1 text-sm font-medium text-foreground">
            {CUSTODY_PARTY_LABEL[custody.custodian]}
          </dd>
        </div>
        <div className="rounded-lg border border-border bg-card px-3 py-3">
          <dt className="text-[11px] tracking-wide text-muted-foreground uppercase">
            Location
          </dt>
          <dd className="mt-1 text-sm font-medium text-foreground">
            {custody.locationLabel}
          </dd>
        </div>
      </dl>

      <OwnershipHistory artworkId={artwork.id} artistName={artwork.artistName} />

      {/* The same code printed on the physical label — anyone can re-scan
          it to land back here and see the current owner. */}
      <div className="mx-auto mt-12 flex max-w-md flex-col items-center gap-4">
        <ArtworkQr artworkId={artwork.id} size={144} showUrl />
        <DownloadCoaButton
          certificate={{
            artworkId: artwork.id,
            productCode: passport?.productCode,
            title: artwork.title,
            artistName: artwork.artistName,
            category: artwork.category,
            medium: artwork.medium,
            dimensions: artwork.dimensions,
            yearCreated: artwork.yearCreated,
            coaCertificateNumber,
            coaIssueDate,
            ownerName,
          }}
        />
      </div>

      <div className="mx-auto mt-14 max-w-md">
        <ProvenanceTimeline history={artwork.statusHistory} />
      </div>

      {artist && (
        <p className="mx-auto mt-14 max-w-md text-center text-xs leading-relaxed text-muted-foreground">
          Registered to{" "}
          <Link
            href={`/artists/${artist.id}`}
            className="font-medium text-gold-bright hover:underline"
          >
            {artist.name}
          </Link>
          , a verified GalleryZone artist.
        </p>
      )}
    </div>
  );
}
