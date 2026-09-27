"use client";

import { useMemo, useState } from "react";
import {
  Area,
  AreaChart,
  CartesianGrid,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Check } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { InstagramGlyph } from "@/components/social-icons";
import { useArtistDashboardArtworks } from "@/hooks/useArtistArtworks";
import { useArtistOrders } from "@/hooks/useArtistOrders";
import {
  useArtistAccountProfile,
  useSaveArtistProfileMutation,
} from "@/hooks/useArtistAccount";
import {
  ChartCard,
  ChartTooltipContent,
} from "@/features/admin/charts/chart-card";
import {
  axisChrome,
  CHART_HEIGHT,
  CHART_MARGIN,
  crosshairCursor,
  formatCompactINR,
  gridChrome,
  rampVar,
  tickInterval,
} from "@/features/admin/charts/chart-theme";
import { CategoryBarChart } from "@/features/admin/charts/category-bar-chart";
import { FunnelChart } from "@/features/admin/charts/funnel-chart";
import type {
  CategoryPerformance,
  FunnelStage,
} from "@/types/admin-analytics";
import { useArtistRevenueSeries } from "@/hooks/useArtistRevenue";
import { formatINR } from "@/lib/utils";

export function ArtistAnalyticsView() {
  const { data: artworks } = useArtistDashboardArtworks();
  const { data: orders } = useArtistOrders();

  const rows = artworks ?? [];
  const soldRows = orders ?? [];

  const totalRevenue = soldRows.reduce((sum, o) => sum + o.artistPayout, 0);
  const salesCount = soldRows.length;
  const avgSale = salesCount > 0 ? Math.round(totalRevenue / salesCount) : 0;

  const categoryData = useMemo<CategoryPerformance[]>(() => {
    const byCategory = new Map<string, { revenue: number; orders: number }>();
    for (const artwork of artworks ?? []) {
      const entry = byCategory.get(artwork.category) ?? {
        revenue: 0,
        orders: 0,
      };
      if (
        artwork.status === "sold" ||
        artwork.status === "settlement_complete"
      ) {
        entry.revenue += artwork.customerPrice;
        entry.orders += 1;
      }
      byCategory.set(artwork.category, entry);
    }
    return Array.from(byCategory.entries()).map(([category, v]) => ({
      category,
      revenue: v.revenue,
      orders: v.orders,
    }));
  }, [artworks]);

  const funnelData = useMemo<FunnelStage[]>(() => {
    const counts = { draft: 0, pending_approval: 0, live: 0, sold: 0 };
    for (const artwork of artworks ?? []) {
      if (artwork.status === "draft") counts.draft += 1;
      else if (artwork.status === "pending_approval")
        counts.pending_approval += 1;
      else if (
        artwork.status === "sold" ||
        artwork.status === "settlement_complete"
      )
        counts.sold += 1;
      else counts.live += 1;
    }
    return [
      { stage: "Draft", count: counts.draft },
      { stage: "Pending Approval", count: counts.pending_approval },
      { stage: "Live", count: counts.live },
      { stage: "Sold", count: counts.sold },
    ];
  }, [artworks]);

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <SummaryStat label="Total artworks" value={String(rows.length)} />
        <SummaryStat label="Total sales" value={String(salesCount)} />
        <SummaryStat label="Total revenue" value={formatINR(totalRevenue)} />
        <SummaryStat label="Avg. sale price" value={formatINR(avgSale)} />
      </div>

      <InstagramConnectCard />

      <ArtistRevenueChart />

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <CategoryBarChart
          data={categoryData}
          description="Your own settled sales, by category."
        />
        <FunnelChart
          data={funnelData}
          title="Artwork status"
          description="Where your artworks currently sit, by count."
        />
      </div>
    </div>
  );
}

