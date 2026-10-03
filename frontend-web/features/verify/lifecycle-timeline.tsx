import {
  ArrowRightLeft,
  BadgeCheck,
  Building2,
  Frame,
  MapPin,
  PackageCheck,
  Palette,
  ShoppingBag,
  Sparkles,
  Store,
  Undo2,
  type LucideIcon,
} from "lucide-react";
import type { LifecycleEntry, LifecycleKind } from "@/services/verifyService";

// The public passport's lifecycle (NFC_IMPLEMENTATION.md §6): one timeline of everything
// that happened to a piece — made, approved, listed, shown at a gallery, sold, handed over,
// delivered — from the server's merged `lifecycle` array, oldest first. It replaces the old
// provenance list, which only knew about ownership transfers.
//
// A place appears only under the artist and a gallery. For a collector the server sends
// null (a collector's home is private), so there is nothing here to hide or to leak.

const ICON: Record<LifecycleKind, LucideIcon> = {
  created: Palette,
  approved: BadgeCheck,
  listed: Store,
  placed_with_gallery: Building2,
  returned_from_gallery: Undo2,
  sold_marketplace: ShoppingBag,
  sold_at_gallery: ShoppingBag,
  transferred: ArrowRightLeft,
  displayed: Frame,
  delivered: PackageCheck,
};

const LABEL: Record<LifecycleKind, (name: string) => string> = {
  created: (name) => `Made by ${name}`,
  approved: () => "Approved by GalleryZone",
  listed: () => "Listed on the marketplace",
  placed_with_gallery: (name) => `On display at ${name}`,
  returned_from_gallery: (name) => `Came back from ${name}`,
  sold_marketplace: (name) => `Sold to ${name}`,
  sold_at_gallery: (name) => `Sold at ${name}`,
  transferred: (name) => `Handed over to ${name}`,
  displayed: (name) => `Lent to ${name} for display`,
  delivered: () => "Delivered to the new owner",
};

function placeOf(location: NonNullable<LifecycleEntry["location"]>): string {
  return [location.city, location.state, location.country].filter(Boolean).join(", ");
}

export function NfcLifecycleTimeline({ entries }: { entries: LifecycleEntry[] }) {
  if (entries.length === 0) return null;
  const last = entries.length - 1;

  return (
    <section aria-labelledby="lifecycle-heading" className="mt-10">
      <h2 id="lifecycle-heading" className="text-xs font-semibold tracking-[0.15em] text-muted-foreground uppercase">
        Lifecycle
      </h2>
      <ol className="mt-4 flex flex-col gap-0">
        {entries.map((entry, i) => {
          const Icon = i === last ? Sparkles : ICON[entry.kind];
          return (
            <li key={entry.id} className="relative flex gap-4 pb-6 last:pb-0">
              {i < last && <span className="absolute top-8 left-[13px] h-full w-px bg-border" aria-hidden="true" />}
              <span
                className={`relative z-10 mt-0.5 flex size-7 shrink-0 items-center justify-center rounded-full border ${i === last ? "border-gold/60 bg-gold/15" : "border-border bg-card"}`}
              >
                <Icon className={`size-3.5 ${i === last ? "text-gold-bright" : "text-muted-foreground"}`} strokeWidth={1.75} />
              </span>
              <div className="flex flex-1 flex-col gap-0.5">
                <p className="text-sm font-medium text-foreground">{LABEL[entry.kind](entry.actor.displayName)}</p>
                {entry.location && (
                  <p className="flex items-center gap-1 text-xs text-muted-foreground">
                    <MapPin className="size-3 shrink-0" strokeWidth={1.75} />
                    {placeOf(entry.location)}
                  </p>
                )}
                {entry.note && <p className="text-xs text-muted-foreground">{entry.note}</p>}
                <p className="text-xs text-muted-foreground">
                  {new Intl.DateTimeFormat("en-IN", { day: "numeric", month: "short", year: "numeric" }).format(new Date(entry.at))}
                </p>
              </div>
            </li>
          );
        })}
      </ol>
    </section>
  );
}
