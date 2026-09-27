import Image from "next/image";
import Link from "next/link";
import { VerifiedBadge } from "@/components/shared/verified-badge";
import type { ArtistProfile } from "@/types/artist";

interface ArtistCardProps {
  artist: ArtistProfile;
}

// Bio is stored as sanitized-at-display rich text (simple <p> markup) — the
// directory card only ever needs a plain-text excerpt, so tags are stripped
// here rather than rendered. This is *not* the dangerouslySetInnerHTML
// exception (that's ArtistStory, Task 16 Step 4, on the full profile page);
// a stripped-and-truncated string needs no sanitizer.
function bioExcerpt(bio: string, maxLength = 120): string {
  const text = bio
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength).trimEnd()}…`;
}

export function ArtistCard({ artist }: ArtistCardProps) {
  return (
    <Link
      href={`/artists/${artist.id}`}
      className="group flex flex-col items-center gap-3 rounded-lg border border-border bg-card p-6 text-center transition-colors duration-200 hover:border-gold/50 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
    >
      <div className="relative size-20 overflow-hidden rounded-full border border-border">
        <Image
          src={artist.profileImageUrl}
          alt={artist.name}
          fill
          sizes="80px"
          className="object-cover transition-transform duration-500 ease-out group-hover:scale-[1.06]"
        />
      </div>

      <div className="flex flex-col items-center gap-1">
        <h3 className="font-display text-base font-semibold text-foreground">
          {artist.name}
        </h3>
        <VerifiedBadge verification={artist.verification} size="sm" />
      </div>

      {/* Bios usually open with the artist's own name, so a two-line excerpt
          just repeated the heading; the headline is the profile's one-liner. */}
      <p className="line-clamp-2 text-xs leading-relaxed text-muted-foreground">
        {artist.headline || bioExcerpt(artist.bio)}
      </p>
    </Link>
  );
}
