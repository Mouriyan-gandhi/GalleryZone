"use client";

import { useRef, useState, type FormEvent } from "react";
import { motion } from "framer-motion";
import {
  AlertTriangle,
  FileSignature,
  ShieldCheck,
  Check,
  ChevronRight,
  ChevronDown,
  Download,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { SignaturePad } from "./signature-pad";
import { downloadMouPdf } from "./mou-pdf";
import {
  MOU_DETAIL_LABEL,
  mouDate,
  mouDateTime,
  mouFieldValue,
  type MouAcceptanceRecord,
  type MouDocument,
  type MouDraft,
  type MouFieldKey,
  type MouFill,
} from "./mou-document";

// One signing surface for both Memoranda of Understanding, the artist's and
// the aggregator's. They are different documents with the same mechanics:
// read the whole thing with your own details filled in, agree, sign with your
// own name. The caller supplies the document and owns the mutation; this
// component owns the reading and signing.

export function MouAgreement({
  document,
  signerName,
  acceptance,
  draft,
  onSign,
  isPending = false,
  error,
  isSuccess = false,
}: {
  document: MouDocument;
  /** The name the signature has to match: the profile's full name. */
  signerName: string;
  acceptance: MouAcceptanceRecord | null;
  draft: MouDraft;
  onSign: (input: { signatureName: string; version: string; signatureDataUrl: string }) => void;
  isPending?: boolean;
  error?: unknown;
  isSuccess?: boolean;
}) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const [readToEnd, setReadToEnd] = useState(false);
  const [agreed, setAgreed] = useState(false);
  const [signature, setSignature] = useState("");
  const [signatureDataUrl, setSignatureDataUrl] = useState<string | null>(null);

  function handleScroll() {
    const el = scrollRef.current;
    if (!el) return;
    // 24px of slack so a trackpad that stops a hair short still counts.
    if (el.scrollTop + el.clientHeight >= el.scrollHeight - 24) {
      setReadToEnd(true);
    }
  }

  if (acceptance) {
    const fill: MouFill = {
      // Records from before the blanks were snapshotted fall back to today's profile.
      parties: acceptance.parties ?? draft.parties,
      date: acceptance.acceptedAt,
      signed: true,
      signatureName: acceptance.signatureName,
      signatureDataUrl: acceptance.signatureDataUrl ?? null,
    };
    return (
      <div className="flex flex-col gap-4 rounded-lg border border-border bg-card p-5 sm:p-6">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div className="flex items-center gap-3">
            <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-emerald-500/40 bg-emerald-500/10">
              <ShieldCheck className="size-4 text-emerald-500" strokeWidth={1.75} />
            </span>
            <div>
              <h2 className="font-display text-base font-semibold text-foreground">{document.title}</h2>
              <p className="text-sm text-muted-foreground">
                Signed {mouDateTime(acceptance.acceptedAt)}. Version {acceptance.version}.
              </p>
            </div>
          </div>
          <span className="rounded-full border border-emerald-500/40 bg-emerald-500/10 px-2.5 py-1 text-xs font-medium text-emerald-600 dark:text-emerald-400">
            Signed
          </span>
        </div>

        <div className="flex flex-wrap items-end justify-between gap-4 rounded-md border border-border bg-background/60 px-4 py-3">
          <div>
            <p className="text-xs text-muted-foreground">Signed by</p>
            <p className="mt-0.5 font-display text-lg italic text-foreground">{acceptance.signatureName}</p>
            {acceptance.signatureDataUrl && (
              // eslint-disable-next-line @next/next/no-img-element -- a locally drawn data URL, not a next/image-optimizable remote asset
              <img
                src={acceptance.signatureDataUrl}
                alt={`${acceptance.signatureName}'s signature`}
                className="mt-2 h-14 w-auto dark:invert"
              />
            )}
          </div>
          <button
            type="button"
            onClick={() => downloadMouPdf(document, fill)}
            className="inline-flex shrink-0 items-center gap-1.5 rounded-md border border-border px-3 py-2 text-xs font-medium text-foreground transition-colors hover:border-gold/50 hover:text-gold-bright focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
          >
            <Download className="size-3.5" />
            Download signed PDF
          </button>
        </div>

        {/* Once signed, the document is reference material rather than
            something to read: it collapses so the rest of the profile is not
            pushed a screen down. <details> rather than state: the browser
            already does this, including keyboard and find-in-page. */}
        <details className="group">
          <summary className="flex cursor-pointer list-none items-center gap-2 text-sm font-medium text-gold-bright transition-colors hover:text-gold">
            <ChevronRight className="size-4 transition-transform group-open:rotate-90" />
            Read the signed agreement
          </summary>
          <div className="mt-3">
            <MouBody document={document} fill={fill} scrollRef={scrollRef} onScroll={handleScroll} compact />
          </div>
        </details>
      </div>
    );
  }

  const fill: MouFill = {
    parties: draft.parties,
    date: draft.asOf,
    signed: false,
    signatureName: null,
    signatureDataUrl: null,
  };
  // The API has a newer text than this page was built with: signing would be refused.
  const stale = draft.version !== document.version;
  const blocked = stale || draft.missing.length > 0;
  const nameMatches = signature.trim().toLowerCase() === signerName.trim().toLowerCase();
  const canSign = !blocked && readToEnd && agreed && nameMatches && signatureDataUrl !== null;

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!canSign || !signatureDataUrl) return;
    onSign({ signatureName: signature.trim(), version: document.version, signatureDataUrl });
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-5 rounded-lg border border-gold/30 bg-card p-5 sm:p-6">
      <div className="flex items-center gap-3">
        <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-gold/40 bg-gold/10">
          <FileSignature className="size-4 text-gold-bright" strokeWidth={1.75} />
        </span>
        <div>
          <h2 className="font-display text-base font-semibold text-foreground">{document.title}</h2>
          <p className="text-sm text-muted-foreground">{document.intro}</p>
        </div>
      </div>

      <SigningSteps readDone={readToEnd} agreeDone={agreed} signDone={isSuccess} />

      {stale ? (
        <Notice>
          This agreement has been updated since the page loaded. Reload the page to read and sign the current version.
        </Notice>
      ) : (
        draft.missing.length > 0 && (
          <Notice>
            <span className="block font-medium text-foreground">Your profile is missing details this agreement needs</span>
            <span className="mt-1 block">
              {draft.missing.map((key) => MOU_DETAIL_LABEL[key]).join(", ")}. Add them to your profile on this page and save. They fill in
              here, and you can sign.
            </span>
          </Notice>
        )
      )}

      <div className="relative">
        <MouBody document={document} fill={fill} scrollRef={scrollRef} onScroll={handleScroll} />
        {!readToEnd && (
          <div className="pointer-events-none absolute inset-x-0 bottom-0 flex items-end justify-center rounded-b-md bg-gradient-to-t from-background/95 via-background/60 to-transparent pb-2 pt-8">
            <span className="flex items-center gap-1.5 rounded-full border border-gold/40 bg-card px-3 py-1 text-xs font-medium text-gold-bright shadow-sm">
              <ChevronDown className="size-3.5 shrink-0 motion-safe:animate-bounce" strokeWidth={2} />
              Scroll to the end to continue
            </span>
          </div>
        )}
      </div>

      <label className="flex cursor-pointer items-start gap-2.5 rounded-md border border-border p-3.5">
        <Checkbox
          checked={agreed}
          disabled={!readToEnd || blocked}
          onCheckedChange={(checked) => setAgreed(checked === true)}
          className="mt-0.5"
        />
        <span className="text-sm leading-relaxed text-foreground">
          I have read this Memorandum of Understanding in full, the details above are mine, and I agree to be bound by it.
        </span>
      </label>

      <div className="flex flex-col gap-2">
        <Label htmlFor="mouSignature">Type your full name</Label>
        <Input
          id="mouSignature"
          value={signature}
          disabled={!agreed}
          onChange={(e) => setSignature(e.target.value)}
          placeholder={signerName}
          className="h-11 font-display text-lg italic"
          autoComplete="off"
        />
        <p className="text-xs text-muted-foreground">
          Exactly as it appears on your profile ({signerName}). It is recorded with your drawn signature, the date and the document version.
        </p>
        {signature.trim().length > 0 && !nameMatches && (
          <p className="text-xs text-destructive">
            This doesn&rsquo;t match the name on your profile. Update your profile first if your legal name is different.
          </p>
        )}
      </div>

      <div className="flex flex-col gap-2">
        <Label>Draw your signature</Label>
        <SignaturePad disabled={!agreed} onChange={setSignatureDataUrl} />
        <p className="text-xs text-muted-foreground">Sign with a mouse, or your finger or stylus on a touchscreen.</p>
      </div>

      <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
        <button
          type="submit"
          disabled={!canSign || isPending}
          className="inline-flex items-center gap-2 rounded-md bg-gradient-to-b from-gold-bright to-gold px-5 py-2.5 text-sm font-semibold text-[#171310] transition-transform hover:scale-[1.02] focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.98] disabled:pointer-events-none disabled:opacity-40"
        >
          {isPending ? "Signing…" : "Sign and accept"}
        </button>
        <span className="text-sm text-muted-foreground">
          Dated <span className="font-medium text-foreground tabular-nums">{mouDate(draft.asOf)}</span>
        </span>
        {Boolean(error) && (
          <span role="alert" className="w-full text-sm text-destructive">
            {error instanceof Error ? error.message : "Something went wrong."}
          </span>
        )}
        {isSuccess && (
          <motion.span initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex items-center gap-1.5 text-sm text-gold-bright">
            <Check className="size-3.5" />
            Signed
          </motion.span>
        )}
      </div>
    </form>
  );
}

