"use client";

import { use, useState } from "react";
import { notFound } from "next/navigation";
import Link from "next/link";
import { AdminPageHeader } from "@/features/admin/admin-page-header";
import { UserDetailHeader } from "@/features/admin/people/user-detail-header";
import { AdminStatusBadge } from "@/features/admin/admin-status-badge";
import { useAdminAggregatorPortfolio } from "@/hooks/useAdminUsers";

import { formatINR } from "@/lib/utils";

export default function AdminAggregatorDetailPage(
  props: PageProps<"/admin/aggregators/[aggregatorId]">,
) {
  const [now] = useState(() => Date.now());
  const { aggregatorId } = use(props.params);
  const { data, isLoading } = useAdminAggregatorPortfolio(aggregatorId);

  if (isLoading) return null;
  if (!data) notFound();

  const { user, holdings, commissionPercent } = data;
  const sold = holdings.filter((h) => h.status === "sold_pending_settlement");
  const commissionEarned = sold.reduce((sum, holding) => {
    const markup = holding.displayPrice - holding.artwork.customerPrice;
    return sum + Math.max(0, markup) * (commissionPercent / 100);
  }, 0);

  return (
    <div className="space-y-6">
      <AdminPageHeader
        title={user.companyName ?? user.name}
        description="Aggregator record, current consignments, and commission."
        backHref="/admin/aggregators"
        backLabel="Back to aggregators"
      />

      <UserDetailHeader user={user} />

      {/* grid-cols-1 below sm isn't decorative — see app/admin/page.tsx's
          identical comment: an implicit grid track sizes to its widest
          child's min-content instead of shrinking, overflowing the page. */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        <Stat
          label="Active holdings"
          value={String(holdings.filter((h) => h.status === "reserved").length)}
        />
        <Stat label="Sales closed" value={String(sold.length)} />
        <Stat
          label="Commission earned"
          value={formatINR(Math.round(commissionEarned))}
        />
      </div>

      <section className="rounded-xl border border-border bg-card">
        <div className="border-b border-border px-5 py-4">
          <h2 className="font-display text-base font-semibold text-foreground">
            Consignments
          </h2>
          <p className="mt-0.5 text-xs text-muted-foreground">
            Works currently held, and their 30-day display windows.
          </p>
        </div>

        {holdings.length === 0 ? (
          <p className="px-5 py-8 text-center text-sm text-muted-foreground">
            No works on consignment.
          </p>
        ) : (
          <ul className="divide-y divide-border">
            {holdings.map((holding) => {
              const daysLeft = Math.max(
                0,
                Math.round(
                  (new Date(holding.expiresAt).getTime() - now) /
                    86_400_000,
                ),
              );
              return (
                <li key={holding.id}>
                  <Link
                    href={`/admin/artworks/${holding.artworkId}`}
                    className="flex flex-wrap items-center gap-3 px-5 py-3.5 transition-colors hover:bg-accent/40"
                  >
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-foreground">
                        {holding.artwork.title}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {holding.advancePercent}% advance ·{" "}
                        {formatINR(holding.advanceAmount)} paid
                      </p>
                    </div>
                    <span className="text-sm tabular-nums text-foreground">
                      {formatINR(holding.displayPrice)}
                    </span>
                    <span
                      className={`text-xs tabular-nums ${daysLeft <= 3 ? "font-medium text-destructive" : "text-muted-foreground"}`}
                    >
                      {holding.status === "sold_pending_settlement"
                        ? "Sold"
                        : `${daysLeft}d left`}
                    </span>
                    <AdminStatusBadge status={holding.artwork.status} size="sm" />
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </section>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
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
