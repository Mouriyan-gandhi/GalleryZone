"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { ArrowLeft, PackageSearch, TriangleAlert } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { EmptyState } from "@/components/shared/empty-state";
import { PriceTag } from "@/components/shared/price-tag";
import { formatINR } from "@/lib/utils";
import {
  AGGREGATOR_CYCLE_MONTHS,
  AGGREGATOR_COMMISSION_RATE,
  PLATFORM_MARKUP,
  aggregatorTermsAt,
} from "@/lib/pricing";
import {
  useReservableArtwork,
  useReserveArtworkMutation,
} from "@/hooks/useAggregatorInventory";
import { useAggregatorWallet } from "@/hooks/useAggregatorWallet";
import { CycleStepper } from "./cycle-stepper";
import {
  ReserveRequirementsNotice,
  useReserveRequirements,
} from "./reserve-requirements";
import { SuggestedArtworks } from "./suggested-artworks";

// Full-page replacement for what used to be a confirm dialog. Reserving is a
// real commitment — it holds money from the wallet for thirty days — so it
// gets its own screen and its own back button rather than a modal you could
// mis-click through. Confirming lands on the new holding's detail page
// (holding-detail.tsx), which is the "what happens next" this flow used to
// leave to a toast.
//
// Month 1 is the one month the aggregator sets the price (client, 30 Sep 2026:
// "the aggregator can set the price only while reserving in month 1"). They may
// go as high as they like, never below GalleryZone's own price, and it can't be
// changed once reserved. Every later month the price is GalleryZone's.
export function ReserveArtworkPage({ artworkId }: { artworkId: string }) {
  const router = useRouter();
  const { data: artwork, isPending, isError } =
    useReservableArtwork(artworkId);
  const reserveMutation = useReserveArtworkMutation();
  const { data: wallet } = useAggregatorWallet();
  const { blockedReason } = useReserveRequirements();
  // What has been typed into the price field, before GST. null until they touch
  // it, which means "GalleryZone's price".
  const [typedPrice, setTypedPrice] = useState<string | null>(null);

  if (isPending) {
    return (
      <div className="mx-auto flex max-w-lg flex-col gap-4">
        <Skeleton className="h-4 w-32" />
        <Skeleton className="aspect-[4/5] w-full rounded-lg" />
        <Skeleton className="h-24 w-full rounded-lg" />
      </div>
    );
  }

  if (isError || !artwork) {
    return (
      <EmptyState
        icon={PackageSearch}
        title="This piece isn't reservable"
        description="It may have just been taken by another aggregator, or its listing period has ended."
        action={
          <Link
            href="/aggregator/inventory"
            className="text-sm font-medium text-gold-bright hover:underline"
          >
            Back to inventory
          </Link>
        }
      />
    );
  }

  const { offer } = artwork;
  const chosenPrice =
    offer.canSetPrice && typedPrice !== null
      ? Number(typedPrice)
      : offer.sellingPrice;
  const priceError = !offer.canSetPrice
    ? null
    : !Number.isInteger(chosenPrice) || chosenPrice <= 0
      ? "Enter a price in whole rupees."
      : chosenPrice < offer.sellingPrice
        ? `It can't be lower than GalleryZone's price, ${formatINR(offer.sellingPrice)}.`
        : null;
  // The numbers below follow what is typed, but never a price the API would refuse.
  const price = priceError ? offer.sellingPrice : chosenPrice;

  // MOU §8: the aggregator's commission is 20% of (selling price − the artist's
  // price), before GST, whoever set the price. The artist's price is worked back
  // from GalleryZone's month-1 price, the same way this screen always has.
  const artistPrice = Math.round(
    offer.standardPrice / (1 + offer.gstRate) / (1 + PLATFORM_MARKUP),
  );
  const terms = aggregatorTermsAt({
    sellingPrice: price,
    artistPrice,
    gstRate: offer.gstRate,
  });
  const commissionPercent = Math.round(AGGREGATOR_COMMISSION_RATE * 100);

  // Month 1's advance follows the price they choose; after that it is fixed.
  const advance = offer.canSetPrice
    ? Math.round(price * offer.advanceRate)
    : offer.advance;
  const advanceBase = offer.canSetPrice ? price : offer.advanceBase;
  const payable = advance + offer.deliveryCharge;
  const free = wallet ? wallet.balance - wallet.lockedBalance : 0;
  const shortfall = Math.max(0, payable - free);
  const priceWarning =
    offer.priceWarnFrom !== null && price >= offer.priceWarnFrom;

  function handleConfirm() {
    reserveMutation.mutate(
      {
        artworkId,
        sellingPrice: offer.canSetPrice ? price : undefined,
      },
      {
        onSuccess: (holding) => {
          toast.success("Artwork reserved", {
            description: `"${artwork!.title}" is now in My Inventory.`,
          });
          router.push(`/aggregator/collection/${holding.id}`);
        },
        onError: (error) => toast.error(error.message),
      },
    );
  }

  return (
    <div className="mx-auto flex max-w-lg flex-col gap-6">
      <Link
        href="/aggregator/inventory"
        className="inline-flex items-center gap-1.5 text-xs font-medium text-muted-foreground transition-colors hover:text-gold-bright"
      >
        <ArrowLeft className="size-3.5" strokeWidth={2} />
        Back to inventory
      </Link>

      <ReserveRequirementsNotice />

      <div className="flex flex-col gap-4 rounded-lg border border-border bg-card p-5">
        <div className="flex items-center gap-3">
          <div className="relative size-16 shrink-0 overflow-hidden rounded-md bg-muted">
            <Image
              src={artwork.thumbnailUrl}
              alt={artwork.title}
              fill
              sizes="64px"
              className="object-cover"
            />
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate font-display text-base font-semibold text-foreground">
              {artwork.title}
            </p>
            <p className="truncate text-sm text-muted-foreground">
              {artwork.artistName}
            </p>
          </div>
          <PriceTag amount={terms.displayPrice} className="text-base" />
        </div>

        <div className="flex flex-col gap-2">
          <CycleStepper currentMonth={offer.month} />
          <p className="text-sm text-muted-foreground">
            Month {offer.month} of {AGGREGATOR_CYCLE_MONTHS}. Confirming holds
            the advance from your wallet and moves this piece into My
            Inventory for 30 days. After that it moves on to the next
            aggregator and your advance is back in your wallet on day 31,
            unless you ask GalleryZone to let you keep it and they agree.
          </p>
        </div>

        {offer.canSetPrice ? (
          <div className="flex flex-col gap-2 rounded-md border border-border bg-background px-3.5 py-3">
            <Label htmlFor="sellingPrice">
              Your selling price, before GST (₹)
            </Label>
            <Input
              id="sellingPrice"
              type="number"
              inputMode="numeric"
              min={offer.sellingPrice}
              step={1}
              value={typedPrice ?? String(offer.sellingPrice)}
              onChange={(e) => setTypedPrice(e.target.value)}
              aria-invalid={Boolean(priceError)}
              aria-describedby="sellingPriceHint"
              className="h-10 font-mono tabular-nums sm:max-w-xs"
            />
            {priceError ? (
              <p id="sellingPriceHint" className="text-xs text-destructive">
                {priceError}
              </p>
            ) : (
              <p
                id="sellingPriceHint"
                className="text-xs text-muted-foreground"
              >
                GalleryZone&rsquo;s price is {formatINR(offer.sellingPrice)}.
                Set it higher if you like, not lower. You set it once: it
                can&rsquo;t be changed after you reserve.
              </p>
            )}
            {priceWarning && !priceError && (
              <div
                role="status"
                className="flex items-start gap-2 rounded-md border border-gold/40 bg-gold/5 p-2.5"
              >
                <TriangleAlert
                  className="mt-0.5 size-3.5 shrink-0 text-gold-bright"
                  strokeWidth={1.75}
                />
                <p className="text-xs leading-relaxed text-muted-foreground">
                  That&rsquo;s at least double GalleryZone&rsquo;s price. You
                  can still reserve it, and GalleryZone will be told about the
                  price.
                </p>
              </div>
            )}
          </div>
        ) : (
          <div className="flex items-center justify-between gap-3 rounded-md border border-border bg-background px-3.5 py-3 text-sm">
            <div>
              <p className="font-medium text-foreground">
                Price this month, before GST
              </p>
              <p className="mt-0.5 text-xs text-muted-foreground">
                Set by GalleryZone. Only the first aggregator sets a price.
              </p>
            </div>
            <span className="font-mono tabular-nums text-foreground">
              {formatINR(offer.sellingPrice)}
            </span>
          </div>
        )}

        <div className="flex flex-col gap-1.5 rounded-md border border-border bg-background px-3.5 py-3 text-sm">
          <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
            Where this price goes
          </p>
          <div className="flex items-center justify-between">
            <span className="text-muted-foreground">Artist&rsquo;s price</span>
            <span className="font-mono tabular-nums text-foreground">
              {formatINR(artistPrice)}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-muted-foreground">
              GalleryZone ({100 - commissionPercent}% of the markup)
            </span>
            <span className="font-mono tabular-nums text-foreground">
              {formatINR(terms.galleryZoneShare)}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-muted-foreground">
              Your commission if it sells here ({commissionPercent}%)
            </span>
            <span className="font-mono tabular-nums text-foreground">
              {formatINR(terms.commission)}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-muted-foreground">
              GST ({+(offer.gstRate * 100).toFixed(2)}%)
            </span>
            <span className="font-mono tabular-nums text-foreground">
              {formatINR(terms.gst)}
            </span>
          </div>
          <div className="flex items-center justify-between border-t border-border pt-1.5">
            <span className="font-medium text-foreground">
              What customers see
            </span>
            <span className="font-mono font-semibold tabular-nums text-gold-bright">
              {formatINR(terms.displayPrice)}
            </span>
          </div>
          {offer.canSetPrice && (
            <p className="text-xs text-muted-foreground">
              Every extra rupee you charge splits {commissionPercent}% to you
              and {100 - commissionPercent}% to GalleryZone. The
              artist&rsquo;s price never changes.
            </p>
          )}
        </div>

        {offer.monthlyReduction > 0 && (
          <div className="flex flex-col gap-1.5 rounded-md border border-border bg-background px-3.5 py-3 text-sm">
            <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
              Why this month&rsquo;s price is lower
            </p>
            <div className="flex items-center justify-between">
              <span className="text-muted-foreground">Month 1 price</span>
              <span className="font-mono tabular-nums text-muted-foreground line-through">
                {formatINR(offer.standardPrice)}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-muted-foreground">
                Month {offer.month} reduction
              </span>
              <span className="font-mono tabular-nums text-foreground">
                &minus;{formatINR(offer.monthlyReduction)}
              </span>
            </div>
            <div className="flex items-center justify-between border-t border-border pt-1.5">
              <span className="font-medium text-foreground">
                Your price today
              </span>
              <span className="font-mono font-semibold tabular-nums text-gold-bright">
                {formatINR(offer.offerPrice)}
              </span>
            </div>
          </div>
        )}

        <div className="flex flex-col gap-2 rounded-md border border-gold/25 bg-gold/5 px-3.5 py-3 text-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="font-medium text-foreground">
                Advance ({Math.round(offer.advanceRate * 100)}%)
              </p>
              <p className="mt-0.5 text-xs text-muted-foreground">
                of{" "}
                {offer.advanceBasis === "selling_price"
                  ? "your price before GST"
                  : "the artist price"}
                , {formatINR(advanceBase)}
              </p>
            </div>
            <span className="font-mono tabular-nums text-foreground">
              {formatINR(advance)}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <div>
              <p className="font-medium text-foreground">Delivery</p>
              <p className="mt-0.5 text-xs text-muted-foreground">
                Returned when the piece sells, not if it comes back
              </p>
            </div>
            <span className="font-mono tabular-nums text-foreground">
              {formatINR(offer.deliveryCharge)}
            </span>
          </div>
          <div className="mt-0.5 flex items-center justify-between border-t border-gold/20 pt-2">
            <div>
              <p className="font-medium text-foreground">Held from your wallet</p>
              <p className="mt-0.5 text-xs text-muted-foreground">
                {formatINR(Math.max(0, free))} free right now
              </p>
            </div>
            <span className="font-display text-lg font-semibold tabular-nums text-gold-bright">
              {formatINR(payable)}
            </span>
          </div>
        </div>

        {shortfall > 0 && (
          <div className="flex items-start justify-between gap-3 rounded-lg border border-border bg-muted/30 p-3">
            <span className="flex flex-1 flex-col gap-0.5">
              <span className="text-xs font-medium text-foreground">
                {formatINR(shortfall)} short
              </span>
              <span className="text-[11px] leading-snug text-muted-foreground">
                Top up your wallet to reserve this piece. Money is held, not
                spent: it comes back when the piece sells.
              </span>
            </span>
            <Button size="sm" variant="outline" nativeButton={false} render={<Link href="/aggregator/wallet" />}>
              Go to wallet
            </Button>
          </div>
        )}

        <div className="flex items-center justify-end gap-2">
          <Button
            variant="outline"
            nativeButton={false}
            render={<Link href="/aggregator/inventory" />}
          >
            Cancel
          </Button>
          <Button
            onClick={handleConfirm}
            disabled={
              reserveMutation.isPending ||
              shortfall > 0 ||
              Boolean(priceError) ||
              blockedReason !== undefined
            }
            title={
              blockedReason ??
              (shortfall > 0
                ? `Add ${formatINR(shortfall)} to your wallet first`
                : undefined)
            }
          >
            {reserveMutation.isPending ? "Reserving…" : "Confirm reservation"}
          </Button>
        </div>
      </div>

      <SuggestedArtworks
        references={[artwork]}
        title="Similar pieces you could reserve"
      />
    </div>
  );
}
