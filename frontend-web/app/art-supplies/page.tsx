import type { Metadata } from "next";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { SuppliesShelf } from "@/features/art-supplies/supplies-shelf";

export const metadata: Metadata = {
  title: "Art Supplies | GalleryZone",
  description:
    "Brushes, paints, canvases and tools recommended by GalleryZone for working artists, available on Amazon.",
};

export default function ArtSuppliesPage() {
  return (
    <>
      <SiteHeader />
      <main className="flex flex-1 flex-col">
        <SuppliesShelf />
      </main>
      <SiteFooter />
    </>
  );
}