function ArtistRevenueChart() {
  const { series } = useArtistRevenueSeries();
  const points = series.map((p) => ({
    label: p.month,
    amount: p.amount,
  }));
  const isEmpty = points.length === 0;

  return (
    <ChartCard
      title="Revenue trend"
      description="Your settled earnings, last 6 months."
      seriesCount={1}
      height={CHART_HEIGHT.default}
      isEmpty={isEmpty}
      emptyTitle="No revenue yet"
      emptyDescription="Settled sales will show up here."
      ariaLabel={`Area chart of monthly revenue, last 6 months, totaling ${formatINR(
        points.reduce((sum, p) => sum + p.amount, 0),
      )}.`}
    >
      <AreaChart data={points} margin={CHART_MARGIN} accessibilityLayer={false}>
        <CartesianGrid {...gridChrome} vertical={false} />
        <XAxis
          {...axisChrome}
          dataKey="label"
          interval={tickInterval(points.length)}
          minTickGap={16}
        />
        <YAxis {...axisChrome} width={56} tickFormatter={formatCompactINR} />
        <Tooltip
          cursor={crosshairCursor}
          content={
            <ChartTooltipContent
              formatValue={formatINR}
              nameByKey={{ amount: "Revenue" }}
            />
          }
        />
        <Area
          type="monotone"
          dataKey="amount"
          name="Revenue"
          fill={rampVar(0)}
          fillOpacity={0.25}
          stroke={rampVar(0)}
          strokeWidth={2}
          isAnimationActive={false}
        />
      </AreaChart>
    </ChartCard>
  );
}

// The handle itself is collected once, on the Profile page (it's a required,
// admin-only field there — see profile-kyc-form.tsx). This card is where the
// artist sees and manages that connection alongside their other performance
// data, rather than analytics quietly reading a field it doesn't own.
function InstagramConnectCard() {
  const { data: profile } = useArtistAccountProfile();
  const saveMutation = useSaveArtistProfileMutation();
  const [editing, setEditing] = useState(false);
  const [handle, setHandle] = useState("");

  if (!profile) return null;

  const connected = profile.instagram.trim().length > 0;

  if (!editing) {
    return (
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border bg-card p-4">
        <div className="flex items-center gap-3">
          <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-gold/30 bg-background">
            <InstagramGlyph className="size-4 text-gold-bright" />
          </span>
          <div>
            <p className="text-sm font-medium text-foreground">Instagram</p>
            <p className="text-xs text-muted-foreground">
              {connected ? `@${profile.instagram}` : "Not connected"}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          {connected && (
            <span className="flex items-center gap-1.5 text-xs font-medium text-emerald-500">
              <Check className="size-3.5" />
              Connected
            </span>
          )}
          <button
            type="button"
            onClick={() => {
              setHandle(profile.instagram);
              setEditing(true);
            }}
            className="text-xs font-medium text-gold-bright hover:underline"
          >
            {connected ? "Update" : "Connect"}
          </button>
        </div>
      </div>
    );
  }

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        if (handle.trim().length === 0) return;
        saveMutation.mutate(
          { instagram: handle.trim() },
          { onSuccess: () => setEditing(false) },
        );
      }}
      className="flex flex-col gap-3 rounded-xl border border-gold/30 bg-card p-4 sm:flex-row sm:items-end"
    >
      <div className="flex flex-1 flex-col gap-1.5">
        <Label htmlFor="analyticsInstagram">Instagram handle</Label>
        <div className="relative">
          <InstagramGlyph className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            id="analyticsInstagram"
            value={handle}
            onChange={(e) => setHandle(e.target.value)}
            placeholder="yourhandle"
            className="h-9 pl-9"
          />
        </div>
        <p className="text-xs text-muted-foreground">
          This is the same handle saved on your Profile page.
        </p>
      </div>
      <div className="flex items-center gap-2">
        <button
          type="submit"
          disabled={saveMutation.isPending}
          className="rounded-md bg-gradient-to-b from-gold-bright to-gold px-4 py-2 text-xs font-semibold text-[#171310] disabled:pointer-events-none disabled:opacity-60"
        >
          {saveMutation.isPending ? "Saving…" : "Save"}
        </button>
        <button
          type="button"
          onClick={() => setEditing(false)}
          className="rounded-md border border-border px-4 py-2 text-xs font-medium text-foreground hover:bg-secondary"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}

function SummaryStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <p className="text-xs font-medium tracking-[0.08em] text-muted-foreground uppercase">
        {label}
      </p>
      <p className="mt-2 font-display text-xl font-semibold tabular-nums text-foreground">
        {value}
      </p>
    </div>
  );
}
