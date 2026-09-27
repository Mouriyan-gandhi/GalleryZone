"use client";

import { useMemo } from "react";
import {
  Award,
  Building2,
  CalendarClock,
  CircleDot,
  Clock3,
  FileEdit,
  PackageCheck,
  Printer,
  ScanLine,
  Truck,
  Undo2,
  UserRoundCheck,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { Artwork, OwnershipTransfer } from "@/types/artwork";
import { isDisplayActive, resolveCustody, transferKind } from "@/types/artwork";
import { useArtworkTransfers } from "@/hooks/useOwnershipTransfers";
import { useArtworkCoaRequests } from "@/hooks/usePhysicalCoa";

// Two histories, side by side, because a certificate answers two questions that
// are not the same question: WHO OWNS THIS, and WHO IS ALLOWED TO SHOW IT. A
// piece can be owned by a collector in Chennai and hanging in a gallery in Pune.
//
// They are also shaped differently, so they are drawn differently rather than as
// one timeline component used twice. Ownership is a CHAIN — it moves once, in
// one direction, and only the last link is current. Display rights are
// EPISODES — each has a start and an end, they do not accumulate, and the piece
// coming back is the normal end of one rather than an incident.

type Event = {
  at: string;
  icon: typeof FileEdit;
  label: string;
  detail?: string;
  /** Renders as the live state of this record rather than a past event. */
  state?: "current" | "pending";
};

// Splitting by status is only honest because the two paths share none: a piece
// heading to an aggregator goes reserved -> preparing_dispatch -> in_transit ->
// with_aggregator, and a piece that has been bought goes sold -> delivered ->
// completed. Explicit maps rather than a list of exceptions, so a new status has
// to be given a side deliberately or it simply will not appear.
const OWNERSHIP_STATUS: Record<string, string> = {
  draft: "Listing created by the artist",
  pending_approval: "Submitted to GalleryZone for review",
  marketplace: "Approved and listed for sale",
  sold: "Sold",
  settlement_complete: "Settlement completed",
  delivered: "Delivered to the buyer",
  completed: "Sale completed",
  sold_externally: "Sold outside GalleryZone",
};

const DISPLAY_STATUS: Record<string, { label: string; icon: typeof FileEdit }> =
  {
    reserved: { label: "Reserved for aggregator display", icon: Clock3 },
    preparing_dispatch: { label: "Being prepared for dispatch", icon: PackageCheck },
    in_transit: { label: "In transit to the display space", icon: Truck },
    with_aggregator: { label: "On display with an aggregator", icon: Building2 },
    returned: { label: "Came back from display", icon: Undo2 },
  };

export function ArtworkHistory({ artwork }: { artwork: Artwork }) {
  const { data: transfers } = useArtworkTransfers(artwork.id);
  const { data: coaRequests } = useArtworkCoaRequests(artwork.id);

  const { ownership, display, ownerName } = useMemo(() => {
    const ownership: Event[] = [];
    const display: Event[] = [];

    for (const event of artwork.statusHistory) {
      const owned = OWNERSHIP_STATUS[event.status];
      if (owned) {
        ownership.push({ at: event.changedAt, icon: FileEdit, label: owned });
        continue;
      }
      const shown = DISPLAY_STATUS[event.status];
      if (shown) {
        display.push({
          at: event.changedAt,
          icon: shown.icon,
          label: shown.label,
        });
      }
    }

    // The certificate and the tag are ownership facts: they are what proves who
    // holds the piece, and they travel with it when it changes hands.
    ownership.push({
      at: artwork.coaIssueDate,
      icon: Award,
      label: "Certificate of Authenticity issued",
      detail: artwork.coaCertificateNumber,
    });

    // No timestamp exists for tagging — the tag is either attached or it is not
    // — so it is pinned to the certificate's date rather than invented.
    if (artwork.nfcTagId) {
      ownership.push({
        at: artwork.coaIssueDate,
        icon: ScanLine,
        label: "NFC / QR tag linked",
        detail: artwork.nfcTagId,
      });
    }

    for (const transfer of transfers ?? []) {
      if (transfer.status === "cancelled") continue;
      if (transferKind(transfer) === "display") {
        display.push(displayEvent(transfer));
      } else {
        ownership.push(ownershipEvent(transfer));
      }
    }

    for (const request of coaRequests ?? []) {
      ownership.push({
        at: request.requestedAt,
        icon: Printer,
        label: "Paper certificate requested",
        detail: `By ${request.requestedByName}`,
      });
      if (request.status === "dispatched" && request.dispatchedAt) {
        ownership.push({
          at: request.dispatchedAt,
          icon: PackageCheck,
          label: "Signed paper certificate dispatched",
          detail: request.courierRef ?? undefined,
        });
      }
    }

    const newestFirst = (a: Event, b: Event) => b.at.localeCompare(a.at);
    const custody = resolveCustody(artwork);
    return {
      ownership: ownership.sort(newestFirst),
      display: display.sort(newestFirst),
      ownerName: custody.legalOwnerName ?? artwork.artistName,
    };
  }, [artwork, transfers, coaRequests]);

  const onDisplayNow = display.some((e) => e.state === "current");

  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <Panel
        icon={UserRoundCheck}
        title="Ownership"
        summary={`Now with ${ownerName}`}
        caption="Who owns this piece. Each hand-over is recorded when the other side accepts it."
        events={ownership}
        emptyText="Nothing recorded yet."
      />
      <Panel
        icon={Building2}
        title="Display rights"
        summary={onDisplayNow ? "On display now" : "Not on display"}
        summaryMuted={!onDisplayNow}
        caption="Who has been allowed to show it. A loan never changes the owner."
        events={display}
        emptyText="This piece has never been out on display."
      />
    </div>
  );
}

