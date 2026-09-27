"use client";

import { useEffect, useState } from "react";
import { Search } from "lucide-react";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

interface MarketplaceSearchBarProps {
  value: string;
  onChange: (query: string) => void;
  className?: string;
  dark?: boolean;
}

// Debounces local keystrokes (300ms) before pushing up to the parent's
// filters state, so useArtworks(filters) - and its 600ms mock delay -
// doesn't refire on every keystroke, only once typing pauses.
export function MarketplaceSearchBar({
  value,
  onChange,
  className,
  dark = false,
}: MarketplaceSearchBarProps) {
  const [draft, setDraft] = useState(value);

  // Stay in sync when the parent resets filters from outside this input
  // (e.g. the empty state's "Clear filters" action) — an accepted "adjust
  // state when a prop changes" case (react.dev/learn/you-might-not-need-an-effect).
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setDraft(value);
  }, [value]);

  useEffect(() => {
    const timeout = setTimeout(() => {
      onChange(draft);
    }, 300);
    return () => clearTimeout(timeout);
    // onChange intentionally excluded: only `draft` should reset the timer.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [draft]);

  return (
    <div className={cn("relative", className)}>
      <Search
        className={cn(
          "pointer-events-none absolute top-1/2 left-4 size-4 -translate-y-1/2",
          dark ? "text-white/40" : "text-muted-foreground",
        )}
        strokeWidth={1.75}
      />
      <Input
        type="text"
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        placeholder="Search artworks, artists, styles..."
        aria-label="Search artworks"
        className={cn(
          "h-12 rounded-full pr-14 pl-11 text-base shadow-sm sm:text-sm",
          dark
            ? "border-white/10 bg-white/10 text-white placeholder:text-white/40 focus:border-gold/50 focus:bg-white/15"
            : "border-border bg-card",
        )}
      />
      <button
        type="button"
        onClick={() => onChange(draft)}
        aria-label="Search"
        className="absolute top-1/2 right-1.5 flex size-9 -translate-y-1/2 items-center justify-center rounded-full bg-gold-bright text-[#171310] transition-transform hover:scale-105 active:scale-95"
      >
        <Search className="size-4" strokeWidth={2} />
      </button>
    </div>
  );
}
