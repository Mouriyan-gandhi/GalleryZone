"use client";

import { useState } from "react";
import { RangeSelector } from "./range-selector";
import { TopPerformersTable } from "./top-performers-table";
import { RevenueAreaChart } from "@/features/admin/charts/revenue-area-chart";
import { VolumeBarChart } from "@/features/admin/charts/volume-bar-chart";
import { CategoryBarChart } from "@/features/admin/charts/category-bar-chart";
import { FunnelChart } from "@/features/admin/charts/funnel-chart";
import { GrowthLineChart } from "@/features/admin/charts/growth-line-chart";
import { TierDonutChart } from "@/features/admin/charts/tier-donut-chart";
import {
  type RangeKey,
} from "@/types/admin-analytics";
import { useAdminAnalytics } from "@/hooks/useAdminAnalytics";
import { formatINR } from "@/lib/utils";

const RANGE_LABEL: Record<RangeKey, string> = {
  "30d": "Last 30 days",
  "90d": "Last 90 days",
  "12m": "Last 12 months",
};

export function AnalyticsView() {
  const [range, setRange] = useState<RangeKey>("30d");

  const { revenue, volume, growth, categoryPerformance, funnel: artworkFunnel, tiers: verificationTiers, topArtists, topAggregators } = useAdminAnalytics(range);

  const gmv = revenue.reduce((sum, p) => sum + p.gmv, 0);
  const platform = revenue.reduce((sum, p) => sum + p.platform, 0);
  const artist = revenue.reduce((sum, p) => sum + p.artist, 0);
  const orders = volume.reduce((sum, p) => sum + p.orders, 0);

  const rangeLabel = RANGE_LABEL[range];

  return (
    <div className="space-y-4">
      {/* The range control governs every time-series below it, so it sits
          once at the top rather than being repeated per card. */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <p className="text-sm text-muted-foreground">
          Showing{" "}
          <span className="font-medium text-foreground">
            {rangeLabel.toLowerCase()}
          </span>
        </p>
        <RangeSelector value={range} onChange={setRange} />
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <SummaryStat label="GMV" value={formatINR(gmv)} note={rangeLabel} />
        <SummaryStat
          label="Platform revenue"
          value={formatINR(platform)}
          note={rangeLabel}
        />
        <SummaryStat
          label="Artist payouts"
          value={formatINR(artist)}
          note={rangeLabel}
        />
        <SummaryStat
          label="Orders"
          value={new Intl.NumberFormat("en-IN").format(orders)}
          note={rangeLabel}
        />
      </div>

      {/* Full-width: the headline series, and the only one worth reading
          point-by-point. */}
      <RevenueAreaChart
        data={revenue}
        description={`${rangeLabel}, by where each rupee lands.`}
      />

      {/* Paired: two different questions at the same altitude. */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <VolumeBarChart
          data={volume}
          description={`Completed orders, ${rangeLabel.toLowerCase()}.`}
        />
        <CategoryBarChart data={categoryPerformance} />
      </div>

      {/* Paired: both are compositional rather than temporal, so they read
          together and neither needs the range control. */}
      {/* grid-cols-1 below lg isn't decorative — see app/admin/page.tsx's
          identical comment: an implicit grid track sizes to its widest
          child's min-content instead of shrinking, overflowing the page. */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-[1.25fr_1fr]">
        <FunnelChart data={artworkFunnel} />
        <TierDonutChart data={verificationTiers} />
      </div>

      <GrowthLineChart
        data={growth}
        description={`Cumulative accounts, ${rangeLabel.toLowerCase()}.`}
      />

      <TopPerformersTable artists={topArtists} aggregators={topAggregators} />
    </div>
  );
}

function SummaryStat({
  label,
  value,
  note,
}: {
  label: string;
  value: string;
  note: string;
}) {
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <p className="text-xs font-medium tracking-[0.08em] text-muted-foreground uppercase">
        {label}
      </p>
      <p className="mt-2 font-display text-xl font-semibold tabular-nums text-foreground">
        {value}
      </p>
      <p className="mt-0.5 text-xs text-muted-foreground">{note}</p>
    </div>
  );
}
