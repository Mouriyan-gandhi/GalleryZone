"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { notFound } from "next/navigation";
import {
  ArrowLeft,
  BadgeCheck,
  CheckCircle2,
  Nfc,
  ShieldCheck,
  Sparkles,
  User,
  Warehouse,
  MapPin,
  Clock,
  ArrowRight,
} from "lucide-react";
import { CUSTODY_PARTY_LABEL, resolveCustody } from "@/types/artwork";
import { useArtwork } from "@/hooks/useArtwork";
import { useVerifyPassport } from "@/hooks/useVerify";
import { useArtistProfile } from "@/hooks/useArtistProfile";
import { DownloadCoaButton } from "@/features/coa/download-coa-button";
import { ArtworkQr } from "./artwork-qr";

// ─── NFC Banner ────────────────────────────────────────────────────────────────
// Shown only when the artwork has a linked NFC tag — gives the collector
// immediate visual confirmation that the tap resolved to a live passport.

function NfcVerifiedBanner() {
  const [visible, setVisible] = useState(false);

  // Animate in on mount so the banner catches the eye immediately on tap.
  useEffect(() => {
    const t = setTimeout(() => setVisible(true), 80);
    return () => clearTimeout(t);
  }, []);

  return (
    <div
      role="status"
      aria-live="polite"
      className={`relative overflow-hidden transition-all duration-500 ${visible ? "max-h-24 opacity-100" : "max-h-0 opacity-0"}`}
    >
      {/* Pulsing gold glow beneath the bar */}
      <div
        className="pointer-events-none absolute inset-0 animate-pulse bg-gradient-to-r from-transparent via-gold/20 to-transparent"
        style={{ animationDuration: "2.4s" }}
        aria-hidden="true"
      />
      <div className="relative z-10 flex items-center justify-center gap-2.5 border-b border-gold/30 bg-gold/10 px-4 py-3 text-sm font-medium text-gold-bright backdrop-blur-sm">
        {/* Pulsing ring around the NFC icon */}
        <span className="relative flex size-5 items-center justify-center">
          <span className="absolute inset-0 animate-ping rounded-full bg-gold/40" style={{ animationDuration: "1.6s" }} />
          <Nfc className="relative size-4" strokeWidth={2} />
        </span>
        Verified via NFC scan
        <CheckCircle2 className="size-4" strokeWidth={2} />
      </div>
    </div>
  );
}

// ─── Fact Cards ────────────────────────────────────────────────────────────────

interface FactCardProps {
  icon: React.ReactNode;
  label: string;
  value: string;
}

function FactCard({ icon, label, value }: FactCardProps) {
  return (
    <div className="flex flex-col gap-1.5 rounded-xl border border-border/60 bg-card/60 px-4 py-3.5 text-center backdrop-blur-sm">
      <div className="mx-auto flex size-8 items-center justify-center rounded-full border border-gold/30 bg-gold/10">
        {icon}
      </div>
      <p className="text-[10px] font-medium tracking-[0.12em] text-muted-foreground uppercase">
        {label}
      </p>
      <p className="text-sm font-medium leading-tight text-foreground">{value}</p>
    </div>
  );
}

// ─── Provenance Timeline ───────────────────────────────────────────────────────
// Reuses the passport events from the verify endpoint (not the artwork status
// history) so the public chain of custody is always the ledger projection.

interface ProvenanceEntry {
  id: string;
  fromName: string;
  toName: string;
  kind: string;
  date: string;
  isLatest: boolean;
}

function NfcProvenanceTimeline({ entries }: { entries: ProvenanceEntry[] }) {
  if (entries.length === 0) return null;

  return (
    <section aria-labelledby="provenance-heading" className="mt-10">
      <h2
        id="provenance-heading"
        className="text-xs font-semibold tracking-[0.15em] text-muted-foreground uppercase"
      >
        Provenance
      </h2>
      <ol className="mt-4 flex flex-col gap-0">
        {entries.map((entry, i) => (
          <li key={entry.id} className="relative flex gap-4 pb-6 last:pb-0">
            {/* Vertical connector */}
            {i < entries.length - 1 && (
              <span
                className="absolute top-8 left-[13px] h-full w-px bg-border"
                aria-hidden="true"
              />
            )}
            {/* Node */}
            <span
              className={`relative z-10 mt-0.5 flex size-7 shrink-0 items-center justify-center rounded-full border ${entry.isLatest ? "border-gold/60 bg-gold/15" : "border-border bg-card"}`}
            >
              {entry.isLatest ? (
                <Sparkles className="size-3.5 text-gold-bright" />
              ) : (
                <CheckCircle2 className="size-3.5 text-muted-foreground" strokeWidth={1.75} />
              )}
            </span>
            <div className="flex flex-1 flex-col gap-0.5">
              <div className="flex flex-wrap items-center gap-x-1.5 gap-y-0.5 text-sm">
                <span className="text-muted-foreground">{entry.fromName}</span>
                <ArrowRight className="size-3 shrink-0 text-gold-bright" strokeWidth={2} />
                <span className="font-medium text-foreground">{entry.toName}</span>
                {entry.kind === "display" && (
                  <span className="rounded-full border border-gold/40 px-2 py-0.5 text-[10px] font-medium text-gold-bright">
                    Display
                  </span>
                )}
              </div>
              <p className="text-xs text-muted-foreground">
                {new Intl.DateTimeFormat("en-IN", {
                  day: "numeric",
                  month: "short",
                  year: "numeric",
                }).format(new Date(entry.date))}
              </p>
            </div>
          </li>
        ))}
      </ol>
    </section>
  );
}

