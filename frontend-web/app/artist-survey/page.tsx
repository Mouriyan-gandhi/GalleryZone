import type { Metadata } from "next";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { ArtistSurveyForm } from "@/features/artist-survey/artist-survey-form";

export const metadata: Metadata = {
  title: "Artist Information and Art Type Survey | GalleryZone",
  description:
    "A short survey for artists. No GalleryZone account needed to fill it out.",
};

export default function ArtistSurveyPage() {
  return (
    <>
      <SiteHeader />
      <main className="flex flex-1 flex-col px-4 py-10 sm:px-6 sm:py-16 lg:px-10 lg:py-20">
        <ArtistSurveyForm />
      </main>
      <SiteFooter />
    </>
  );
}
