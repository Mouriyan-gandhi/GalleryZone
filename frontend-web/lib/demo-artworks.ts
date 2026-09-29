import type {
  Artwork,
  ArtworkFilters,
  ArtworkRarity,
  ArtworkSizeBand,
  ArtworkStatus,
  ArtworkSummary,
  MarketplaceFacets,
  MarketplacePage,
} from "@/types/artwork";

// Local-preview paintings, so the marketplace grid and its paging can be seen
// with more than the handful of live listings.
//
// NOTHING may import this module statically — that is what put these invented
// artists into the production client bundle. Import the gate from
// ./demo-artworks-flag, then `await import()` this file inside the gated
// branch. See that file's header for the full reasoning.
import { isDemoId } from "./demo-artworks-flag";

export { isDemoId };

const ARTISTS = {
  kabir: { id: "demo-artist-kabir", name: "Kabir Shekhawat", location: "Jodhpur, Rajasthan" },
  rohan: { id: "demo-artist-rohan", name: "Rohan Bhatt", location: "Udaipur, Rajasthan" },
  meera: { id: "demo-artist-meera", name: "Meera Rathore", location: "Jaipur, Rajasthan" },
  sanjukta: { id: "demo-artist-sanjukta", name: "Sanjukta Mohapatra", location: "Puri, Odisha" },
  anaya: { id: "demo-artist-anaya", name: "Anaya Iyer", location: "Thanjavur, Tamil Nadu" },
  arjun: { id: "demo-artist-arjun", name: "Arjun Nair", location: "Kochi, Kerala" },
  devika: { id: "demo-artist-devika", name: "Devika Menon", location: "Bengaluru, Karnataka" },
  ishita: { id: "demo-artist-ishita", name: "Ishita Sen", location: "Kolkata, West Bengal" },
};

const STYLES = [
  {
    image: "/artworks/bird.png",
    category: "painting",
    medium: "natural-colours-on-handmade-paper",
    artists: [ARTISTS.kabir, ARTISTS.rohan],
    titles: ["Caravan under the Flame Tree", "Desert Wanderer", "Thar Evening", "Camel of the Blooming Tree"],
  },
  {
    image: "/artworks/collage-busts.png",
    category: "painting",
    medium: "gouache-on-paper",
    artists: [ARTISTS.meera],
    titles: ["Royal Procession", "The Garden Elephant", "Mangal Kala", "Elephant and Rose Vine"],
  },
  {
    image: "/artworks/draped-figure.png",
    category: "painting",
    medium: "natural-pigments-on-cloth",
    artists: [ARTISTS.sanjukta],
    titles: ["Under the Kadamba Tree", "Flute at Dusk", "Rasa Leela", "Divine Union"],
  },
  {
    image: "/artworks/landscape.png",
    category: "painting",
    medium: "acrylic-and-gold-leaf-on-canvas",
    artists: [ARTISTS.anaya, ARTISTS.arjun],
    titles: ["Bal Gopal", "Golden Aura", "Tanjore Blue", "Krishna in Gold"],
  },
  {
    image: "/artworks/portrait-woman.png",
    category: "painting",
    medium: "watercolor",
    artists: [ARTISTS.devika],
    titles: ["Water Bearer of Jaisalmer", "Morning at the Well", "Pink and Brass", "Shadow on the Wall"],
  },
  {
    image: "/artworks/hero-original-art.png",
    category: "mixed-media",
    medium: "mixed-media-with-gold-leaf",
    artists: [ARTISTS.ishita],
    titles: ["Still Life with Blue Bird", "Quiet Vessel", "Gilded Morning", "Earth and Leaf"],
  },
];

const PRICES = [
  18500, 42000, 27800, 64500, 12400, 36900, 9800, 118000, 23600, 51200, 31750, 7400,
  88000, 15900, 46300, 29100, 142000, 19750, 57800, 11200, 34400, 72500, 24900, 185000,
];
const DIMENSIONS = ["12 x 16 in", "24 x 30 in", "18 x 24 in", "36 x 48 in", "16 x 20 in", "30 x 40 in"];
const SIZE_OF: Record<string, ArtworkSizeBand> = {
  "12 x 16 in": "small",
  "16 x 20 in": "small",
  "18 x 24 in": "medium",
  "24 x 30 in": "medium",
  "30 x 40 in": "large",
  "36 x 48 in": "large",
};
const RANKS: Partial<Record<number, ArtworkRarity>> = { 2: "R", 7: "U", 11: "O", 16: "N" };
const STATUSES: Partial<Record<number, ArtworkStatus>> = { 9: "reserved", 19: "sold" };

