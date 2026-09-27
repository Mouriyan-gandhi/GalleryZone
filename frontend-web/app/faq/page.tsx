import type { Metadata } from "next";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { FaqTabs } from "@/features/faq/faq-tabs";

export const metadata: Metadata = {
  title: "FAQ | GalleryZone",
  description:
    "Answers on pricing privacy, settlement timing, verification tiers, reservations, and buyer rights, organized by who's asking.",
};

export default function FaqPage() {
  return (
    <>
      <SiteHeader />
      <main className="flex flex-1 flex-col">
        <section className="relative overflow-hidden py-14 sm:py-20 md:py-28">
          <div className="mx-auto max-w-4xl px-6 lg:px-10">
            <h1 className="text-balance font-display text-4xl leading-[1.15] font-semibold sm:text-5xl">
              Frequently asked questions.
            </h1>
            <p className="mt-5 max-w-xl text-balance text-base leading-relaxed text-muted-foreground">
              How pricing privacy, settlements, verification, and buyer rights
              work on GalleryZone, organized by who&rsquo;s asking.
            </p>

            <div className="mt-12">
              <FaqTabs />
            </div>
          </div>
        </section>
      </main>
      <SiteFooter />
    </>
  );
}