function Notice({ children }: { children: React.ReactNode }) {
  return (
    <div role="status" className="flex items-start gap-2.5 rounded-md border border-destructive/40 bg-destructive/5 p-3.5 text-sm text-muted-foreground">
      <AlertTriangle className="mt-0.5 size-4 shrink-0 text-destructive" strokeWidth={1.75} />
      <p>{children}</p>
    </div>
  );
}

// Small progress cue so a first-time signer knows where they are in the
// read -> agree -> sign flow before they've done any of it, rather than
// discovering the rules (must scroll, must type your name) one disabled
// control at a time.
function SigningSteps({ readDone, agreeDone, signDone }: { readDone: boolean; agreeDone: boolean; signDone: boolean }) {
  const steps = [
    { label: "Read", done: readDone },
    { label: "Agree", done: agreeDone },
    { label: "Sign", done: signDone },
  ];

  return (
    <div className="flex items-center gap-2">
      {steps.map((step, index) => (
        <div key={step.label} className="flex items-center gap-2">
          <div className="flex items-center gap-1.5">
            <span
              className={cn(
                "flex size-5 shrink-0 items-center justify-center rounded-full border text-[10px] font-semibold transition-colors",
                step.done ? "border-gold bg-gold-bright text-[#171310]" : "border-border text-muted-foreground",
              )}
            >
              {step.done ? <Check className="size-3" strokeWidth={3} /> : index + 1}
            </span>
            <span className={cn("text-xs font-medium", step.done ? "text-foreground" : "text-muted-foreground")}>{step.label}</span>
          </div>
          {index < steps.length - 1 && <span className="h-px w-6 shrink-0 bg-border sm:w-10" />}
        </div>
      ))}
    </div>
  );
}

