"use client";

import { AdminPageHeader } from "@/features/admin/admin-page-header";
import { AdminKpiGrid } from "@/features/admin/overview/admin-kpi-grid";
import { AdminActivityFeed } from "@/features/admin/overview/admin-activity-feed";
import { AdminRevenueOverview } from "@/features/admin/overview/admin-revenue-overview";

export default function AdminOverviewPage() {
  return (
    <div className="space-y-6">
      <AdminPageHeader
        title="Overview"
        description="Platform health, and whatever is waiting on you."
      />

      <AdminKpiGrid />

      {/* grid-cols-1 below lg isn't decorative: with no column utility at
          all, an implicit grid track sizes to its child's min-content (a
          chart's axis + margins can't shrink past some floor), overflowing
          the page instead of shrinking the chart. Tailwind's grid-cols-1
          uses minmax(0, 1fr), which is what actually fixes it. */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-[1.35fr_1fr]">
        <AdminRevenueOverview />
        <AdminActivityFeed />
      </div>
    </div>
  );
}
