"use client";

import Link from "next/link";
import { AlertTriangle, Lock, Nfc, ShieldAlert, ShieldCheck } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { useNfcOverview } from "@/hooks/useAdminNfc";
import type { NfcOverview } from "@/services/nfcTagService";

// §13: how many pieces are unlinked, linked-but-unlocked and locked across the whole
// catalogue, who is still to lock, and the events that mean a chip failed or the
// process is being bypassed (a replaced tag, an override, a dispatch the gate would stop).

const ACTION_LABEL: Record<string, string> = {
  "nfc.tag_replaced": "Tag replaced",
  "nfc.shipment_gate_overridden": "Shipping allowed unlocked",
  "nfc.shipment_gate_warning": "Dispatch the gate would have stopped",
};

function when(iso: string): string {
  return new Date(iso).toLocaleString("en-IN", { day: "numeric", month: "short", hour: "numeric", minute: "2-digit" });
}

function Tile({ label, value, tone }: { label: string; value: number; tone: "neutral" | "warn" | "good" }) {
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <p className="text-xs text-muted-foreground">{label}</p>
      <p
        className={`mt-1 font-display text-2xl font-semibold tabular-nums ${tone === "warn" ? "text-red-300" : tone === "good" ? "text-gold-bright" : "text-foreground"}`}
      >
        {value.toLocaleString("en-IN")}
      </p>
    </div>
  );
}

export function NfcOverviewPanel() {
  const { data, isPending, isError } = useNfcOverview();

  if (isPending) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-24 w-full rounded-xl" />
        <Skeleton className="h-64 w-full rounded-xl" />
      </div>
    );
  }
  if (isError || !data) {
    return <p className="text-sm text-muted-foreground">The NFC overview couldn&apos;t be loaded. Try again in a moment.</p>;
  }
  return <Loaded overview={data} />;
}

function Loaded({ overview }: { overview: NfcOverview }) {
  const { counts } = overview;
  return (
    <div className="space-y-6">
      <div
        id="nfc-gate-state"
        className={`flex items-start gap-3 rounded-xl border p-4 ${overview.gateEnforced ? "border-gold/40 bg-gold/10" : "border-amber-500/40 bg-amber-500/10"}`}
      >
        {overview.gateEnforced ? <ShieldCheck className="mt-0.5 size-4 text-gold-bright" /> : <ShieldAlert className="mt-0.5 size-4 text-amber-300" />}
        <div className="text-sm">
          <p className="font-medium text-foreground">
            {overview.gateEnforced ? "The dispatch gate is enforced" : "The dispatch gate is in warn-only mode"}
          </p>
          <p className="mt-0.5 text-xs leading-relaxed text-muted-foreground">
            {overview.gateEnforced
              ? "A piece whose tag isn't locked (and hasn't been allowed) can't be dispatched."
              : "An unlocked dispatch is allowed and recorded below, so you can see what would be stopped. Once the list below is clear, turn the gate on under Settings → pricing rules (it needs a second admin to approve)."}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
        <Tile label="Artworks" value={counts.total} tone="neutral" />
        <Tile label="No tag yet" value={counts.unlinked} tone="neutral" />
        <Tile label="Linked, unlocked" value={counts.linkedUnlocked} tone={counts.linkedUnlocked > 0 ? "warn" : "neutral"} />
        <Tile label="Locked" value={counts.locked} tone="good" />
        <Tile label="Allowed unlocked" value={counts.gateOverridden} tone="neutral" />
      </div>

      <section className="rounded-xl border border-border bg-card">
        <div className="border-b border-border px-5 py-4">
          <h2 className="flex items-center gap-2 font-display text-base font-semibold text-foreground">
            <Lock className="size-4 text-red-300" strokeWidth={1.75} />
            Still to lock
          </h2>
          <p className="mt-0.5 text-xs text-muted-foreground">Linked but never locked, longest-waiting first. Open one to email the artist.</p>
        </div>
        {overview.awaitingLock.length === 0 ? (
          <p className="px-5 py-8 text-center text-sm text-muted-foreground">Every linked tag is locked.</p>
        ) : (
          <ul className="divide-y divide-border">
            {overview.awaitingLock.map((row) => (
              <li key={row.artworkId}>
                <Link href={`/admin/artworks/${row.artworkId}`} className="flex items-center justify-between gap-4 px-5 py-3 transition-colors hover:bg-muted/40">
                  <span className="min-w-0 truncate text-sm font-medium text-foreground">{row.title}</span>
                  <span className="shrink-0 text-xs text-muted-foreground">linked {when(row.linkedAt)}</span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="rounded-xl border border-border bg-card">
        <div className="border-b border-border px-5 py-4">
          <h2 className="flex items-center gap-2 font-display text-base font-semibold text-foreground">
            <AlertTriangle className="size-4 text-amber-300" strokeWidth={1.75} />
            Worth a look
          </h2>
          <p className="mt-0.5 text-xs text-muted-foreground">
            A replaced tag means a chip failed or was rewritten. An override or a stopped dispatch means the process is being bypassed.
          </p>
        </div>
        {overview.recent.length === 0 ? (
          <p className="px-5 py-8 text-center text-sm text-muted-foreground">Nothing yet.</p>
        ) : (
          <ul className="divide-y divide-border">
            {overview.recent.map((event) => (
              <li key={event.id}>
                <Link href={`/admin/artworks/${event.artworkId}`} className="flex items-center justify-between gap-4 px-5 py-3 transition-colors hover:bg-muted/40">
                  <span className="flex min-w-0 items-center gap-2">
                    <Nfc className="size-3.5 shrink-0 text-gold-bright" strokeWidth={1.75} />
                    <span className="min-w-0">
                      <span className="block truncate text-sm font-medium text-foreground">{ACTION_LABEL[event.action] ?? event.action}</span>
                      <span className="block truncate text-xs text-muted-foreground">{event.title ?? event.artworkId}</span>
                    </span>
                  </span>
                  <span className="shrink-0 text-xs text-muted-foreground">{when(event.at)}</span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
