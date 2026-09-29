"use client";

import Image from "next/image";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { useMarketplaceOverview } from "@/hooks/useArtworks";
import { useArtwork } from "@/hooks/useArtwork";
import { useVerifyPassport } from "@/hooks/useVerify";
import { ArtworkQr } from "@/features/verify/artwork-qr";
import { isPlaceholderImage } from "@/lib/api-mappers";
import { isDemoId } from "@/lib/demo-artworks";
import type { PassportTopicSlug } from "./passport-topics";

function formatDate(iso: string | null | undefined): string {
  if (!iso) return "Pending";
  return new Intl.DateTimeFormat("en-IN", { day: "numeric", month: "long", year: "numeric" }).format(new Date(iso));
}

// A real listed piece with a certificate, so the example is a passport anyone
// can open rather than a mock-up. Demo listings have no passport behind them.
function useSamplePiece() {
  const overview = useMarketplaceOverview();
  const candidates = (overview.data?.artworks ?? []).filter(
    (a) => a.coaCertificateNumber && !isDemoId(a.id),
  );
  const sample = candidates.find((a) => !isPlaceholderImage(a.thumbnailUrl)) ?? candidates[0];
  return { sample, loading: overview.isPending };
}

export function PassportLiveExample({ topic }: { topic: PassportTopicSlug }) {
  const { sample, loading: overviewLoading } = useSamplePiece();
  const artworkQuery = useArtwork(sample?.id ?? "");
  const passportQuery = useVerifyPassport(sample?.id ?? "");

  if (!overviewLoading && !sample) return null;

  const artwork = artworkQuery.data;
  const passport = passportQuery.data;
  const settled = !artworkQuery.isLoading && !passportQuery.isLoading;
  if (settled && sample && (!artwork || !passport)) return null;

  const handovers = passport?.events.filter((e) => e.kind === "ownership" && e.status === "accepted").length ?? 0;
  const facts: { label: string; value: string }[] =
    topic === "certificate"
      ? [
          { label: "Certificate number", value: artwork?.coaCertificateNumber || "Pending" },
          { label: "Issued", value: formatDate(artwork?.coaIssueDate) },
        ]
      : topic === "provenance"
        ? [
            { label: "Owner of record", value: passport?.owner.displayName ?? "" },
            { label: "Hand-overs recorded", value: String(handovers) },
          ]
        : topic === "legacy"
          ? [
              { label: "Made by", value: sample?.artistName ?? "" },
              { label: "On the record since", value: formatDate(passport?.listedAt) },
              { label: "Hand-overs recorded", value: String(handovers) },
            ]
          : [{ label: "Product ID", value: passport?.productCode ?? "" }];

  return (
    <section aria-labelledby="live-example" className="border-y border-border/60 bg-card/30">
      <div className="mx-auto max-w-[1200px] px-6 py-14 lg:px-10 lg:py-20">
        <h2 id="live-example" className="font-display text-2xl font-semibold text-foreground sm:text-3xl">
          See it on a real piece
        </h2>

        {!sample || !settled ? (
          <div className="mt-8 h-72 animate-pulse rounded-2xl bg-muted/40" aria-hidden="true" />
        ) : (
          <div className="mt-8 grid items-center gap-8 rounded-2xl border border-border bg-card/60 p-6 sm:p-8 md:grid-cols-[14rem_minmax(0,1fr)] md:gap-10">
            <div className="flex flex-col gap-3">
              <div className="relative aspect-[4/5] w-full max-w-56 overflow-hidden rounded-lg bg-muted ring-1 ring-border">
                <Image
                  src={sample.thumbnailUrl}
                  alt={sample.title}
                  fill
                  sizes="224px"
                  className="object-cover"
                />
              </div>
              <p className="font-display text-lg font-semibold text-foreground">{sample.title}</p>
              <p className="-mt-2 text-sm text-muted-foreground">{sample.artistName}</p>
            </div>

            <div className="flex flex-col gap-6">
              <dl className="grid gap-x-8 gap-y-5 sm:grid-cols-2">
                {facts.map((fact) => (
                  <div key={fact.label}>
                    <dt className="text-sm text-muted-foreground">{fact.label}</dt>
                    <dd className="mt-1 font-display text-xl font-semibold text-foreground tabular-nums">
                      {fact.value}
                    </dd>
                  </div>
                ))}
              </dl>

              {topic === "identity" && (
                <div className="flex items-center gap-4">
                  <ArtworkQr artworkId={sample.id} size={112} />
                  <p className="max-w-52 text-sm text-muted-foreground">
                    This is the code for the piece on the left. Scan it with a phone camera.
                  </p>
                </div>
              )}

              <Link
                href={`/verify/${sample.id}`}
                className="inline-flex h-11 w-fit items-center gap-2 rounded-full border border-gold/60 px-5 text-sm font-medium text-gold-bright transition-[background-color,transform] duration-150 ease-out hover:bg-gold/10 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.97]"
              >
                Open this passport
                <ArrowRight className="size-4" strokeWidth={1.75} />
              </Link>
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
