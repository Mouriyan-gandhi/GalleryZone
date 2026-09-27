"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { GalleryVerticalEnd } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/shared/empty-state";
import { PriceTag } from "@/components/shared/price-tag";
import { ExpiryCountdown } from "./expiry-countdown";
import { RecordSaleDialog } from "./record-sale-dialog";
import { ReturnHoldingDialog } from "./return-holding-dialog";
import { HOLDING_STATUS_CONFIG } from "./holding-status";
import { useAggregatorCollection } from "@/hooks/useAggregatorCollection";
import type { AggregatorHolding } from "@/types/aggregator";
import type { ArtworkSummary } from "@/types/artwork";

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
  });
}

type CollectionRow = AggregatorHolding & { artwork: ArtworkSummary };

type StatusFilter = "all" | AggregatorHolding["status"];

const STATUS_TABS: Array<{ key: StatusFilter; label: string }> = [
  { key: "all", label: "All" },
  { key: "reserved", label: "Reserved" },
  { key: "sold_pending_settlement", label: "Sold" },
  { key: "returned", label: "Returned" },
];

export function CollectionTable() {
  const { data, isPending, isError } = useAggregatorCollection();
  const [saleDialogHolding, setSaleDialogHolding] =
    useState<CollectionRow | null>(null);
  const [returnDialogHolding, setReturnDialogHolding] =
    useState<CollectionRow | null>(null);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");

  if (isPending) {
    return (
      <div className="flex flex-col gap-3">
        {Array.from({ length: 4 }).map((_, i) => (
          <Skeleton key={i} className="h-20 w-full rounded-lg" />
        ))}
      </div>
    );
  }

  if (isError) {
    return (
      <EmptyState
        icon={GalleryVerticalEnd}
        title="Couldn't load your collection"
        description="Something went wrong loading your holdings. Try refreshing the page."
      />
    );
  }

  if (!data || data.length === 0) {
    return (
      <EmptyState
        icon={GalleryVerticalEnd}
        title="No holdings yet"
        description="Reserve an artwork from Inventory to see it appear here."
        action={
          <Button nativeButton={false} render={<Link href="/aggregator/inventory" />} className="mt-2">
            Browse Inventory
          </Button>
        }
      />
    );
  }

  const filtered =
    statusFilter === "all"
      ? data
      : data.filter((holding) => holding.status === statusFilter);

  return (
    <>
      <div className="mb-4 flex flex-wrap items-center gap-2">
        {STATUS_TABS.map((tab) => {
          const count =
            tab.key === "all"
              ? data.length
              : data.filter((h) => h.status === tab.key).length;
          const active = statusFilter === tab.key;
          return (
            <button
              key={tab.key}
              type="button"
              onClick={() => setStatusFilter(tab.key)}
              className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition-colors ${
                active
                  ? "border-gold/50 bg-gold/10 text-gold-bright"
                  : "border-border text-muted-foreground hover:bg-muted"
              }`}
            >
              {tab.label}
              <span
                className={
                  active ? "text-gold-bright/70" : "text-muted-foreground/70"
                }
              >
                {count}
              </span>
            </button>
          );
        })}
      </div>

      {filtered.length === 0 ? (
        <EmptyState
          icon={GalleryVerticalEnd}
          title="No holdings with this status"
          description="Try a different filter above."
        />
      ) : (
        <>
          {/* ── MOBILE CARD LIST ───────────────────────────────────── */}
          <div className="flex flex-col gap-3 lg:hidden">
            {filtered.map((holding) => {
              const isSold = holding.status === "sold_pending_settlement";
              const isReserved = holding.status === "reserved";
              const status = HOLDING_STATUS_CONFIG[holding.status];
              return (
                <div key={holding.id} className="rounded-xl border border-border bg-card overflow-hidden">
                  <Link
                    href={`/aggregator/collection/${holding.id}`}
                    className="flex items-center gap-3 p-3 hover:bg-muted/30 transition-colors"
                  >
                    <div className="relative size-14 shrink-0 overflow-hidden rounded-lg bg-muted">
                      <Image
                        src={holding.artwork.thumbnailUrl}
                        alt={holding.artwork.title}
                        fill
                        sizes="56px"
                        className="object-cover"
                      />
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-start justify-between gap-2">
                        <p className="truncate text-sm font-semibold text-foreground">
                          {holding.artwork.title}
                        </p>
                        <span
                          className={`inline-flex shrink-0 items-center gap-1 rounded-full border px-2 py-0.5 text-[10px] font-medium whitespace-nowrap ${status.className}`}
                        >
                          <status.icon className="size-2.5" strokeWidth={2} />
                          {status.label}
                        </span>
                      </div>
                      <p className="truncate text-xs text-muted-foreground mt-0.5">
                        {holding.artwork.artistName}
                      </p>
                      <div className="flex items-center gap-3 mt-1.5">
                        <PriceTag amount={holding.displayPrice} className="text-sm font-semibold" />
                        {isReserved && (
                          <ExpiryCountdown expiresAt={holding.expiresAt} className="text-xs" />
                        )}
                      </div>
                    </div>
                  </Link>
                  {isReserved && (
                    <div className="flex gap-2 border-t border-border px-3 py-2">
                      <Button
                        size="sm"
                        className="flex-1 text-xs h-8"
                        onClick={() => setSaleDialogHolding(holding)}
                      >
                        Record sale
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        className="flex-1 text-xs h-8"
                        onClick={() => setReturnDialogHolding(holding)}
                      >
                        Return
                      </Button>
                    </div>
                  )}
                  {!isReserved && (
                    <div className="border-t border-border px-3 py-2">
                      <span className="text-xs text-muted-foreground">
                        {isSold ? "Sale recorded" : "Went back to GalleryZone"}
                      </span>
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* ── DESKTOP TABLE ──────────────────────────────────────── */}
          <div className="hidden lg:block overflow-x-auto rounded-lg border border-border">
            <table className="w-full min-w-[1120px] border-collapse text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/40 text-left text-xs text-muted-foreground uppercase">
                  <th className="px-4 py-3 font-medium">Artwork</th>
                  <th className="px-4 py-3 font-medium">
                    Display price
                    <span className="block text-[10px] font-normal normal-case text-muted-foreground/70">
                      Incl. GST
                    </span>
                  </th>
                  <th className="px-4 py-3 font-medium">
                    Advance
                    <span className="block text-[10px] font-normal normal-case text-muted-foreground/70">
                      Held from wallet
                    </span>
                  </th>
                  <th className="px-4 py-3 font-medium">
                    Delivery
                    <span className="block text-[10px] font-normal normal-case text-muted-foreground/70">
                      Refunded on sale
                    </span>
                  </th>
                  <th className="px-4 py-3 font-medium">Expiry</th>
                  <th className="px-4 py-3 font-medium">Status</th>
                  <th className="px-4 py-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((holding) => {
                  const isSold = holding.status === "sold_pending_settlement";
                  const isReserved = holding.status === "reserved";
                  const status = HOLDING_STATUS_CONFIG[holding.status];
                  return (
                    <tr key={holding.id} className="border-b border-border last:border-0">
                      <td className="px-4 py-3.5">
                        <Link
                          href={`/aggregator/collection/${holding.id}`}
                          className="flex items-center gap-3 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
                        >
                          <div className="relative size-12 shrink-0 overflow-hidden rounded-md bg-muted">
                            <Image
                              src={holding.artwork.thumbnailUrl}
                              alt={holding.artwork.title}
                              fill
                              sizes="48px"
                              className="object-cover"
                            />
                          </div>
                          <div className="min-w-0">
                            <p className="truncate font-medium text-foreground hover:text-gold-bright">
                              {holding.artwork.title}
                            </p>
                            <p className="truncate text-xs text-muted-foreground">
                              {holding.artwork.artistName}
                            </p>
                          </div>
                        </Link>
                      </td>
                      <td className="px-4 py-3.5">
                        <PriceTag amount={holding.displayPrice} className="text-sm" />
                        {!isSold && (
                          <p className="mt-0.5 text-[11px] text-muted-foreground">Set by GalleryZone</p>
                        )}
                      </td>
                      <td className="px-4 py-3.5">
                        <PriceTag amount={holding.advanceAmount} className="text-sm" />
                        <p className="mt-0.5 text-[11px] text-muted-foreground">
                          {holding.advancePercent}% of the{" "}
                          {(holding.cycleMonth ?? 1) <= 1 ? "display" : "artist"}{" "}
                          price
                        </p>
                      </td>
                      <td className="px-4 py-3.5">
                        <PriceTag amount={holding.deliveryDeposit ?? 0} className="text-sm" />
                        <p className="mt-0.5 text-[11px] text-muted-foreground">Refunded only on sale</p>
                      </td>
                      <td className="px-4 py-3.5">
                        {isReserved ? (
                          <>
                            <ExpiryCountdown expiresAt={holding.expiresAt} className="w-32" />
                            <p className="mt-1 text-[11px] text-muted-foreground">
                              Reserved {formatDate(holding.assignedAt)} &middot; expires {formatDate(holding.expiresAt)}
                            </p>
                          </>
                        ) : (
                          <span className="text-xs text-muted-foreground">&mdash;</span>
                        )}
                      </td>
                      <td className="px-4 py-3.5">
                        <span className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-medium whitespace-nowrap ${status.className}`}>
                          <status.icon className="size-3" strokeWidth={2} />
                          {status.label}
                        </span>
                      </td>
                      <td className="px-4 py-3.5">
                        {isReserved ? (
                          <div className="flex items-center gap-2">
                            <Button size="sm" onClick={() => setSaleDialogHolding(holding)}>Record sale</Button>
                            <Button size="sm" variant="outline" onClick={() => setReturnDialogHolding(holding)}>Return</Button>
                          </div>
                        ) : (
                          <span className="text-xs text-muted-foreground">
                            {isSold ? "Sale recorded" : "Went back to GalleryZone"}
                          </span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </>
      )}

      <RecordSaleDialog
        holding={saleDialogHolding}
        open={saleDialogHolding !== null}
        onOpenChange={(open) => !open && setSaleDialogHolding(null)}
      />

      <ReturnHoldingDialog
        holding={returnDialogHolding}
        open={returnDialogHolding !== null}
        onOpenChange={(open) => !open && setReturnDialogHolding(null)}
      />
    </>
  );
}
