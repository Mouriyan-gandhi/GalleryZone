"use client";

import { useState } from "react";
import { toast } from "sonner";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useRequestExtensionMutation } from "@/hooks/useAggregatorCollection";
import type { AggregatorHolding } from "@/types/aggregator";
import type { ArtworkSummary } from "@/types/artwork";

// The same floor the API enforces (requestHoldingExtensionInputSchema).
const MIN_ASSURANCE = 10;

interface RequestExtensionDialogProps {
  holding: (AggregatorHolding & { artwork: ArtworkSummary }) | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

// After 30 days a piece moves on to the next aggregator. The same aggregator
// keeps it only by asking with an assurance that it will sell, and only if
// GalleryZone says yes (client, 30 Sep 2026: "GalleryZone decides each time").
export function RequestExtensionDialog({
  holding,
  open,
  onOpenChange,
}: RequestExtensionDialogProps) {
  const requestMutation = useRequestExtensionMutation();
  const [assurance, setAssurance] = useState("");

  if (!holding) return null;

  const tooShort = assurance.trim().length < MIN_ASSURANCE;

  function handleSend() {
    if (!holding || tooShort) return;
    requestMutation.mutate(
      { holdingId: holding.id, assurance: assurance.trim() },
      {
        onSuccess: () => {
          toast.success("Request sent to GalleryZone", {
            description:
              "If it isn't approved before the window ends, the piece goes back on sale and your advance is released.",
          });
          setAssurance("");
          onOpenChange(false);
        },
        onError: (error) => toast.error(error.message),
      },
    );
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        if (!requestMutation.isPending) onOpenChange(next);
      }}
    >
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Ask to keep this piece longer</DialogTitle>
          <DialogDescription>
            &ldquo;{holding.artwork.title}&rdquo; moves on to another
            aggregator when its 30 days end. GalleryZone decides each request,
            and only agrees when you can say why it will sell.
          </DialogDescription>
        </DialogHeader>

        <div className="flex flex-col gap-2">
          <Label htmlFor="extensionAssurance">
            Your assurance that it will sell
          </Label>
          <Textarea
            id="extensionAssurance"
            rows={4}
            maxLength={1000}
            placeholder="e.g. A collector has viewed it twice and is confirming this week."
            value={assurance}
            onChange={(e) => setAssurance(e.target.value)}
          />
          <p className="text-xs text-muted-foreground">
            A sentence or two. GalleryZone reads this before answering.
          </p>
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={requestMutation.isPending}
          >
            Cancel
          </Button>
          <Button
            onClick={handleSend}
            disabled={tooShort || requestMutation.isPending}
          >
            {requestMutation.isPending ? "Sending…" : "Send request"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
