"use client";

import { useState, useSyncExternalStore } from "react";
import { AlertTriangle, Copy, Loader2, Lock, Nfc, Radio, ShieldCheck, Smartphone } from "lucide-react";
import { toast } from "sonner";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useLinkNfcTagMutation } from "@/hooks/useLinkNfcTag";
import { MOBILE_APP_URL, webNfcSupported } from "@/lib/nfc";
import { verifyUrlFor } from "@/lib/verify-url";
import { QrImage } from "@/features/verify/qr-image";

interface LinkNfcDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  artworkId: string;
  artworkTitle: string;
  /** The piece already has a linked, unlocked tag; writing a new chip replaces it. */
  replacing?: boolean;
}

type DialogStep = "idle" | "scanning" | "success";

// Whether this browser can write tags never changes while the page is open.
const subscribeNever = () => () => {};

// Writes the artwork's verify URL to a blank NTAG213 chip from the browser (Web NFC:
// Chrome on Android) and records the link. A browser can write but not lock a chip, so
// the lock is finished in the GalleryZone app — and anyone without Web NFC is sent there
// for the whole job.
export function LinkNfcDialog({
  open,
  onOpenChange,
  artworkId,
  artworkTitle,
  replacing = false,
}: LinkNfcDialogProps) {
  const [step, setStep] = useState<DialogStep>("idle");
  // Null on the server and during hydration (there is no `window` to ask), then the browser's answer.
  const supported = useSyncExternalStore(subscribeNever, webNfcSupported, () => null);

  const verifyUrl = verifyUrlFor(artworkId);
  const { mutateAsync } = useLinkNfcTagMutation();

  function handleCopyUrl() {
    void navigator.clipboard.writeText(verifyUrl).then(() => {
      toast.success("URL copied to clipboard");
    });
  }

  async function handleWrite() {
    setStep("scanning");
    try {
      await mutateAsync({ artworkId });
      setStep("success");
      toast.success(`NFC tag linked to "${artworkTitle}"`, {
        description: "Now lock it in the GalleryZone app before the piece ships.",
        duration: 6000,
      });
    } catch (err) {
      setStep("idle");
      toast.error("The tag wasn't linked", {
        description: err instanceof Error ? err.message : "Please try again.",
      });
    }
  }

  function handleOpenChange(next: boolean) {
    if (!next) setStep("idle");
    onOpenChange(next);
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Nfc className="size-4 text-gold-bright" strokeWidth={1.75} />
            {replacing ? "Replace NFC Tag" : "Link NFC Tag"}
          </DialogTitle>
        </DialogHeader>

        <div className="flex flex-col gap-5 pb-2">
          <p className="text-sm text-muted-foreground">
            {replacing ? "Writing a new chip for " : "Linking a physical NFC chip to "}
            <span className="font-medium text-foreground">
              &ldquo;{artworkTitle}&rdquo;
            </span>
          </p>

          {step === "success" ? (
            <SuccessPanel verifyUrl={verifyUrl} />
          ) : supported === false ? (
            <UseTheAppPanel verifyUrl={verifyUrl} onCopy={handleCopyUrl} />
          ) : (
            <>
              <div className="rounded-lg border border-border bg-muted/40 px-4 py-3.5">
                <p className="text-xs font-medium text-foreground">
                  How to program the tag
                </p>
                <ol className="mt-2 flex list-inside list-decimal flex-col gap-1.5 text-xs leading-relaxed text-muted-foreground">
                  <li>Tap the button, then hold a blank NTAG213 chip to the back of your phone.</li>
                  <li>The URL below is written to it as a single NDEF record.</li>
                  <li>Lock the chip in the GalleryZone app afterwards. Until it is locked it can be rewritten, and the piece can&apos;t be dispatched.</li>
                </ol>
              </div>

              {replacing && (
                <p className="flex items-start gap-2 rounded-lg border border-amber-500/40 bg-amber-500/10 px-3 py-2.5 text-xs leading-relaxed text-amber-300">
                  <AlertTriangle className="mt-0.5 size-3.5 shrink-0" />
                  The chip linked now stops being the record for this piece the moment the new one is written.
                </p>
              )}

              <UrlPreview verifyUrl={verifyUrl} onCopy={handleCopyUrl} />

              {step === "scanning" && <ScanningIndicator />}

              <button
                id="nfc-dialog-write-btn"
                type="button"
                disabled={step === "scanning" || supported === null}
                onClick={() => void handleWrite()}
                className="inline-flex w-full items-center justify-center gap-2 rounded-lg border border-gold/50 bg-gold/10 px-4 py-2.5 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/20 disabled:pointer-events-none disabled:opacity-50"
              >
                {step === "scanning" ? (
                  <>
                    <Loader2 className="size-4 animate-spin" />
                    Scanning &amp; writing…
                  </>
                ) : (
                  <>
                    <Radio className="size-4" />
                    {replacing ? "Write a new tag" : "Write tag"}
                  </>
                )}
              </button>
            </>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}

function UrlPreview({ verifyUrl, onCopy }: { verifyUrl: string; onCopy: () => void }) {
  return (
    <div>
      <p className="mb-1.5 text-xs font-medium tracking-wide text-muted-foreground uppercase">
        NFC URL (NDEF payload)
      </p>
      <div className="flex items-center gap-2 rounded-md border border-border bg-card px-3 py-2.5">
        <span className="flex-1 truncate font-mono text-[11px] text-gold-bright">
          {verifyUrl}
        </span>
        <button
          type="button"
          id="nfc-dialog-copy-url"
          onClick={onCopy}
          aria-label="Copy verification URL"
          className="shrink-0 rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
        >
          <Copy className="size-3.5" />
        </button>
      </div>
    </div>
  );
}

// This browser can't write tags (iOS Safari, desktop, Firefox...). There is no fake write
// any more: the app does the whole job.
function UseTheAppPanel({ verifyUrl, onCopy }: { verifyUrl: string; onCopy: () => void }) {
  return (
    <div className="flex flex-col gap-4" id="nfc-dialog-use-app">
      <div className="flex items-start gap-3 rounded-lg border border-border bg-muted/40 px-4 py-3.5">
        <Smartphone className="mt-0.5 size-4 shrink-0 text-gold-bright" strokeWidth={1.75} />
        <div className="text-xs leading-relaxed text-muted-foreground">
          <p className="font-medium text-foreground">Use the GalleryZone app</p>
          <p className="mt-1">
            Writing and locking a tag needs a phone&apos;s NFC. This browser can&apos;t do it, so open the
            GalleryZone app, choose this piece under Certificates &amp; tags and tap the chip.
          </p>
        </div>
      </div>

      {MOBILE_APP_URL && (
        <div className="flex flex-col items-center gap-2">
          <QrImage value={MOBILE_APP_URL} size={132} alt="QR code to install the GalleryZone app" />
          <a href={MOBILE_APP_URL} target="_blank" rel="noopener noreferrer" className="text-xs font-medium text-gold-bright hover:underline">
            Get the app
          </a>
        </div>
      )}

      <UrlPreview verifyUrl={verifyUrl} onCopy={onCopy} />
    </div>
  );
}

function ScanningIndicator() {
  return (
    <div className="flex flex-col items-center gap-3 py-4">
      <div className="relative flex size-16 items-center justify-center">
        <span
          className="absolute inset-0 animate-ping rounded-full border border-gold/30"
          style={{ animationDuration: "1.4s" }}
        />
        <span
          className="absolute inset-2 animate-ping rounded-full border border-gold/40"
          style={{ animationDuration: "1.4s", animationDelay: "0.2s" }}
        />
        <Nfc className="relative z-10 size-6 text-gold-bright" strokeWidth={1.5} />
      </div>
      <p className="text-xs text-muted-foreground">Hold the tag to the back of your phone…</p>
    </div>
  );
}

// Linked, not locked: the second step of the two-step flow. It must not read as "done".
function SuccessPanel({ verifyUrl }: { verifyUrl: string }) {
  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-col items-center gap-3 rounded-xl border border-emerald-500/30 bg-emerald-500/8 px-6 py-6 text-center">
        <span className="flex size-12 items-center justify-center rounded-full border border-emerald-500/40 bg-emerald-500/15">
          <ShieldCheck className="size-6 text-emerald-400" strokeWidth={1.75} />
        </span>
        <p className="font-display text-base font-semibold text-foreground">Tag linked</p>
        <p className="text-xs leading-relaxed text-muted-foreground">
          The chip is paired to this artwork. Attach it behind the artist&apos;s signature on the canvas.
        </p>
      </div>

      <div className="flex items-start gap-2.5 rounded-lg border border-red-500/40 bg-red-500/10 px-3.5 py-3">
        <Lock className="mt-0.5 size-4 shrink-0 text-red-400" />
        <div className="text-xs leading-relaxed text-red-200">
          <p className="font-medium text-red-300">Not locked yet — must lock before shipping</p>
          <p className="mt-0.5">
            Until it is locked anyone with a phone could rewrite the chip, and the piece can&apos;t be dispatched. A
            browser can&apos;t lock a tag: open the GalleryZone app to finish.
          </p>
        </div>
      </div>

      <a
        href={verifyUrl}
        id="nfc-dialog-open-app"
        className="inline-flex w-full items-center justify-center gap-2 rounded-lg border border-gold/50 bg-gold/10 px-4 py-2.5 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/20"
      >
        <Smartphone className="size-4" />
        Open in the app to lock
      </a>
      <p className="text-center text-[11px] text-muted-foreground">
        On a phone with the app this opens the piece in it. You can also lock later: the piece stays flagged until you do.
      </p>
    </div>
  );
}