function ownershipEvent(transfer: OwnershipTransfer): Event {
  if (transfer.status === "pending") {
    return {
      at: transfer.initiatedAt,
      icon: Clock3,
      label: `Transfer to ${transfer.toName}`,
      detail: `From ${transfer.fromName}`,
      state: "pending",
    };
  }
  return {
    at: transfer.acceptedAt ?? transfer.initiatedAt,
    icon: UserRoundCheck,
    label: `Transferred to ${transfer.toName}`,
    detail: `From ${transfer.fromName}`,
  };
}

function displayEvent(transfer: OwnershipTransfer): Event {
  if (transfer.status === "pending") {
    return {
      at: transfer.initiatedAt,
      icon: Clock3,
      label: `Offered to ${transfer.toName}`,
      detail: "Awaiting acceptance",
      state: "pending",
    };
  }

  const at = transfer.acceptedAt ?? transfer.initiatedAt;

  // A loan still running, one that ran its course, and one the owner pulled
  // back early are three different facts.
  if (isDisplayActive(transfer)) {
    return {
      at,
      icon: CalendarClock,
      label: `With ${transfer.toName}`,
      detail: transfer.displayEndsAt
        ? `Until ${formatDate(transfer.displayEndsAt)}`
        : undefined,
      state: "current",
    };
  }

  const endedOn = transfer.displayEndedAt ?? transfer.displayEndsAt;
  return {
    at,
    icon: Undo2,
    label: `With ${transfer.toName}`,
    detail: endedOn
      ? `${transfer.displayEndedAt ? "Ended early" : "Ran to"} ${formatDate(endedOn)}`
      : "Ended",
  };
}

function Panel({
  icon: Icon,
  title,
  summary,
  summaryMuted = false,
  caption,
  events,
  emptyText,
}: {
  icon: typeof FileEdit;
  title: string;
  summary: string;
  summaryMuted?: boolean;
  caption: string;
  events: Event[];
  emptyText: string;
}) {
  return (
    <section className="flex flex-col rounded-lg border border-border bg-card">
      <header className="flex flex-col gap-2 border-b border-border px-4 py-3">
        <div className="flex items-center gap-2.5">
          <span className="flex size-7 shrink-0 items-center justify-center rounded-md border border-gold/30 bg-gold/10">
            <Icon className="size-3.5 text-gold-bright" strokeWidth={1.75} />
          </span>
          <h3 className="flex-1 text-sm font-semibold text-foreground">
            {title}
          </h3>
          <span className="font-mono text-[11px] tabular-nums text-muted-foreground">
            {events.length}
          </span>
        </div>
        <p
          className={cn(
            "text-xs font-medium",
            summaryMuted ? "text-muted-foreground" : "text-gold-bright",
          )}
        >
          {summary}
        </p>
        <p className="text-[11px] leading-snug text-muted-foreground">
          {caption}
        </p>
      </header>

      {events.length === 0 ? (
        <p className="px-4 py-6 text-center text-xs text-muted-foreground">
          {emptyText}
        </p>
      ) : (
        <ol className="flex flex-col px-4 py-3">
          {events.map((event, i) => (
            <li key={`${event.at}-${event.label}-${i}`} className="flex gap-3">
              <div className="flex flex-col items-center">
                <span
                  className={cn(
                    "mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full border",
                    event.state === "current"
                      ? "border-gold bg-gold/15"
                      : "border-border bg-background",
                  )}
                >
                  <event.icon
                    className={cn(
                      "size-3",
                      event.state === "current"
                        ? "text-gold-bright"
                        : "text-muted-foreground",
                    )}
                    strokeWidth={1.75}
                  />
                </span>
                {i < events.length - 1 && (
                  <span className="w-px flex-1 bg-border" aria-hidden />
                )}
              </div>

              <div className="min-w-0 flex-1 pb-4">
                <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
                  <p className="text-sm leading-snug text-foreground">
                    {event.label}
                  </p>
                  {event.state && <StateChip state={event.state} />}
                </div>
                <p className="mt-0.5 text-[11px] text-muted-foreground">
                  {formatDate(event.at)}
                  {event.detail ? ` · ${event.detail}` : ""}
                </p>
              </div>
            </li>
          ))}
        </ol>
      )}
    </section>
  );
}

function StateChip({ state }: { state: "current" | "pending" }) {
  const current = state === "current";
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-full border px-1.5 py-px text-[10px] font-medium",
        current
          ? "border-gold/50 bg-gold/10 text-gold-bright"
          : "border-border bg-muted/50 text-muted-foreground",
      )}
    >
      <CircleDot className="size-2.5" strokeWidth={2.5} />
      {current ? "Active" : "Awaiting"}
    </span>
  );
}

function formatDate(iso: string): string {
  return new Intl.DateTimeFormat("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(iso));
}
