"use client";

import { useEffect, useState } from "react";
import { useForm, useWatch, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Loader2 } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
  Field,
  FieldLabel,
  FieldError,
  FieldDescription,
} from "@/components/ui/field";

// A rejection with no reason is useless to the artist or aggregator receiving
// it, so the reason is mandatory rather than merely encouraged. Minimum five
// characters after trimming: enough to reject " " and "no", short enough that
// a legitimately terse reason ("Blurry") still passes.
const rejectReasonSchema = z.object({
  reason: z.string().trim().min(5, "Give a reason the recipient can act on"),
});
type RejectReasonFormValues = z.infer<typeof rejectReasonSchema>;

interface RejectReasonDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description?: React.ReactNode;
  /** Quick-select chips. Clicking one fills the textarea; it stays editable. */
  presets?: string[];
  label?: string;
  placeholder?: string;
  confirmLabel?: string;
  /** The line under the box. Defaults to the rejection wording; override where nobody is notified. */
  helpText?: string;
  /** Pass a mutation's `isPending`; omitted, the dialog awaits onSubmit itself. */
  isPending?: boolean;
  /**
   * Receives the trimmed reason. This dialog does not close itself on success
   * -- the caller closes it from its own onSuccess, after the cache update and
   * audit append, so a failed mutation leaves the typed reason intact.
   */
  onSubmit: (reason: string) => void | Promise<void>;
}

// Shared by artwork reject, KYC reject and withdrawal reject. Each passes its
// own presets drawn from that workflow's real criteria.
export function RejectReasonDialog({
  open,
  onOpenChange,
  title,
  description,
  presets,
  label = "Reason for rejection",
  placeholder = "Explain what needs to change...",
  confirmLabel = "Reject",
  helpText = "This is recorded on the audit log and sent to the recipient.",
  isPending,
  onSubmit,
}: RejectReasonDialogProps) {
  const [internalPending, setInternalPending] = useState(false);
  const pending = isPending ?? internalPending;

  const { control, handleSubmit, reset, setValue } =
    useForm<RejectReasonFormValues>({
      resolver: zodResolver(rejectReasonSchema),
      defaultValues: { reason: "" },
    });

  // useWatch, not watch(): register-form.tsx sets the same precedent, and the
  // React Compiler lint can't memoize a component that calls watch().
  const currentReason = useWatch({ control, name: "reason" }) ?? "";

  useEffect(() => {
    if (open) reset({ reason: "" });
  }, [open, reset]);

  async function submit(values: RejectReasonFormValues) {
    if (pending) return;
    try {
      setInternalPending(true);
      await onSubmit(values.reason.trim());
    } finally {
      setInternalPending(false);
    }
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        if (!pending) onOpenChange(next);
      }}
    >
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          {description && (
            <DialogDescription render={<div />}>
              {description}
            </DialogDescription>
          )}
        </DialogHeader>

        <form
          id="reject-reason-form"
          onSubmit={handleSubmit(submit)}
          className="flex flex-col gap-4"
        >
          {presets && presets.length > 0 && (
            <div className="flex flex-wrap gap-1.5">
              {presets.map((preset) => {
                const selected = currentReason.trim() === preset;
                return (
                  <button
                    key={preset}
                    type="button"
                    onClick={() =>
                      setValue("reason", preset, {
                        shouldValidate: true,
                        shouldDirty: true,
                      })
                    }
                    aria-pressed={selected}
                    className={`rounded-full border px-2.5 py-1 text-xs font-medium transition-colors active:scale-[0.98] ${
                      selected
                        ? "border-gold/45 bg-gold/15 text-gold-bright"
                        : "border-border bg-secondary text-muted-foreground hover:border-gold/30 hover:text-foreground"
                    }`}
                  >
                    {preset}
                  </button>
                );
              })}
            </div>
          )}

          <Controller
            control={control}
            name="reason"
            render={({ field, fieldState }) => (
              <Field data-invalid={fieldState.invalid}>
                <FieldLabel htmlFor="reject-reason">{label}</FieldLabel>
                <Textarea
                  id="reject-reason"
                  rows={4}
                  placeholder={placeholder}
                  aria-invalid={fieldState.invalid}
                  {...field}
                />
                <FieldDescription>{helpText}</FieldDescription>
                <FieldError errors={[fieldState.error]} />
              </Field>
            )}
          />
        </form>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={pending}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            form="reject-reason-form"
            variant="destructive"
            disabled={pending}
          >
            {pending && <Loader2 className="size-4 animate-spin" />}
            {confirmLabel}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
