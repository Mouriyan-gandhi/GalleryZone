"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { CheckCircle2, Clock3, Pencil, ShieldCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { http, isApiError } from "@/lib/api";
import { useCurrentUser } from "@/hooks/useCurrentUser";
import { RATE_GROUPS, formatRate, ungroupedKeys } from "./rate-field-groups";
import { RateEditor } from "./rate-editor";

// The platform's pricing rules (GST, markup, commissions, delivery, payout
// timing) live on the API as versioned "rate config". A version is
// proposed by one platform admin and must be approved by a DIFFERENT one
// before it takes effect — checkout refuses to run without an approved
// version, so this panel is the first thing a fresh deployment needs.

interface RateVersion {
  id: string;
  rates: Record<string, unknown>;
  effectiveFrom: string | null;
  proposedBy: string;
  proposedAt: string | null;
  approvedBy: string | null;
  approvedAt: string | null;
  approved: boolean;
  reason: string | null;
}

export function PricingRulesPanel() {
  const queryClient = useQueryClient();
  const { data: me } = useCurrentUser();
  const isPlatformAdmin = me?.roleGrants.includes("platform_admin") ?? false;
  const [editing, setEditing] = useState(false);

  const active = useQuery({
    queryKey: ["rate-config", "active"],
    queryFn: () => http.get<{ rates: Record<string, unknown> }>("/v1/admin/rate-config"),
    retry: false,
  });
  const versions = useQuery({
    queryKey: ["rate-config", "versions"],
    queryFn: () => http.get<{ versions: RateVersion[] }>("/v1/admin/rate-config/versions"),
  });
  const defaults = useQuery({
    queryKey: ["rate-config", "defaults"],
    queryFn: () => http.get<{ rates: Record<string, unknown> }>("/v1/admin/rate-config/defaults"),
  });

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ["rate-config"] });
  };

  const propose = useMutation({
    mutationFn: (input: { rates: Record<string, unknown>; reason: string }) =>
      http.post<{ versionId: string }>("/v1/admin/rate-config/propose", {
        rates: input.rates,
        effectiveFrom: new Date().toISOString(),
        reason: input.reason,
      }),
    onSuccess: () => {
      toast.success("Proposed — a second platform admin must approve it");
      setEditing(false);
      invalidate();
    },
    onError: (e) => toast.error(e instanceof Error ? e.message : "Could not propose"),
  });

  const approve = useMutation({
    mutationFn: (versionId: string) => http.post(`/v1/admin/rate-config/${encodeURIComponent(versionId)}/approve`),
    onSuccess: () => {
      toast.success("Approved — pricing rules are live");
      invalidate();
    },
    onError: (e) => toast.error(e instanceof Error ? e.message : "Could not approve"),
  });

  const noActive = active.isError && isApiError(active.error) && active.error.status >= 400;
  const pending = versions.data?.versions.filter((v) => !v.approved) ?? [];
  const rates = active.data?.rates;

  return (
    <section className="rounded-lg border border-border bg-card p-5 sm:p-6">
      <div className="flex flex-col gap-1 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h2 className="font-display text-base font-semibold text-foreground">Pricing rules</h2>
          <p className="mt-1 text-xs text-muted-foreground">
            GST, markup, commissions, delivery and payout timing. Proposed by one platform admin, approved by another.
          </p>
        </div>
        {rates ? (
          <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-600/30 bg-emerald-600/10 px-3 py-1 text-xs font-medium text-emerald-700">
            <ShieldCheck className="size-3.5" /> Active version in force
          </span>
        ) : noActive || (!active.isPending && !rates) ? (
          <span className="inline-flex items-center gap-1.5 rounded-full border border-destructive/30 bg-destructive/10 px-3 py-1 text-xs font-medium text-destructive">
            <Clock3 className="size-3.5" /> No approved version — checkout is blocked
          </span>
        ) : null}
      </div>

      {rates && !editing && (
        <div className="mt-5 flex flex-col gap-5">
          {RATE_GROUPS.map((group) => (
            <div key={group.title}>
              <p className="text-xs font-semibold tracking-wide text-foreground uppercase">{group.title}</p>
              <dl className="mt-2 grid grid-cols-1 gap-x-6 gap-y-1 sm:grid-cols-2 lg:grid-cols-3">
                {group.fields.map((field) => (
                  <div key={field.key} className="flex items-baseline justify-between gap-3 border-b border-border/60 py-1.5 text-sm">
                    <dt className="text-muted-foreground" title={field.hint}>{field.label}</dt>
                    <dd className="font-mono text-foreground tabular-nums">{formatRate(field.key, rates[field.key])}</dd>
                  </div>
                ))}
              </dl>
            </div>
          ))}
          {ungroupedKeys(rates).length > 0 && (
            <div>
              <p className="text-xs font-semibold tracking-wide text-foreground uppercase">Other</p>
              <dl className="mt-2 grid grid-cols-1 gap-x-6 gap-y-1 sm:grid-cols-2 lg:grid-cols-3">
                {ungroupedKeys(rates).map((key) => (
                  <div key={key} className="flex items-baseline justify-between gap-3 border-b border-border/60 py-1.5 text-sm">
                    <dt className="text-muted-foreground">{key}</dt>
                    <dd className="font-mono text-foreground tabular-nums">{formatRate(key, rates[key])}</dd>
                  </div>
                ))}
              </dl>
            </div>
          )}
        </div>
      )}

      {pending.length > 0 && (
        <div className="mt-5 flex flex-col gap-2">
          <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">Awaiting approval</p>
          {pending.map((v) => {
            const mine = v.proposedBy === me?.uid;
            return (
              <div key={v.id} className="flex flex-col gap-2 rounded-md border border-border p-3 sm:flex-row sm:items-center sm:justify-between">
                <div className="min-w-0">
                  <p className="truncate text-sm text-foreground">{v.reason ?? "Rate change"}</p>
                  <p className="text-xs text-muted-foreground">
                    Proposed {v.proposedAt ? new Date(v.proposedAt).toLocaleString("en-IN") : ""}
                    {mine ? " · by you — someone else must approve" : ""}
                  </p>
                </div>
                <Button size="sm" disabled={!isPlatformAdmin || mine || approve.isPending} onClick={() => approve.mutate(v.id)}>
                  <CheckCircle2 className="size-4" /> Approve
                </Button>
              </div>
            );
          })}
        </div>
      )}

      {editing ? (
        <RateEditor
          initial={(rates ?? defaults.data?.rates ?? {}) as Record<string, unknown>}
          onCancel={() => setEditing(false)}
          submitting={propose.isPending}
          onSubmit={(nextRates, reason) => propose.mutate({ rates: nextRates, reason })}
        />
      ) : (
        <div className="mt-5 flex flex-wrap items-center gap-3 border-t border-border pt-4">
          <Button
            variant="outline"
            disabled={!isPlatformAdmin || (!rates && !defaults.data)}
            onClick={() => setEditing(true)}
          >
            <Pencil className="size-4" /> {rates ? "Propose a change" : "Set up pricing rules"}
          </Button>
          {!rates && defaults.data && (
            <p className="text-xs text-muted-foreground">
              Nothing is in force yet — the form opens pre-filled with the standard rules.
            </p>
          )}
        </div>
      )}

      {!isPlatformAdmin && (
        <p className="mt-2 text-xs text-muted-foreground">Only accounts with the platform_admin grant can propose or approve.</p>
      )}
    </section>
  );
}
