import type { Metadata } from "next";

// Task 14 deliberately makes page.tsx itself a client component (it owns
// the interactive filters/search state directly, with no URL sync in this
// phase) - but a "use client" file cannot export `metadata`. This thin
// server-component layout recovers a real per-route <title>/description for
// the marketplace listing without turning the page itself back into a
// server component, matching how every other route in this app (about,
// checkout, account) ships its own metadata.
export const metadata: Metadata = {
  title: "The Marketplace | GalleryZone",
  description:
    "Browse original, verified artwork from independent artists across India. Every piece comes with its own digital passport.",
};

export default function MarketplaceLayout(props: LayoutProps<"/marketplace">) {
  return props.children;
}
