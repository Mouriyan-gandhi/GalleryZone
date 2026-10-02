"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { DownloadCoaButton } from "@/features/coa/download-coa-button";
import { useMyPassports } from "@/hooks/useMyPassports";
import { useSessionRole } from "@/hooks/useSessionRole";
import { isApiError } from "@/lib/api";
import type { SessionRole } from "@/lib/session";
import { cn } from "@/lib/utils";
import type { MyPassport } from "@/services/passportService";
import { passportEventToTransfer } from "@/services/verifyService";
import { activeDisplayTransfer } from "@/types/artwork";
import { formatDate, PassportLiveExample } from "./passport-live-example";
import type { PassportTopicSlug } from "./passport-topics";

type Viewer = "customer" | "artist" | "aggregator";

// How many pieces show before "Show all". Three keeps the topic's own
// explanation in view; the rest is one click away.
const VISIBLE = 3;

const HEADING: Record<Viewer, string> = {
  customer: "Your pieces",
  artist: "Your works",
  aggregator: "Pieces you hold",
};

const EMPTY: Record<Viewer, { text: string; label: string; href: string }> = {
  customer: {
    text: "You don't own a piece yet. Every piece you buy gets a passport.",
    label: "Browse artworks",
    href: "/marketplace",
  },
  artist: {
    text: "You haven't listed a work yet. Each work you list gets a passport.",
    label: "Submit artwork",
    href: "/dashboard/artworks/upload",
  },
  aggregator: {
    text: "You aren't holding a piece right now. Pieces you reserve show up here.",
    label: "Browse inventory",
    href: "/aggregator/inventory",
  },
};

// The one place a person manages what a topic describes, when there is one.
const MANAGE: Record<Viewer, Partial<Record<PassportTopicSlug, { label: string; href: string }>>> = {
  customer: {
    certificate: { label: "Ask for a signed copy", href: "/account/collection" },
    provenance: { label: "Hand over a piece", href: "/account/collection" },
    legacy: { label: "Resell or gift a piece", href: "/account/resale" },
  },
  artist: {
    identity: { label: "Link a tag", href: "/dashboard/coa-nfc" },
    certificate: { label: "Signed-copy requests", href: "/dashboard/coa-nfc" },
    legacy: { label: "Open your portfolio", href: "/dashboard/portfolio" },
  },
  aggregator: {},
};

const relationText = (relations: MyPassport["relations"]): string => {
  const made = relations.includes("artist");
  const owns = relations.includes("owner");
  if (made && owns) return "You made this and still own it";
  if (made) return "You made this piece";
  if (relations.includes("holder")) return "On display with you";
  return "You own this piece";
};

const linkClass =
  "inline-flex h-10 items-center gap-2 rounded-full border border-gold/60 px-5 text-sm font-medium text-gold-bright transition-[background-color,transform] duration-150 ease-out hover:bg-gold/10 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.97]";

// The slot under "what it includes". A signed-out visitor gets one real
// sample piece; a signed-in collector, artist or aggregator gets their own
// pieces, read through this topic. Admins and an aggregator on Legacy (which
// has nothing of their own to show) get the sample too.
export function PassportViewerPanel({ topic }: { topic: PassportTopicSlug }) {
  const role = useSessionRole();
  const viewer = viewerFor(role, topic);
  if (!viewer) return <PassportLiveExample topic={topic} />;
  return <MyPieces topic={topic} viewer={viewer} />;
}

function viewerFor(role: SessionRole | null, topic: PassportTopicSlug): Viewer | null {
  if (role === "customer" || role === "artist") return role;
  if (role === "aggregator" && topic !== "legacy") return role;
  return null;
}

function MyPieces({ topic, viewer }: { topic: PassportTopicSlug; viewer: Viewer }) {
  const query = useMyPassports(true);
  const [showAll, setShowAll] = useState(false);

  // The cookie said signed in but the API disagrees (expired sign-in): show
  // what a visitor sees rather than an error about an account they don't have.
  if (isApiError(query.error, 401)) return <PassportLiveExample topic={topic} />;

  const items = query.data?.items ?? [];
  const total = query.data?.total ?? 0;
  const shown = showAll ? items : items.slice(0, VISIBLE);
  const manage = MANAGE[viewer][topic];

  return (
    <section aria-labelledby="my-pieces" className="border-y border-border/60 bg-card/30">
      <div className="mx-auto max-w-[1200px] px-6 py-14 lg:px-10 lg:py-20">
        <div className="flex flex-wrap items-end justify-between gap-x-8 gap-y-3">
          <div>
            <h2 id="my-pieces" className="font-display text-2xl font-semibold text-foreground sm:text-3xl">
              {HEADING[viewer]}
            </h2>
            {query.data && total > 0 && (
              <p className="mt-2 text-sm text-muted-foreground">
                {total} {total === 1 ? "piece" : "pieces"}
                {total > items.length && `, showing the first ${items.length}`}
              </p>
            )}
          </div>
          {manage && total > 0 && (
            <Link href={manage.href} className={linkClass}>
              {manage.label}
              <ArrowRight className="size-4" strokeWidth={1.75} />
            </Link>
          )}
        </div>

        {query.isPending ? (
          <RowsSkeleton />
        ) : query.isError ? (
          <div role="alert" className="mt-8 rounded-2xl border border-border bg-card/60 p-6 sm:p-8">
            <p className="text-foreground">We couldn&apos;t load your pieces.</p>
            <p className="mt-1 text-sm text-muted-foreground">Check your connection and try again.</p>
            <button type="button" onClick={() => query.refetch()} className={cn(linkClass, "mt-5")}>
              Try again
            </button>
          </div>
        ) : items.length === 0 ? (
          <div className="mt-8 rounded-2xl border border-border bg-card/60 p-6 sm:p-8">
            <p className="max-w-md text-foreground">{EMPTY[viewer].text}</p>
            <Link href={EMPTY[viewer].href} className={cn(linkClass, "mt-5")}>
              {EMPTY[viewer].label}
              <ArrowRight className="size-4" strokeWidth={1.75} />
            </Link>
          </div>
        ) : (
          <>
            <ul className="mt-8 divide-y divide-border overflow-hidden rounded-2xl border border-border bg-card/60">
              {shown.map((entry) => (
                <PieceRow key={entry.passport.artworkId} entry={entry} topic={topic} />
              ))}
            </ul>
            {items.length > VISIBLE && (
              <button
                type="button"
                aria-expanded={showAll}
                onClick={() => setShowAll((open) => !open)}
                className={cn(linkClass, "mt-5")}
              >
                {showAll ? "Show fewer" : `Show all ${items.length} pieces`}
              </button>
            )}
          </>
        )}
      </div>
    </section>
  );
}

