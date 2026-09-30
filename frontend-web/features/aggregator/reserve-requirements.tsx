"use client";

import Link from "next/link";
import { FileSignature, Receipt, type LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAggregatorProfile } from "@/hooks/useAggregatorProfile";

// What GalleryZone needs from an aggregator before it places a piece with
// them: a signed MOU (custody, pricing, settlement) and an approved GST number
// (client, 30 Sep 2026: "GST required for aggregators before reserving"). The
// API refuses a reservation without both. This says so up front, on the grid
// and on the reserve screen, rather than after they have picked a piece.
//
// Everything is `undefined` while the profile loads. Only `false` blocks
// anything, so a slow fetch never locks out someone who is fine.
export function useReserveRequirements() {
  const { data: profile } = useAggregatorProfile();
  const mouSigned = profile ? Boolean(profile.mouAcceptance) : undefined;
  const gstStatus = profile?.gstStatus;
  const gstApproved = profile ? profile.gstStatus === "approved" : undefined;
  const blockedReason =
    mouSigned === false
      ? "Sign your Aggregator MOU first"
      : gstApproved === false
        ? "Get your GST number approved first"
        : undefined;
  return { mouSigned, gstStatus, gstApproved, blockedReason };
}

const GST_NOTICE = {
  not_submitted: {
    title: "Add your GST number to reserve artwork.",
    body: "GalleryZone needs an approved GST registration before it can place a piece with you. Add it on your profile and we'll review it.",
    action: true,
  },
  submitted: {
    title: "Your GST number is being reviewed.",
    body: "You can reserve artwork as soon as GalleryZone approves it.",
    action: false,
  },
  rejected: {
    title: "Your GST number wasn't approved.",
    body: "Correct it on your profile and submit it again to reserve artwork.",
    action: true,
  },
} as const;

export function ReserveRequirementsNotice({ className }: { className?: string }) {
  const { mouSigned, gstStatus, gstApproved } = useReserveRequirements();
  if (mouSigned !== false && gstApproved !== false) return null;

  const gst = gstStatus && gstStatus !== "approved" ? GST_NOTICE[gstStatus] : null;

  return (
    <div className={cn("flex flex-col gap-3", className)}>
      {mouSigned === false && (
        <Requirement
          icon={FileSignature}
          title="Sign your Aggregator MOU to reserve artwork."
          body="It covers custody, pricing and settlement — GalleryZone can't place a piece with you until it's signed."
          action
        />
      )}
      {gstApproved === false && gst && (
        <Requirement icon={Receipt} title={gst.title} body={gst.body} action={gst.action} />
      )}
    </div>
  );
}

function Requirement({
  icon: Icon,
  title,
  body,
  action,
}: {
  icon: LucideIcon;
  title: string;
  body: string;
  action: boolean;
}) {
  return (
    <div className="flex flex-col gap-3 rounded-lg border border-gold/40 bg-gold/5 p-4 sm:flex-row sm:items-center">
      <div className="flex items-start gap-3 sm:flex-1 sm:items-center">
        <Icon
          className="mt-0.5 size-4 shrink-0 text-gold-bright sm:mt-0"
          strokeWidth={1.75}
        />
        <p className="text-sm text-muted-foreground">
          <span className="font-medium text-foreground">{title}</span> {body}
        </p>
      </div>
      {action && (
        <Link
          href="/aggregator/profile"
          className="inline-flex shrink-0 items-center justify-center gap-1.5 rounded-md border border-gold/60 px-4 py-2 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
        >
          Go to My Profile
        </Link>
      )}
    </div>
  );
}
