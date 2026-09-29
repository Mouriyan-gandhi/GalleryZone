"use client";

import { useEffect, useState } from "react";
import { ArrowRight, Search } from "lucide-react";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

interface MarketplaceSearchBarProps {
  value: string;
  onChange: (query: string) => void;
  className?: string;
}

// Debounces keystrokes (300ms) before pushing up to the parent's filters, so
// the listing query only refires once typing pauses. Enter or the arrow
// button searches immediately.
export function MarketplaceSearchBar({ value, onChange, className }: MarketplaceSearchBarProps) {
  const [draft, setDraft] = useState(value);

  // Stay in sync when the parent resets filters from outside this input
  // (e.g. "Clear all") — an accepted "adjust state when a prop changes" case.
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setDraft(value);
  }, [value]);

  useEffect(() => {
    const timeout = setTimeout(() => onChange(draft), 300);
    return () => clearTimeout(timeout);
    // onChange intentionally excluded: only `draft` should reset the timer.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [draft]);

  return (
    <form
      role="search"
      onSubmit={(e) => {
        e.preventDefault();
        onChange(draft);
      }}
      className={cn("relative", className)}
    >
      <Search
        className="pointer-events-none absolute top-1/2 left-5 size-5 -translate-y-1/2 text-muted-foreground"
        strokeWidth={1.75}
      />
      <Input
        type="text"
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        placeholder="Search artworks, artists, styles, mediums..."
        aria-label="Search artworks"
        className="h-14 rounded-full border-gold/50 bg-card/60 pr-16 pl-13 text-[0.95rem] shadow-none focus-visible:border-gold"
      />
      <button
        type="submit"
        aria-label="Search"
        className="absolute top-1/2 right-2 flex size-10 -translate-y-1/2 items-center justify-center rounded-full bg-gold text-[#171310] transition-[background-color,transform] duration-150 ease-out hover:bg-gold-bright focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-95 dark:bg-gold-bright dark:hover:bg-gold"
      >
        <ArrowRight className="size-5" strokeWidth={2} />
      </button>
    </form>
  );
}
