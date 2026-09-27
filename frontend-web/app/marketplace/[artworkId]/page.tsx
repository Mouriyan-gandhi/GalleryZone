import { cache } from "react";
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { ArtworkGallery } from "@/features/marketplace/artwork-gallery";
import { ArtworkInfoPanel } from "@/features/marketplace/artwork-info-panel";
import { RelatedArtworksRail } from "@/features/marketplace/related-artworks-rail";
import { artistService, artworkService } from "@/services/artworkService";
import type { ArtistVerificationState } from "@/types/artist";

// react's cache() dedupes this within a single request, so generateMetadata
// and the page component below both calling getArtwork() only pays the mock
// service's 600ms delay once, not twice serially.
const getArtwork = cache((artworkId: string) => artworkService.get(artworkId));

const NO_VERIFICATION: ArtistVerificationState = {
  tier1SocialMedia: false,
  tier2ActivePlan: false,
  tier3FirstSale: false,
};

export async function generateMetadata(
  props: PageProps<"/marketplace/[artworkId]">,
): Promise<Metadata> {
  const { artworkId } = await props.params;
  const artwork = await getArtwork(artworkId);

  if (!artwork) {
    return { title: "Artwork not found | GalleryZone" };
  }

  return {
    title: `${artwork.title} | GalleryZone`,
    description: artwork.description.slice(0, 155),
  };
}

// Async Server Component: does the initial lookup server-side (SAD §5.6 —
// "Server Component initial SEO"), so the page has real content and a real
// 404 before any client JS runs. Only the pieces that genuinely need client
// state — the gallery's zoom dialog and thumbnail selection, the wishlist
// toggle inside ArtworkInfoPanel — are client components; everything else
// here is plain server-rendered markup. Per the Task 15 note: the artist's
// *real* ArtistVerificationState is looked up via artistService (not
// synthesized from artwork.verifiedArtist) so VerifiedBadge can render the
// full Gold ✦ Verified tier when it applies, not just the boolean lower
// bound ArtworkCard is stuck with.
export default async function ArtworkDetailPage(
  props: PageProps<"/marketplace/[artworkId]">,
) {
  const { artworkId } = await props.params;
  const artwork = await getArtwork(artworkId);

  if (!artwork) {
    notFound();
  }

  const artist = await artistService.get(artwork.artistId);
  const verification = artist?.verification ?? NO_VERIFICATION;

  const artistListings = await artworkService.listByArtist(artwork.artistId);
  const related = artistListings
    .filter((item) => item.id !== artwork.id)
    .slice(0, 4);

  return (
    <>
      <SiteHeader />
      <main className="flex flex-1 flex-col">
        <div className="mx-auto w-full max-w-[1200px] px-6 py-10 lg:px-10 lg:py-14">
          <nav
            aria-label="Breadcrumb"
            className="mb-6 flex min-w-0 items-center text-xs text-muted-foreground"
          >
            <Link
              href="/marketplace"
              className="shrink-0 py-1.5 transition-colors hover:text-gold-bright lg:py-0"
            >
              Marketplace
            </Link>
            <span className="mx-1.5" aria-hidden="true">
              /
            </span>
            <span className="truncate text-foreground/80">{artwork.title}</span>
          </nav>

          <div className="grid grid-cols-1 gap-10 lg:grid-cols-2 lg:gap-16">
            <ArtworkGallery images={artwork.images} title={artwork.title} />
            <ArtworkInfoPanel artwork={artwork} verification={verification} />
          </div>

          <RelatedArtworksRail
            artworks={related}
            artistName={artwork.artistName}
          />
        </div>
      </main>
      <SiteFooter />
    </>
  );
}