// The document as the company wrote it, block for block, with its blanks
// filled. Set like the paper: headings as written, lettered items hanging,
// the opening block centred where the PDF centres it.
function MouBody({
  document,
  fill,
  scrollRef,
  onScroll,
  compact = false,
}: {
  document: MouDocument;
  fill: MouFill;
  scrollRef: React.RefObject<HTMLDivElement | null>;
  onScroll: () => void;
  compact?: boolean;
}) {
  return (
    <div
      ref={scrollRef}
      onScroll={onScroll}
      tabIndex={0}
      aria-label={`${document.title}, full text`}
      className={cn(
        "overflow-y-auto rounded-md border border-border bg-background/60 px-4 py-6 text-[0.9rem] leading-relaxed focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 sm:px-8 sm:py-8",
        compact ? "max-h-[28rem]" : "max-h-[70vh]",
      )}
    >
      <article className="mx-auto flex max-w-[72ch] flex-col gap-2.5">
        {document.blocks.map((block, i) => {
          switch (block.type) {
            case "title":
              return (
                <h3 key={i} className="text-center font-display text-xl font-semibold tracking-wide text-foreground sm:text-2xl">
                  {block.text}
                </h3>
              );
            case "heading":
              return (
                <h4 key={i} className={cn("mt-4 text-sm font-semibold tracking-wide text-foreground", block.center && "text-center")}>
                  {block.text}
                </h4>
              );
            case "subheading":
              return (
                <h5 key={i} className="mt-2 font-medium text-foreground">
                  {block.text}
                </h5>
              );
            case "paragraph":
              return (
                <p key={i} className={cn("text-foreground/80", block.center && "text-center")}>
                  {block.text}
                </p>
              );
            case "item":
              return (
                // One run of text ("a. establishing…") with a hanging indent, so
                // it copies and reads aloud exactly as the paper has it.
                <p key={i} className="pl-9 -indent-6 text-foreground/80">
                  {`${block.marker} ${block.text}`}
                </p>
              );
            case "signer":
              return (
                <h4 key={i} className="mt-6 border-t border-border pt-5 text-sm font-semibold tracking-wide text-foreground">
                  {block.text}
                </h4>
              );
            case "field":
              return <Field key={i} label={block.label} fieldKey={block.key} fill={fill} party={document.party} />;
            case "note":
              return (
                <p key={i} className="mt-6 border-t border-border pt-4 text-xs text-muted-foreground">
                  {block.text}
                </p>
              );
          }
        })}
      </article>
    </div>
  );
}

