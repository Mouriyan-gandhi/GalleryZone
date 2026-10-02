"use client";

import { useAdminUser } from "@/hooks/useAdminUsers";

import { useAdminArtworks } from "@/hooks/useAdminCatalog";

import { useCurrentUser } from "@/hooks/useCurrentUser";

import { useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Check, X, ShieldAlert } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent } from "@/components/ui/dialog";
import { AdminStatusBadge } from "@/features/admin/admin-status-badge";
import { RejectReasonDialog } from "@/features/admin/reject-reason-dialog";
import {
  EligibilityChecklist,
  ELIGIBILITY_CRITERIA,
  type EligibilityId,
} from "./eligibility-checklist";
import {
  useApproveArtworkMutation,
  useRejectArtworkMutation,
} from "@/hooks/useAdminModeration";
import { useAdminAuditStore } from "@/store/useAdminAuditStore";
import { formatINR } from "@/lib/utils";
import {
  ARTWORK_RARITY_LABEL,
  ARTWORK_RARITY_OPTIONS,
  LISTING_TYPE_LABEL,
  type Artwork,
  type ArtworkRarity,
} from "@/types/artwork";

const REJECT_PRESETS = [
  "Appears to be a reproduction or replica",
  "AI-generated, digital print, or not original physical media",
  "Image quality insufficient to assess the work",
  "Incomplete or inconsistent documentation",
  "Possible third-party IP in the work",
];