// Round-robin across styles so neighbouring cards never share a painting.
export const DEMO_ARTWORKS: ArtworkSummary[] = [0, 1, 2, 3].flatMap((round) =>
  STYLES.map((style, s) => {
    const n = round * STYLES.length + s;
    const artist = style.artists[round % style.artists.length];
    const dimensions = DIMENSIONS[n % DIMENSIONS.length];
    return {
      id: `demo-${n + 1}`,
      title: style.titles[round],
      artistId: artist.id,
      artistName: artist.name,
      verifiedArtist: false,
      category: style.category,
      medium: style.medium,
      customerPrice: PRICES[n],
      thumbnailUrl: style.image,
      insured: n % 5 === 3,
      status: STATUSES[n] ?? "marketplace",
      listingType: "marketplace_only",
      rarityType: RANKS[n] ?? null,
      yearCreated: 2026 - (n % 7),
      dimensions,
      coaCertificateNumber: `GZ-COA-DEMO-${String(n + 1).padStart(4, "0")}`,
      sizeBand: SIZE_OF[dimensions],
      artistLocation: artist.location,
    } satisfies ArtworkSummary;
  }),
);

function matches(a: ArtworkSummary, f: ArtworkFilters): boolean {
  const q = f.query?.trim().toLowerCase();
  return (
    (!f.category?.length || f.category.includes(a.category)) &&
    (!f.medium?.length || f.medium.includes(a.medium)) &&
    (!f.rarity || a.rarityType === f.rarity) &&
    (!f.artistId || a.artistId === f.artistId) &&
    (!f.location || a.artistLocation === f.location) &&
    (!f.size || a.sizeBand === f.size) &&
    (f.minPrice === undefined || a.customerPrice >= f.minPrice) &&
    (f.maxPrice === undefined || a.customerPrice <= f.maxPrice) &&
    (!q || [a.title, a.artistName, a.medium, a.category].some((v) => v.toLowerCase().includes(q)))
  );
}

function union<T>(a: T[], b: T[], key: (item: T) => string = String): T[] {
  const seen = new Set<string>();
  return [...a, ...b].filter((item) => {
    const k = key(item);
    if (seen.has(k)) return false;
    seen.add(k);
    return true;
  });
}

function demoFacets(real: MarketplaceFacets): MarketplaceFacets {
  const rarityCounts = { ...real.rarityCounts };
  for (const a of DEMO_ARTWORKS) {
    if (a.rarityType) rarityCounts[a.rarityType] = (rarityCounts[a.rarityType] ?? 0) + 1;
  }
  const prices = DEMO_ARTWORKS.map((a) => a.customerPrice);
  return {
    categories: union(real.categories, DEMO_ARTWORKS.map((a) => a.category)),
    mediums: union(real.mediums, DEMO_ARTWORKS.map((a) => a.medium)),
    rarities: Object.keys(rarityCounts),
    rarityCounts,
    locations: union(real.locations, DEMO_ARTWORKS.map((a) => a.artistLocation!)),
    artists: union(
      real.artists,
      DEMO_ARTWORKS.map((a) => ({ id: a.artistId, name: a.artistName })),
      (artist) => artist.id,
    ),
    priceRange: {
      min: Math.min(real.priceRange?.min ?? Infinity, ...prices),
      max: Math.max(real.priceRange?.max ?? 0, ...prices),
    },
  };
}

/**
 * Merges the demo paintings into a real listing response. `real` must hold
 * every real match (first page, fetched at the API's max page size); this
 * filters, sorts and pages the combined set the way the API would.
 */
export function withDemoArtworks(real: MarketplacePage, filters: ArtworkFilters, pageSize: number): MarketplacePage {
  const combined = [...real.artworks, ...DEMO_ARTWORKS.filter((a) => matches(a, filters))];
  if (filters.sortBy === "price_asc") combined.sort((a, b) => a.customerPrice - b.customerPrice);
  if (filters.sortBy === "price_desc") combined.sort((a, b) => b.customerPrice - a.customerPrice);
  const page = filters.page ?? 1;
  return {
    artworks: combined.slice((page - 1) * pageSize, page * pageSize),
    total: combined.length,
    page,
    pageSize,
    facets: demoFacets(real.facets),
  };
}

export function demoArtwork(id: string): Artwork | undefined {
  const a = DEMO_ARTWORKS.find((item) => item.id === id);
  if (!a) return undefined;
  return {
    ...a,
    description: `${a.title} by ${a.artistName}. A demo listing shown only on local development builds.`,
    dimensions: a.dimensions ?? null,
    yearCreated: a.yearCreated ?? null,
    images: [{ url: a.thumbnailUrl, thumbnailUrl: a.thumbnailUrl, sortOrder: 0, altText: a.title }],
    coaCertificateNumber: a.coaCertificateNumber ?? "",
    coaIssueDate: "",
    socialProofLinks: [],
    statusHistory: [{ status: a.status, changedAt: new Date(2026, 0, 1).toISOString() }],
  };
}

export function demoArtworksByArtist(artistId: string): ArtworkSummary[] {
  return DEMO_ARTWORKS.filter((a) => a.artistId === artistId);
}
