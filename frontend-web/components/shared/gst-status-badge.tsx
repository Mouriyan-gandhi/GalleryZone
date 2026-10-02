import { cn } from "@/lib/utils";

export type GstStatus = "not_submitted" | "submitted" | "approved" | "rejected";

const GST_STATUS_LABEL: Record<GstStatus, { label: string; className: string }> = {
  not_submitted: {
    label: "Not started",
    className: "border-border text-muted-foreground",
  },
  submitted: {
    label: "Pending GalleryZone approval",
    className: "border-gold/40 bg-gold/10 text-gold-bright",
  },
  approved: {
    label: "Approved",
    className: "border-emerald-500/40 bg-emerald-500/10 text-emerald-500",
  },
  rejected: {
    label: "Rejected — resubmit",
    className: "border-destructive/40 bg-destructive/10 text-destructive",
  },
};

// Where a GST number stands with GalleryZone. Shared by the artist and
// aggregator profiles so the same state never reads two ways.
export function GstStatusBadge({
  status,
  className,
}: {
  status: GstStatus;
  className?: string;
}) {
  const { label, className: tone } = GST_STATUS_LABEL[status];
  return (
    <span
      className={cn(
        "rounded-full border px-2 py-0.5 text-[11px] font-medium",
        tone,
        className,
      )}
    >
      {label}
    </span>
  );
}
