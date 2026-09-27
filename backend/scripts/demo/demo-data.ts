export const PASSWORD = "Demo@12345";

export const accounts = [
  { key: "admin", email: "admin@demo.galleryzone.test", name: "Nandita Rao", role: "customer" },
  { key: "admin2", email: "admin2@demo.galleryzone.test", name: "Vikram Malhotra", role: "customer" },
  { key: "artist", email: "artist@demo.galleryzone.test", name: "Aanya Deshmukh", role: "artist" },
  { key: "artist2", email: "artist2@demo.galleryzone.test", name: "Raghunath Venkataramanan-Iyer", role: "artist" },
  { key: "artistNew", email: "artist-new@demo.galleryzone.test", name: "Kabir Sethi", role: "artist" },
  { key: "aggregator", email: "aggregator@demo.galleryzone.test", name: "Kala Ghar Gallery, Bandra West, Mumbai", role: "aggregator" },
  { key: "aggregatorNew", email: "aggregator-new@demo.galleryzone.test", name: "Rangmanch Art House", role: "aggregator" },
  { key: "collector", email: "collector@demo.galleryzone.test", name: "Meera Iyer", role: "customer" },
  { key: "friend", email: "friend@demo.galleryzone.test", name: "Zoya Menon", role: "customer" },
  { key: "collectorNew", email: "collector-new@demo.galleryzone.test", name: "Arjun Nair", role: "customer" },
] as const;

export type AccountKey = (typeof accounts)[number]["key"];

export const categories = ["Painting", "Sculpture", "Photography", "Digital Art", "Printmaking", "Mixed Media", "Textile"];

export interface ArtworkSeed {
  title: string;
  description: string;
  category: string;
  medium: string;
  dimensions: string;
  yearCreated: number;
  listingType: "marketplace_only" | "aggregator_only" | "marketplace_and_aggregator";
  displayPricePaise: number;
  artworkType?: string;
  paintingStyle?: string;
  insuranceNumber?: string;
}

const busyTitles = [
  "First Light over Sinhagad",
  "Courtyard after the Rain",
  "The Mango Seller's Red Scarf",
  "Blue Hour at Deccan Gymkhana",
  "Copper Vessels, Sunday Morning",
  "Threads of the Western Ghats",
  "Quiet Geometry of an Old Wada",
  "A River Remembers Every Monsoon",
  "Night Bus to Kolhapur",
  "Marigolds beside the Ticket Window",
  "Pomegranate Season in Aundh",
  "Three Windows Facing East",
  "The Long Walk Home from School",
  "Terracotta Sky above Baner",
  "Conversations in Burnt Umber",
  "A Brass Bell for the New Moon",
  "Salt Wind, Konkan Coast",
  "Liminal Garden with Two Mynas",
  "Indigo Ledger of Forgotten Names",
  "Market Day, Tulshibaug",
  "Small Astronomy of Everyday Things",
  "Palash Bloom against a Grey Wall",
  "Memory Map of the Mula-Mutha",
  "Late Afternoon at Shaniwar Wada",
  "Unsent Letters from the Plateau",
  "Red Earth, Green Door",
  "The City Learns to Breathe Again",
  "Twenty-Seven Kites over Pune",
];

const longTitles = [
  "Monsoon Over Marine Drive, Study No. 7 in Indigo, Burnt Sienna and Unfinished Grey",
  "An Inventory of Shadows Cast by Coconut Palms at Four Minutes Past Five",
  "The Cartographer's Dream of Backwaters, Railway Bridges and an Approaching Summer Storm",
  "Notes from a Thiruvananthapuram Verandah While the Evening News Played in Another Room",
  "What the Arabian Sea Told the Red Laterite Cliffs Before the Fishing Boats Returned",
  "Portrait of a Library Queue During the First Rain after an Unreasonably Long April",
  "Seven Variations on Temple Brass, Blue Tarpaulin and the Smell of Wet Earth",
  "A Very Long Conversation between Daybreak, the Western Ghats and a Solitary Kingfisher",
];

const mediums = [
  "Acrylic on canvas",
  "Oil and cold wax on linen",
  "Archival pigment print",
  "Hand-cut paper and ink",
  "Natural dyes on handloom cotton",
  "Bronze with reclaimed teak",
  "Giclée print on museum rag",
  "Found objects, thread and plaster",
];

const dimensions = ["16 x 20 in", "24 x 36 in", "36 x 24 in", "40 x 40 in", "18 x 36 in", "48 x 24 in", "60 x 90 cm", "120 x 60 cm"];
const listingTypes: ArtworkSeed["listingType"][] = ["marketplace_only", "marketplace_and_aggregator", "aggregator_only"];
const targetPrices = [
  450_000, 650_000, 850_000, 1_200_000, 1_800_000, 2_400_000, 3_500_000, 4_800_000,
  6_500_000, 8_500_000, 12_500_000, 18_000_000, 25_000_000, 35_000_000, 48_000_000,
  65_000_000, 85_000_000, 100_000_000, 125_000_000,
];

function artwork(title: string, index: number, artist: "Aanya" | "Raghunath"): ArtworkSeed {
  const category = categories[index % categories.length]!;
  return {
    title,
    description:
      artist === "Aanya"
        ? `A layered ${category.toLowerCase()} developed from field sketches, remembered conversations and the shifting light of western India. Fine passages sit beside deliberately rough marks so the work changes character from across a room to arm's length. Signed, dated and accompanied by a GalleryZone certificate of authenticity.`
        : `This extended study moves between observation and recollection, building a slow visual rhythm from translucent colour, repeated architectural fragments and hand-worked surfaces. The series considers migration, coastal weather and the private rituals through which a place becomes home. Additional process notes and conservation guidance accompany the work for collectors.` ,
    category,
    medium: mediums[index % mediums.length]!,
    dimensions: dimensions[index % dimensions.length]!,
    yearCreated: 2018 + (index % 9),
    listingType: listingTypes[index % listingTypes.length]!,
    displayPricePaise: targetPrices[index % targetPrices.length]!,
    artworkType: category === "Painting" ? "Original" : "Limited edition",
    paintingStyle: category === "Painting" ? ["Abstract", "Contemporary", "Figurative"][index % 3] : undefined,
    ...(index >= 3 && index <= 5 ? { insuranceNumber: `GZ-INS-DEMO-${String(index).padStart(4, "0")}` } : {}),
  };
}

export const busyArtistArtworks = busyTitles.map((title, index) => {
  const item = artwork(title, index, "Aanya");
  if (index >= 3 && index <= 5) item.listingType = "marketplace_and_aggregator";
  if (index >= 10 && index <= 13) item.listingType = "marketplace_only";
  if (index >= 14) item.listingType = "marketplace_and_aggregator";
  if (index === 21) item.displayPricePaise = 450_000;
  return item;
});
export const longNameArtistArtworks = longTitles.map((title, index) => {
  const item = artwork(title, index + 11, "Raghunath");
  item.listingType = "marketplace_only";
  if (index === longTitles.length - 1) item.displayPricePaise = 125_000_000;
  return item;
});

export const imageSizes = [
  [800, 1000],
  [800, 1200],
  [1200, 800],
  [900, 900],
  [600, 1200],
  [1400, 700],
] as const;
