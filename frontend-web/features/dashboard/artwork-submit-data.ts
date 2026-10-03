import type { ListingType } from "@/types/artwork";

export const ARTWORK_CATEGORIES = [
  { value: "painting", label: "Painting" },
  { value: "sculpture", label: "Sculpture" },
  { value: "printmaking", label: "Printmaking" },
  { value: "mixed-media", label: "Mixed Media" },
  { value: "textile", label: "Textile Art" },
  { value: "ceramics", label: "Ceramics" },
];

// A different axis from category (painting/sculpture/...) — what kind of
// piece this instance of the work is. "Other" reveals a free-text field
// rather than forcing a guess into one of the fixed options.
export const ARTWORK_TYPES = [
  { value: "original", label: "Original" },
  { value: "limited_edition_print", label: "Limited Edition Print" },
  { value: "open_edition_print", label: "Open Edition Print" },
  { value: "study_sketch", label: "Study / Sketch" },
  { value: "commission_piece", label: "Commission Piece" },
  { value: "other", label: "Other" },
];

export const DIMENSION_UNITS = [
  { value: "in", label: "in" },
  { value: "cm", label: "cm" },
];

export const ARTWORK_MEDIUMS = [
  { value: "oil-on-canvas", label: "Oil on Canvas" },
  { value: "acrylic-on-canvas", label: "Acrylic on Canvas" },
  { value: "watercolor", label: "Watercolor" },
  { value: "charcoal", label: "Charcoal" },
  { value: "ink", label: "Ink" },
  { value: "bronze", label: "Bronze" },
  { value: "ceramic-mixed-media", label: "Ceramic & Mixed Media" },
  { value: "other", label: "Other" },
];

export const LISTING_TYPES: {
  value: ListingType;
  label: string;
  description: string;
}[] = [
  {
    value: "marketplace_only",
    label: "Marketplace",
    description: "Sell online through GalleryZone's own marketplace.",
  },
  {
    value: "aggregator_only",
    label: "Aggregator",
    description:
      "Send the physical piece to a verified aggregator to display and sell in person.",
  },
  {
    value: "marketplace_and_aggregator",
    label: "Both",
    description:
      "List online and make the piece available for aggregator display at the same time.",
  },
];

// Surface/format the work is made on. Free-ish list rather than a rigid enum —
// an aggregator needs to know what they are hanging, not a taxonomy.
export const ARTWORK_FORMATS = [
  { value: "canvas", label: "Canvas" },
  { value: "paper", label: "Paper" },
  { value: "board", label: "Board / panel" },
  { value: "wood", label: "Wood" },
  { value: "metal", label: "Metal" },
  { value: "stone", label: "Stone" },
  { value: "textile", label: "Textile" },
  { value: "other", label: "Other" },
];

export const MAX_ARTWORK_IMAGES = 8;
export const INSURANCE_RECOMMENDED_THRESHOLD = 20000;
// Named in the Artist Onboarding Guide. The buy-link is not published yet —
// when GalleryZone supplies the partner URL, set it here and the form turns
// the partner name into a link automatically.
export const INSURANCE_PARTNER = "HDFC ERGO";
export const INSURANCE_PARTNER_URL: string | null = "https://www.hdfcergo.com/";

// Stock photos pre-filling every image slot so the upload form is always
// submittable with zero clicks (there's no backend to actually store a
// photo either way) — picking a real file swaps a slot's placeholder for a
// real preview via FileReader, but nothing is ever required.
export const PLACEHOLDER_ARTWORK_IMAGES = [
  "/ecosystem/artwork-1.png",
  "/ecosystem/artwork-2.png",
  "/ecosystem/artwork-3.png",
  "/artworks/framed-painting.png",
  "/artworks/landscape.png",
  "/artworks/portrait-woman.png",
  "/artworks/collage-busts.png",
  "/artworks/draped-figure.png",
];
