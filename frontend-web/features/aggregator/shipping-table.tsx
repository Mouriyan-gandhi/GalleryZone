"use client";

import { useAggregatorCollection } from "@/hooks/useAggregatorCollection";

import Image from "next/image";
import { Lock, Truck, PackageCheck, PackageSearch } from "lucide-react";
import { toast } from "sonner";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import {
  useAggregatorShipments,
  useAdvanceShipmentMutation,
} from "@/hooks/useAggregatorSales";
import type { AggregatorShipment } from "@/services/aggregatorSalesService";

const NEXT_ACTION: Record<
  AggregatorShipment["shipmentStatus"],
  string | null
> = {
  preparing: "Mark dispatched",
  dispatched: "Mark delivered",
  delivered: null,
};

const STATUS_CLASS: Record<AggregatorShipment["shipmentStatus"], string> = {
  preparing: "border-gold/35 bg-gold/10 text-gold-bright",
  dispatched: "border-sky-500/30 bg-sky-500/10 text-sky-400",
  delivered: "border-emerald-500/30 bg-emerald-500/10 text-emerald-400",
};

export function ShippingTable() {
  return (
    <div className="flex flex-col gap-8">
      <InboundSection />

      <div>
        <h2 className="font-display text-base font-semibold text-foreground">
          Outbound
        </h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Post-sale shipments to buyers.
        </p>
        <div className="mt-4">
          <OutboundList />
        </div>
      </div>
    </div>
  );
}

// Illustrative only — the platform's data model has no "in transit from
// GalleryZone to aggregator" status distinct from a holding's own
// `reserved` state (see SAD §2.7), so this section isn't backed by a real
// shipment record the way Outbound is. It surfaces recently-reserved
// holdings as a stand-in for "due for pickup", not a fabricated tracking
// state machine.
function InboundSection() {
  const { data: holdings } = useAggregatorCollection();
  const inbound = (holdings ?? []).filter((h) => h.status === "reserved").slice(0, 3);

  return (
    <div>
      <h2 className="font-display text-base font-semibold text-foreground">
        Inbound
      </h2>
      <p className="mt-1 text-sm text-muted-foreground">
        Artworks GalleryZone has assigned or you&rsquo;ve reserved, en route
        to your premises. Detailed transit tracking isn&rsquo;t modeled yet —
        this reflects your currently reserved holdings.
      </p>

      {inbound.length === 0 ? (
        <EmptyState
          icon={PackageSearch}
          title="Nothing inbound"
          description="Reserve an artwork from Browse GalleryZone to see it here."
          className="mt-4"
        />
      ) : (
        <div className="mt-4 flex flex-col gap-2">
          {inbound.map((holding) => {
            const artwork = holding.artwork;
            if (!artwork) return null;
            return (
              <div
                key={holding.id}
                className="flex items-center gap-3 rounded-lg border border-border bg-card p-3.5"
              >
                <div className="relative size-10 shrink-0 overflow-hidden rounded-md bg-muted">
                  <Image
                    src={artwork.thumbnailUrl}
                    alt={artwork.title}
                    fill
                    sizes="40px"
                    className="object-cover"
                  />
                </div>
                <p className="min-w-0 flex-1 truncate text-sm font-medium text-foreground">
                  {artwork.title}
                </p>
                <span className="inline-flex shrink-0 items-center gap-1.5 rounded-full border border-sky-500/30 bg-sky-500/10 px-2.5 py-1 text-xs font-medium text-sky-400">
                  <Truck className="size-3" strokeWidth={2} />
                  Due for pickup
                </span>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function OutboundList() {
  const { data: shipments, isPending } = useAggregatorShipments();
  const { data: holdings } = useAggregatorCollection();
  const advanceMutation = useAdvanceShipmentMutation();

  if (isPending) {
    return (
      <div className="flex flex-col gap-3">
        {Array.from({ length: 3 }).map((_, i) => (
          <Skeleton key={i} className="h-16 w-full rounded-lg" />
        ))}
      </div>
    );
  }

  if (!shipments || shipments.length === 0) {
    return (
      <EmptyState
        icon={PackageCheck}
        title="No outbound shipments yet"
        description="Recorded sales will appear here for dispatch tracking."
      />
    );
  }

  return (
    <div className="overflow-x-auto rounded-lg border border-border">
      <table className="w-full min-w-[720px] border-collapse text-sm">
        <thead>
          <tr className="border-b border-border bg-muted/40 text-left text-xs text-muted-foreground uppercase">
            <th className="px-4 py-3 font-medium">Artwork</th>
            <th className="px-4 py-3 font-medium">Buyer</th>
            <th className="px-4 py-3 font-medium">Mode</th>
            <th className="px-4 py-3 font-medium">Status</th>
            <th className="px-4 py-3 font-medium">Action</th>
          </tr>
        </thead>
        <tbody>
          {shipments.map((shipment) => {
            const artwork = holdings?.find((h) => h.artworkId === shipment.artworkId)?.artwork;
            const nextAction = NEXT_ACTION[shipment.shipmentStatus];
            return (
              <tr key={shipment.id} className="border-b border-border last:border-0">
                <td className="px-4 py-3.5">
                  <p className="truncate font-medium text-foreground">
                    {artwork?.title ?? shipment.artworkId}
                  </p>
                </td>
                <td className="px-4 py-3.5 text-muted-foreground">
                  {shipment.buyerName}
                </td>
                <td className="px-4 py-3.5 text-muted-foreground">
                  {shipment.deliveryMode === "courier"
                    ? (shipment.courierRef ?? "Courier")
                    : "Self pickup"}
                </td>
                <td className="px-4 py-3.5">
                  <span
                    className={`inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-medium whitespace-nowrap ${STATUS_CLASS[shipment.shipmentStatus]}`}
                  >
                    {shipment.shipmentStatus}
                  </span>
                  {shipment.shipmentStatus === "preparing" && !shipment.nfcReady && (
                    <span
                      id={`nfc-unlocked-${shipment.id}`}
                      className="mt-1.5 flex w-fit items-center gap-1 rounded-full border border-red-500/40 bg-red-500/10 px-2 py-0.5 text-[11px] font-medium whitespace-nowrap text-red-300"
                    >
                      <Lock className="size-3" strokeWidth={2} />
                      Unlocked — lock the tag first
                    </span>
                  )}
                </td>
                <td className="px-4 py-3.5">
                  {nextAction ? (
                    <Button
                      size="sm"
                      variant="outline"
                      disabled={advanceMutation.isPending}
                      onClick={() =>
                        advanceMutation.mutate(shipment.id, {
                          onError: (error) => toast.error("Couldn't update the shipment", { description: error instanceof Error ? error.message : "Please try again." }),
                        })
                      }
                    >
                      {nextAction}
                    </Button>
                  ) : (
                    <span className="text-xs text-muted-foreground">Done</span>
                  )}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
