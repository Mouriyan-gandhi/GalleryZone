"use client";

import { useAggregatorCollection } from "@/hooks/useAggregatorCollection";
import type { AggregatorHolding } from "@/types/aggregator";
import type { ArtworkSummary } from "@/types/artwork";

import { useCallback, useMemo, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { ShoppingBag, Search, SlidersHorizontal, ChevronDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Popover, PopoverTrigger, PopoverContent } from "@/components/ui/popover";
import {
  AdminDataTable,
  type AdminDataTableColumn,
} from "@/features/admin/admin-data-table";
import { PriceTag } from "@/components/shared/price-tag";
import { formatINR, cn } from "@/lib/utils";
import { useAggregatorSales } from "@/hooks/useAggregatorSales";
import type { AggregatorSale } from "@/types/aggregator";

const SHIPMENT_STATUSES: AggregatorSale["shipmentStatus"][] = [
  "preparing",
  "dispatched",
  "delivered",
];

const SHIPMENT_LABEL: Record<AggregatorSale["shipmentStatus"], string> = {
  preparing: "Preparing",
  dispatched: "Dispatched",
  delivered: "Delivered",
};

const SHIPMENT_CLASS: Record<AggregatorSale["shipmentStatus"], string> = {
  preparing: "border-gold/35 bg-gold/10 text-gold-bright",
  dispatched: "border-sky-500/30 bg-sky-500/10 text-sky-400",
  delivered: "border-emerald-500/30 bg-emerald-500/10 text-emerald-400",
};

type DatePreset = "7d" | "30d" | "year";
const DATE_PRESETS: { value: DatePreset; label: string; days: number }[] = [
  { value: "7d", label: "Last 7 days", days: 7 },
  { value: "30d", label: "Last 30 days", days: 30 },
  { value: "year", label: "This year", days: 365 },
];

// "Owed to GalleryZone" is the same vocabulary the settlements table uses for
// a cash sale the aggregator hasn't remitted yet — not a new status concept.
type PaymentStatus = "owed" | "settled";
function paymentStatusOf(sale: AggregatorSale): PaymentStatus {
  return sale.paymentRoute === "cash_at_premises" && !sale.remittedAt ? "owed" : "settled";
}
const PAYMENT_STATUS_LABEL: Record<PaymentStatus, string> = {
  owed: "Owed to GalleryZone",
  settled: "Settled",
};

// Mirrors aggregatorSalesService's internal commissionForSale (not exported,
// UI-only concern) — 20% of the markup the display price carries over the
// customer-price floor, same formula the Dashboard KPI and recordSale() use.
type HoldingRow = AggregatorHolding & { artwork: ArtworkSummary };
function commissionForSale(sale: AggregatorSale, holdings: HoldingRow[]): number {
  const holding = holdings.find((h) => h.id === sale.holdingId);
  const artwork = holding?.artwork;
  if (!holding || !artwork) return 0;
  return Math.round(
    0.2 * Math.max(0, holding.displayPrice - artwork.customerPrice),
  );
}

export function SalesTable() {
  const { data: sales, isPending } = useAggregatorSales();
  const { data: holdings } = useAggregatorCollection();
  const artworkOf = useCallback(
    (artworkId: string) => holdings?.find((h) => h.artworkId === artworkId)?.artwork,
    [holdings],
  );
  const [active, setActive] = useState<AggregatorSale | null>(null);

  // Mobile's own filter state — the desktop AdminDataTable owns its search
  // and filtering internally, but the mobile card list below doesn't go
  // through that component, so it needs its own.
  const [mobileSearch, setMobileSearch] = useState("");
  const [shipmentFilter, setShipmentFilter] = useState<AggregatorSale["shipmentStatus"] | null>(null);
  const [dateFilter, setDateFilter] = useState<DatePreset | null>(null);
  const [statusFilter, setStatusFilter] = useState<PaymentStatus | null>(null);
  const mobileFiltersActive = Boolean(mobileSearch || shipmentFilter || dateFilter || statusFilter);
  // Snapshotted once (react-hooks/purity forbids a bare Date.now() in render
  // — see holding-detail.tsx). A stale-by-minutes value is fine for a
  // day-granularity date filter.
  const [now] = useState(() => Date.now());

  const mobileSales = useMemo(() => {
    let rows = sales ?? [];
    const q = mobileSearch.trim().toLowerCase();
    if (q) {
      rows = rows.filter((row) =>
        `${row.buyerName} ${row.buyerEmail} ${artworkOf(row.artworkId)?.title ?? ""}`
          .toLowerCase()
          .includes(q),
      );
    }
    if (shipmentFilter) rows = rows.filter((row) => row.shipmentStatus === shipmentFilter);
    if (statusFilter) rows = rows.filter((row) => paymentStatusOf(row) === statusFilter);
    if (dateFilter) {
      const days = DATE_PRESETS.find((d) => d.value === dateFilter)!.days;
      const cutoff = now - days * 86_400_000;
      rows = rows.filter((row) => new Date(row.soldAt).getTime() >= cutoff);
    }
    return rows;
  }, [sales, mobileSearch, shipmentFilter, statusFilter, dateFilter, now, artworkOf]);

  function clearMobileFilters() {
    setMobileSearch("");
    setShipmentFilter(null);
    setDateFilter(null);
    setStatusFilter(null);
  }

  const columns: AdminDataTableColumn<AggregatorSale>[] = [
    {
      key: "artwork",
      header: "Artwork",
      render: (row) => {
        const artwork = artworkOf(row.artworkId);
        return (
          <div className="flex min-w-0 items-center gap-3">
            {artwork && (
              <div className="relative size-10 shrink-0 overflow-hidden rounded-md bg-muted">
                <Image
                  src={artwork.thumbnailUrl}
                  alt={artwork.title}
                  fill
                  sizes="40px"
                  className="object-cover"
                />
              </div>
            )}
            <p className="truncate text-sm font-medium text-foreground">
              {artwork?.title ?? row.artworkId}
            </p>
          </div>
        );
      },
      sortable: true,
      sortValue: (row) => artworkOf(row.artworkId)?.title ?? row.artworkId,
    },
    {
      key: "buyer",
      header: "Buyer",
      render: (row) => (
        <div className="min-w-0">
          <p className="truncate text-sm text-foreground">{row.buyerName}</p>
          <p className="truncate text-xs text-muted-foreground">
            {row.buyerEmail}
          </p>
        </div>
      ),
      sortable: true,
      sortValue: (row) => row.buyerName,
    },
    {
      key: "soldPrice",
      header: "Sold price",
      render: (row) => <PriceTag amount={row.soldPrice} className="text-sm" />,
      sortable: true,
      sortValue: (row) => row.soldPrice,
    },
    {
      key: "commission",
      header: "Commission",
      render: (row) => (
        <span className="text-sm tabular-nums text-gold-bright">
          {formatINR(commissionForSale(row, holdings ?? []))}
        </span>
      ),
      sortable: true,
      sortValue: (row) => commissionForSale(row, holdings ?? []),
    },
    {
      key: "shipmentStatus",
      header: "Shipment",
      render: (row) => (
        <span
          className={`inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-medium whitespace-nowrap ${SHIPMENT_CLASS[row.shipmentStatus]}`}
        >
          {SHIPMENT_LABEL[row.shipmentStatus]}
        </span>
      ),
      sortable: true,
      sortValue: (row) => row.shipmentStatus,
    },
    {
      key: "soldAt",
      header: "Sold",
      render: (row) => (
        <span className="text-sm text-muted-foreground">
          {new Date(row.soldAt).toLocaleDateString("en-IN", {
            day: "numeric",
            month: "short",
            year: "numeric",
          })}
        </span>
      ),
      sortable: true,
      sortValue: (row) => -new Date(row.soldAt).getTime(),
    },
  ];

  return (
    <>
      {/* Custom Mobile Layout matching reference */}
      <div className="flex flex-col gap-4 lg:hidden">
        {/* Tabs */}
        <div className="flex w-full items-center gap-1.5 overflow-x-auto hide-scrollbar -mx-4 px-4 sm:mx-0 sm:px-0">
          {["All", "Reservations", "Sold", "Returned"].map((tab, i) => (
            <button
              key={tab}
              className={`shrink-0 rounded-md border px-4 py-1.5 text-[13px] font-medium transition-colors ${
                i === 0
                  ? "border-gold-700 bg-[#9a7b4f] text-white"
                  : "border-border bg-muted/20 text-foreground hover:bg-muted/50"
              }`}
            >
              {tab}
            </button>
          ))}
        </div>

        {/* Search & clear-filters */}
        <div className="flex items-center gap-2">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
            <input
              type="text"
              value={mobileSearch}
              onChange={(e) => setMobileSearch(e.target.value)}
              placeholder="Search by buyer or artwork..."
              className="w-full rounded-lg border border-border bg-muted/30 py-2 pl-9 pr-4 text-base outline-none placeholder:text-muted-foreground focus:border-gold/50 focus:ring-1 focus:ring-gold/50 transition-all sm:text-sm"
            />
          </div>
          <button
            type="button"
            onClick={clearMobileFilters}
            disabled={!mobileFiltersActive}
            aria-label="Clear search and filters"
            className="flex shrink-0 size-9 items-center justify-center rounded-lg border border-border bg-muted/30 text-muted-foreground transition-colors hover:bg-muted disabled:pointer-events-none disabled:opacity-40"
          >
            <SlidersHorizontal className="size-4" />
          </button>
        </div>

        {/* Dropdowns */}
        <div className="flex items-center gap-2 overflow-x-auto hide-scrollbar -mx-4 px-4 sm:mx-0 sm:px-0">
          <MobilePillFilter
            label="All Shipment"
            value={shipmentFilter}
            onChange={setShipmentFilter}
            options={SHIPMENT_STATUSES.map((s) => ({ value: s, label: SHIPMENT_LABEL[s] }))}
          />
          <MobilePillFilter
            label="All Dates"
            value={dateFilter}
            onChange={setDateFilter}
            options={DATE_PRESETS.map((d) => ({ value: d.value, label: d.label }))}
          />
          <MobilePillFilter
            label="All Status"
            value={statusFilter}
            onChange={setStatusFilter}
            options={(["owed", "settled"] as const).map((s) => ({ value: s, label: PAYMENT_STATUS_LABEL[s] }))}
          />
        </div>

        {/* True empty state: no sales recorded at all */}
        {(!sales || sales.length === 0) && (
          <div className="mt-4 flex flex-col items-center justify-center rounded-xl bg-[#F6F3EC] px-6 py-12 text-center border border-border/50">
            <div className="relative w-32 h-32 mb-4">
              <Image
                src="/images/no_sales_empty_state.jpg"
                alt="No sales yet"
                fill
                className="object-contain mix-blend-multiply brightness-[1.08] contrast-[1.15] sepia-[.2]"
              />
            </div>
            <h3 className="font-display text-xl font-bold text-foreground">
              No sales yet
            </h3>
            <p className="mt-2 text-[13px] text-muted-foreground max-w-[280px]">
              Recorded sales from your holdings will show up here. When a
              customer purchases or a reservation is converted to a sale, it
              will appear in this list.
            </p>
            <Button 
              nativeButton={false} 
              render={<Link href="/aggregator/inventory" />} 
              className="mt-6 bg-primary hover:bg-gold-deep text-primary-foreground"
            >
              Browse GalleryZone
            </Button>
            <p className="mt-3 text-[11px] text-muted-foreground max-w-[200px]">
              Discover more artworks to display in your gallery.
            </p>
          </div>
        )}

        {/* Sales exist, but none match the current search/filters */}
        {sales && sales.length > 0 && mobileSales.length === 0 && (
          <div className="mt-2 rounded-xl border border-dashed border-border py-12 text-center">
            <p className="text-sm text-muted-foreground">No sales match these filters.</p>
            <button
              type="button"
              onClick={clearMobileFilters}
              className="mt-2 text-xs font-medium text-gold-bright hover:underline"
            >
              Clear filters
            </button>
          </div>
        )}

        {mobileSales.length > 0 && (
          <div className="mt-2 flex flex-col gap-3">
            {mobileSales.map((sale) => (
              <MobileSaleCard
                key={sale.id}
                sale={sale}
                artwork={artworkOf(sale.artworkId)}
                onOpen={() => setActive(sale)}
              />
            ))}
          </div>
        )}
      </div>

      {/* Desktop Layout */}
      <div className="hidden lg:block">
        <AdminDataTable
          rows={sales ?? []}
          columns={columns}
          isLoading={isPending}
          getRowKey={(row) => row.id}
          onRowClick={(row) => setActive(row)}
          getRowLabel={(row) => `Open sale for ${row.buyerName}`}
          searchPlaceholder="Search by buyer or artwork"
          searchValue={(row) =>
            `${row.buyerName} ${row.buyerEmail} ${artworkOf(row.artworkId)?.title ?? ""}`
          }
          filters={[
            {
              key: "shipmentStatus",
              label: "Shipment",
              options: SHIPMENT_STATUSES.map((s) => ({
                value: s,
                label: SHIPMENT_LABEL[s],
              })),
              matches: (row, value) => row.shipmentStatus === value,
            },
          ]}
          emptyTitle="No sales yet"
          emptyDescription="Recorded sales from your holdings will show up here."
          emptyIcon={ShoppingBag}
        />
      </div>

      <SaleDetailDialog sale={active} onClose={() => setActive(null)} />
    </>
  );
}

// Small single-select pill dropdown for the mobile filter row — a handful of
// options each, so a Popover + plain button list is enough; no need for the
// search-box overhead a Command combobox brings for 2-3 items.
function MobilePillFilter<T extends string>({
  label,
  value,
  onChange,
  options,
}: {
  label: string;
  value: T | null;
  onChange: (value: T | null) => void;
  options: { value: T; label: string }[];
}) {
  const [open, setOpen] = useState(false);
  const current = options.find((o) => o.value === value)?.label ?? label;

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger
        className={cn(
          "flex shrink-0 items-center gap-2 rounded-md border px-3 py-1.5 text-[13px] font-medium transition-colors",
          value
            ? "border-gold/50 bg-gold/10 text-gold-bright"
            : "border-border bg-muted/20 text-foreground hover:bg-muted/40",
        )}
      >
        {current}
        <ChevronDown className="size-3.5 text-muted-foreground" />
      </PopoverTrigger>
      <PopoverContent align="start" className="w-52 p-1.5">
        <button
          type="button"
          onClick={() => {
            onChange(null);
            setOpen(false);
          }}
          className={cn(
            "block w-full rounded-md px-2.5 py-2 text-left text-sm transition-colors hover:bg-muted",
            value === null ? "text-gold-bright" : "text-foreground/90",
          )}
        >
          {label}
        </button>
        {options.map((option) => (
          <button
            key={option.value}
            type="button"
            onClick={() => {
              onChange(option.value);
              setOpen(false);
            }}
            className={cn(
              "block w-full rounded-md px-2.5 py-2 text-left text-sm transition-colors hover:bg-muted",
              value === option.value ? "text-gold-bright" : "text-foreground/90",
            )}
          >
            {option.label}
          </button>
        ))}
      </PopoverContent>
    </Popover>
  );
}

