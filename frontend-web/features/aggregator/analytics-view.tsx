"use client";

import { useAggregatorCollection } from "@/hooks/useAggregatorCollection";

import { useMemo } from "react";
import { useAggregatorAnalytics } from "@/hooks/useAggregatorAnalytics";
import { useAggregatorSales } from "@/hooks/useAggregatorSales";
import { CategoryBarChart } from "@/features/admin/charts/category-bar-chart";
import type { CategoryPerformance } from "@/types/admin-analytics";
import { formatINR } from "@/lib/utils";

export function AnalyticsView() {
  const { data: summary, isPending } = useAggregatorAnalytics();
  const { data: sales } = useAggregatorSales();
  const { data: holdings } = useAggregatorCollection();

  const categoryData = useMemo<CategoryPerformance[]>(() => {
    const byCategory = new Map<string, { revenue: number; orders: number }>();
    for (const sale of sales ?? []) {
      const artwork = holdings?.find((h) => h.artworkId === sale.artworkId)?.artwork;
      if (!artwork) continue;
      const entry = byCategory.get(artwork.category) ?? {
        revenue: 0,
        orders: 0,
      };
      entry.revenue += sale.soldPrice;
      entry.orders += 1;
      byCategory.set(artwork.category, entry);
    }
    return Array.from(byCategory.entries()).map(([category, v]) => ({
      category,
      revenue: v.revenue,
      orders: v.orders,
    }));
  }, [sales]);

  return (
    <div className="flex flex-col gap-4">
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <SummaryStat
          label="Sales recorded"
          value={isPending ? "—" : String(summary?.salesCount ?? 0)}
        />
        <SummaryStat
          label="Total revenue"
          value={isPending ? "—" : formatINR(summary?.totalRevenue ?? 0)}
        />
        <SummaryStat
          label="Avg. sold price"
          value={isPending ? "—" : formatINR(summary?.averageSoldPrice ?? 0)}
        />
        <SummaryStat
          label="Avg. display markup"
          value={
            isPending ? "—" : formatINR(summary?.averageDisplayMarkup ?? 0)
          }
        />
      </div>

      <CategoryBarChart
        data={categoryData}
        title="Top categories moved"
        description="Revenue from your recorded sales, by artwork category."
      />
    </div>
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
