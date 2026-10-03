"use client";

import { useCurrentUser } from "@/hooks/useCurrentUser";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import {
  Frame,
  Fingerprint,
  ScanLine,
  BadgeCheck,
  Repeat2,
  UserRoundCheck,
  ExternalLink,
} from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { PriceTag } from "@/components/shared/price-tag";
import { cn } from "@/lib/utils";
import { useCollection } from "@/hooks/useCollection";
import { useVerifyPassport } from "@/hooks/useVerify";
import type { CollectionItem } from "@/services/customerCollectionService";
import { TransferRightsDialog } from "@/features/verify/transfer-rights-dialog";
import { PhysicalCoaRequest } from "./physical-coa-request";

function formatDate(iso: string): string {
  return new Intl.DateTimeFormat("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(iso));
}

function statusLabel(status: string): string {
  return status
    .split("_")
    .map((word) => word[0]!.toUpperCase() + word.slice(1))
    .join(" ");
}

// Owned = a delivered order (see customerCollectionService's comment on why
// there's no separate "ownership transfer" event). Each card opens a detail
// dialog that folds Certificate/Provenance/Ownership into one view rather
// than three separate destinations — the collection is usually a handful of
// pieces, not fifty, so a dedicated sub-nav per artwork would be more
// clicking than reading.
export function CollectionBoard() {
  const { data: me } = useCurrentUser();
  const { data, isPending } = useCollection();
  const [viewing, setViewing] = useState<CollectionItem | null>(null);
  const [transferring, setTransferring] = useState<CollectionItem | null>(null);

  if (isPending) {
    return (
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 4 }).map((_, i) => (
          <Skeleton key={i} className="aspect-[4/5] w-full rounded-lg" />
        ))}
      </div>
    );
  }

  const items = data ?? [];

  if (items.length === 0) {
    return (
      <EmptyState
        icon={Frame}
        title="No owned artworks yet"
        description="Once an order is delivered, the artwork moves here with its certificate, provenance, and ownership record."
        action={
          <Link
            href="/marketplace"
            className="inline-flex items-center gap-2 rounded-md border border-gold/60 px-4 py-2 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
          >
            Browse the marketplace
          </Link>
        }
      />
    );
  }

  return (
    <>
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {items.map((item) => (
          <button
            key={item.artwork.id}
            type="button"
            onClick={() => setViewing(item)}
            className="group flex flex-col overflow-hidden rounded-lg border border-border bg-card text-left transition-colors hover:border-gold/50 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
          >
            <div className="relative aspect-square w-full overflow-hidden bg-muted">
              <Image
                src={item.artwork.thumbnailUrl}
                alt={item.artwork.title}
                fill
                sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
                className="object-cover transition-transform duration-300 group-hover:scale-105"
              />
            </div>
            <div className="flex flex-col gap-1 p-3">
              <p className="truncate font-display text-sm font-semibold text-foreground">
                {item.artwork.title}
              </p>
              <p className="truncate text-xs text-muted-foreground">
                {item.artwork.artistName}
              </p>
              <PriceTag amount={item.paidPrice} className="mt-1 text-sm" />
            </div>
          </button>
        ))}
      </div>

      <CollectionItemDialog
        item={viewing}
        onClose={() => setViewing(null)}
        onTransfer={(item) => {
          setViewing(null);
          setTransferring(item);
        }}
      />

      {/* Resale hand-over: the collector names the next owner, who accepts
          through a link. Same flow the artist used to transfer it here. */}
      {transferring && (
        <TransferRightsDialog
          open
          onOpenChange={(open) => !open && setTransferring(null)}
          artworkId={transferring.artwork.id}
          artworkTitle={transferring.artwork.title}
          fromName={me?.name ?? ""}
        />
      )}
    </>
  );
}

