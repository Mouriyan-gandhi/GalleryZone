"use client";

import { useState } from "react";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Download, FileText, TriangleAlert } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field, FieldLabel, FieldError } from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  useAdminReports,
  useGenerateReportMutation,
} from "@/hooks/useAdminSystem";
import type { GeneratedReport, ReportType } from "@/types/admin";

const REPORT_TYPES: Array<{ value: ReportType; label: string }> = [
  { value: "sales", label: "Sales" },
  { value: "settlements", label: "Settlements" },
  { value: "artist_payouts", label: "Artist payouts" },
  { value: "aggregator_commission", label: "Aggregator commission" },
  { value: "gst", label: "GST" },
];

const reportSchema = z
  .object({
    type: z.enum([
      "sales",
      "settlements",
      "artist_payouts",
      "aggregator_commission",
      "gst",
    ]),
    from: z.string().min(1, "Pick a start date"),
    to: z.string().min(1, "Pick an end date"),
  })
  .refine((v) => new Date(v.to).getTime() >= new Date(v.from).getTime(), {
    message: "The end date must fall after the start date",
    path: ["to"],
  });

type ReportInput = z.infer<typeof reportSchema>;

export function ReportGenerator() {
  const { data: reports, isPending } = useAdminReports();
  const generateMutation = useGenerateReportMutation();
  const queryClient = useQueryClient();
  const [formError, setFormError] = useState<string | null>(null);

  const { control, handleSubmit } = useForm<ReportInput>({
    resolver: zodResolver(reportSchema),
    defaultValues: { type: "sales", from: "2026-07-01", to: "2026-08-11" },
  });

  async function onSubmit(values: ReportInput) {
    setFormError(null);
    try {
      const report = await generateMutation.mutateAsync(values);
      queryClient.setQueryData<GeneratedReport[]>(["admin-reports"], (prev) => [
        report,
        ...(prev ?? []),
      ]);
      toast.success("Report generated", { description: report.label });
    } catch (error) {
      setFormError(
        error instanceof Error
          ? error.message
          : "Could not generate the report.",
      );
    }
  }

  return (
    // grid-cols-1 below lg isn't decorative — see app/admin/page.tsx's
    // identical comment: an implicit grid track sizes to its widest child's
    // min-content instead of shrinking, overflowing the page.
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.5fr)] lg:items-start">
      <section className="rounded-xl border border-border bg-card p-5">
        <h2 className="font-display text-base font-semibold text-foreground">
          Generate a report
        </h2>
        <p className="mt-0.5 text-xs text-muted-foreground">
          Pick a type and a date range.
        </p>

        <form onSubmit={handleSubmit(onSubmit)} className="mt-4 space-y-4">
          <Controller
            control={control}
            name="type"
            render={({ field, fieldState }) => (
              <Field data-invalid={fieldState.invalid}>
                <FieldLabel>Report type</FieldLabel>
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger>
                    <SelectValue>
                      {REPORT_TYPES.find((t) => t.value === field.value)?.label}
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent>
                    {REPORT_TYPES.map((type) => (
                      <SelectItem key={type.value} value={type.value}>
                        {type.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <FieldError
                  errors={fieldState.error ? [fieldState.error] : undefined}
                />
              </Field>
            )}
          />

          <div className="grid grid-cols-2 gap-3">
            <Controller
              control={control}
              name="from"
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor="report-from">From</FieldLabel>
                  <Input {...field} id="report-from" type="date" />
                  <FieldError
                    errors={fieldState.error ? [fieldState.error] : undefined}
                  />
                </Field>
              )}
            />
            <Controller
              control={control}
              name="to"
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor="report-to">To</FieldLabel>
                  <Input {...field} id="report-to" type="date" />
                  <FieldError
                    errors={fieldState.error ? [fieldState.error] : undefined}
                  />
                </Field>
              )}
            />
          </div>

          {formError ? (
            <p className="flex items-start gap-2 rounded-md border border-destructive/50 bg-destructive/[0.06] p-3 text-xs text-foreground">
              <TriangleAlert className="mt-px size-3.5 shrink-0 text-destructive" />
              {formError}
            </p>
          ) : null}

          <Button
            type="submit"
            disabled={generateMutation.isPending}
            className="w-full"
          >
            <FileText className="size-4" />
            {generateMutation.isPending ? "Generating…" : "Generate report"}
          </Button>
        </form>
      </section>

      <section className="rounded-xl border border-border bg-card">
        <div className="border-b border-border px-5 py-4">
          <h2 className="font-display text-base font-semibold text-foreground">
            Generated reports
          </h2>
        </div>

        {isPending ? (
          <p className="px-5 py-8 text-center text-sm text-muted-foreground">
            Loading…
          </p>
        ) : (reports ?? []).length === 0 ? (
          <p className="px-5 py-8 text-center text-sm text-muted-foreground">
            No reports generated yet.
          </p>
        ) : (
          <ul className="divide-y divide-border">
            {(reports ?? []).map((report) => (
              <li
                key={report.id}
                className="flex flex-wrap items-center gap-3 px-5 py-3.5"
              >
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium text-foreground">
                    {report.label}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {report.rowCount} rows · by {report.generatedBy} ·{" "}
                    {new Date(report.generatedAt).toLocaleDateString("en-IN", {
                      day: "numeric",
                      month: "short",
                      year: "numeric",
                    })}
                  </p>
                </div>
                {/* Honest about being inert: there is no file behind this in a
                    mock build, so it is labelled and disabled rather than
                    dressed up as a working link that silently does nothing. */}
                <Button
                  size="sm"
                  variant="outline"
                  disabled
                  title="Downloads are not available in this demo build"
                >
                  <Download className="size-3.5" />
                  Demo (no file)
                </Button>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
