"use client";

import { use } from "react";
import { notFound } from "next/navigation";
import Link from "next/link";
import { AdminPageHeader } from "@/features/admin/admin-page-header";
import { UserDetailHeader } from "@/features/admin/people/user-detail-header";
import { AdminStatusBadge } from "@/features/admin/admin-status-badge";
import { useAdminCustomerPortfolio } from "@/hooks/useAdminUsers";
import { useArtwork } from "@/hooks/useArtwork";
import { formatINR } from "@/lib/utils";
import type { Order } from "@/types/order";

export default function AdminCustomerDetailPage(
  props: PageProps<"/admin/customers/[customerId]">,
) {
  const { customerId } = use(props.params);
  const { data, isLoading } = useAdminCustomerPortfolio(customerId);

  if (isLoading) return null;
  if (!data) notFound();

  const { user, orders, addresses } = data;
  const lifetimeValue = orders
    .filter((o) => o.status !== "cancelled")
    .reduce((sum, o) => sum + o.amount + o.gstAmount + o.deliveryCharge, 0);

  return (
    <div className="space-y-6">
      <AdminPageHeader
        title={user.name}
        description="Customer record and order history."
        backHref="/admin/customers"
        backLabel="Back to customers"
      />

      <UserDetailHeader user={user} />

      {/* grid-cols-1 below sm isn't decorative — see app/admin/page.tsx's
          identical comment: an implicit grid track sizes to its widest
          child's min-content instead of shrinking, overflowing the page. */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        <Stat label="Orders" value={String(orders.length)} />
        <Stat label="Lifetime value" value={formatINR(lifetimeValue)} />
        <Stat label="Saved addresses" value={String(addresses.length)} />
      </div>

      <section className="rounded-xl border border-border bg-card">
        <div className="border-b border-border px-5 py-4">
          <h2 className="font-display text-base font-semibold text-foreground">
            Order history
          </h2>
        </div>

        {orders.length === 0 ? (
          <p className="px-5 py-8 text-center text-sm text-muted-foreground">
            No orders yet.
          </p>
        ) : (
          <ul className="divide-y divide-border">
            {orders.map((order) => (
              <OrderRow key={order.id} order={order} />
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}

function OrderRow({ order }: { order: Order }) {
  const { data: artwork } = useArtwork(order.artworkId);
  const total = order.amount + order.gstAmount + order.deliveryCharge;
  return (
    <li>
      <Link
        href={`/admin/orders/${order.id}`}
        className="flex flex-wrap items-center gap-3 px-5 py-3.5 transition-colors hover:bg-accent/40"
      >
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-medium text-foreground">
            {artwork?.title ?? order.artworkId}
          </p>
          <p className="text-xs text-muted-foreground">
            {new Date(order.createdAt).toLocaleDateString("en-IN", {
              day: "numeric",
              month: "short",
              year: "numeric",
            })}
          </p>
        </div>
        <AdminStatusBadge status={order.status} size="sm" />
        <span className="shrink-0 text-sm tabular-nums text-foreground">
          {formatINR(total)}
        </span>
      </Link>
    </li>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <p className="text-xs font-medium tracking-[0.08em] text-muted-foreground uppercase">
        {label}
      </p>
      <p className="mt-2 font-display text-xl font-semibold tabular-nums text-foreground">
        {value}
      </p>
    </div>
  );
}
