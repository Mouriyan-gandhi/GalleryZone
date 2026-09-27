"use client";

import { useState } from "react";
import Image from "next/image";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { toast } from "sonner";
import { Repeat2, Tag, X } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { formatINR } from "@/lib/utils";
import { Input } from "@/components/ui/input";
import { Field, FieldLabel, FieldError, FieldGroup } from "@/components/ui/field";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { PriceTag } from "@/components/shared/price-tag";
import { cn } from "@/lib/utils";
import { useCollection } from "@/hooks/useCollection";
import {
  useCustomerResaleListings,
  useCreateResaleListingMutation,
  useCompleteResaleMutation,
  useWithdrawResaleListingMutation,
} from "@/hooks/useCustomerResale";
import type { CollectionItem } from "@/services/customerCollectionService";

const listingSchema = z.object({
  listedPrice: z.coerce.number<number>().positive("Enter a listing price"),
});
type ListingFormValues = z.infer<typeof listingSchema>;

// Seller-side only (see customerResaleService's comment) — this demonstrates
// the "your owned artwork can go back on the market" capability the PRD
// calls out, not a full secondary-market checkout flow.
export function ResaleView() {
  const { data: collection, isPending: collectionPending } = useCollection();
  const { data: listings, isPending: listingsPending } =
    useCustomerResaleListings();
  const [listing, setListing] = useState<CollectionItem | null>(null);

  const isPending = collectionPending || listingsPending;

  if (isPending) {
    return (
      <div className="flex flex-col gap-3">
        {Array.from({ length: 2 }).map((_, i) => (
          <Skeleton key={i} className="h-24 w-full rounded-lg" />
        ))}
      </div>
    );
  }

  const activeArtworkIds = new Set(
    (listings ?? [])
      .filter((l) => l.status === "active")
      .map((l) => l.artworkId),
  );
  const eligible = (collection ?? []).filter(
    (item) => !activeArtworkIds.has(item.artwork.id),
  );

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h2 className="font-display text-lg font-semibold text-foreground">
          Eligible artworks
        </h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Any artwork in your collection can be listed for resale.
        </p>

        {eligible.length === 0 ? (
          <EmptyState
            icon={Repeat2}
            title="Nothing eligible right now"
            description="Artworks become eligible for resale once they're delivered and part of your collection."
            className="mt-4"
          />
        ) : (
          <div className="mt-4 flex flex-col gap-3">
            {eligible.map((item) => (
              <div
                key={item.artwork.id}
                className="flex flex-wrap items-center gap-3 rounded-lg border border-border bg-card p-4 sm:flex-nowrap sm:gap-4"
              >
                <div className="flex min-w-0 basis-full items-center gap-3 sm:flex-1 sm:gap-4">
                  <div className="relative size-14 shrink-0 overflow-hidden rounded-md bg-muted">
                    <Image
                      src={item.artwork.thumbnailUrl}
                      alt={item.artwork.title}
                      fill
                      sizes="56px"
                      className="object-cover"
                    />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium text-foreground">
                      {item.artwork.title}
                    </p>
                    <p className="truncate text-xs text-muted-foreground">
                      Acquired for <PriceTag amount={item.paidPrice} className="text-xs" />
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setListing(item)}
                  className="inline-flex shrink-0 items-center gap-1.5 rounded-md border border-gold/60 px-3 py-1.5 text-xs font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
                >
                  <Tag className="size-3.5" />
                  List for resale
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      <div>
        <h2 className="font-display text-lg font-semibold text-foreground">
          Your listings
        </h2>

        {!listings || listings.length === 0 ? (
          <EmptyState
            icon={Tag}
            title="No resale listings yet"
            description="Artworks you list for resale will appear here."
            className="mt-4"
          />
        ) : (
          <div className="mt-4 flex flex-col gap-3">
            {listings.map((l) => {
              const artwork = collection?.find((c) => c.artwork.id === l.artworkId)?.artwork;
              return (
                <div
                  key={l.id}
                  className="flex flex-wrap items-center gap-3 rounded-lg border border-border bg-card p-4 sm:flex-nowrap sm:gap-4"
                >
                  <div className="flex min-w-0 basis-full items-center gap-3 sm:flex-1 sm:gap-4">
                    <div className="relative size-14 shrink-0 overflow-hidden rounded-md bg-muted">
                      {artwork && (
                        <Image
                          src={artwork.thumbnailUrl}
                          alt={artwork.title}
                          fill
                          sizes="56px"
                          className="object-cover"
                        />
                      )}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-foreground">
                        {artwork?.title ?? "Artwork"}
                      </p>
                      <PriceTag amount={l.listedPrice} className="text-sm" />
                    </div>
                  </div>
                  <div className="flex shrink-0 items-center gap-4">
                    <ListingStatusPill status={l.status} />
                    {l.status === "active" && (
                      <>
                        <SimulateSaleButton id={l.id} />
                        <WithdrawButton id={l.id} />
                      </>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <ListingDialog item={listing} onClose={() => setListing(null)} />
    </div>
  );
}

function ListingStatusPill({ status }: { status: string }) {
  return (
    <span
      className={cn(
        "shrink-0 rounded-full border px-2.5 py-1 text-xs font-medium capitalize",
        status === "active"
          ? "border-emerald-500/30 bg-emerald-500/10 text-emerald-400"
          : "border-border bg-secondary text-muted-foreground",
      )}
    >
      {status}
    </span>
  );
}

// Nobody else exists to buy the piece in this demo, so this stands in for a
// second collector. The point is the money: the proceeds land in the seller's
// balance, where their bank details can take them out.
function SimulateSaleButton({ id }: { id: string }) {
  const completeMutation = useCompleteResaleMutation();

  return (
    <button
      type="button"
      onClick={() =>
        completeMutation.mutate(id, {
          onSuccess: (listing) =>
            toast.success("Resale complete", {
              description: `${formatINR(listing.listedPrice)} added to your balance — withdraw it from Wallet.`,
            }),
          onError: (error) => toast.error(error.message),
        })
      }
      disabled={completeMutation.isPending}
      title="Demo only — stands in for a buyer"
      className="inline-flex shrink-0 items-center gap-1 rounded-md border border-dashed border-gold/40 px-2.5 py-1.5 text-xs font-medium text-gold-bright transition-colors hover:bg-gold/10 disabled:pointer-events-none disabled:opacity-40"
    >
      Simulate sale
    </button>
  );
}

function WithdrawButton({ id }: { id: string }) {
  const withdrawMutation = useWithdrawResaleListingMutation();

  return (
    <button
      type="button"
      onClick={() =>
        withdrawMutation.mutate(id, {
          onSuccess: () => toast.success("Listing withdrawn"),
        })
      }
      disabled={withdrawMutation.isPending}
      className="inline-flex shrink-0 items-center gap-1 rounded-md border border-border px-2.5 py-1.5 text-xs font-medium text-foreground transition-colors hover:bg-muted disabled:pointer-events-none disabled:opacity-40"
    >
      <X className="size-3.5" />
      Withdraw
    </button>
  );
}

function ListingDialog({
  item,
  onClose,
}: {
  item: CollectionItem | null;
  onClose: () => void;
}) {
  const createMutation = useCreateResaleListingMutation();
  const { control, handleSubmit, reset } = useForm<ListingFormValues>({
    resolver: zodResolver(listingSchema),
    defaultValues: { listedPrice: 0 },
  });

  function handleClose() {
    reset({ listedPrice: 0 });
    onClose();
  }

  function onSubmit(values: ListingFormValues) {
    if (!item) return;
    createMutation.mutate(
      { artworkId: item.artwork.id, listedPrice: values.listedPrice },
      {
        onSuccess: () => {
          toast.success("Listed for resale");
          handleClose();
        },
        onError: (error) => toast.error(error.message),
      },
    );
  }

  return (
    <Dialog open={Boolean(item)} onOpenChange={(open) => !open && handleClose()}>
      <DialogContent className="max-w-sm">
        {item ? (
          <>
            <DialogHeader>
              <DialogTitle>List &ldquo;{item.artwork.title}&rdquo;</DialogTitle>
            </DialogHeader>

            <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
              <FieldGroup>
                <Controller
                  control={control}
                  name="listedPrice"
                  render={({ field, fieldState }) => (
                    <Field data-invalid={fieldState.invalid}>
                      <FieldLabel htmlFor="listedPrice">Asking price (₹)</FieldLabel>
                      <Input
                        id="listedPrice"
                        type="number"
                        min={1}
                        step={1}
                        className="h-10"
                        {...field}
                        aria-invalid={fieldState.invalid}
                      />
                      <FieldError errors={[fieldState.error]} />
                    </Field>
                  )}
                />
              </FieldGroup>

              <p className="text-xs text-muted-foreground">
                Originally acquired for ₹{item.paidPrice.toLocaleString("en-IN")}.
                Buyer inquiries and resale checkout aren&rsquo;t wired to a live
                marketplace in this demo.
              </p>

              <Button type="submit" disabled={createMutation.isPending}>
                {createMutation.isPending ? "Listing…" : "List for resale"}
              </Button>
            </form>
          </>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
