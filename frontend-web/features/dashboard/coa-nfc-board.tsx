"use client";

import { useCurrentUser } from "@/hooks/useCurrentUser";

import { useState } from "react";
import Image from "next/image";
import {
  AlertTriangle,
  BadgeCheck,
  History,
  Lock,
  ScanLine,
  UserRoundCheck,
  Link2,
  ShieldCheck,
} from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useArtistDashboardArtworks } from "@/hooks/useArtistArtworks";
import { cn } from "@/lib/utils";
import { NFC_STAGE_LABEL, nfcStageOf, type NfcStage } from "@/lib/nfc";
import { resolveCustody } from "@/types/artwork";
import { TransferRightsDialog } from "@/features/verify/transfer-rights-dialog";
import { PhysicalCoaQueue } from "./physical-coa-queue";
import { ArtworkHistory } from "./artwork-history";
import { NfcArtworkPassportView } from "@/features/verify/nfc-artwork-passport-view";
import { LinkNfcDialog } from "./link-nfc-dialog";
import { verifyUrlFor } from "@/lib/verify-url";

type ArtistArtwork = NonNullable<
  ReturnType<typeof useArtistDashboardArtworks>["data"]
>[number];

export function CoaNfcBoard() {
  const { data: me } = useCurrentUser();
  const { data: artworks } = useArtistDashboardArtworks();
  const [previewing, setPreviewing] = useState<ArtistArtwork | null>(null);
  const [transferring, setTransferring] = useState<ArtistArtwork | null>(null);
  const [linkingNfc, setLinkingNfc] = useState<ArtistArtwork | null>(null);
  const [viewingHistory, setViewingHistory] = useState<ArtistArtwork | null>(
    null,
  );

  const rows = artworks ?? [];
  // Linked but not locked: these cannot be dispatched until the artist finishes in the app.
  const awaitingLock = rows.filter((a) => nfcStageOf(a) === "linked_unlocked").length;

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h2 className="font-display text-xl font-semibold text-foreground">
          Certificates &amp; tags
        </h2>
        <p className="mt-0.5 text-sm text-muted-foreground">
          Every submitted artwork gets a Certificate of Authenticity;
          physical pieces also get an NFC/QR tag linked to it.
        </p>
      </div>

      {awaitingLock > 0 && (
        <div
          id="nfc-lock-warning"
          role="alert"
          className="flex items-start gap-2.5 rounded-lg border border-red-500/40 bg-red-500/10 px-4 py-3"
        >
          <AlertTriangle className="mt-0.5 size-4 shrink-0 text-red-400" />
          <p className="text-xs leading-relaxed text-red-200">
            <span className="font-medium text-red-300">
              {awaitingLock === 1 ? "1 piece has" : `${awaitingLock} pieces have`} a tag that isn&apos;t locked.
            </span>{" "}
            Open the GalleryZone app and lock {awaitingLock === 1 ? "it" : "each one"}: a piece can&apos;t be dispatched
            to a buyer or a gallery until its tag is locked.
          </p>
        </div>
      )}

      <PhysicalCoaQueue />

      {rows.length === 0 ? (
        <div className="rounded-lg border border-dashed border-border py-16 text-center">
          <p className="text-sm text-muted-foreground">
            Submit an artwork to generate its first certificate.
          </p>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {rows.map((artwork) => {
            const stage = nfcStageOf(artwork);
            return (
            <div
              key={artwork.id}
              className="flex flex-col gap-3 rounded-lg border border-border bg-card p-4 sm:flex-row sm:items-center sm:justify-between"
            >
              <div className="flex min-w-0 items-center gap-3">
                <div className="relative size-14 shrink-0 overflow-hidden rounded-md bg-muted">
                  <Image
                    src={artwork.thumbnailUrl}
                    alt={artwork.title}
                    fill
                    sizes="56px"
                    className="object-cover"
                  />
                </div>
                <div className="min-w-0">
                  <p className="truncate text-sm font-medium text-foreground">
                    {artwork.title}
                  </p>
                  <p className="truncate text-xs text-muted-foreground">
                    {artwork.coaCertificateNumber}
                  </p>
                </div>
              </div>

              <div className="flex flex-wrap items-center gap-2 sm:shrink-0">
                {stage !== "unlinked" && (
                  <div className="mr-3 hidden flex-col items-end sm:flex">
                    <p className="text-[10px] tracking-wider text-muted-foreground uppercase">
                      Public verify URL (written to tag)
                    </p>
                    <a
                      href={`/verify/${artwork.id}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="mt-0.5 text-xs font-medium text-gold-bright transition-colors hover:text-gold hover:underline"
                    >
                      {verifyUrlFor(artwork.id).replace(/^https?:\/\//, "")}
                    </a>
                  </div>
                )}

                <NfcPill stage={stage} />

                {stage === "linked_unlocked" && (
                  <span
                    id={`nfc-must-lock-${artwork.id}`}
                    className="inline-flex items-center gap-1.5 rounded-full border border-red-500/40 bg-red-500/10 px-2.5 py-1 text-xs font-medium whitespace-nowrap text-red-300"
                  >
                    <AlertTriangle className="size-3" strokeWidth={2} />
                    Must lock before shipping
                  </span>
                )}

                {stage !== "linked_locked" && (
                  <button
                    id={`link-nfc-${artwork.id}`}
                    type="button"
                    onClick={() => setLinkingNfc(artwork)}
                    className="inline-flex items-center gap-1.5 rounded-md border border-emerald-500/50 bg-emerald-500/10 px-3 py-1.5 text-xs font-medium text-emerald-400 transition-colors hover:border-emerald-400 hover:bg-emerald-500/20"
                  >
                    <Link2 className="size-3.5" />
                    {stage === "unlinked" ? "Link Tag" : "Replace tag"}
                  </button>
                )}

                <button
                  type="button"
                  onClick={() => setPreviewing(artwork)}
                  className="inline-flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-xs font-medium text-foreground transition-colors hover:bg-muted"
                >
                  <BadgeCheck className="size-3.5 text-gold-bright" />
                  Preview certificate
                </button>
                <button
                  type="button"
                  onClick={() => setViewingHistory(artwork)}
                  className="inline-flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-xs font-medium text-foreground transition-colors hover:bg-muted"
                >
                  <History className="size-3.5 text-gold-bright" />
                  History
                </button>
              </div>
            </div>
            );
          })}
        </div>
      )}

      {linkingNfc && (
        <LinkNfcDialog
          open={Boolean(linkingNfc)}
          onOpenChange={(open) => {
            if (!open) setLinkingNfc(null);
          }}
          artworkId={linkingNfc.id}
          artworkTitle={linkingNfc.title}
          replacing={nfcStageOf(linkingNfc) === "linked_unlocked"}
        />
      )}

      <CertificateDialog
        artwork={previewing}
        onClose={() => setPreviewing(null)}
        onTransfer={(artwork) => {
          setPreviewing(null);
          setTransferring(artwork);
        }}
      />

      <HistoryDialog
        artwork={viewingHistory}
        onClose={() => setViewingHistory(null)}
      />

      {transferring && (
        <TransferRightsDialog
          open
          onOpenChange={(open) => !open && setTransferring(null)}
          artworkId={transferring.id}
          artworkTitle={transferring.title}
          fromName={
            resolveCustody(transferring).legalOwnerName ?? me?.name ?? ""
          }
        />
      )}
    </div>
  );
}

function HistoryDialog({
  artwork,
  onClose,
}: {
  artwork: ArtistArtwork | null;
  onClose: () => void;
}) {
  return (
    <Dialog open={Boolean(artwork)} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-h-[85dvh] flex flex-col overflow-hidden sm:max-w-3xl">
        <DialogHeader>
          <DialogTitle>History</DialogTitle>
        </DialogHeader>
        {artwork ? (
          <div className="flex-1 overflow-y-auto pr-2 -mr-2 flex flex-col gap-4">
            <p className="-mt-1 text-sm text-muted-foreground">
              {artwork.title}
            </p>
            <ArtworkHistory artwork={artwork} />
          </div>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

// Three states, not two (NFC_IMPLEMENTATION.md §3). "Linked, unlocked" is deliberately not
// the gold of a finished tag: the piece cannot ship in it.
function NfcPill({ stage }: { stage: NfcStage }) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-medium whitespace-nowrap",
        stage === "linked_locked" && "border-gold/40 bg-gold/10 text-gold-bright",
        stage === "linked_unlocked" && "border-amber-500/40 bg-amber-500/10 text-amber-300",
        stage === "unlinked" && "border-border bg-secondary text-muted-foreground",
      )}
    >
      {stage === "linked_locked" ? (
        <Lock className="size-3" strokeWidth={2} />
      ) : stage === "linked_unlocked" ? (
        <ShieldCheck className="size-3" strokeWidth={2} />
      ) : (
        <ScanLine className="size-3" strokeWidth={2} />
      )}
      {NFC_STAGE_LABEL[stage]}
    </span>
  );
}

function CertificateDialog({
  artwork,
  onClose,
  onTransfer,
}: {
  artwork: ArtistArtwork | null;
  onClose: () => void;
  onTransfer: (artwork: ArtistArtwork) => void;
}) {
  return (
    <Dialog
      open={Boolean(artwork)}
      onOpenChange={(open) => !open && onClose()}
    >
      <DialogContent className="max-h-[90dvh] flex flex-col overflow-y-auto overflow-x-hidden p-0 sm:max-w-[440px] bg-background border-gold/20">
        <DialogTitle className="sr-only">Certificate of Authenticity</DialogTitle>
        {artwork ? (
          <div className="relative w-full">
            <NfcArtworkPassportView artworkId={artwork.id} />
            {/* First hand-over of the passport: artist to buyer. The buyer can
                pass it on again later from their own collection. */}
            <div className="border-t border-border px-5 py-4">
              <button
                type="button"
                onClick={() => onTransfer(artwork)}
                className="inline-flex items-center justify-center gap-1.5 rounded-md border border-gold/60 px-4 py-2.5 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
              >
                <UserRoundCheck className="size-3.5" />
                Transfer rights
              </button>
            </div>
          </div>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