// One blank, filled. The value sits on the line the paper leaves for it, so
// the reader sees their own details written into the agreement.
function Field({ label, fieldKey, fill, party }: { label: string; fieldKey: MouFieldKey; fill: MouFill; party: MouDocument["party"] }) {
  const value = mouFieldValue(fieldKey, fill, party);
  return (
    <div className="grid grid-cols-[auto_minmax(0,1fr)] items-baseline gap-x-2">
      <span className="text-foreground/80">{label}:</span>
      {value.kind === "text" && (
        <span className="w-fit border-b border-dashed border-gold/60 pb-0.5 font-medium break-words text-foreground">{value.text}</span>
      )}
      {value.kind === "signature" && (
        <span className="flex w-fit flex-col border-b border-dashed border-gold/60 pb-1">
          {value.image && (
            // eslint-disable-next-line @next/next/no-img-element -- a locally drawn data URL
            <img src={value.image} alt={`${value.name}'s signature`} className="h-12 w-auto dark:invert" />
          )}
          <span className="font-display text-base italic text-foreground">{value.name}</span>
        </span>
      )}
      {value.kind === "pending" && (
        <span className="w-fit border-b border-dashed border-border pb-0.5 text-muted-foreground italic">{value.text}</span>
      )}
      {value.kind === "missing" && (
        <span className="w-fit border-b border-dashed border-destructive/70 pb-0.5 text-destructive">Missing from your profile</span>
      )}
      {value.kind === "blank" && <span aria-label="Blank" className="h-4 w-40 max-w-full border-b border-border sm:w-56" />}
    </div>
  );
}
