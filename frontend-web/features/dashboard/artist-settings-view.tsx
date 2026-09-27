"use client";

import { useState, type FormEvent } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { toast } from "sonner";
import { BadgeCheck, Check, Loader2 } from "lucide-react";
import { Switch } from "@/components/ui/switch";
import { Input } from "@/components/ui/input";
import { Field, FieldLabel, FieldError } from "@/components/ui/field";
import {
  useArtistSettings,
  useUpdateArtistSettingsMutation,
} from "@/hooks/useArtistSettings";
import {
  useDeactivationRequest,
  useRequestDeactivationMutation,
  useWithdrawDeactivationMutation,
} from "@/hooks/useArtistAccount";
import { passwordRule } from "@/features/auth/schemas/auth-schemas";
import { SUBSCRIPTION } from "./dashboard-data";
import { useArtistAccountProfile } from "@/hooks/useArtistAccount";

const NOTIFICATION_TOGGLES = [
  {
    key: "notifyArtworkApproved" as const,
    label: "Artwork approved or rejected",
  },
  { key: "notifyNewSale" as const, label: "New sale" },
  { key: "notifyWithdrawalProcessed" as const, label: "Withdrawal processed" },
  { key: "notifyNewMessage" as const, label: "New message" },
];

export function ArtistSettingsView() {
  const { data: settings } = useArtistSettings();
  const updateMutation = useUpdateArtistSettingsMutation();

  return (
    <div className="flex flex-col gap-6">
      <SubscriptionCard />

      <div className="rounded-lg border border-border bg-card p-5 sm:p-6">
        <h2 className="font-display text-base font-semibold text-foreground">
          Notifications
        </h2>
        <div className="mt-4 flex flex-col divide-y divide-border">
          {NOTIFICATION_TOGGLES.map((toggle) => (
            <div
              key={toggle.key}
              className="flex items-center justify-between gap-3 py-3 first:pt-0 last:pb-0"
            >
              <span className="text-sm text-foreground">{toggle.label}</span>
              <Switch
                checked={settings?.[toggle.key] ?? false}
                onCheckedChange={(checked) =>
                  updateMutation.mutate({ [toggle.key]: checked })
                }
              />
            </div>
          ))}
        </div>
      </div>

      <SecurityCard />

      <DangerZone />
    </div>
  );
}

// Closing the account is a request, not a switch. A GalleryZone admin decides,
// because an account on its way out may still owe a settlement, have a piece
// sitting with an aggregator, or have a transfer someone is waiting to accept.
// The typed word is deliberate friction on a step that cannot be undone by
// pressing the same button again.
const CONFIRM_WORD = "DEACTIVATE";

function DangerZone() {
  const { data: request } = useDeactivationRequest();
  const requestMutation = useRequestDeactivationMutation();
  const withdrawMutation = useWithdrawDeactivationMutation();
  const [reason, setReason] = useState("");
  const [confirmWord, setConfirmWord] = useState("");

  const pending = request?.status === "pending";
  const canSubmit =
    reason.trim().length > 0 &&
    confirmWord.trim().toUpperCase() === CONFIRM_WORD &&
    !requestMutation.isPending;

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!canSubmit) return;
    requestMutation.mutate(
      { reason },
      {
        onSuccess: () => {
          setReason("");
          setConfirmWord("");
          toast.info("Deactivation requested. GalleryZone will review it.");
        },
      },
    );
  }

  return (
    <div className="rounded-lg border border-destructive/30 bg-destructive/5 p-5 sm:p-6">
      <h2 className="font-display text-base font-semibold text-foreground">
        Danger zone
      </h2>

      {pending ? (
        <div className="mt-3 flex flex-col items-start gap-3">
          <p className="text-sm text-muted-foreground">
            Deactivation requested on{" "}
            {new Date(request.requestedAt).toLocaleDateString("en-IN", {
              day: "numeric",
              month: "short",
              year: "numeric",
            })}
            , awaiting review. Your listings stay live until it is approved.
          </p>
          <p className="rounded-md border border-border bg-background/60 px-3 py-2 text-xs text-muted-foreground">
            Your reason: {request.reason}
          </p>
          <button
            type="button"
            disabled={withdrawMutation.isPending}
            onClick={() => withdrawMutation.mutate(request.id)}
            className="rounded-md border border-border px-4 py-2 text-sm font-medium text-foreground transition-colors hover:bg-secondary disabled:pointer-events-none disabled:opacity-40"
          >
            Withdraw request
          </button>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="mt-3 flex flex-col gap-3">
          {request?.status === "rejected" && (
            <p className="rounded-md border border-border bg-background/60 px-3 py-2 text-xs text-muted-foreground">
              Your last request was refused
              {request.decisionNote ? `: ${request.decisionNote}` : "."} You can
              ask again.
            </p>
          )}
          {request?.status === "approved" && (
            <p className="rounded-md border border-border bg-background/60 px-3 py-2 text-xs text-muted-foreground">
              This account has been deactivated by GalleryZone. Contact support
              to reopen it.
            </p>
          )}

          <p className="text-sm text-muted-foreground">
            Deactivating removes your listings from the marketplace. It is
            reviewed by GalleryZone first — certificates, ownership records and
            anything still owed to you have to be settled before an account
            closes.
          </p>

          <Field>
            <FieldLabel htmlFor="deactivateReason">
              Why are you closing the account?
            </FieldLabel>
            <Input
              id="deactivateReason"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Moving abroad"
              className="h-10"
            />
          </Field>

          <Field>
            <FieldLabel htmlFor="deactivateConfirm">
              Type {CONFIRM_WORD} to confirm
            </FieldLabel>
            <Input
              id="deactivateConfirm"
              value={confirmWord}
              onChange={(e) => setConfirmWord(e.target.value)}
              placeholder={CONFIRM_WORD}
              className="h-10 font-mono sm:max-w-[14rem]"
            />
          </Field>

          {requestMutation.error instanceof Error && (
            <p className="text-sm text-destructive">
              {requestMutation.error.message}
            </p>
          )}

          <button
            type="submit"
            disabled={!canSubmit}
            className="self-start rounded-md border border-destructive/40 px-4 py-2 text-sm font-medium text-destructive transition-colors hover:bg-destructive/10 disabled:pointer-events-none disabled:opacity-40"
          >
            Request deactivation
          </button>
        </form>
      )}
    </div>
  );
}

