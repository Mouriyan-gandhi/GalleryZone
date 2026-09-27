import { Star } from "lucide-react";
import { formatINR } from "@/lib/utils";
import type { ArtistPublicStats } from "@/types/profile-stats";

// The numbers a collector actually wants before reading a bio: how much work
// is there, how much has sold, what does it cost, what do other buyers say.
//
// Everything here is a count, a date or the LISTED price — the customer-facing
// figure that is already on every artwork card. What the artist is paid is
// confidential and never reaches this component; see types/profile-stats.ts.

// The API doesn't send a join date yet (lib/api-mappers.ts defaults it to ""),
// which rendered as "Invalid Date".
function joinedLabel(iso: string): string {
  const date = new Date(iso);
  if (!iso || Number.isNaN(date.getTime())) return "—";
  return date.toLocaleDateString("en-IN", {
    month: "long",
    year: "numeric",
  });
}

export function ArtistStatStrip({
  stats,
  className,
}: {
  stats: ArtistPublicStats;
  className?: string;
}) {
  const cells: Array<{ label: string; value: string; hint?: string }> = [
    {
      label: "Works listed",
      value: String(stats.artworksListed),
      hint: stats.onDisplay > 0 ? `${stats.onDisplay} on gallery display` : undefined,
    },
    { label: "Works sold", value: String(stats.worksSold) },
    {
      label: "Price range",
      value: stats.listedPriceRange
        ? stats.listedPriceRange.low === stats.listedPriceRange.high
          ? formatINR(stats.listedPriceRange.low)
          : `${formatINR(stats.listedPriceRange.low)} – ${formatINR(stats.listedPriceRange.high)}`
        : "—",
      hint: stats.listedPriceRange ? "Listed price, GST included" : undefined,
    },
    { label: "On GalleryZone since", value: joinedLabel(stats.joinedAt) },
  ];

  return (
    <div className={className}>
      <dl className="grid grid-cols-2 gap-px overflow-hidden rounded-lg border border-border bg-border sm:grid-cols-4">
        {cells.map((cell) => (
          <div key={cell.label} className="flex flex-col gap-0.5 bg-card p-4">
            <dt className="text-xs text-muted-foreground">{cell.label}</dt>
            <dd className="font-display text-lg font-semibold tabular-nums text-foreground">
              {cell.value}
              {cell.hint && (
                <p className="font-sans text-[11px] leading-snug font-normal text-muted-foreground">
                  {cell.hint}
                </p>
              )}
            </dd>
          </div>
        ))}
      </dl>

      {(stats.rating.count > 0 ||
        stats.mediums.length > 0 ||
        stats.connections > 0) && (
        <div className="mt-4 flex flex-wrap items-center gap-x-5 gap-y-2 text-sm">
          {stats.rating.count > 0 && (
            <span className="flex items-center gap-1.5">
              <Star
                className="size-4 fill-gold-bright text-gold-bright"
                strokeWidth={1.75}
              />
              <span className="font-medium tabular-nums text-foreground">
                {stats.rating.average.toFixed(1)}
              </span>
              <span className="text-muted-foreground">
                from {stats.rating.count}{" "}
                {stats.rating.count === 1 ? "collector" : "collectors"}
              </span>
            </span>
          )}

          {stats.connections > 0 && (
            <span className="text-muted-foreground">
              Connected with {stats.connections}{" "}
              {stats.connections === 1 ? "artist" : "artists"}

            </span>
          )}
        </div>
      )}

      {stats.mediums.length > 0 && (
        <div className="mt-4 flex flex-wrap gap-2">
          {/* Most-used first, so what they mostly do reads off the front. */}
          {stats.mediums.slice(0, 5).map((medium) => (
            <span
              key={medium}
              className="rounded-full border border-border px-3 py-1 text-xs text-muted-foreground"
            >
              {medium}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}
