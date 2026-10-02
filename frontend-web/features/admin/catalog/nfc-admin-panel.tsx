"use client";

import { useState } from "react";
import { toast } from "sonner";
import { Lock, Mail, Nfc, ShieldAlert, Unlink } from "lucide-react";
import { Button } from "@/components/ui/button";
import { RejectReasonDialog } from "@/features/admin/reject-reason-dialog";
import { useAdminRemindNfcMutation, useAdminSkipShipmentGateMutation, useAdminUnlinkNfcMutation } from "@/hooks/useAdminNfc";
import { NFC_STAGE_LABEL, nfcStageOf } from "@/lib/nfc";
import { cn } from "@/lib/utils";
import type { Artwork } from "@/types/artwork";

// One piece's NFC tag, as an admin handles it (NFC_IMPLEMENTATION.md §4.3, §4.4).
// An admin never writes to a chip. They can undo a link made to a defective chip
// (only before it is locked: afterwards the chip stays locked whatever the server says),
// chase the artist, and — as a last resort, with a reason on the audit log — let a legacy
// piece ship without a locked tag.

const when = (iso: string) => new Date(iso).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" });

export function NfcAdminPanel({ artwork }: { artwork: Artwork }) {
  const stage = nfcStageOf(artwork);
  const unlink = useAdminUnlinkNfcMutation();
  const skipGate = useAdminSkipShipmentGateMutation();
  const remind = useAdminRemindNfcMutation();
  const [unlinkOpen, setUnlinkOpen] = useState(false);
  const [overrideOpen, setOverrideOpen] = useState(false);

  const overridden = Boolean(artwork.nfcShipmentGateOverrideAt);

  return (
    <section className="rounded-xl border border-border bg-card p-5" id="admin-nfc-panel">
      <div className="flex items-center justify-between gap-3">
        <h2 className="flex items-center gap-2 font-display text-base font-semibold text-foreground">
          <Nfc className="size-4 text-gold-bright" strokeWidth={1.75} />
          NFC tag
        </h2>
        <span
          className={cn(
            "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-[11px] font-medium whitespace-nowrap",
            stage === "linked_locked" && "border-gold/40 bg-gold/10 text-gold-bright",
            stage === "linked_unlocked" && "border-red-500/40 bg-red-500/10 text-red-300",
            stage === "unlinked" && "border-border bg-secondary text-muted-foreground",
          )}
        >
          {stage !== "unlinked" && <Lock className="size-3" strokeWidth={2} />}
          {stage === "linked_unlocked" ? "Unlocked" : NFC_STAGE_LABEL[stage]}
        </span>
      </div>

      <dl className="mt-3 grid grid-cols-2 gap-x-4 gap-y-3 text-sm">
        <div className="col-span-2">
          <dt className="text-xs text-muted-foreground">Chip ID</dt>
          <dd className="font-mono text-xs text-foreground">{artwork.nfcTagUid ?? "None linked"}</dd>
        </div>
        <div>
          <dt className="text-xs text-muted-foreground">Linked</dt>
          <dd className="text-foreground">{artwork.nfcLinkedAt ? when(artwork.nfcLinkedAt) : "—"}</dd>
        </div>
        <div>
          <dt className="text-xs text-muted-foreground">Locked</dt>
          <dd className="text-foreground">{artwork.nfcLockedAt ? when(artwork.nfcLockedAt) : "—"}</dd>
        </div>
      </dl>

      {stage !== "linked_locked" && (
        <p className="mt-3 text-xs leading-relaxed text-muted-foreground">
          {stage === "linked_unlocked"
            ? "The chip was written but never locked. Until it is, anyone with a phone could rewrite it, and the piece can't be dispatched once the gate is enforced."
            : "No chip has been linked yet. The artist links and locks it in the GalleryZone app."}
        </p>
      )}

      {overridden && (
        <div id="admin-nfc-override" className="mt-3 flex items-start gap-2 rounded-lg border border-amber-500/40 bg-amber-500/10 px-3 py-2.5">
          <ShieldAlert className="mt-0.5 size-3.5 shrink-0 text-amber-300" />
          <p className="text-xs leading-relaxed text-amber-200">
            Allowed to ship without a locked tag{artwork.nfcShipmentGateOverrideAt ? ` (${when(artwork.nfcShipmentGateOverrideAt)})` : ""}
            {artwork.nfcShipmentGateOverrideReason ? `: ${artwork.nfcShipmentGateOverrideReason}` : "."}
          </p>
        </div>
      )}

      {stage !== "linked_locked" && (
        <div className="mt-4 flex flex-wrap gap-2">
          <Button
            size="sm"
            variant="outline"
            disabled={remind.isPending}
            onClick={() =>
              remind.mutate(artwork.id, {
                onSuccess: () => toast.success("The artist has been emailed", { description: `A reminder to ${stage === "unlinked" ? "link and lock" : "lock"} the tag on “${artwork.title}”.` }),
                onError: (error) => toast.error("Couldn't send the reminder", { description: error.message }),
              })
            }
          >
            <Mail className="size-3.5" />
            Email the artist
          </Button>
          {stage === "linked_unlocked" && (
            <Button size="sm" variant="outline" onClick={() => setUnlinkOpen(true)}>
              <Unlink className="size-3.5" />
              Unlink tag
            </Button>
          )}
          {!overridden && (
            <Button size="sm" variant="outline" onClick={() => setOverrideOpen(true)}>
              <ShieldAlert className="size-3.5" />
              Allow shipping unlocked
            </Button>
          )}
        </div>
      )}

      <RejectReasonDialog
        open={unlinkOpen}
        onOpenChange={setUnlinkOpen}
        title="Unlink this NFC tag?"
        description="Use this when the artist wrote to a defective chip and needs a fresh one. It only resets the record: the artist links a new chip afterwards."
        presets={["Artist reported the chip failed to write", "Artist reported the chip failed to lock", "Linked to the wrong piece"]}
        label="Why is it being unlinked?"
        placeholder="e.g. artist reported the chip failed to lock"
        confirmLabel="Unlink tag"
        helpText="Recorded on the audit log. The artist isn't emailed."
        isPending={unlink.isPending}
        onSubmit={(reason) =>
          unlink.mutate(
            { artworkId: artwork.id, reason },
            {
              onSuccess: () => {
                setUnlinkOpen(false);
                toast.success("Tag unlinked", { description: `“${artwork.title}” can be linked to a new chip.` });
              },
              onError: (error) => toast.error("Couldn't unlink the tag", { description: error.message }),
            },
          )
        }
      />

      <RejectReasonDialog
        open={overrideOpen}
        onOpenChange={setOverrideOpen}
        title="Allow this piece to ship without a locked tag?"
        description="A last resort for pieces from before the lock requirement. It lets this one piece through the dispatch gate, and the reason is kept."
        presets={["Shipped before the lock requirement; grandfathering"]}
        label="Why may it ship unlocked?"
        placeholder="e.g. shipped to the collector before the lock requirement"
        confirmLabel="Allow shipping"
        helpText="Recorded on the audit log with your name."
        isPending={skipGate.isPending}
        onSubmit={(reason) =>
          skipGate.mutate(
            { artworkId: artwork.id, reason },
            {
              onSuccess: () => {
                setOverrideOpen(false);
                toast.success("Allowed to ship", { description: `“${artwork.title}” will no longer be stopped by the NFC gate.` });
              },
              onError: (error) => toast.error("Couldn't record the override", { description: error.message }),
            },
          )
        }
      />
    </section>
  );
}
