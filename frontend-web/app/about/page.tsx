import type { Metadata } from "next";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { AboutOverviewSection } from "@/features/about/about-overview-section";
import { AboutMissionSection } from "@/features/about/about-mission-section";
import { AboutTeamSection } from "@/features/about/about-team-section";
import { VerificationTiersSection } from "@/features/about/verification-tiers-section";
import { TechFeaturesSection } from "@/features/about/tech-features-section";

export const metadata: Metadata = {
  title: "About | GalleryZone",
  description:
    "How GalleryZone protects artist pricing, verifies authenticity, and connects original art to collectors and galleries worldwide.",
};

export default function AboutPage() {
  return (
    <>
      <SiteHeader />
      <main className="flex flex-1 flex-col">
        <AboutOverviewSection />
        <AboutMissionSection />
        <AboutTeamSection />
        <VerificationTiersSection />
        <TechFeaturesSection />
      </main>
      <SiteFooter />
    </>
  );
}
