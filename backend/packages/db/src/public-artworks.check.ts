// queryMarketplace() is pure — filter, sort, page, facets over an
// in-memory marketplace. Run: node --experimental-strip-types public-artworks.check.ts
import assert from "node:assert/strict";
import { queryMarketplace, toMarketplaceView, type PublicArtworkView } from "./public-artworks.ts";
import { sizeBandOf } from "./listing-projection.ts";

const piece = (over: Partial<PublicArtworkView>): PublicArtworkView => ({
  id: "a",
  productCode: "GZ000001",
  artistId: "art1",
  artistName: "Devika",
  title: "Monsoon",
  description: "",
  category: "Painting",
  medium: "Oil",
  dimensions: null,
  yearCreated: 2024,
  images: [],
  displayPricePaise: 100_00,
  insured: false,
  status: "marketplace",
  listingType: "marketplace",
  rarityType: null,
  coaCertificateNumber: null,
  coaIssuedAt: null,
  createdAt: "2026-01-01T00:00:00.000Z",
  artistLocation: "Hyderabad",
  sizeBand: "medium",
  ...over,
});
const all = [
  piece({ id: "a", displayPricePaise: 300_00, createdAt: "2026-01-03T00:00:00.000Z" }),
  piece({ id: "b", displayPricePaise: 100_00, category: "Sculpture", medium: "Bronze", rarityType: "R", createdAt: "2026-01-01T00:00:00.000Z", title: "Bull" }),
  piece({ id: "c", displayPricePaise: 200_00, artistId: "art2", artistName: "Ravi", artistLocation: "Pune", sizeBand: "large", createdAt: "2026-01-02T00:00:00.000Z" }),
];
const ids = (page: { artworks: { id: string }[] }) => page.artworks.map((a) => a.id);

// The marketplace listing carries no certificate, even for a piece that has one.
const certified = piece({ id: "z", coaCertificateNumber: "GZ-COA-2026-0001", coaIssuedAt: "2026-02-01T00:00:00.000Z" });
for (const listed of queryMarketplace([certified], {}).artworks.concat(toMarketplaceView(certified))) {
  assert.ok(!("coaCertificateNumber" in listed) && !("coaIssuedAt" in listed), "marketplace views never carry the COA");
}
assert.equal(certified.coaCertificateNumber, "GZ-COA-2026-0001", "the source view keeps it for the passport page");

assert.deepEqual(ids(queryMarketplace(all, {})), ["a", "c", "b"], "newest first by default");
assert.deepEqual(ids(queryMarketplace(all, { sort: "price_asc" })), ["b", "c", "a"]);
assert.deepEqual(ids(queryMarketplace(all, { sort: "price_desc" })), ["a", "c", "b"]);
assert.deepEqual(ids(queryMarketplace(all, { category: ["Sculpture"] })), ["b"]);
assert.deepEqual(ids(queryMarketplace(all, { medium: ["Oil"], artistId: "art2" })), ["c"]);
assert.deepEqual(ids(queryMarketplace(all, { category: ["Sculpture", "nonexistent"] })), ["b"], "multiple categories OR together");
assert.deepEqual(ids(queryMarketplace(all, { category: [] })), ["a", "c", "b"], "empty category list is no filter, not zero matches");
assert.deepEqual(ids(queryMarketplace(all, { rarity: "R" })), ["b"]);
assert.deepEqual(ids(queryMarketplace(all, { minPricePaise: 150_00, maxPricePaise: 250_00 })), ["c"]);
assert.deepEqual(ids(queryMarketplace(all, { q: "ravi" })), ["c"], "search matches artist name");
assert.deepEqual(ids(queryMarketplace(all, { q: "BULL" })), ["b"], "search is case-insensitive");

const page2 = queryMarketplace(all, { pageSize: 2, page: 2 });
assert.equal(page2.total, 3);
assert.deepEqual(ids(page2), ["b"]);
assert.equal(queryMarketplace(all, { pageSize: 10_000 }).pageSize, 60, "page size is capped");

const facets = queryMarketplace(all, { category: ["Sculpture"] }).facets;
assert.deepEqual(facets.categories, ["Painting", "Sculpture"], "facets span the whole marketplace, not the filtered page");
assert.deepEqual(facets.mediums, ["Bronze", "Oil"]);
assert.deepEqual(facets.rarities, ["R"]);
assert.deepEqual(facets.rarityCounts, { R: 1 });
assert.deepEqual(facets.priceRangePaise, { min: 100_00, max: 300_00 });
assert.deepEqual(facets.locations, ["Hyderabad", "Pune"]);
assert.deepEqual(facets.artists, [{ id: "art1", name: "Devika" }, { id: "art2", name: "Ravi" }]);
assert.deepEqual(ids(queryMarketplace(all, { location: "Pune" })), ["c"]);
assert.deepEqual(ids(queryMarketplace(all, { size: "large" })), ["c"]);
assert.equal(queryMarketplace([], {}).facets.priceRangePaise, null);

assert.equal(sizeBandOf("24 x 36 in"), "medium");
assert.equal(sizeBandOf("10 x 10 in"), "small");
assert.equal(sizeBandOf("100 x 100 cm"), "large");
assert.equal(sizeBandOf("big"), null);
assert.equal(sizeBandOf(null), null);

console.log("public-artworks.check.ts: ok");
