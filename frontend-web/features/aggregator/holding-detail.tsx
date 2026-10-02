"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { toast } from "sonner";
import {
  ArrowLeft,
  CircleCheckBig,
  CircleX,
  GalleryVerticalEnd,
  Hourglass,
  ShieldOff,
} from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/shared/empty-state";
import { PriceTag } from "@/components/shared/price-tag";
import { ArtworkPassportCard } from "@/features/verify/artwork-passport-card";
import { ExpiryCountdown } from "./expiry-countdown";
import { CycleStepper } from "./cycle-stepper";
import { RecordSaleDialog } from "./record-sale-dialog";
import { RequestExtensionDialog } from "./request-extension-dialog";
import { ReturnHoldingDialog } from "./return-holding-dialog";
import { SuggestedArtworks } from "./suggested-artworks";
import { HOLDING_STATUS_CONFIG } from "./holding-status";
import {
  useAggregatorHolding,
} from "@/hooks/useAggregatorCollection";
import { AGGREGATOR_CYCLE_MONTHS } from "@/lib/pricing";
import { formatINR } from "@/lib/utils";
import type { HoldingExtensionRequest } from "@/types/aggregator";

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

// The "what happens next" screen the old confirm-dialog flow never had: one
// holding's full lifecycle in one place — price breakdown, expiry, the
// COA/NFC passport while it's actively yours, and what to do when a period
// ends. Reserve (reserve-artwork-page.tsx) lands here on success; the
// Inventory row (CollectionTable) links here too, so both paths meet at the
// same page.
export function HoldingDetail({ holdingId }: { holdingId: string }) {
  const { data: holding, isPending, isError } = useAggregatorHolding(holdingId);
  const [saleDialogOpen, setSaleDialogOpen] = useState(false);
  const [returnDialogOpen, setReturnDialogOpen] = useState(false);
  const [extensionDialogOpen, setExtensionDialogOpen] = useState(false);
  // Snapshotted once (react-hooks/purity forbids a bare Date.now() in render
  // — see expiry-countdown.tsx). Only used to notice "the window has already
  // passed" for the banner below; a stale-by-a-few-seconds value doesn't
  // matter for that.
  const [now] = useState(() => Date.now());

  if (isPending) {
    return (
      <div className="mx-auto flex max-w-2xl flex-col gap-4">
        <Skeleton className="h-4 w-32" />
        <Skeleton className="h-64 w-full rounded-lg" />
      </div>
    );
  }

  if (isError || !holding) {
    return (
      <EmptyState
        icon={GalleryVerticalEnd}
        title="Holding not found"
        description="This reservation may have been removed, or the link is wrong."
        action={
          <Link
            href="/aggregator/collection"
            className="text-sm font-medium text-gold-bright hover:underline"
          >
            Back to My Inventory
          </Link>
        }
      />
    );
  }

  const { artwork } = holding;
  const status = HOLDING_STATUS_CONFIG[holding.status];
  const isReserved = holding.status === "reserved";
  const isReturned = holding.status === "returned";
  // The API takes a piece back itself once its window has passed (a sweep
  // every 15 minutes), so this only shows in the gap before that runs. Recording
  // a sale is the one thing still worth doing from here.
  const isExpired =
    isReserved && new Date(holding.expiresAt).getTime() <= now;
  // One answer per window: GalleryZone's reply stands until the window moves.
  // The API also refuses a second request while one is waiting, and once the
  // piece is already held to the end of its listing.
  const request = holding.extensionRequest;
  const canAskToKeep =
    isReserved &&
    !isExpired &&
    !holding.windowExtended &&
    request?.status !== "pending" &&
    !(request && request.previousExpiresAt === holding.expiresAt);
  // The note's rule: COA/NFC access follows the ACTIVE allocation. Once a
  // piece is returned it moves on to the next aggregator, so the passport
  // stops showing here — it isn't deleted, just no longer this aggregator's
  // to see (types/artwork.ts's coa fields live permanently on the artwork).
  const showPassport = !isReturned;


  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-6">
      <Link
        href="/aggregator/collection"
        className="inline-flex items-center gap-1.5 text-xs font-medium text-muted-foreground transition-colors hover:text-gold-bright"
      >
        <ArrowLeft className="size-3.5" strokeWidth={2} />
        Back to My Inventory
      </Link>

      {isExpired && (
        <div className="flex flex-col gap-3 rounded-lg border border-destructive/30 bg-destructive/5 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-sm font-medium text-foreground">
              This piece&rsquo;s 30-day window has ended.
            </p>
            <p className="text-sm text-muted-foreground">
              GalleryZone takes it back and offers it to another aggregator,
              and your advance returns to your wallet. If it sold before then,
              record the sale now.
            </p>
          </div>
          <div className="flex shrink-0 items-center gap-2">
            <Button size="sm" onClick={() => setSaleDialogOpen(true)}>
              Record sale
            </Button>
          </div>
        </div>
      )}

      {isReturned && (
        <div className="flex flex-col gap-1 rounded-lg border border-border bg-muted/40 p-4">
          <p className="text-sm font-medium text-foreground">
            Your period for this piece has ended.
          </p>
          <p className="text-sm text-muted-foreground">
            It has gone back to GalleryZone and is now available to another
            aggregator. Your advance is back in your wallet.{" "}
            <Link
              href="/aggregator/inventory"
              className="font-medium text-gold-bright hover:underline"
            >
              Browse inventory
            </Link>{" "}
            to reserve something else.
          </p>
        </div>
      )}

      <div className="flex flex-col gap-5 rounded-lg border border-border bg-card p-5 sm:p-6">
        <div className="flex items-start gap-4">
          <div className="relative size-20 shrink-0 overflow-hidden rounded-md bg-muted">
            <Image
              src={artwork.thumbnailUrl}
              alt={artwork.title}
              fill
              sizes="80px"
              className="object-cover"
            />
          </div>
          <div className="min-w-0 flex-1">
            <p className="font-display text-lg font-semibold text-foreground">
              {artwork.title}
            </p>
            <p className="text-sm text-muted-foreground">
              {artwork.artistName}
            </p>
            <span
              className={`mt-2 inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-medium ${status.className}`}
            >
              <status.icon className="size-3" strokeWidth={2} />
              {status.label}
            </span>
          </div>
          <PriceTag amount={holding.displayPrice} className="text-lg" />
        </div>

        {isReserved && (
          <div className="flex flex-col gap-2.5 border-t border-border pt-4">
            <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
              Display window
            </p>
            <ExpiryCountdown expiresAt={holding.expiresAt} className="w-40" />
            <p className="text-xs text-muted-foreground">
              Reserved {formatDate(holding.assignedAt)} &middot; expires{" "}
              {formatDate(holding.expiresAt)}
            </p>
            {request && (
              <ExtensionStatus request={request} expiresAt={holding.expiresAt} />
            )}
          </div>
        )}

        <div className="flex flex-col gap-1.5 border-t border-border pt-4">
          <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
            Rotation &middot; month {holding.cycleMonth ?? 1} of{" "}
            {AGGREGATOR_CYCLE_MONTHS}
          </p>
          <CycleStepper currentMonth={holding.cycleMonth ?? 1} />
        </div>

        <div className="grid grid-cols-3 gap-4 border-t border-border pt-4 text-sm">
          <div>
            <p className="text-xs text-muted-foreground">Advance</p>
            <p className="mt-0.5 font-medium text-foreground tabular-nums">
              {formatINR(holding.advanceAmount)}
              <span className="ml-1 text-xs font-normal text-muted-foreground">
                ({holding.advancePercent}%)
              </span>
            </p>
          </div>
          <div>
            <p className="text-xs text-muted-foreground">Delivery deposit</p>
            <p className="mt-0.5 font-medium text-foreground tabular-nums">
              {formatINR(holding.deliveryDeposit ?? 0)}
            </p>
          </div>
          <div>
            <p className="text-xs text-muted-foreground">Display price</p>
            <p className="mt-0.5 font-medium text-foreground tabular-nums">
              {formatINR(holding.displayPrice)}
            </p>
          </div>
        </div>

        {isReserved && (
          <div className="flex flex-wrap items-center gap-2 border-t border-border pt-4">
            <Button onClick={() => setSaleDialogOpen(true)}>
              Record sale
            </Button>
            <Button
              variant="outline"
              onClick={() => setReturnDialogOpen(true)}
            >
              Return
            </Button>
            {canAskToKeep && (
              <Button
                variant="outline"
                onClick={() => setExtensionDialogOpen(true)}
              >
                Ask to keep it longer
              </Button>
            )}
          </div>
        )}
      </div>

      {showPassport ? (
        <ArtworkPassportCard
          title={artwork.title}
          artistName={artwork.artistName}
          coverImageUrl={artwork.thumbnailUrl}
          coaCertificateNumber={artwork.coaCertificateNumber}
          coaIssueDate={artwork.coaIssueDate}
        />
      ) : (
        <div className="flex items-center gap-3 rounded-lg border border-dashed border-border p-4 text-sm text-muted-foreground">
          <ShieldOff className="size-4 shrink-0" strokeWidth={1.75} />
          This piece&rsquo;s COA/NFC passport is only visible while it&rsquo;s
          in your active inventory.
        </div>
      )}

      <SuggestedArtworks references={[artwork]} title="Similar artworks" />

      <RecordSaleDialog
        holding={holding}
        open={saleDialogOpen}
        onOpenChange={setSaleDialogOpen}
      />

      <ReturnHoldingDialog
        holding={holding}
        open={returnDialogOpen}
        onOpenChange={setReturnDialogOpen}
      />

      <RequestExtensionDialog
        holding={holding}
        open={extensionDialogOpen}
        onOpenChange={setExtensionDialogOpen}
      />
    </div>
  );
}