// Every artist is on the founding-member plan (free for the first year) —
// a platform policy, not per-user data. The one per-user fact, the renewal
// date, is a year after the account was created.
function SubscriptionCard() {
  const { data: profile } = useArtistAccountProfile();
  const startedOn = profile?.joinedAt ?? new Date().toISOString();
  const renewsOn = new Date(new Date(startedOn).setFullYear(new Date(startedOn).getFullYear() + 1)).toISOString();
  return (
    <div className="rounded-lg border border-gold/30 bg-gold/5 p-5 sm:p-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex items-center gap-3">
          <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-gold/40 bg-background">
            <BadgeCheck className="size-4 text-gold-bright" strokeWidth={1.75} />
          </span>
          <div>
            <h2 className="font-display text-base font-semibold text-foreground">
              {SUBSCRIPTION.planName} plan
            </h2>
            <p className="text-sm text-gold-bright">
              {SUBSCRIPTION.priceLabel}
            </p>
          </div>
        </div>
        <span className="rounded-full border border-gold/40 px-2.5 py-1 text-xs font-medium text-gold-bright">
          Active
        </span>
      </div>

      <ul className="mt-4 grid grid-cols-1 gap-1.5 sm:grid-cols-2">
        {SUBSCRIPTION.benefits.map((benefit) => (
          <li
            key={benefit}
            className="flex items-start gap-2 text-sm text-muted-foreground"
          >
            <Check className="mt-0.5 size-3.5 shrink-0 text-gold-bright" />
            {benefit}
          </li>
        ))}
      </ul>

      <p className="mt-4 border-t border-gold/20 pt-3 text-xs text-muted-foreground">
        Renews {formatPlanDate(renewsOn)} at{" "}
        {SUBSCRIPTION.renewalPriceLabel}. Nothing to pay until then, and we
        will tell you well before anything changes.
      </p>
    </div>
  );
}

function formatPlanDate(iso: string): string {
  return new Intl.DateTimeFormat("en-IN", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(iso));
}

const passwordSchema = z
  .object({
    currentPassword: z.string().min(1, "Enter your current password"),
    newPassword: passwordRule,
    confirmPassword: z.string(),
  })
  .refine((data) => data.newPassword === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

type PasswordFormInput = z.infer<typeof passwordSchema>;

// Client-validated only — there's no real auth backend to check the current
// password against, so this is an honest mock (like GoogleAuthButton),
// reusing the same 8-char/letter/number rule the register form enforces.
function SecurityCard() {
  const [saved, setSaved] = useState(false);
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<PasswordFormInput>({
    resolver: zodResolver(passwordSchema),
    defaultValues: { currentPassword: "", newPassword: "", confirmPassword: "" },
  });

  function onSubmit(e?: FormEvent<HTMLFormElement>) {
    e?.preventDefault();
    handleSubmit(() => {
      setSaved(true);
      reset();
    })(e);
  }

  return (
    <div className="rounded-lg border border-border bg-card p-5 sm:p-6">
      <h2 className="font-display text-base font-semibold text-foreground">
        Security
      </h2>
      <form onSubmit={onSubmit} className="mt-4 flex flex-col gap-4">
        <Field data-invalid={Boolean(errors.currentPassword)}>
          <FieldLabel htmlFor="currentPassword">Current password</FieldLabel>
          <Input
            id="currentPassword"
            type="password"
            className="h-10"
            {...register("currentPassword")}
          />
          <FieldError errors={[errors.currentPassword]} />
        </Field>

        <Field data-invalid={Boolean(errors.newPassword)}>
          <FieldLabel htmlFor="newPassword">New password</FieldLabel>
          <Input
            id="newPassword"
            type="password"
            className="h-10"
            {...register("newPassword")}
          />
          <FieldError errors={[errors.newPassword]} />
        </Field>

        <Field data-invalid={Boolean(errors.confirmPassword)}>
          <FieldLabel htmlFor="confirmNewPassword">
            Confirm new password
          </FieldLabel>
          <Input
            id="confirmNewPassword"
            type="password"
            className="h-10"
            {...register("confirmPassword")}
          />
          <FieldError errors={[errors.confirmPassword]} />
        </Field>

        <div className="flex items-center gap-3">
          <button
            type="submit"
            disabled={isSubmitting}
            className="inline-flex items-center justify-center gap-2 rounded-md bg-gradient-to-b from-gold-bright to-gold px-5 py-2.5 text-sm font-semibold text-[#171310] transition-transform hover:scale-[1.02] disabled:pointer-events-none disabled:opacity-40"
          >
            {isSubmitting && <Loader2 className="size-4 animate-spin" />}
            Update password
          </button>
          {saved && (
            <span className="flex items-center gap-1.5 text-sm text-gold-bright">
              <Check className="size-3.5" />
              Updated
            </span>
          )}
        </div>
      </form>
    </div>
  );
}
