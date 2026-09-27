"use client";

import { useCurrentUser } from "@/hooks/useCurrentUser";

import { useState } from "react";
import { useForm, Controller, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { TriangleAlert } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Field,
  FieldLabel,
  FieldError,
  FieldDescription,
} from "@/components/ui/field";
import { Skeleton } from "@/components/ui/skeleton";
import {
  useAdminSettings,
  useUpdateSettingsMutation,
} from "@/hooks/useAdminSystem";
import { useAdminAuditStore } from "@/store/useAdminAuditStore";
import { formatINR } from "@/lib/utils";
import type { PlatformSettings } from "@/types/admin";

const settingsSchema = z.object({
  markupPercent: z.coerce
    .number<number>()
    .min(0, "Cannot be negative")
    .max(100, "Cannot exceed 100%"),
  gstPercent: z.coerce
    .number<number>()
    .min(0, "Cannot be negative")
    .max(100, "Cannot exceed 100%"),
  aggregatorCommissionPercent: z.coerce
    .number<number>()
    .min(0, "Cannot be negative")
    .max(100, "Cannot exceed 100%"),
  minWithdrawalAmount: z.coerce.number<number>().min(1, "Must be at least ₹1"),
  insuranceThreshold: z.coerce.number<number>().min(1, "Must be at least ₹1"),
});

type SettingsInput = z.infer<typeof settingsSchema>;

const FIELDS: Array<{
  name: keyof SettingsInput;
  label: string;
  description: string;
  suffix: "%" | "₹";
}> = [
  {
    name: "markupPercent",
    label: "Customer markup",
    description:
      "Added to the artist's private price to reach the public price.",
    suffix: "%",
  },
  {
    name: "gstPercent",
    label: "GST",
    description: "Applied on top of the marked-up customer price.",
    suffix: "%",
  },
  {
    name: "aggregatorCommissionPercent",
    label: "Aggregator commission",
    description:
      "Share of the markup paid to the aggregator on an assisted sale.",
    suffix: "%",
  },
  {
    name: "minWithdrawalAmount",
    label: "Minimum withdrawal",
    description: "Smallest payout an artist or aggregator can request.",
    suffix: "₹",
  },
  {
    name: "insuranceThreshold",
    label: "Insurance threshold",
    description: "Above this value, transit insurance is strongly recommended.",
    suffix: "₹",
  },
];

export function SettingsForm() {
  const { data: settings, isPending } = useAdminSettings();

  if (isPending || !settings) {
    return (
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
        <Skeleton className="h-[520px] rounded-xl" />
        <Skeleton className="h-[320px] rounded-xl" />
      </div>
    );
  }

  return <SettingsFormBody settings={settings} />;
}

function SettingsFormBody({ settings }: { settings: PlatformSettings }) {
  const adminName = useCurrentUser().data?.name ?? "Admin";
  const queryClient = useQueryClient();
  const appendAudit = useAdminAuditStore((s) => s.append);
  const updateMutation = useUpdateSettingsMutation();
  const [formError, setFormError] = useState<string | null>(null);

  const { control, handleSubmit, reset } = useForm<SettingsInput>({
    resolver: zodResolver(settingsSchema),
    defaultValues: settings,
  });

  // Drives the preview panel: every keystroke re-prices the worked example, so
  // you can see what a number does before committing to it.
  const live = useWatch({ control });

  async function onSubmit(values: SettingsInput) {
    setFormError(null);
    const changed = FIELDS.filter(
      (f) => values[f.name] !== settings[f.name],
    ).map((f) => f.label);

    try {
      const updated = await updateMutation.mutateAsync(values);
      queryClient.setQueryData<PlatformSettings>(["admin-settings"], updated);
      appendAudit({
        adminName: adminName,
        action: "settings.updated",
        entityType: "settings",
        entityId: "platform",
        entityLabel: "Platform settings",
        detail: changed.length
          ? `Changed: ${changed.join(", ")}`
          : "Saved with no changes",
      });
      reset(values);
      toast.success("Settings saved");
    } catch (error) {
      setFormError(
        error instanceof Error ? error.message : "Could not save settings.",
      );
    }
  }

  return (
    // grid-cols-1 below lg isn't decorative — see app/admin/page.tsx's
    // identical comment: an implicit grid track sizes to its widest child's
    // min-content instead of shrinking, overflowing the page.
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-start">
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="space-y-4 rounded-xl border border-border bg-card p-5"
      >
        <div>
          <h2 className="font-display text-base font-semibold text-foreground">
            Pricing & payouts
          </h2>
          <p className="mt-0.5 text-xs text-muted-foreground">
            These values govern every listing and settlement on the platform.
          </p>
        </div>

        <div className="space-y-4 border-t border-border pt-4">
          {FIELDS.map((entry) => (
            <Controller
              key={entry.name}
              control={control}
              name={entry.name}
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor={`setting-${entry.name}`}>
                    {entry.label}
                  </FieldLabel>
                  <div className="relative">
                    <Input
                      id={`setting-${entry.name}`}
                      type="number"
                      inputMode="decimal"
                      step={entry.suffix === "%" ? "0.5" : "100"}
                      value={field.value ?? ""}
                      onChange={(e) =>
                        field.onChange(
                          e.target.value === "" ? "" : Number(e.target.value),
                        )
                      }
                      onBlur={field.onBlur}
                      name={field.name}
                      className={entry.suffix === "₹" ? "pl-7" : "pr-8"}
                    />
                    <span
                      aria-hidden
                      className={`pointer-events-none absolute inset-y-0 flex items-center text-sm text-muted-foreground ${
                        entry.suffix === "₹" ? "left-3" : "right-3"
                      }`}
                    >
                      {entry.suffix}
                    </span>
                  </div>
                  <FieldDescription>{entry.description}</FieldDescription>
                  <FieldError
                    errors={fieldState.error ? [fieldState.error] : undefined}
                  />
                </Field>
              )}
            />
          ))}
        </div>

        {formError ? (
          <p className="flex items-start gap-2 rounded-md border border-destructive/50 bg-destructive/[0.06] p-3 text-xs text-foreground">
            <TriangleAlert className="mt-px size-3.5 shrink-0 text-destructive" />
            {formError}
          </p>
        ) : null}

        <Button
          type="submit"
          disabled={updateMutation.isPending}
          className="w-full"
        >
          {updateMutation.isPending ? "Saving…" : "Save settings"}
        </Button>
      </form>

      <PricingPreview
        markupPercent={Number(live.markupPercent ?? settings.markupPercent)}
        gstPercent={Number(live.gstPercent ?? settings.gstPercent)}
        aggregatorCommissionPercent={Number(
          live.aggregatorCommissionPercent ??
            settings.aggregatorCommissionPercent,
        )}
      />
    </div>
  );
}