function PieceRow({ entry, topic }: { entry: MyPassport; topic: PassportTopicSlug }) {
  const { passport } = entry;
  const cover = passport.images[0];
  const handovers = passport.events.filter((e) => e.kind === "ownership" && e.status === "accepted").length;
  const display = activeDisplayTransfer(passport.events.map((e) => passportEventToTransfer(e, passport)));

  const facts: { label: string; value: string }[] =
    topic === "certificate"
      ? [
          { label: "Certificate number", value: passport.coaCertificateNumber ?? "Issued when approved" },
          { label: "Issued", value: formatDate(passport.coaIssuedAt) },
        ]
      : topic === "provenance"
        ? [
            { label: "Owner of record", value: passport.owner.displayName },
            { label: "Hand-overs recorded", value: String(handovers) },
            ...(display
              ? [{ label: "On display", value: `${display.toName} until ${formatDate(display.displayEndsAt)}` }]
              : []),
          ]
        : topic === "legacy"
          ? [
              { label: "On the record since", value: formatDate(passport.listedAt) },
              { label: "Hand-overs recorded", value: String(handovers) },
            ]
          : [
              { label: "Product ID", value: passport.productCode },
              ...(entry.nfcLinked !== null
                ? [{ label: "Label tag", value: entry.nfcLinked ? "Linked" : "Not linked yet" }]
                : []),
            ];

  return (
    <li className="grid gap-5 p-5 sm:p-6 md:grid-cols-[4.5rem_minmax(0,1fr)_auto] md:items-center md:gap-6">
      <div className="relative aspect-[4/5] w-[4.5rem] overflow-hidden rounded-md bg-muted ring-1 ring-border">
        {cover && (
          <Image src={cover.thumbnailUrl ?? cover.url} alt={cover.altText ?? passport.title} fill sizes="72px" className="object-cover" />
        )}
      </div>

      <div className="min-w-0">
        <p className="font-display text-lg font-semibold text-foreground">{passport.title}</p>
        <p className="text-sm text-muted-foreground">
          {passport.artistName}. {relationText(entry.relations)}.
        </p>
        <dl className="mt-4 grid gap-x-8 gap-y-3 sm:grid-cols-2">
          {facts.map((fact) => (
            <div key={fact.label}>
              <dt className="text-sm text-muted-foreground">{fact.label}</dt>
              <dd className="mt-0.5 font-medium text-foreground tabular-nums">{fact.value}</dd>
            </div>
          ))}
        </dl>
      </div>

      <div className="flex flex-wrap gap-2 md:justify-end">
        {topic === "certificate" ? (
          <DownloadCoaButton
            className="h-10 rounded-full px-5"
            certificate={{
              artworkId: passport.artworkId,
              productCode: passport.productCode,
              title: passport.title,
              artistName: passport.artistName,
              category: passport.category,
              medium: passport.medium,
              dimensions: passport.dimensions,
              yearCreated: passport.yearCreated,
              coaCertificateNumber: passport.coaCertificateNumber ?? "",
              coaIssueDate: passport.coaIssuedAt ?? "",
              ownerName: passport.owner.displayName,
            }}
          />
        ) : (
          <Link href={`/verify/${passport.artworkId}`} className={linkClass}>
            {topic === "provenance" ? "See full history" : "Open passport"}
            <ArrowRight className="size-4" strokeWidth={1.75} />
          </Link>
        )}
        {topic === "provenance" && entry.holdingId && (
          <Link href={`/aggregator/collection/${entry.holdingId}`} className={linkClass}>
            Open holding
          </Link>
        )}
      </div>
    </li>
  );
}

function RowsSkeleton() {
  return (
    <div
      aria-hidden="true"
      className="mt-8 divide-y divide-border overflow-hidden rounded-2xl border border-border bg-card/60"
    >
      {[0, 1].map((i) => (
        <div key={i} className="grid animate-pulse gap-5 p-5 sm:p-6 md:grid-cols-[4.5rem_minmax(0,1fr)_auto] md:items-center md:gap-6">
          <div className="aspect-[4/5] w-[4.5rem] rounded-md bg-muted" />
          <div className="space-y-3">
            <div className="h-5 w-48 max-w-full rounded bg-muted" />
            <div className="h-4 w-64 max-w-full rounded bg-muted" />
          </div>
          <div className="h-10 w-36 rounded-full bg-muted" />
        </div>
      ))}
    </div>
  );
}
