"use client";

import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { useSessionRole } from "@/hooks/useSessionRole";
import type { SessionRole } from "@/lib/session";

// The hero button goes where this person's next step is: a collector to their
// collection, an artist to their dashboard, an aggregator to their inventory.
// A visitor (and an admin, who has no pieces here) gets the marketplace, plus
// a way to sign up. Server-rendered as the visitor's version, then swapped.
const DESTINATION: Record<SessionRole, { label: string; href: string }> = {
  customer: { label: "Open my collection", href: "/account/collection" },
  artist: { label: "Open my dashboard", href: "/dashboard" },
  aggregator: { label: "Open my inventory", href: "/aggregator/collection" },
  admin: { label: "Browse artworks", href: "/marketplace" },
};

const VISITOR = { label: "Browse artworks", href: "/marketplace" };

export function PassportHeroCta() {
  const role = useSessionRole();
  const cta = role ? DESTINATION[role] : VISITOR;

  return (
    <div className="mt-7 flex flex-wrap items-center gap-x-3 gap-y-2">
      <Link
        href={cta.href}
        className="inline-flex h-11 w-fit items-center gap-2 rounded-full bg-gold px-6 text-sm font-semibold text-[#171310] transition-[background-color,transform] duration-150 ease-out hover:bg-gold-bright focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.97] dark:bg-gold-bright dark:hover:bg-gold"
      >
        {cta.label}
        <ArrowRight className="size-4" strokeWidth={2} />
      </Link>
      {!role && (
        <Link
          href="/register"
          className="inline-flex h-11 items-center rounded-full px-4 text-sm font-medium text-foreground/80 transition-colors duration-150 hover:text-foreground focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
        >
          Create an account
        </Link>
      )}
    </div>
  );
}
