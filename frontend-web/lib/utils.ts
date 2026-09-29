import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Single shared money formatter — every ₹ amount in the app renders through
// this (never an ad-hoc toLocaleString call), per the Global Constraints.
// maximumFractionDigits: 0 because every price in this product is a whole
// rupee amount (see mock-data/artworks.ts).
// Catalogue values arrive as slugs ("acrylic-on-canvas") — show them as a
// person would write them ("Acrylic on canvas").
export function humanize(slug: string): string {
  const text = slug.replace(/[-_]+/g, " ").trim();
  return text.charAt(0).toUpperCase() + text.slice(1);
}

export function formatINR(amount: number): string {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(amount);
}
