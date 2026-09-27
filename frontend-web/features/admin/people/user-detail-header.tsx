"use client";

import { useCurrentUser } from "@/hooks/useCurrentUser";

import { useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Ban, UserCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AdminStatusBadge } from "@/features/admin/admin-status-badge";
import { ConfirmActionDialog } from "@/features/admin/confirm-action-dialog";
import { useSetUserStatusMutation } from "@/hooks/useAdminUsers";
import { useAdminAuditStore } from "@/store/useAdminAuditStore";
import type { AdminUser, UserStatus } from "@/types/admin";

function initials(name: string): string {
  return name
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("");
}

function formatDate(iso: string | null): string {
  if (!iso) return "Never";
  return new Date(iso).toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

export function UserDetailHeader({ user }: { user: AdminUser }) {
  const adminName = useCurrentUser().data?.name ?? "Admin";
  const queryClient = useQueryClient();
  const appendAudit = useAdminAuditStore((s) => s.append);
  const setStatusMutation = useSetUserStatusMutation();
  const [confirmOpen, setConfirmOpen] = useState(false);

  const isSuspended = user.status === "suspended" || user.status === "blocked";
  const nextStatus: UserStatus = isSuspended ? "active" : "suspended";

  async function handleToggle() {
    try {
      await setStatusMutation.mutateAsync({
        userId: user.id,
        status: nextStatus,
      });
      queryClient.setQueryData<AdminUser | undefined>(
        ["admin-user", user.id],
        (prev) => (prev ? { ...prev, status: nextStatus } : prev),
      );
      queryClient.setQueriesData<AdminUser[]>(
        { queryKey: ["admin-users"] },
        (prev) =>
          (prev ?? []).map((u) =>
            u.id === user.id ? { ...u, status: nextStatus } : u,
          ),
      );
      appendAudit({
        adminName: adminName,
        action: isSuspended ? "user.activated" : "user.suspended",
        entityType: "user",
        entityId: user.id,
        entityLabel: user.name,
      });
      setConfirmOpen(false);
      toast.success(isSuspended ? "Account reactivated" : "Account suspended", {
        description: isSuspended
          ? `${user.name} can sign in again.`
          : `${user.name} can no longer sign in.`,
      });
    } catch {
      toast.error("Could not change account status. Try again.");
    }
  }

  return (
    <>
      <section className="rounded-xl border border-border bg-card p-5">
        <div className="flex flex-wrap items-start gap-4">
          <span className="flex size-14 shrink-0 items-center justify-center rounded-full border border-gold/40 bg-gold/10 font-display text-lg font-semibold text-gold-bright">
            {initials(user.companyName ?? user.name)}
          </span>

          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <h1 className="font-display text-lg font-semibold text-foreground">
                {user.companyName ?? user.name}
              </h1>
              <AdminStatusBadge status={user.status} size="sm" />
            </div>
            <p className="mt-0.5 break-all text-sm text-muted-foreground">{user.email}</p>

            <dl className="mt-4 grid grid-cols-2 gap-x-4 gap-y-3 sm:grid-cols-4">
              <Detail label="Role" value={user.role} className="capitalize" />
              <Detail label="Phone" value={user.phone} />
              <Detail label="Joined" value={formatDate(user.createdAt)} />
              <Detail label="Last seen" value={formatDate(user.lastLoginAt)} />
            </dl>
          </div>

          <Button
            variant="outline"
            onClick={() => setConfirmOpen(true)}
            disabled={setStatusMutation.isPending}
            className="shrink-0"
          >
            {isSuspended ? (
              <UserCheck className="size-4" />
            ) : (
              <Ban className="size-4" />
            )}
            {isSuspended ? "Reactivate" : "Suspend"}
          </Button>
        </div>
      </section>

      <ConfirmActionDialog
        open={confirmOpen}
        onOpenChange={setConfirmOpen}
        title={
          isSuspended ? `Reactivate ${user.name}?` : `Suspend ${user.name}?`
        }
        description={
          isSuspended
            ? "They regain access immediately and can sign in as normal."
            : "They lose access immediately. Existing orders and settlements are unaffected."
        }
        confirmLabel={isSuspended ? "Reactivate" : "Suspend"}
        destructive={!isSuspended}
        isPending={setStatusMutation.isPending}
        onConfirm={handleToggle}
      />
    </>
  );
}

function Detail({
  label,
  value,
  className,
}: {
  label: string;
  value: string;
  className?: string;
}) {
  return (
    <div className="min-w-0">
      <dt className="text-xs text-muted-foreground">{label}</dt>
      <dd className={`truncate text-sm text-foreground ${className ?? ""}`}>
        {value}
      </dd>
    </div>
  );
}