function CollectionItemDialog({
  item,
  onClose,
  onTransfer,
}: {
  item: CollectionItem | null;
  onClose: () => void;
  onTransfer: (item: CollectionItem) => void;
}) {
  // Whether the piece's tag is linked and locked is on its public passport; the listing doesn't carry it.
  const { data: passport } = useVerifyPassport(item?.artwork.id ?? "");
  return (
    <Dialog open={Boolean(item)} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-md">
        {item ? (
          <>
            <DialogHeader>
              <DialogTitle>{item.artwork.title}</DialogTitle>
            </DialogHeader>

            <div className="flex flex-col items-center gap-3 rounded-lg border border-gold/30 bg-gold/5 p-6 text-center">
              <Fingerprint className="size-8 text-gold-bright" strokeWidth={1.5} />
              <p className="font-mono text-xs text-muted-foreground">
                {item.artwork.coaCertificateNumber}
              </p>
              <NfcPill linked={passport?.nfcLinked ?? false} locked={passport?.nfcLocked ?? false} />
            </div>

            <dl className="grid grid-cols-2 gap-x-4 gap-y-3 border-t border-border pt-4 text-sm">
              <div>
                <dt className="text-xs text-muted-foreground">Artist</dt>
                <dd className="text-foreground">{item.artwork.artistName}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Medium</dt>
                <dd className="text-foreground">{item.artwork.medium}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Certificate issued</dt>
                <dd className="text-foreground">
                  {formatDate(item.artwork.coaIssueDate)}
                </dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Acquired</dt>
                <dd className="text-foreground">
                  {formatDate(item.acquiredAt)}
                </dd>
              </div>
            </dl>

            <div className="border-t border-border pt-4">
              <p className="mb-2 text-xs font-medium tracking-wide text-muted-foreground uppercase">
                Provenance
              </p>
              <ol className="flex flex-col gap-2">
                {item.artwork.statusHistory.map((event, i) => (
                  <li
                    key={i}
                    className="flex items-center justify-between gap-3 text-sm"
                  >
                    <span className="text-foreground">
                      {statusLabel(event.status)}
                    </span>
                    <span className="shrink-0 text-xs text-muted-foreground">
                      {formatDate(event.changedAt)}
                    </span>
                  </li>
                ))}
              </ol>
            </div>

            <PhysicalCoaRequest
              artworkId={item.artwork.id}
              artworkTitle={item.artwork.title}
            />

            <div className="flex flex-col gap-2 border-t border-border pt-4 sm:flex-row">
              {/* Bought in person from an aggregator: there is no GalleryZone
                  order to open, so the provenance of the purchase is stated
                  instead of linking nowhere. */}
              {item.order ? (
                <Link
                  href={`/account/orders/${item.order.id}`}
                  onClick={onClose}
                  className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-md border border-border px-3 py-2 text-xs font-medium text-foreground transition-colors hover:bg-muted"
                >
                  <ExternalLink className="size-3.5" />
                  View order
                </Link>
              ) : (
                <span className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-md border border-border px-3 py-2 text-xs text-muted-foreground">
                  Bought in person
                </span>
              )}
              <Link
                href="/account/resale"
                onClick={onClose}
                className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-md border border-gold/60 px-3 py-2 text-xs font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
              >
                <Repeat2 className="size-3.5" />
                List for resale
              </Link>
              <button
                type="button"
                onClick={() => onTransfer(item)}
                className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-md border border-border px-3 py-2 text-xs font-medium text-foreground transition-colors hover:bg-muted"
              >
                <UserRoundCheck className="size-3.5" />
                Transfer rights
              </button>
            </div>
          </>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

function NfcPill({ linked, locked }: { linked: boolean; locked: boolean }) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-medium whitespace-nowrap",
        linked
          ? "border-emerald-500/30 bg-emerald-500/10 text-emerald-400"
          : "border-border bg-secondary text-muted-foreground",
      )}
    >
      {linked ? (
        <ScanLine className="size-3" strokeWidth={2} />
      ) : (
        <BadgeCheck className="size-3" strokeWidth={2} />
      )}
      {locked ? "NFC tagged · locked" : linked ? "NFC tagged" : "Digital certificate only"}
    </span>
  );
}