const EXAMPLE_ARTIST_PRICE = 30_000;

function PricingPreview({
  markupPercent,
  gstPercent,
  aggregatorCommissionPercent,
}: {
  markupPercent: number;
  gstPercent: number;
  aggregatorCommissionPercent: number;
}) {
  const safeMarkup = Number.isFinite(markupPercent) ? markupPercent : 0;
  const safeGst = Number.isFinite(gstPercent) ? gstPercent : 0;
  const safeCommission = Number.isFinite(aggregatorCommissionPercent)
    ? aggregatorCommissionPercent
    : 0;

  const markup = Math.round(EXAMPLE_ARTIST_PRICE * (safeMarkup / 100));
  const customerPrice = EXAMPLE_ARTIST_PRICE + markup;
  const gst = Math.round(customerPrice * (safeGst / 100));
  const finalPrice = customerPrice + gst;
  const aggregatorShare = Math.round(markup * (safeCommission / 100));
  const platformShare = markup - aggregatorShare;

  return (
    <section className="rounded-xl border border-gold/40 bg-gold/[0.04] p-5">
      <h2 className="font-display text-base font-semibold text-foreground">
        What this means
      </h2>
      <p className="mt-0.5 text-xs text-muted-foreground">
        A worked example, recalculated as you type.
      </p>

      <dl className="mt-4 space-y-2.5 border-t border-gold/25 pt-4">
        <Row
          label="Artist lists at"
          value={formatINR(EXAMPLE_ARTIST_PRICE)}
          muted
        />
        <Row
          label={`Markup (${safeMarkup}%)`}
          value={`+ ${formatINR(markup)}`}
          muted
        />
        <Row label="Customer sees" value={formatINR(customerPrice)} emphasis />
        <Row label={`GST (${safeGst}%)`} value={`+ ${formatINR(gst)}`} muted />
        <div className="flex items-baseline justify-between border-t border-gold/25 pt-2.5">
          <dt className="text-sm font-medium text-foreground">Customer pays</dt>
          <dd className="font-display text-xl font-semibold tabular-nums text-gold-bright">
            {formatINR(finalPrice)}
          </dd>
        </div>
      </dl>

      <div className="mt-5 border-t border-gold/25 pt-4">
        <p className="text-xs font-medium tracking-[0.08em] text-muted-foreground uppercase">
          How the markup splits
        </p>
        <dl className="mt-2.5 space-y-2.5">
          <Row
            label="Artist receives"
            value={formatINR(EXAMPLE_ARTIST_PRICE)}
          />
          <Row
            label={`Aggregator (${safeCommission}% of markup)`}
            value={formatINR(aggregatorShare)}
          />
          <Row label="Platform retains" value={formatINR(platformShare)} />
        </dl>
        <p className="mt-3 text-xs text-muted-foreground">
          On a marketplace-only sale with no aggregator involved, the platform
          retains the full {formatINR(markup)} markup.
        </p>
      </div>
    </section>
  );
}

function Row({
  label,
  value,
  muted = false,
  emphasis = false,
}: {
  label: string;
  value: string;
  muted?: boolean;
  emphasis?: boolean;
}) {
  return (
    <div className="flex items-baseline justify-between gap-3">
      <dt
        className={`text-sm ${muted ? "text-muted-foreground" : "text-foreground"}`}
      >
        {label}
      </dt>
      <dd
        className={`tabular-nums ${
          emphasis
            ? "text-base font-semibold text-foreground"
            : "text-sm text-foreground"
        }`}
      >
        {value}
      </dd>
    </div>
  );
}
