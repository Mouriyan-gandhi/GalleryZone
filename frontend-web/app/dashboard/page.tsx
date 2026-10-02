import type { Metadata } from "next";
import { KpiCards } from "@/features/dashboard/kpi-cards";
import { VerificationProgress } from "@/features/dashboard/verification-progress";
import { RecentActivityFeed } from "@/features/dashboard/recent-activity-feed";
import { RevenueChart } from "@/features/dashboard/revenue-chart";
import { RatingCard } from "@/features/dashboard/rating-card";
import { DashboardGreeting } from "@/features/dashboard/dashboard-greeting";
import { FreeAccessNote } from "@/features/dashboard/free-access-note";
import { NextActionCard } from "@/features/dashboard/next-action-card";
import { ArtworkOverviewCard } from "@/features/dashboard/artwork-overview-card";
import { NeedsAttentionCard } from "@/features/dashboard/needs-attention-card";

export const metadata: Metadata = {
  title: "Dashboard | GalleryZone",
};

export default function DashboardOverviewPage() {
  return (
    <>
      {/* Mobile: purpose-built order — status, next action, artworks,
          attention, earnings, activity — instead of the desktop grid
          squeezed into one column. */}
      <div className="flex flex-col gap-5 lg:hidden">
        <DashboardGreeting />
        <FreeAccessNote />
        <VerificationProgress />
        <NextActionCard />
        <ArtworkOverviewCard />
        <NeedsAttentionCard />
        <KpiCards />
        <RecentActivityFeed />
      </div>

      {/* Desktop/tablet: unchanged. */}
      <div className="hidden lg:flex lg:flex-col lg:gap-6">
        <FreeAccessNote />
        <KpiCards />

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1.4fr_1fr]">
          <RevenueChart />
          <VerificationProgress />
        </div>

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1fr_1.4fr]">
          <RatingCard />
          <RecentActivityFeed />
        </div>
      </div>
    </>
  );
}