// ─── Artist Footer ─────────────────────────────────────────────────────────────

function ArtistVerifiedFooter({
  artistId,
  artistName,
}: {
  artistId: string;
  artistName: string;
}) {
  const { data: artist } = useArtistProfile(artistId);

  return (
    <footer className="mt-14 border-t border-border/50 pt-8">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          {/* Placeholder avatar ring */}
          <div className="relative flex size-10 items-center justify-center rounded-full border border-gold/40 bg-gold/10">
            <User className="size-4 text-gold-bright" strokeWidth={1.75} />
            <span className="absolute -right-0.5 -bottom-0.5 flex size-4 items-center justify-center rounded-full border border-background bg-emerald-500">
              <BadgeCheck className="size-2.5 text-white" strokeWidth={2.5} />
            </span>
          </div>
          <div>
            <p className="text-sm font-medium text-foreground">
              {artist?.name ?? artistName}
            </p>
            <p className="text-xs text-muted-foreground">
              Verified GalleryZone artist
            </p>
          </div>
        </div>
        <Link
          href={`/artists/${artistId}`}
          className="rounded-lg border border-gold/40 px-3.5 py-2 text-xs font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
        >
          View portfolio
        </Link>
      </div>

      {/* GalleryZone wordmark */}
      <div className="mt-6 flex items-center gap-2 text-[11px] text-muted-foreground">
        <ShieldCheck className="size-3.5 text-gold-bright" strokeWidth={1.75} />
        Authenticated by GalleryZone · One tag. One artwork. One unbroken
        record.
      </div>
    </footer>
  );
}

// ─── Main View ─────────────────────────────────────────────────────────────────

