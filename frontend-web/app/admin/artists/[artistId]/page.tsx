"use client";

import { use } from "react";
import { notFound } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { AdminPageHeader } from "@/features/admin/admin-page-header";
import { UserDetailHeader } from "@/features/admin/people/user-detail-header";
import { AdminStatusBadge } from "@/features/admin/admin-status-badge";
import { InstagramGlyph } from "@/components/social-icons";
import { useAdminArtistPortfolio } from "@/hooks/useAdminUsers";
import { verifiedTierCount } from "@/types/artist";
import { formatINR } from "@/lib/utils";
import type { AdminUser } from "@/types/admin";

const TIER_LABELS = [
  { key: "tier1SocialMedia", label: "Tier 1 · Social media linked" },
  { key: "tier2ActivePlan", label: "Tier 2 · Active subscription" },
  { key: "tier3FirstSale", label: "Tier 3 · First confirmed sale" },
] as const;

export default function AdminArtistDetailPage(
  props: PageProps<"/admin/artists/[artistId]">,
) {
  const { artistId } = use(props.params);
  const { data, isLoading } = useAdminArtistPortfolio(artistId);

  if (isLoading) return null;
  if (!data) notFound();

  const { user, profile, artworks } = data;
  const tier = profile ? verifiedTierCount(profile.verification) : 0;
  const listedValue = artworks.reduce((sum, a) => sum + a.customerPrice, 0);

  return (
    <div className="space-y-6">
      <AdminPageHeader
        title={user.name}
        description="Artist record, verification standing, and catalogue."
        backHref="/admin/artists"
        backLabel="Back to artists"
      />

      <UserDetailHeader user={user} />

      {/* grid-cols-1 below lg isn't decorative — see app/admin/page.tsx's
          identical comment: an implicit grid track sizes to its widest
          child's min-content instead of shrinking, overflowing the page. */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.4fr)] lg:items-start">
        <div className="space-y-4">
          <section className="rounded-xl border border-border bg-card p-5">
            <div className="flex items-baseline justify-between gap-3">
              <h2 className="font-display text-base font-semibold text-foreground">
                Verification
              </h2>
              <span className="text-xs tabular-nums text-muted-foreground">
                {tier} of 3
              </span>
            </div>
            <ul className="mt-3 space-y-2.5">
              {TIER_LABELS.map((entry) => {
                const cleared = profile
                  ? profile.verification[entry.key]
                  : false;
                return (
                  <li key={entry.key} className="flex items-center gap-2.5">
                    <span
                      aria-hidden
                      className={`size-2 shrink-0 rounded-full ${cleared ? "bg-gold-bright" : "bg-border"}`}
                    />
                    <span
                      className={`text-sm ${cleared ? "text-foreground" : "text-muted-foreground"}`}
                    >
                      {entry.label}
                    </span>
                  </li>
                );
              })}
            </ul>
            {tier === 3 ? (
              <p className="mt-4 rounded-md border border-gold/40 bg-gold/[0.06] p-3 text-xs text-muted-foreground">
                Fully verified. Carries the Gold badge across the marketplace.
              </p>
            ) : null}
          </section>

          <section className="rounded-xl border border-border bg-card p-5">
            <h2 className="font-display text-base font-semibold text-foreground">
              KYC
            </h2>
            <div className="mt-3 flex items-center justify-between gap-3">
              <span className="text-sm text-muted-foreground">
                Identity check
              </span>
              {user.kycStatus ? (
                <AdminStatusBadge status={user.kycStatus} size="sm" />
              ) : (
                <span className="text-sm text-muted-foreground">Not set</span>
              )}
            </div>
            <p className="mt-3 text-xs text-muted-foreground">
              Identity documents are never exposed in this console. Review
              submissions from the KYC queue.
            </p>
          </section>

          <ComplianceSection user={user} />

          <section className="rounded-xl border border-border bg-card p-5">
            <h2 className="font-display text-base font-semibold text-foreground">
              Catalogue
            </h2>
            <dl className="mt-3 grid grid-cols-2 gap-4">
              <div>
                <dt className="text-xs text-muted-foreground">Works listed</dt>
                <dd className="font-display text-xl font-semibold tabular-nums text-foreground">
                  {artworks.length}
                </dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Listed value</dt>
                <dd className="font-display text-xl font-semibold tabular-nums text-foreground">
                  {formatINR(listedValue)}
                </dd>
              </div>
            </dl>
          </section>
        </div>

        <section className="rounded-xl border border-border bg-card">
          <div className="border-b border-border px-5 py-4">
            <h2 className="font-display text-base font-semibold text-foreground">
              Works by this artist
            </h2>
          </div>
          {artworks.length === 0 ? (
            <p className="px-5 py-8 text-center text-sm text-muted-foreground">
              Nothing listed yet.
            </p>
          ) : (
            <ul className="divide-y divide-border">
              {artworks.map((artwork) => (
                <li key={artwork.id}>
                  <Link
                    href={`/admin/artworks/${artwork.id}`}
                    className="flex items-center gap-3 px-5 py-3 transition-colors hover:bg-accent/40"
                  >
                    <div className="relative size-10 shrink-0 overflow-hidden rounded-md border border-border bg-muted">
                      {artwork.images[0] ? (
                        <Image
                          src={artwork.images[0].thumbnailUrl}
                          alt=""
                          fill
                          sizes="40px"
                          className="object-cover"
                        />
                      ) : null}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-foreground">
                        {artwork.title}
                      </p>
                      <p className="text-xs capitalize text-muted-foreground">
                        {artwork.category}
                      </p>
                    </div>
                    <AdminStatusBadge status={artwork.status} size="sm" />
                    <span className="shrink-0 text-sm tabular-nums text-muted-foreground">
                      {formatINR(artwork.customerPrice)}
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>
    </div>
  );
}

// PAN, GST and Instagram are admin-only — none of these ever appear on the
// artist's public profile page. Shown together here since they're the same
// kind of thing: compliance detail collected from the artist, reviewed by
// GalleryZone rather than shown to buyers.
function ComplianceSection({ user }: { user: AdminUser }) {
  return (
    <section className="rounded-xl border border-border bg-card p-5">
      <h2 className="font-display text-base font-semibold text-foreground">
        Compliance
      </h2>
      <dl className="mt-3 space-y-3">
        <div className="flex items-center justify-between gap-3">
          <dt className="text-sm text-muted-foreground">PAN</dt>
          <dd className="font-mono text-sm text-foreground">
            {user.pan ?? "Not on file"}
          </dd>
        </div>
        <div className="flex items-center justify-between gap-3">
          <dt className="text-sm text-muted-foreground">GSTIN</dt>
          <dd className="font-mono text-sm text-foreground">
            {user.gstin ?? "Not on file"}
          </dd>
        </div>
        <div className="flex items-center justify-between gap-3">
          <dt className="text-sm text-muted-foreground">GST status</dt>
          <dd>
            <AdminStatusBadge
              status={user.gstStatus ?? "not_submitted"}
              size="sm"
            />
          </dd>
        </div>
        <div className="flex items-center justify-between gap-3">
          <dt className="flex items-center gap-1.5 text-sm text-muted-foreground">
            <InstagramGlyph className="size-3.5" />
            Instagram
          </dt>
          <dd className="text-sm text-foreground">
            {user.instagramHandle
              ? `@${user.instagramHandle}`
              : "Not connected"}
          </dd>
        </div>
      </dl>
    </section>
  );
}
