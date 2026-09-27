"use client";

import Link from "next/link";
import {
  IndianRupee,
  Landmark,
  Palette,
  ShoppingBag,
  Users,
  Wallet,
  ImageIcon,
  BadgeCheck,
  Banknote,
  ArrowUpRight,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { useAdminKpis } from "@/hooks/useAdminDashboard";
import { formatINR, cn } from "@/lib/utils";

// ---------------------------------------------------------------------------
// Nine tiles, split into two ranks that are read differently:
//
//   - Six informational tiles: what the platform has done. Glanced at.
//   - Three queue tiles: what is waiting for THIS admin, right now. These are
//     actionable, so they are visually separated, gold-edged, and link
//     straight into their queue. A count you cannot act on and a count that is
//     your job to clear should not look identical.
//
// A queue at zero is deliberately styled DOWN rather than up — "nothing
// waiting" is good news, and shouting it would train admins to ignore the
// same shape when it is not zero.
// ---------------------------------------------------------------------------

function formatCount(value: number): string {
  return new Intl.NumberFormat("en-IN").format(value);
}

interface StatTile {
  key: string;
  label: string;
  icon: LucideIcon;
  value: (k: NonNullable<ReturnType<typeof useAdminKpis>["data"]>) => string;
  hint?: string;
}

const MONEY_TILES: StatTile[] = [
  {
    key: "gmv",
    label: "Gross merchandise value",
    icon: IndianRupee,
    value: (k) => formatINR(k.gmv),
    hint: "All confirmed sales, both channels",
  },
  {
    key: "platformRevenue",
    label: "Platform revenue",
    icon: Landmark,
    value: (k) => formatINR(k.platformRevenue),
    hint: "Markup retained after payouts",
  },
  {
    key: "artistPayouts",
    label: "Artist payouts",
    icon: Wallet,
    value: (k) => formatINR(k.artistPayouts),
    hint: "Settled to artist wallets",
  },
];

const COUNT_TILES: StatTile[] = [
  {
    key: "totalOrders",
    label: "Orders",
    icon: ShoppingBag,
    value: (k) => formatCount(k.totalOrders),
  },
  {
    key: "activeArtworks",
    label: "Live artworks",
    icon: Palette,
    value: (k) => formatCount(k.activeArtworks),
  },
  {
    key: "totalUsers",
    label: "Users",
    icon: Users,
    value: (k) => formatCount(k.totalUsers),
  },
];

interface QueueTile {
  key: string;
  label: string;
  icon: LucideIcon;
  href: string;
  count: (k: NonNullable<ReturnType<typeof useAdminKpis>["data"]>) => number;
}

const QUEUE_TILES: QueueTile[] = [
  {
    key: "artworks",
    label: "Artworks to review",
    icon: ImageIcon,
    href: "/admin/moderation/artworks",
    count: (k) => k.pendingArtworkApprovals,
  },
  {
    key: "kyc",
    label: "KYC to verify",
    icon: BadgeCheck,
    href: "/admin/moderation/kyc",
    count: (k) => k.pendingKyc,
  },
  {
    key: "withdrawals",
    label: "Withdrawals to approve",
    icon: Banknote,
    href: "/admin/moderation/withdrawals",
    count: (k) => k.pendingWithdrawals,
  },
];

export function AdminKpiGrid() {
  const { data: kpis, isPending } = useAdminKpis();

  if (isPending || !kpis) {
    return (
      <div className="space-y-4">
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="h-[104px] rounded-xl" />
          ))}
        </div>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-[92px] rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {MONEY_TILES.map((tile) => (
          <StatCard key={tile.key} tile={tile} kpis={kpis} emphasis />
        ))}
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        {COUNT_TILES.map((tile) => (
          <StatCard key={tile.key} tile={tile} kpis={kpis} />
        ))}
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        {QUEUE_TILES.map((tile) => {
          const count = tile.count(kpis);
          return <QueueCard key={tile.key} tile={tile} count={count} />;
        })}
      </div>
    </div>
  );
}

function StatCard({
  tile,
  kpis,
  emphasis = false,
}: {
  tile: StatTile;
  kpis: NonNullable<ReturnType<typeof useAdminKpis>["data"]>;
  emphasis?: boolean;
}) {
  const Icon = tile.icon;
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <div className="flex items-start justify-between gap-3">
        <p className="text-xs font-medium tracking-[0.08em] text-muted-foreground uppercase">
          {tile.label}
        </p>
        <Icon
          className="size-4 shrink-0 text-muted-foreground/70"
          strokeWidth={1.75}
        />
      </div>
      <p
        className={cn(
          "mt-3 font-display font-semibold tabular-nums text-foreground",
          emphasis ? "text-2xl" : "text-xl",
        )}
      >
        {tile.value(kpis)}
      </p>
      {tile.hint ? (
        <p className="mt-1 text-xs text-muted-foreground">{tile.hint}</p>
      ) : null}
    </div>
  );
}

function QueueCard({ tile, count }: { tile: QueueTile; count: number }) {
  const Icon = tile.icon;
  const waiting = count > 0;

  return (
    <Link
      href={tile.href}
      className={cn(
        "group flex items-center gap-4 rounded-xl border p-4 transition-colors",
        waiting
          ? "border-gold/45 bg-gold/[0.06] hover:border-gold hover:bg-gold/10"
          : "border-border bg-card hover:bg-accent/50",
      )}
    >
      <span
        className={cn(
          "flex size-10 shrink-0 items-center justify-center rounded-lg",
          waiting
            ? "bg-gold/15 text-gold-bright"
            : "bg-muted text-muted-foreground",
        )}
      >
        <Icon className="size-5" strokeWidth={1.75} />
      </span>

      <div className="min-w-0 flex-1">
        <p className="text-sm font-medium text-foreground">{tile.label}</p>
        <p
          className={cn(
            "font-display text-xl font-semibold tabular-nums",
            waiting ? "text-gold-bright" : "text-muted-foreground",
          )}
        >
          {waiting ? count : "Clear"}
        </p>
      </div>

      <ArrowUpRight
        className={cn(
          "size-4 shrink-0 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5",
          waiting ? "text-gold-bright" : "text-muted-foreground/60",
        )}
      />
    </Link>
  );
}
