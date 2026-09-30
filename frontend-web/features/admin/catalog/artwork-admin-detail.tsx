"use client";

import { useCurrentUser } from "@/hooks/useCurrentUser";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { EyeOff, ExternalLink, Send, Check, X, Undo2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AdminStatusBadge } from "@/features/admin/admin-status-badge";
import { ConfirmActionDialog } from "@/features/admin/confirm-action-dialog";
import {
  useActiveHolding,
  useDelistArtworkMutation,
  usePullBackHoldingMutation,
  useSetArtworkInsuranceStatusMutation,
  useSetArtworkRarityMutation,
} from "@/hooks/useAdminCatalog";
import { RarityBadge } from "@/components/shared/rarity-badge";
import { TransferRightsDialog } from "@/features/verify/transfer-rights-dialog";
import { PullBackHoldingDialog } from "./pull-back-holding-dialog";
import { HoldingExtensionPanel } from "./holding-extension-panel";
import { useAdminAuditStore } from "@/store/useAdminAuditStore";
import { formatINR } from "@/lib/utils";
import { AGGREGATOR_CYCLE_MONTHS } from "@/lib/pricing";
import {
  ARTWORK_RARITY_LABEL,
  ARTWORK_RARITY_OPTIONS,
  CUSTODY_PARTY_LABEL,
  insuranceStatusOf,
  resolveCustody,
  type Artwork,
  type ArtworkRarity,
  type ArtworkStatus,
} from "@/types/artwork";

const STATUS_LABEL: Record<ArtworkStatus, string> = {
  draft: "Draft saved",
  pending_approval: "Submitted for review",
  marketplace: "Published to marketplace",
  reserved: "Reserved by aggregator",
  preparing_dispatch: "Preparing dispatch",
  in_transit: "In transit",
  with_aggregator: "With aggregator",
  sold: "Sold",
  settlement_complete: "Settlement complete",
  delivered: "Delivered",
  completed: "Completed",
  returned: "Returned",
  sold_externally: "Sold outside GalleryZone",
};