export function NfcArtworkPassportView({ artworkId }: { artworkId: string }) {
  const { data: artwork, isLoading } = useArtwork(artworkId);
  const { data: passport, isLoading: passportLoading } = useVerifyPassport(artworkId);

  if (isLoading || passportLoading) {
    return (
      <div className="flex min-h-dvh items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          {/* Spinning NFC ring loader */}
          <div className="relative flex size-12 items-center justify-center">
            <span className="absolute inset-0 animate-spin rounded-full border-2 border-transparent border-t-gold/60" />
            <Nfc className="size-5 text-gold-bright" strokeWidth={1.5} />
          </div>
          <p className="text-sm text-muted-foreground">Loading passport…</p>
        </div>
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
  const ownerName =
    passport?.owner.displayName ??
    custody.legalOwnerName ??
    CUSTODY_PARTY_LABEL[custody.legalOwner];
  const coverImage =
    [...artwork.images].sort((a, b) => a.sortOrder - b.sortOrder)[0]?.url ??
    artwork.thumbnailUrl;
  const hasNfc = Boolean(artwork.nfcTagId);

  // Build provenance entries from passport events (ownership transfers)
  const provenanceEntries: ProvenanceEntry[] = (passport?.events ?? [])
    .filter((e) => e.status !== "cancelled")
    .sort(
      (a, b) =>
        new Date(a.initiatedAt).getTime() - new Date(b.initiatedAt).getTime(),
    )
    .map((e, i, arr) => ({
      id: e.id,
      fromName: e.fromName,
      toName: e.toName,
      kind: e.kind,
      date: e.acceptedAt ?? e.initiatedAt,
      isLatest: i === arr.length - 1,
    }));

  return (
    <div className="relative min-h-dvh">
      {/* Full-page dark gradient background */}
      <div
        className="pointer-events-none fixed inset-0 -z-10"
        aria-hidden="true"
      >
        {/* Deep dark base */}
        <div className="absolute inset-0 bg-background" />
        {/* Top-left gold bloom */}
        <div className="absolute -top-32 -left-32 size-[500px] rounded-full bg-gold/8 blur-[120px]" />
        {/* Bottom-right bloom */}
        <div className="absolute -bottom-40 -right-40 size-[400px] rounded-full bg-gold/6 blur-[100px]" />
        {/* Subtle dot grid */}
        <div
          className="absolute inset-0 opacity-[0.025]"
          style={{
            backgroundImage:
              "radial-gradient(circle, rgba(255,255,255,0.8) 1px, transparent 1px)",
            backgroundSize: "24px 24px",
          }}
        />
      </div>

      {/* NFC Verified Banner — at the very top */}
      {hasNfc && <NfcVerifiedBanner />}

      {/* Content */}
      <div className="mx-auto w-full max-w-md px-5 pb-16 pt-8">
        {/* Back nav */}
        <Link
          href={`/marketplace/${artwork.id}`}
          className="inline-flex items-center gap-1.5 text-xs font-medium text-muted-foreground transition-colors hover:text-gold-bright"
        >
          <ArrowLeft className="size-3.5" strokeWidth={2} />
          Back to listing
        </Link>

        {/* ── Passport Card ──────────────────────────────────────────────────── */}
        <section aria-label="Artwork passport" className="mt-6">
          <div className="relative overflow-hidden rounded-2xl border border-gold/30 bg-card/80 shadow-[0_0_80px_-20px_rgba(201,154,74,0.2)] backdrop-blur-md">
            {/* Card inner glow */}
            <div
              className="pointer-events-none absolute inset-0"
              aria-hidden="true"
            >
              <div className="absolute top-0 left-1/2 size-80 -translate-x-1/2 -translate-y-1/2 rounded-full bg-gold/10 blur-[80px]" />
            </div>

            <div className="relative z-10 flex flex-col items-center px-6 py-8 text-center">
              {/* Passport badge */}
              <span className="inline-flex items-center gap-1.5 rounded-full border border-gold/40 bg-gold/10 px-3 py-1 text-[11px] font-medium tracking-[0.14em] text-gold-bright uppercase">
                <ShieldCheck className="size-3.5" strokeWidth={2} />
                Artwork Passport
              </span>

              {/* Cover image */}
              <div className="relative mt-6 aspect-square w-44 overflow-hidden rounded-xl border border-gold/25 shadow-lg">
                <Image
                  src={coverImage}
                  alt={artwork.title}
                  fill
                  sizes="176px"
                  className="object-cover"
                  priority
                />
              </div>

              {/* Title & artist */}
              <h1 className="mt-5 text-balance font-display text-xl font-semibold leading-snug text-foreground">
                {artwork.title}
              </h1>
              <p className="mt-1 text-sm text-muted-foreground">
                by{" "}
                <span className="font-medium text-foreground/90">
                  {artwork.artistName}
                </span>
              </p>

              {/* COA badge */}
              <div className="mt-4 flex items-center gap-2 rounded-lg border border-gold/30 bg-gold/8 px-4 py-2.5 text-center">
                <BadgeCheck className="size-4 shrink-0 text-gold-bright" strokeWidth={1.75} />
                <div className="text-left">
                  <p className="text-[10px] font-medium tracking-wide text-muted-foreground uppercase">
                    Certificate of Authenticity
                  </p>
                  <p className="font-mono text-xs font-medium text-gold-bright">
                    {coaCertificateNumber || "Pending issuance"}
                  </p>
                </div>
              </div>

              {/* NFC tag ID */}
              {hasNfc && (
                <p className="mt-3 flex items-center gap-1.5 text-[11px] text-muted-foreground">
                  <Nfc className="size-3.5 text-gold-bright" strokeWidth={1.75} />
                  <span className="font-mono">{artwork.nfcTagId}</span>
                </p>
              )}
            </div>
          </div>
        </section>

        {/* ── Fact Cards ─────────────────────────────────────────────────────── */}
        <section aria-label="Artwork facts" className="mt-5 grid grid-cols-3 gap-3">
          <FactCard
            icon={<User className="size-3.5 text-gold-bright" strokeWidth={1.75} />}
            label="Owner"
            value={ownerName}
          />
          <FactCard
            icon={<Warehouse className="size-3.5 text-gold-bright" strokeWidth={1.75} />}
            label="Held by"
            value={CUSTODY_PARTY_LABEL[custody.custodian]}
          />
          <FactCard
            icon={<MapPin className="size-3.5 text-gold-bright" strokeWidth={1.75} />}
            label="Location"
            value={custody.locationLabel}
          />
        </section>

        {/* ── COA issue date ─────────────────────────────────────────────────── */}
        {coaIssueDate && (
          <div className="mt-3 flex items-center gap-2 rounded-lg border border-border/50 bg-card/50 px-4 py-2.5">
            <Clock className="size-3.5 shrink-0 text-muted-foreground" strokeWidth={1.75} />
            <p className="text-xs text-muted-foreground">
              COA issued{" "}
              {new Intl.DateTimeFormat("en-IN", {
                day: "numeric",
                month: "long",
                year: "numeric",
              }).format(new Date(coaIssueDate))}
            </p>
          </div>
        )}

        {/* ── Provenance Timeline ────────────────────────────────────────────── */}
        <NfcProvenanceTimeline entries={provenanceEntries} />

        {/* ── QR + Download ─────────────────────────────────────────────────── */}
        <div className="mt-10 flex flex-col items-center gap-4">
          <ArtworkQr artworkId={artwork.id} size={128} showUrl />
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

        {/* ── Artist Footer ──────────────────────────────────────────────────── */}
        {artwork.artistId && (
          <ArtistVerifiedFooter
            artistId={artwork.artistId}
            artistName={artwork.artistName}
          />
        )}
      </div>
    </div>
  );
}