const EXTENSION_TONE = {
  pending: {
    icon: Hourglass,
    title: "Waiting for GalleryZone",
    className: "border-gold/30 bg-gold/5",
  },
  approved: {
    icon: CircleCheckBig,
    title: "GalleryZone agreed",
    className: "border-emerald-500/30 bg-emerald-500/10",
  },
  declined: {
    icon: CircleX,
    title: "GalleryZone said no",
    className: "border-border bg-muted/40",
  },
} as const;

// Asking to keep a piece longer, and what GalleryZone answered. The answer
// stands for the window it was asked about.
function ExtensionStatus({
  request,
  expiresAt,
}: {
  request: HoldingExtensionRequest;
  expiresAt: string;
}) {
  const tone = EXTENSION_TONE[request.status];
  const ends = formatDate(expiresAt);
  return (
    <div
      className={`mt-1 flex items-start gap-2.5 rounded-md border p-3 ${tone.className}`}
    >
      <tone.icon className="mt-0.5 size-4 shrink-0 text-foreground/70" strokeWidth={1.75} />
      <div className="min-w-0 text-sm">
        <p className="font-medium text-foreground">{tone.title}</p>
        <p className="mt-0.5 text-muted-foreground">
          {request.status === "pending" &&
            `You asked to keep this piece longer. If it isn't approved by ${ends}, it goes back on sale and your advance is released.`}
          {request.status === "approved" && `The window now runs to ${ends}.`}
          {request.status === "declined" &&
            `The window ends on ${ends}. Then the piece goes back on sale and your advance is released.`}
        </p>
        {request.status === "pending" && (
          <p className="mt-1 text-muted-foreground">
            Your assurance: &ldquo;{request.assurance}&rdquo;
          </p>
        )}
        {request.note && (
          <p className="mt-1 text-muted-foreground">
            GalleryZone wrote: &ldquo;{request.note}&rdquo;
          </p>
        )}
      </div>
    </div>
  );
}
