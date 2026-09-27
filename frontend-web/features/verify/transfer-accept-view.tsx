"use client";

import { useSyncExternalStore } from "react";
import Image from "next/image";
import Link from "next/link";
import { readSessionRole, subscribeToSession } from "@/lib/session";
import { useMounted } from "@/hooks/useMounted";
import { ShieldCheck, CircleAlert, ArrowRight, ScanLine } from "lucide-react";
import { useTransfer, useAcceptTransferMutation } from "@/hooks/useOwnershipTransfers";
import { useArtwork } from "@/hooks/useArtwork";
import { transferKind } from "@/types/artwork";

// What the incoming owner sees when they open the transfer link. The route is
// public (the recipient may not have an account yet), but the API only reveals
// the transfer to a signed-in account, so signed-out visitors are asked to sign
// in first. The page shows nothing confidential — a title, who is handing it
// over, and the button that moves the record.
export function TransferAcceptView({ transferId }: { transferId: string }) {
  // The API only shows a transfer to a signed-in account, so a signed-out
  // recipient used to wait out the retries and then read "isn't valid".
  const mounted = useMounted();
  const sessionRole = useSyncExternalStore(subscribeToSession, readSessionRole, () => null);
  const signedOut = mounted && !sessionRole;
  const { data: transfer, isLoading } = useTransfer(signedOut ? "" : transferId);
  // The link is the only thing the recipient gets, so this page carries what
  // they need to recognise the piece: the image, the tag on it, and a way
  // through to the full passport.
  const { data: artwork } = useArtwork(transfer?.artworkId ?? "");
  const acceptMutation = useAcceptTransferMutation();

  if (signedOut) {
    const next = encodeURIComponent(`/transfer/${transferId}`);
    return (
      <Panel
        tone="warn"
        title="Sign in to accept this transfer"
        body="Use the email address the transfer was sent to. New to GalleryZone? Create an account with that email first."
        action={
          <div className="flex w-full flex-col gap-3 sm:flex-row">
            <Link
              href={`/login?next=${next}`}
              className="inline-flex flex-1 items-center justify-center rounded-md bg-gold-bright px-5 py-3 text-sm font-semibold text-background transition-colors hover:bg-gold"
            >
              Sign in
            </Link>
            <Link
              href="/register?role=customer"
              className="inline-flex flex-1 items-center justify-center rounded-md border border-border px-5 py-3 text-sm font-medium text-foreground/85 transition-colors hover:border-gold/40 hover:text-gold-bright"
            >
              Create an account
            </Link>
          </div>
        }
      />
    );
  }

  if (isLoading) {
    return (
      <div className="mx-auto w-full max-w-md px-6 py-20 text-center text-sm text-muted-foreground">
        Checking this transfer…
      </div>
    );
  }

  if (!transfer) {
    return (
      <Panel
        tone="warn"
        title="This transfer link isn’t valid"
        body="It may have been mistyped, or the transfer was removed. Ask the sender for a new link."
      />
    );
  }

  if (transfer.status === "cancelled") {
    return (
      <Panel
        tone="warn"
        title="This transfer was cancelled"
        body={`${transfer.fromName} cancelled the hand-over of “${transfer.artworkTitle}”. Nothing has changed on the ownership record.`}
      />
    );
  }

  if (transfer.status === "accepted" || acceptMutation.isSuccess) {
    return (
      <Panel
        tone="ok"
        title={
          transferKind(transfer) === "display"
            ? "Display rights recorded"
            : "Ownership transferred"
        }
        body={
          transferKind(transfer) === "display"
            ? `“${transfer.artworkTitle}” is recorded as on display with ${transfer.toName}. Ownership has not changed — the passport shows both.`
            : `“${transfer.artworkTitle}” is now recorded to ${transfer.toName}. The artwork’s passport shows the full chain of ownership.`
        }
        action={
          <Link
            href={`/verify/${transfer.artworkId}`}
            className="inline-flex items-center gap-2 rounded-md bg-gradient-to-b from-gold-bright to-gold px-5 py-2.5 text-sm font-semibold text-[#171310] transition-transform hover:scale-[1.02]"
          >
            View the passport
            <ArrowRight className="size-3.5" />
          </Link>
        }
      />
    );
  }

  const isDisplay = transferKind(transfer) === "display";

  return (
    <div className="mx-auto flex w-full max-w-md flex-col gap-5 px-6 py-16 lg:py-24">
      <div className="flex flex-col gap-2 text-center">
        <p className="font-mono text-xs tracking-[0.16em] text-gold-bright uppercase">
          GalleryZone passport
        </p>
        <h1 className="font-display text-2xl font-semibold text-foreground">
          {isDisplay
            ? `${transfer.fromName} is giving you display rights`
            : `${transfer.fromName} is transferring ownership to you`}
        </h1>
      </div>

      <div className="overflow-hidden rounded-lg border border-gold/30 bg-card">
        {artwork && (
          <div className="relative aspect-[4/3] w-full bg-muted">
            <Image
              src={artwork.thumbnailUrl}
              alt={transfer.artworkTitle}
              fill
              sizes="(min-width: 768px) 28rem, 100vw"
              className="object-cover"
            />
          </div>
        )}
        <dl className="flex flex-col gap-3 p-5 text-sm">
          <Row label="Artwork" value={transfer.artworkTitle} />
          <Row label="From" value={transfer.fromName} />
          <Row label="To" value={`${transfer.toName} · ${transfer.toEmail}`} />
          {isDisplay && transfer.displayEndsAt && (
            <Row label="On display until" value={formatDate(transfer.displayEndsAt)} />
          )}
          {artwork?.nfcTagId && (
            <Row label="NFC tag" value={artwork.nfcTagId} />
          )}
        </dl>
        <Link
          href={`/verify/${transfer.artworkId}`}
          className="flex items-center justify-between gap-2 border-t border-border px-5 py-3 text-sm text-gold-bright transition-colors hover:bg-gold/5"
        >
          <span className="inline-flex items-center gap-2">
            <ScanLine className="size-3.5" strokeWidth={2} />
            View full passport
          </span>
          <ArrowRight className="size-3.5" />
        </Link>
      </div>

      <p className="text-sm leading-relaxed text-muted-foreground">
        {isDisplay
          ? "Accepting records the piece as on display with you until that date. Ownership stays where it is, and the display ends on its own when the date passes."
          : "Accepting records you as the artwork’s owner on its digital passport. The previous owners stay in its history — provenance is added to, never rewritten."}
      </p>

      {acceptMutation.isError && (
        <p className="text-sm text-destructive">
          {acceptMutation.error instanceof Error
            ? acceptMutation.error.message
            : "Something went wrong."}
        </p>
      )}

      <button
        type="button"
        onClick={() => acceptMutation.mutate(transfer.id)}
        disabled={acceptMutation.isPending}
        className="inline-flex items-center justify-center gap-2 rounded-md bg-gradient-to-b from-gold-bright to-gold px-6 py-3 text-sm font-semibold text-[#171310] transition-transform hover:scale-[1.02] disabled:pointer-events-none disabled:opacity-60"
      >
        {isDisplay ? "Accept display rights" : "Accept ownership"}
      </button>
    </div>
  );
}

function formatDate(iso: string): string {
  return new Intl.DateTimeFormat("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(iso));
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-baseline justify-between gap-3">
      <dt className="text-xs text-muted-foreground">{label}</dt>
      <dd className="text-right font-medium text-foreground">{value}</dd>
    </div>
  );
}

function Panel({
  tone,
  title,
  body,
  action,
}: {
  tone: "ok" | "warn";
  title: string;
  body: string;
  action?: React.ReactNode;
}) {
  const Icon = tone === "ok" ? ShieldCheck : CircleAlert;
  return (
    <div className="mx-auto flex w-full max-w-md flex-col items-center gap-4 px-6 py-20 text-center">
      <span
        className={`flex size-11 items-center justify-center rounded-full border ${
          tone === "ok"
            ? "border-emerald-500/40 bg-emerald-500/10 text-emerald-500"
            : "border-border bg-secondary text-muted-foreground"
        }`}
      >
        <Icon className="size-5" strokeWidth={1.75} />
      </span>
      <h1 className="font-display text-xl font-semibold text-foreground">
        {title}
      </h1>
      <p className="text-sm leading-relaxed text-muted-foreground">{body}</p>
      {action}
    </div>
  );
}
