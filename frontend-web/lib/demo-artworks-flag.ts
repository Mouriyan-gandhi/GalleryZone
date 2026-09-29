// The demo-artworks gate and its id test, deliberately kept in their own
// module with no data in it.
//
// `lib/demo-artworks.ts` holds ~200 lines of invented paintings, artists and
// titles. Importing anything from that file — even a one-line helper — pulls
// the whole catalogue into the bundle, because ES modules are bundled whole.
// That is how fabricated artist names ended up in ten client chunks of a
// production build: the gate stopped them rendering, but anyone reading the
// JavaScript could find "Kabir Shekhawat" and take him for a real listed
// artist. On a product whose whole promise is verified authenticity, that is
// not a cost worth paying for a local preview.
//
// So: import the gate from here, and load the catalogue itself with a dynamic
// `await import()` inside the gated branch. The condition folds to `false` at
// build time in production, the dynamic import is then unreachable, and the
// data never enters the bundle at all.

/**
 * Local-preview paintings, so the marketplace grid and its paging can be seen
 * with more than the handful of live listings.
 *
 * Needs `NEXT_PUBLIC_DEMO_ARTWORKS=true` AND a non-production build. Next
 * inlines both at build time, so this is a compile-time constant, not a
 * runtime check.
 */
export const DEMO_ARTWORKS_ENABLED =
  process.env.NODE_ENV !== "production" && process.env.NEXT_PUBLIC_DEMO_ARTWORKS === "true";

/** Demo records carry a `demo-` id prefix, so real data can never collide with them. */
export function isDemoId(id: string): boolean {
  return id.startsWith("demo-");
}
