"use client";

import type { TopPerformer } from "@/types/admin-analytics";
import { formatINR } from "@/lib/utils";

// Two compact ranked lists side by side. A bar chart of eight names would
// waste width on labels; the numbers are the point here, so they are set in
// tabular figures and right-aligned to compare down the column.
export function TopPerformersTable({
  artists,
  aggregators,
}: {
  artists: TopPerformer[];
  aggregators: TopPerformer[];
}) {
  return (
    <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
      <PerformerPanel
        title="Top artists"
        description="By revenue generated, trailing twelve months."
        countLabel="works sold"
        rows={artists}
      />
      <PerformerPanel
        title="Top aggregators"
        description="By commission earned, trailing twelve months."
        countLabel="sales closed"
        rows={aggregators}
      />
    </div>
  );
}

function PerformerPanel({
  title,
  description,
  countLabel,
  rows,
}: {
  title: string;
  description: string;
  countLabel: string;
  rows: TopPerformer[];
}) {
  const leader = rows[0]?.revenue ?? 0;

  return (
    <div className="rounded-xl border border-border bg-card">
      <div className="border-b border-border px-5 py-4">
        <h3 className="font-display text-base font-semibold text-foreground">
          {title}
        </h3>
        <p className="mt-0.5 text-xs text-muted-foreground">{description}</p>
      </div>

      <ol className="divide-y divide-border">
        {rows.map((row, index) => (
          <li key={row.name} className="relative px-5 py-3">
            {/* A hairline share bar behind the row: rank is legible at a
                glance without spending a whole column on a chart. */}
            <span
              aria-hidden
              className="absolute inset-y-0 left-0 bg-gold/[0.07]"
              style={{
                width: leader > 0 ? `${(row.revenue / leader) * 100}%` : "0%",
              }}
            />
            <div className="relative flex items-baseline gap-3">
              <span className="w-4 shrink-0 text-xs tabular-nums text-muted-foreground/70">
                {index + 1}
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium text-foreground">
                  {row.name}
                </p>
                <p className="text-xs text-muted-foreground">
                  {row.count} {countLabel}
                </p>
              </div>
              <span className="shrink-0 text-sm font-semibold tabular-nums text-foreground">
                {formatINR(row.revenue)}
              </span>
            </div>
          </li>
        ))}
      </ol>
    </div>
  );
}
