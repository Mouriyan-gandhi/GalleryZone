"use client";

import { use } from "react";
import { notFound } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { AdminPageHeader } from "@/features/admin/admin-page-header";
import { AdminStatusBadge } from "@/features/admin/admin-status-badge";
import {
  useAdminOrder,
  useAdminAddress,
  useAdminSettlementByOrder,
} from "@/hooks/useAdminCommerce";
import { useArtwork } from "@/hooks/useArtwork";
import { useCustomerProfile } from "@/hooks/useCustomerProfile";
import { formatINR } from "@/lib/utils";
import type { OrderStatus } from "@/types/order";

const STATUS_LABEL: Record<OrderStatus, string> = {
  pending: "Order placed",
  paid: "Payment received",
  confirmed: "Confirmed",
  packed: "Packed for dispatch",
  transit: "In transit",
  delivered: "Delivered",
  cancelled: "Cancelled",
};

export default function AdminOrderDetailPage(
  props: PageProps<"/admin/orders/[orderId]">,
) {
  const { orderId } = use(props.params);
  const { data: order, isLoading } = useAdminOrder(orderId);
  const { data: artwork } = useArtwork(order?.artworkId ?? "");
  const { data: address } = useAdminAddress(order?.addressId ?? "");
  const { data: settlement } = useAdminSettlementByOrder(orderId);
  const { data: buyer } = useCustomerProfile();

  if (isLoading) return null;
  if (!order) notFound();

  const total = order.amount + order.gstAmount + order.deliveryCharge;
  const history = [...order.statusHistory].sort(
    (a, b) => new Date(a.changedAt).getTime() - new Date(b.changedAt).getTime(),
  );

  return (
    <div className="space-y-6">
      <AdminPageHeader
        title={artwork?.title ?? "Order"}
        description={`Order ${order.id}`}
        backHref="/admin/orders"
        backLabel="Back to orders"
      />

      {/* grid-cols-1 below lg isn't decorative — see app/admin/page.tsx's
          identical comment: an implicit grid track sizes to its widest
          child's min-content instead of shrinking, overflowing the page. */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-[minmax(0,1.3fr)_minmax(0,1fr)] lg:items-start">
        <div className="space-y-4">
          <section className="rounded-xl border border-border bg-card p-5">
            <div className="flex items-start gap-4">
              <div className="relative size-20 shrink-0 overflow-hidden rounded-lg border border-border bg-muted">
                {artwork?.images[0] ? (
                  <Image
                    src={artwork.images[0].thumbnailUrl}
                    alt=""
                    fill
                    sizes="80px"
                    className="object-cover"
                  />
                ) : null}
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <h2 className="font-display text-base font-semibold text-foreground">
                    {artwork?.title ?? order.artworkId}
                  </h2>
                  <AdminStatusBadge status={order.status} size="sm" />
                </div>
                <p className="mt-0.5 text-sm text-muted-foreground">
                  {artwork?.artistName ?? "Unknown artist"}
                </p>
                {artwork ? (
                  <Link
                    href={`/admin/artworks/${artwork.id}`}
                    className="mt-2 inline-block text-sm text-gold-bright transition-colors hover:text-gold"
                  >
                    Open artwork record
                  </Link>
                ) : null}
              </div>
            </div>
          </section>

          <section className="rounded-xl border border-border bg-card">
            <div className="border-b border-border px-5 py-4">
              <h2 className="font-display text-base font-semibold text-foreground">
                Fulfilment
              </h2>
            </div>
            <ol className="px-5 py-4">
              {history.map((event, index) => {
                const isLast = index === history.length - 1;
                return (
                  <li
                    key={`${event.status}-${event.changedAt}`}
                    className="relative flex gap-4 pb-5 last:pb-0"
                  >
                    {!isLast ? (
                      <span
                        aria-hidden
                        className="absolute top-3 left-[5px] h-full w-px bg-border"
                      />
                    ) : null}
                    <span
                      aria-hidden
                      className={`relative mt-1.5 size-2.5 shrink-0 rounded-full ${
                        isLast ? "bg-gold-bright" : "bg-border"
                      }`}
                    />
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-foreground">
                        {STATUS_LABEL[event.status]}
                      </p>
                      <time
                        dateTime={event.changedAt}
                        className="text-xs text-muted-foreground"
                      >
                        {new Date(event.changedAt).toLocaleDateString("en-IN", {
                          day: "numeric",
                          month: "short",
                          year: "numeric",
                        })}
                      </time>
                    </div>
                  </li>
                );
              })}
            </ol>
          </section>
        </div>

        <div className="space-y-4">
          <section className="rounded-xl border border-border bg-card p-5">
            <h2 className="font-display text-base font-semibold text-foreground">
              Payment
            </h2>
            <dl className="mt-3 space-y-2 border-t border-border pt-3">
              <Line label="Artwork" value={formatINR(order.amount)} />
              <Line label="GST" value={formatINR(order.gstAmount)} />
              <Line label="Delivery" value={formatINR(order.deliveryCharge)} />
              <div className="flex items-baseline justify-between border-t border-border pt-2">
                <dt className="text-sm font-medium text-foreground">Total</dt>
                <dd className="font-display text-lg font-semibold tabular-nums text-foreground">
                  {formatINR(total)}
                </dd>
              </div>
            </dl>
          </section>

          <section className="rounded-xl border border-border bg-card p-5">
            <h2 className="font-display text-base font-semibold text-foreground">
              Buyer
            </h2>
            {buyer ? (
              <>
                <p className="mt-2 text-sm text-foreground">{buyer.name}</p>
                <p className="text-xs text-muted-foreground">{buyer.email}</p>
              </>
            ) : null}
            {address ? (
              <address className="mt-3 border-t border-border pt-3 text-sm leading-relaxed not-italic text-muted-foreground">
                {address.line1}
                {address.line2 ? <>, {address.line2}</> : null}
                <br />
                {address.city}, {address.state} {address.pincode}
              </address>
            ) : null}
          </section>

          <section className="rounded-xl border border-border bg-card p-5">
            <h2 className="font-display text-base font-semibold text-foreground">
              Settlement
            </h2>
            {settlement ? (
              <>
                <div className="mt-2 flex items-center justify-between gap-2">
                  <span className="text-sm text-muted-foreground">Status</span>
                  <AdminStatusBadge status={settlement.status} size="sm" />
                </div>
                <dl className="mt-3 space-y-2 border-t border-border pt-3">
                  <Line
                    label="Artist"
                    value={formatINR(settlement.artistAmount)}
                  />
                  <Line
                    label="Aggregator"
                    value={formatINR(settlement.aggregatorCommission)}
                  />
                  <Line
                    label="Platform"
                    value={formatINR(settlement.platformRevenue)}
                  />
                </dl>
              </>
            ) : (
              <p className="mt-2 text-sm text-muted-foreground">
                No settlement recorded for this order yet.
              </p>
            )}
          </section>
        </div>
      </div>
    </div>
  );
}

function Line({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-baseline justify-between">
      <dt className="text-sm text-muted-foreground">{label}</dt>
      <dd className="text-sm tabular-nums text-foreground">{value}</dd>
    </div>
  );
}