function MobileSaleCard({
  sale,
  artwork,
  onOpen,
}: {
  sale: AggregatorSale;
  artwork: ArtworkSummary | undefined;
  onOpen: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onOpen}
      className="flex items-center gap-3 rounded-xl border border-border bg-card p-3 text-left transition-colors hover:border-gold/40"
    >
      {artwork && (
        <div className="relative size-14 shrink-0 overflow-hidden rounded-lg bg-muted">
          <Image src={artwork.thumbnailUrl} alt={artwork.title} fill sizes="56px" className="object-cover" />
        </div>
      )}
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium text-foreground">
          {artwork?.title ?? sale.artworkId}
        </p>
        <p className="truncate text-xs text-muted-foreground">{sale.buyerName}</p>
        <div className="mt-1 flex items-center gap-2">
          <PriceTag amount={sale.soldPrice} className="text-sm font-semibold" />
          <span
            className={cn(
              "inline-flex items-center rounded-full border px-2 py-0.5 text-[11px] font-medium whitespace-nowrap",
              SHIPMENT_CLASS[sale.shipmentStatus],
            )}
          >
            {SHIPMENT_LABEL[sale.shipmentStatus]}
          </span>
        </div>
      </div>
      <span className="shrink-0 text-xs text-muted-foreground">
        {new Date(sale.soldAt).toLocaleDateString("en-IN", { day: "numeric", month: "short" })}
      </span>
    </button>
  );
}

