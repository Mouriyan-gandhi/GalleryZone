"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  RATE_GROUPS,
  formatRate,
  fromFormValue,
  toFormValue,
  ungroupedKeys,
  type RateField,
} from "./rate-field-groups";

// The form behind "Propose a change" in the pricing rules panel. It edits a
// copy of the currently active rates and hands the whole object back — the
// API only ever accepts a complete PricingRates, so a partial edit is not a
// thing that can be sent.
//
// Percent rates are typed as percentages and money as rupees; the
// conversions to fractions and paise happen in rate-field-groups, in one
// place, so a rate can never be stored at 100x by a typo in a field.

interface RateEditorProps {
  initial: Record<string, unknown>;
  onCancel: () => void;
  onSubmit: (rates: Record<string, unknown>, reason: string) => void;
  submitting: boolean;
}

export function RateEditor({ initial, onCancel, onSubmit, submitting }: RateEditorProps) {
  const [draft, setDraft] = useState<Record<string, unknown>>(() => ({ ...initial }));
  const [reason, setReason] = useState("");

  const setNumber = (key: string, raw: string) => {
    const parsed = Number(raw);
    if (raw !== "" && Number.isNaN(parsed)) return;
    setDraft((d) => ({ ...d, [key]: fromFormValue(key, raw === "" ? 0 : parsed) }));
  };

  const changed = Object.keys(draft).filter((k) => JSON.stringify(draft[k]) !== JSON.stringify(initial[k]));
  const canSubmit = reason.trim().length >= 10 && changed.length > 0 && !submitting;

  return (
    <form
      className="mt-5 border-t border-border pt-5"
      onSubmit={(e) => {
        e.preventDefault();
        if (canSubmit) onSubmit(draft, reason.trim());
      }}
    >
      <div className="flex flex-col gap-6">
        {RATE_GROUPS.map((group) => (
          <fieldset key={group.title}>
            <legend className="text-sm font-medium text-foreground">{group.title}</legend>
            <p className="mt-0.5 mb-3 text-xs text-muted-foreground">{group.description}</p>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              {group.fields.map((field) => (
                <RateInput
                  key={field.key}
                  field={field}
                  value={draft[field.key]}
                  original={initial[field.key]}
                  onChange={(raw) => setNumber(field.key, raw)}
                />
              ))}
            </div>
          </fieldset>
        ))}

        {ungroupedKeys(initial).length > 0 && (
          <div>
            <p className="text-sm font-medium text-foreground">Other</p>
            <p className="mt-0.5 mb-2 text-xs text-muted-foreground">
              Carried through unchanged — edit these in the API&rsquo;s rate definitions first.
            </p>
            <dl className="grid grid-cols-1 gap-x-6 gap-y-1 sm:grid-cols-2">
              {ungroupedKeys(initial).map((key) => (
                <div key={key} className="flex items-baseline justify-between gap-3 border-b border-border/60 py-1 text-xs">
                  <dt className="text-muted-foreground">{key}</dt>
                  <dd className="font-mono tabular-nums text-foreground">{formatRate(key, initial[key])}</dd>
                </div>
              ))}
            </dl>
          </div>
        )}
      </div>

      <div className="mt-6 flex flex-col gap-3 border-t border-border pt-4">
        <label className="flex flex-col gap-1.5 text-xs text-muted-foreground">
          Why this change? (recorded against the version, minimum 10 characters)
          <input
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="e.g. GST on services corrected to 18% per the 19 Sep sheet"
            className="h-9 rounded-md border border-border bg-background px-3 text-sm text-foreground"
          />
        </label>
        <div className="flex flex-wrap items-center gap-3">
          <Button type="submit" disabled={!canSubmit}>
            {submitting ? "Proposing…" : `Propose ${changed.length || "no"} change${changed.length === 1 ? "" : "s"}`}
          </Button>
          <Button type="button" variant="outline" onClick={onCancel} disabled={submitting}>
            Cancel
          </Button>
          <p className="text-xs text-muted-foreground">
            A different platform admin has to approve it before it takes effect.
          </p>
        </div>
      </div>
    </form>
  );
}

function RateInput({
  field,
  value,
  original,
  onChange,
}: {
  field: RateField;
  value: unknown;
  original: unknown;
  onChange: (raw: string) => void;
}) {
  const editable = field.unit === "percent" || field.unit === "rupees" || field.unit === "days" || field.unit === "number";
  const dirty = JSON.stringify(value) !== JSON.stringify(original);

  if (!editable || typeof value !== "number") {
    return (
      <div className="flex flex-col gap-1">
        <span className="text-xs font-medium text-foreground">{field.label}</span>
        <span className="rounded-md border border-border bg-muted/40 px-3 py-2 font-mono text-xs text-muted-foreground">
          {formatRate(field.key, value)}
        </span>
        <span className="text-[11px] leading-snug text-muted-foreground">{field.hint}</span>
      </div>
    );
  }

  return (
    <label className="flex flex-col gap-1">
      <span className="text-xs font-medium text-foreground">
        {field.label}
        {dirty && <span className="ml-1.5 text-gold-bright">changed</span>}
      </span>
      <span className="relative flex items-center">
        {field.unit === "rupees" && (
          <span className="pointer-events-none absolute left-3 text-sm text-muted-foreground">₹</span>
        )}
        <input
          type="number"
          inputMode="decimal"
          step={field.unit === "percent" ? "0.01" : field.unit === "rupees" ? "1" : "1"}
          min="0"
          value={toFormValue(field.key, value)}
          onChange={(e) => onChange(e.target.value)}
          className={`h-9 w-full rounded-md border bg-background px-3 text-sm tabular-nums text-foreground ${
            field.unit === "rupees" ? "pl-7" : ""
          } ${dirty ? "border-gold/60" : "border-border"}`}
        />
        {field.unit === "percent" && (
          <span className="pointer-events-none absolute right-3 text-sm text-muted-foreground">%</span>
        )}
        {field.unit === "days" && (
          <span className="pointer-events-none absolute right-3 text-xs text-muted-foreground">days</span>
        )}
      </span>
      <span className="text-[11px] leading-snug text-muted-foreground">{field.hint}</span>
    </label>
  );
}