export function ArtworkAdminDetail({ artwork }: { artwork: Artwork }) {
  const adminName = useCurrentUser().data?.name ?? "Admin";
  const queryClient = useQueryClient();
  const appendAudit = useAdminAuditStore((s) => s.append);
  const delistMutation = useDelistArtworkMutation();
  const rarityMutation = useSetArtworkRarityMutation();
  const insuranceMutation = useSetArtworkInsuranceStatusMutation();
  const { data: activeHolding } = useActiveHolding(artwork.id);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [transferOpen, setTransferOpen] = useState(false);
  const [pullBackOpen, setPullBackOpen] = useState(false);
  const pullBackMutation = usePullBackHoldingMutation();

  const isLive = artwork.status === "marketplace";
  // A transfer is recorded as coming FROM whoever currently holds the piece,
  // not from GalleryZone — an admin acting on an owner's behalf must not
  // rewrite the chain to say the platform owned it. The named owner is used
  // when a transfer has already put one on the record.
  const custody = resolveCustody(artwork);
  const currentOwner =
    custody.legalOwnerName ??
    (custody.legalOwner === "artist"
      ? artwork.artistName
      : CUSTODY_PARTY_LABEL[custody.legalOwner]);
  const sortedImages = [...artwork.images].sort(
    (a, b) => a.sortOrder - b.sortOrder,
  );
  const history = [...artwork.statusHistory].sort(
    (a, b) => new Date(a.changedAt).getTime() - new Date(b.changedAt).getTime(),
  );

  // Clicking the rank a piece already carries clears it — an admin who ranked
  // something wrongly needs a way back to unranked, and a separate Clear button
  // for four buttons is more chrome than the job deserves.
  function handleRarity(next: ArtworkRarity) {
    const rarity = artwork.rarityType === next ? null : next;
    rarityMutation.mutate(
      { artworkId: artwork.id, rarity },
      {
        onSuccess: () => {
          appendAudit({
            adminName: adminName,
            action: rarity ? "artwork.ranked" : "artwork.rank_cleared",
            entityType: "artwork",
            entityId: artwork.id,
            entityLabel: artwork.title,
            detail: rarity ? ARTWORK_RARITY_LABEL[rarity] : undefined,
          });
          toast.success(
            rarity
              ? `Ranked ${ARTWORK_RARITY_OPTIONS.find((o) => o.value === rarity)?.label}`
              : "Rank cleared",
            { description: `“${artwork.title}” on the marketplace card.` },
          );
        },
        onError: (error) => toast.error(error.message),
      },
    );
  }

  function handleInsuranceDecision(decision: "approved" | "rejected") {
    insuranceMutation.mutate(
      { artworkId: artwork.id, insuranceStatus: decision },
      {
        onSuccess: () => {
          appendAudit({
            adminName: adminName,
            action:
              decision === "approved"
                ? "insurance.approved"
                : "insurance.rejected",
            entityType: "artwork",
            entityId: artwork.id,
            entityLabel: artwork.title,
          });
          toast.success(
            decision === "approved"
              ? "Insurance verified"
              : "Insurance rejected",
            { description: `“${artwork.title}”` },
          );
        },
        onError: () => toast.error("Could not update insurance status."),
      },
    );
  }

  async function handleDelist() {
    try {
      await delistMutation.mutateAsync(artwork.id);
      queryClient.setQueryData<Artwork[]>(["admin-artworks"], (prev) =>
        (prev ?? []).map((a) =>
          a.id === artwork.id ? { ...a, status: "returned" } : a,
        ),
      );
      appendAudit({
        adminName: adminName,
        action: "artwork.delisted",
        entityType: "artwork",
        entityId: artwork.id,
        entityLabel: artwork.title,
      });
      setConfirmOpen(false);
      toast.success("Artwork delisted", {
        description: `“${artwork.title}” is no longer visible on the marketplace.`,
      });
    } catch {
      toast.error("Could not delist artwork. Try again.");
    }
  }

  return (
    <div className="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1.4fr)_minmax(0,1fr)] lg:items-start">
      <div className="space-y-4">
        <div className="overflow-hidden rounded-xl border border-border bg-card">
          <div className="relative aspect-[4/3] w-full bg-muted">
            {sortedImages[0] ? (
              <Image
                src={sortedImages[0].url}
                alt={sortedImages[0].altText}
                fill
                sizes="(min-width: 1024px) 55vw, 100vw"
                className="object-contain"
              />
            ) : null}
          </div>
        </div>

        <section className="rounded-xl border border-border bg-card">
          <div className="border-b border-border px-5 py-4">
            <h2 className="font-display text-base font-semibold text-foreground">
              Status history
            </h2>
            <p className="mt-0.5 text-xs text-muted-foreground">
              Append-only. Every transition this work has been through.
            </p>
          </div>
          <ol className="px-5 py-4">
            {history.map((event, index) => {
              const isLast = index === history.length - 1;
              return (
                <li
                  key={`${event.status}-${event.changedAt}`}
                  className="relative flex gap-4 pb-5 last:pb-0"
                >
                  {!isLast ? (
                    <span
                      aria-hidden
                      className="absolute top-3 left-[5px] h-full w-px bg-border"
                    />
                  ) : null}
                  <span
                    aria-hidden
                    className={`relative mt-1.5 size-2.5 shrink-0 rounded-full ${
                      isLast ? "bg-gold-bright" : "bg-border"
                    }`}
                  />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium text-foreground">
                      {STATUS_LABEL[event.status]}
                    </p>
                    <time
                      dateTime={event.changedAt}
                      className="text-xs text-muted-foreground"
                    >
                      {new Date(event.changedAt).toLocaleDateString("en-IN", {
                        day: "numeric",
                        month: "short",
                        year: "numeric",
                      })}
                    </time>
                  </div>
                </li>
              );
            })}
          </ol>
        </section>
      </div>

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
            <Detail label="Type" value={artwork.artworkType ?? "Not set"} />
            {artwork.category === "painting" && (
              <Detail
                label="Painting style"
                value={artwork.paintingStyle ?? "Not set"}
              />
            )}
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
          </dl>
        </section>

        <section className="rounded-xl border border-border bg-card p-5">
          <h2 className="font-display text-base font-semibold text-foreground">
            Identity & provenance
          </h2>
          <dl className="mt-3 space-y-3">
            <Detail
              label="COA certificate"
              value={artwork.coaCertificateNumber}
              mono
            />
            <Detail
              label="COA issued"
              value={new Date(artwork.coaIssueDate).toLocaleDateString(
                "en-IN",
                {
                  day: "numeric",
                  month: "short",
                  year: "numeric",
                },
              )}
            />
          </dl>
          <Link
            href={`/verify/${artwork.id}`}
            target="_blank"
            className="mt-4 inline-flex items-center gap-1.5 text-sm text-gold-bright transition-colors hover:text-gold"
          >
            View public passport
            <ExternalLink className="size-3.5" />
          </Link>
        </section>

        {artwork.insured && (
          <section className="rounded-xl border border-border bg-card p-5">
            <div className="flex items-center justify-between gap-3">
              <h2 className="font-display text-base font-semibold text-foreground">
                Insurance
              </h2>
              <AdminStatusBadge status={insuranceStatusOf(artwork)} size="sm" />
            </div>
            <dl className="mt-3">
              <Detail
                label="Policy / certificate number"
                value={artwork.insuranceNumber ?? "Not submitted"}
                mono
              />
            </dl>
            {insuranceStatusOf(artwork) === "submitted" && (
              <div className="mt-3 flex gap-2">
                <Button
                  size="sm"
                  onClick={() => handleInsuranceDecision("approved")}
                  disabled={insuranceMutation.isPending}
                  className="flex-1"
                >
                  <Check className="size-4" />
                  Verify
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleInsuranceDecision("rejected")}
                  disabled={insuranceMutation.isPending}
                  className="flex-1"
                >
                  <X className="size-4" />
                  Reject
                </Button>
              </div>
            )}
          </section>
        )}

        <section className="rounded-xl border border-border bg-card p-5">
          <div className="flex items-center justify-between gap-3">
            <h2 className="font-display text-base font-semibold text-foreground">
              Rank
            </h2>
            <RarityBadge rarity={artwork.rarityType} />
          </div>
          <p className="mt-1 text-xs text-muted-foreground">
            GalleryZone decides this, not the artist. It shows on the artwork
            image everywhere a buyer sees the piece, and buyers can filter by
            it.
          </p>
          <div className="mt-3 flex flex-col gap-1.5">
            {ARTWORK_RARITY_OPTIONS.map((option) => {
              const active = artwork.rarityType === option.value;
              return (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => handleRarity(option.value)}
                  disabled={rarityMutation.isPending}
                  aria-pressed={active}
                  className={`flex items-start gap-2.5 rounded-md border px-3 py-2 text-left transition-colors disabled:opacity-50 ${
                    active
                      ? "border-gold bg-gold/10"
                      : "border-border hover:border-gold/50 hover:bg-muted/40"
                  }`}
                >
                  <span className="mt-px w-4 shrink-0 font-mono text-xs font-bold text-gold-bright">
                    {option.value}
                  </span>
                  <span className="flex flex-col gap-0.5">
                    <span className="text-xs font-medium text-foreground">
                      {option.label}
                    </span>
                    <span className="text-[11px] leading-snug text-muted-foreground">
                      {option.description}
                    </span>
                  </span>
                </button>
              );
            })}
          </div>
          <p className="mt-2 text-[11px] text-muted-foreground">
            Selecting the current rank again clears it.
          </p>
        </section>

        {activeHolding && (
          <section className="rounded-xl border border-border bg-card p-5">
            <div className="flex items-center justify-between gap-3">
              <h2 className="font-display text-base font-semibold text-foreground">
                Aggregator placement
              </h2>
              <span className="rounded-full border border-sky-500/30 bg-sky-500/10 px-2 py-0.5 text-[11px] font-medium text-sky-400">
                On display
              </span>
            </div>
            <p className="mt-1 text-xs leading-snug text-muted-foreground">
              artwork.status stays &ldquo;marketplace&rdquo; while a piece is
              reserved &mdash; this comes from the holding record, which is
              the only place the placement actually lives.
            </p>
            <dl className="mt-3 grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
              <div>
                <dt className="text-xs text-muted-foreground">Advance held</dt>
                <dd className="tabular-nums text-foreground">
                  {formatINR(activeHolding.advanceAmount)}
                </dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Cycle month</dt>
                <dd className="text-foreground">
                  {activeHolding.cycleMonth} of {AGGREGATOR_CYCLE_MONTHS}
                </dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">
                  Selling price (incl. GST)
                </dt>
                <dd className="tabular-nums text-foreground">
                  {formatINR(activeHolding.displayPrice)}
                </dd>
              </div>
              {activeHolding.cycleMonth === 1 && (
                <div>
                  <dt className="text-xs text-muted-foreground">Priced</dt>
                  <dd className="text-foreground">
                    {activeHolding.appreciated
                      ? "Above GalleryZone's price"
                      : "At GalleryZone's price"}
                  </dd>
                </div>
              )}
            </dl>
            <HoldingExtensionPanel holding={activeHolding} />
            <Button
              variant="outline"
              onClick={() => setPullBackOpen(true)}
              disabled={pullBackMutation.isPending}
              className="mt-3 w-full"
            >
              <Undo2 className="size-4" />
              Pull back from aggregator
            </Button>
            <p className="mt-2 text-[11px] leading-snug text-muted-foreground">
              Ends the placement now. The aggregator&rsquo;s advance is
              released; the delivery deposit is your call.
            </p>
          </section>
        )}

        <section className="rounded-xl border border-border bg-card p-5">
          <h2 className="font-display text-base font-semibold text-foreground">
            Admin actions
          </h2>
          <p className="mt-1 text-xs text-muted-foreground">
            {isLive
              ? "Delisting pulls this work from the marketplace immediately."
              : "This work is not currently live on the marketplace."}
          </p>
          <Button
            variant="outline"
            onClick={() => setConfirmOpen(true)}
            disabled={!isLive || delistMutation.isPending}
            className="mt-3 w-full"
          >
            <EyeOff className="size-4" />
            Delist from marketplace
          </Button>

          <Button
            variant="outline"
            onClick={() => setTransferOpen(true)}
            className="mt-2 w-full"
          >
            <Send className="size-4" />
            Transfer rights
          </Button>
          <p className="mt-2 text-[11px] leading-snug text-muted-foreground">
            Ownership or a display loan, on behalf of {currentOwner}. The other
            side still has to accept the link before anything moves.
          </p>
        </section>
      </div>

      <PullBackHoldingDialog
        holding={activeHolding ?? null}
        artworkTitle={artwork.title}
        open={pullBackOpen}
        onOpenChange={setPullBackOpen}
      />

      <TransferRightsDialog
        open={transferOpen}
        onOpenChange={setTransferOpen}
        artworkId={artwork.id}
        artworkTitle={artwork.title}
        fromName={currentOwner}
      />

      <ConfirmActionDialog
        open={confirmOpen}
        onOpenChange={setConfirmOpen}
        title={`Delist “${artwork.title}”?`}
        description="It disappears from the marketplace straight away. The artist keeps the work and can resubmit it."
        confirmLabel="Delist"
        destructive
        isPending={delistMutation.isPending}
        onConfirm={handleDelist}
      />
    </div>
  );
}

function Detail({
  label,
  value,
  className,
  mono = false,
}: {
  label: string;
  value: string;
  className?: string;
  mono?: boolean;
}) {
  return (
    <div className="min-w-0">
      <dt className="text-xs text-muted-foreground">{label}</dt>
      <dd
        className={`truncate text-sm text-foreground ${mono ? "font-mono tabular-nums" : ""} ${className ?? ""}`}
      >
        {value}
      </dd>
    </div>
  );
}