function SaleDetailDialog({
  sale,
  onClose,
}: {
  sale: AggregatorSale | null;
  onClose: () => void;
}) {
  const { data: holdings } = useAggregatorCollection();
  const artwork = sale ? holdings?.find((h) => h.artworkId === sale.artworkId)?.artwork : undefined;

  return (
    <Dialog open={Boolean(sale)} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-lg">
        {sale && (
          <>
            <DialogHeader>
              <DialogTitle>{artwork?.title ?? sale.artworkId}</DialogTitle>
              <DialogDescription>
                Sold to {sale.buyerName} for {formatINR(sale.soldPrice)}
              </DialogDescription>
            </DialogHeader>

            <dl className="grid grid-cols-2 gap-x-4 gap-y-3 border-y border-border py-4">
              <Detail label="Buyer email" value={sale.buyerEmail} />
              <Detail label="Buyer phone" value={sale.buyerPhone} />
              <Detail
                label="Delivery mode"
                value={sale.deliveryMode === "courier" ? "Courier" : "Self pickup"}
              />
              <Detail
                label="Commission"
                value={formatINR(commissionForSale(sale, holdings ?? []))}
              />
              <div className="col-span-2 min-w-0">
                <dt className="text-xs text-muted-foreground">Delivery address</dt>
                <dd className="text-sm text-foreground">
                  {sale.deliveryAddress.line1}, {sale.deliveryAddress.city},{" "}
                  {sale.deliveryAddress.state} {sale.deliveryAddress.pincode}
                </dd>
              </div>
              {sale.courierRef && (
                <Detail label="Courier reference" value={sale.courierRef} />
              )}
            </dl>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}

function Detail({ label, value }: { label: string; value: string }) {
  return (
    <div className="min-w-0">
      <dt className="text-xs text-muted-foreground">{label}</dt>
      <dd className="truncate text-sm text-foreground">{value}</dd>
    </div>
  );
}
