"use client";

import { useState } from "react";
import { toast } from "sonner";
import { TriangleAlert } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { useDecideExtensionMutation } from "@/hooks/useAdminCatalog";
import type { AggregatorHolding } from "@/types/aggregator";

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

// The two things about a placement GalleryZone has to act on besides pulling it
// back (client, 30 Sep 2026): an aggregator who priced far above GalleryZone's
// offer, which is a warning and never a block, and an aggregator asking to keep
// a piece past its 30 days, which GalleryZone decides each time.
export function HoldingExtensionPanel({ holding }: { holding: AggregatorHolding }) {
  const decide = useDecideExtensionMutation();
  const [note, setNote] = useState("");
  const request = holding.extensionRequest;

  function answer(decision: "approve" | "decline") {
    decide.mutate(
      { holdingId: holding.id, decision, note },
      {
        onSuccess: () => {
          toast.success(
            decision === "approve" ? "Extension approved" : "Extension declined",
            {
              description:
                decision === "approve"
                  ? "The window now runs 30 days further."
                  : "The piece goes back on sale when the window ends.",
            },
          );
          setNote("");
        },
        onError: (error) => toast.error(error.message),
      },
    );
  }

  return (
    <>
      {holding.priceWarning && (
        <div
          role="status"
          className="mt-3 flex items-start gap-2 rounded-md border border-gold/40 bg-gold/5 p-2.5"
        >
          <TriangleAlert
            className="mt-0.5 size-3.5 shrink-0 text-gold-bright"
            strokeWidth={1.75}
          />
          <p className="text-xs leading-relaxed text-muted-foreground">
            Priced at least double GalleryZone&rsquo;s offer. Check that it is a
            price a buyer would pay. You can pull the piece back if it is not.
          </p>
        </div>
      )}

      {request?.status === "pending" ? (
        <div className="mt-3 flex flex-col gap-2 rounded-md border border-border bg-background p-3">
          <p className="text-xs font-medium text-foreground">
            Asked to keep it longer
          </p>
          <p className="text-xs leading-relaxed text-muted-foreground">
            &ldquo;{request.assurance}&rdquo;
          </p>
          <p className="text-[11px] text-muted-foreground">
            The window ends {formatDate(holding.expiresAt)}. Approving adds 30
            days, never past the 180-day listing. If nobody answers by then, the
            piece goes back on sale.
          </p>
          <Textarea
            rows={2}
            maxLength={500}
            placeholder="A note for the aggregator (optional)"
            value={note}
            onChange={(e) => setNote(e.target.value)}
            aria-label="A note for the aggregator"
          />
          <div className="flex gap-2">
            <Button
              size="sm"
              onClick={() => answer("approve")}
              disabled={decide.isPending}
            >
              Approve
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={() => answer("decline")}
              disabled={decide.isPending}
            >
              Decline
            </Button>
          </div>
        </div>
      ) : request ? (
        <p className="mt-3 text-xs text-muted-foreground">
          Extension request {request.status}
          {request.decidedAt ? ` on ${formatDate(request.decidedAt)}` : ""}.
        </p>
      ) : null}
    </>
  );
}