export function ArtworkReviewPanel({ artwork }: { artwork: Artwork }) {
  const adminName = useCurrentUser().data?.name ?? "Admin";
  const router = useRouter();
  const queryClient = useQueryClient();
  const appendAudit = useAdminAuditStore((s) => s.append);

  const [checked, setChecked] = useState<Record<string, boolean>>({});
  // The rank is compulsory: approval stays off until the admin has picked one
  // (a piece re-submitted after a return may already carry one).
  const [rank, setRank] = useState<ArtworkRarity | null>(artwork.rarityType ?? null);
  const [rejectOpen, setRejectOpen] = useState(false);
  const [zoomIndex, setZoomIndex] = useState<number | null>(null);

  const approveMutation = useApproveArtworkMutation();
  const rejectMutation = useRejectArtworkMutation();

  const allCleared = ELIGIBILITY_CRITERIA.every((c) => checked[c.id]);
  const canApprove = allCleared && rank !== null;
  const isBusy = approveMutation.isPending || rejectMutation.isPending;

  // The artist's other work and profile, from the admin catalogue.
  const { data: allArtworks } = useAdminArtworks();
  const { data: artistUser } = useAdminUser(artwork.artistId);
  const artistPriorWorks = (allArtworks ?? []).filter((a) => a.artistId === artwork.artistId && a.id !== artwork.id).length;
  // Tier 1 = a public handle on the profile; higher tiers come from the MOU + first sale, which the admin view does not carry yet.
  const artistTier = artistUser?.instagramHandle ? 1 : 0;

  const submittedAt =
    artwork.statusHistory.at(-1)?.changedAt ?? artwork.coaIssueDate;
  const [now] = useState(() => Date.now());
  const waitingDays = Math.max(
    0,
    Math.round((now - new Date(submittedAt).getTime()) / 86_400_000),
  );

  // The mock services never mutate the shared fixture arrays, so the call site
  // is what makes an action stick for the session — drop the row from the
  // queue cache here, and the hooks' own invalidations handle the KPI counts.
  function dropFromQueue() {
    queryClient.setQueryData<Artwork[]>(["admin-pending-artworks"], (prev) =>
      (prev ?? []).filter((a) => a.id !== artwork.id),
    );
  }

  async function handleApprove() {
    if (!rank) return;
    try {
      await approveMutation.mutateAsync({ artworkId: artwork.id, rarity: rank });
      dropFromQueue();
      appendAudit({
        adminName: adminName,
        action: "artwork.approved",
        entityType: "artwork",
        entityId: artwork.id,
        entityLabel: artwork.title,
        detail: `Ranked ${ARTWORK_RARITY_LABEL[rank]}`,
      });
      toast.success("Artwork approved", {
        description: `“${artwork.title}” is live on the marketplace as ${ARTWORK_RARITY_LABEL[rank]}.`,
      });
      router.push("/admin/moderation/artworks");
    } catch {
      toast.error("Could not approve artwork. Try again.");
    }
  }

  async function handleReject(reason: string) {
    try {
      await rejectMutation.mutateAsync({ artworkId: artwork.id, reason });
      dropFromQueue();
      appendAudit({
        adminName: adminName,
        action: "artwork.rejected",
        entityType: "artwork",
        entityId: artwork.id,
        entityLabel: artwork.title,
        detail: reason,
      });
      setRejectOpen(false);
      toast.success("Artwork rejected", {
        description: "The artist has been notified with your reason.",
      });
      router.push("/admin/moderation/artworks");
    } catch {
      toast.error("Could not reject artwork. Try again.");
    }
  }

  const sortedImages = [...artwork.images].sort(
    (a, b) => a.sortOrder - b.sortOrder,
  );

  return (
    // grid-cols-1 below lg isn't decorative — see app/admin/page.tsx's
    // identical comment: an implicit grid track sizes to its widest child's
    // min-content instead of shrinking, overflowing the page.
    <div className="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1.5fr)_minmax(0,1fr)] lg:items-start">
      {/* Left: the work itself, at a size you can actually judge. */}
      <div className="space-y-4">
        <div className="overflow-hidden rounded-xl border border-border bg-card">
          <div className="relative aspect-[4/3] w-full bg-muted">
            {sortedImages[0] ? (
              <Image
                src={sortedImages[0].url}
                alt={sortedImages[0].altText}
                fill
                sizes="(min-width: 1024px) 60vw, 100vw"
                className="object-contain"
                priority
              />
            ) : null}
          </div>
        </div>

        {sortedImages.length > 1 ? (
          <div className="grid grid-cols-4 gap-2 sm:grid-cols-6">
            {sortedImages.map((image, index) => (
              <button
                key={image.url}
                type="button"
                onClick={() => setZoomIndex(index)}
                className="group relative aspect-square overflow-hidden rounded-md border border-border bg-muted transition-colors hover:border-gold"
              >
                <Image
                  src={image.thumbnailUrl}
                  alt={image.altText}
                  fill
                  sizes="120px"
                  className="object-cover transition-transform group-hover:scale-105"
                />
              </button>
            ))}
          </div>
        ) : null}

        <section className="rounded-xl border border-border bg-card p-5">
          <h2 className="font-display text-base font-semibold text-foreground">
            Artist statement
          </h2>
          <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
            {artwork.description}
          </p>
        </section>
      </div>

      {/* Right: everything needed to decide, then the decision. */}
      <div className="space-y-4">
        <section className="rounded-xl border border-border bg-card p-5">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <h1 className="font-display text-lg font-semibold text-foreground">
                {artwork.title}
              </h1>
              <p className="mt-0.5 text-sm text-muted-foreground">
                {artwork.artistName}
              </p>
            </div>
            <AdminStatusBadge status={artwork.status} />
          </div>

          <dl className="mt-4 grid grid-cols-2 gap-x-4 gap-y-3 border-t border-border pt-4">
            <Detail
              label="Category"
              value={artwork.category}
              className="capitalize"
            />
            <Detail label="Medium" value={artwork.medium} />
            <Detail
              label="Dimensions"
              value={artwork.dimensions ?? "Not set"}
            />
            <Detail
              label="Year"
              value={artwork.yearCreated?.toString() ?? "Not set"}
            />
            <Detail
              label="Customer price"
              value={formatINR(artwork.customerPrice)}
            />
            <Detail label="Insured" value={artwork.insured ? "Yes" : "No"} />
            <Detail
              label="Listing"
              value={LISTING_TYPE_LABEL[artwork.listingType]}
            />
            <Detail
              label="Waiting"
              value={waitingDays === 0 ? "Today" : `${waitingDays} days`}
            />
          </dl>
        </section>

        <section className="rounded-xl border border-border bg-card p-5">
          <h2 className="font-display text-base font-semibold text-foreground">
            Artist context
          </h2>
          <dl className="mt-3 grid grid-cols-2 gap-x-4 gap-y-3">
            <Detail label="Verification" value={`Tier ${artistTier} of 3`} />
            <Detail label="Works listed" value={artistPriorWorks.toString()} />
          </dl>
          {artistTier === 0 ? (
            <p className="mt-3 flex items-start gap-2 rounded-md border border-gold/40 bg-gold/[0.06] p-3 text-xs text-muted-foreground">
              <ShieldAlert className="mt-px size-3.5 shrink-0 text-gold-bright" />
              First-time artist with no verification tiers cleared yet. Worth a
              closer look at documentation.
            </p>
          ) : null}
        </section>

        <EligibilityChecklist
          checked={checked}
          onToggle={(id: EligibilityId, next) =>
            setChecked((prev) => ({ ...prev, [id]: next }))
          }
          disabled={isBusy}
        />

        <section className="rounded-xl border border-border bg-card p-5">
          <h2 className="font-display text-base font-semibold text-foreground">
            Rank
            <span className="ml-2 text-xs font-normal text-muted-foreground">
              required
            </span>
          </h2>
          <p className="mt-1 text-xs text-muted-foreground">
            GalleryZone decides this, not the artist. Buyers see it on the
            artwork and can filter by it.
          </p>
          <div
            role="radiogroup"
            aria-label="Artwork rank"
            className="mt-3 grid grid-cols-2 gap-2"
          >
            {ARTWORK_RARITY_OPTIONS.map((option) => {
              const active = rank === option.value;
              return (
                <button
                  key={option.value}
                  type="button"
                  role="radio"
                  aria-checked={active}
                  onClick={() => setRank(option.value)}
                  disabled={isBusy}
                  className={`flex flex-col gap-0.5 rounded-md border px-3 py-2 text-left transition-colors disabled:opacity-50 ${
                    active
                      ? "border-gold bg-gold/10"
                      : "border-border hover:border-gold/50 hover:bg-muted/40"
                  }`}
                >
                  <span className="text-xs font-medium text-foreground">
                    <span className="mr-1.5 font-mono font-bold text-gold-bright">
                      {option.value}
                    </span>
                    {option.label}
                  </span>
                  <span className="text-[11px] leading-snug text-muted-foreground">
                    {option.description}
                  </span>
                </button>
              );
            })}
          </div>
        </section>

        <div className="flex flex-col gap-2 sm:flex-row">
          <Button
            onClick={handleApprove}
            disabled={!canApprove || isBusy}
            className="flex-1"
          >
            <Check className="size-4" />
            {approveMutation.isPending ? "Approving…" : "Approve & publish"}
          </Button>
          <Button
            variant="outline"
            onClick={() => setRejectOpen(true)}
            disabled={isBusy}
            className="flex-1"
          >
            <X className="size-4" />
            Reject
          </Button>
        </div>

        {!canApprove ? (
          <p className="text-center text-xs text-muted-foreground">
            {allCleared
              ? "Choose a rank to enable approval."
              : rank
                ? "Clear all five eligibility criteria to enable approval."
                : "Clear all five eligibility criteria and choose a rank to enable approval."}
          </p>
        ) : null}
      </div>

      <RejectReasonDialog
        open={rejectOpen}
        onOpenChange={setRejectOpen}
        title={`Reject “${artwork.title}”?`}
        description="The artist sees this reason, so make it something they can act on."
        presets={REJECT_PRESETS}
        isPending={rejectMutation.isPending}
        onSubmit={handleReject}
      />

      <Dialog
        open={zoomIndex !== null}
        onOpenChange={(open) => !open && setZoomIndex(null)}
      >
        <DialogContent className="max-w-4xl p-2">
          {zoomIndex !== null && sortedImages[zoomIndex] ? (
            <div className="relative aspect-[4/3] w-full">
              <Image
                src={sortedImages[zoomIndex].url}
                alt={sortedImages[zoomIndex].altText}
                fill
                sizes="90vw"
                className="rounded-md object-contain"
              />
            </div>
          ) : null}
        </DialogContent>
      </Dialog>
    </div>
  );
}

function Detail({
  label,
  value,
  className,
}: {
  label: string;
  value: string;
  className?: string;
}) {
  return (
    <div className="min-w-0">
      <dt className="text-xs text-muted-foreground">{label}</dt>
      <dd className={`truncate text-sm text-foreground ${className ?? ""}`}>
        {value}
      </dd>
    </div>
  );
}
