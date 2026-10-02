"use client";

import { Lock, ShoppingBag } from "lucide-react";
import {
  AdminDataTable,
  type AdminDataTableColumn,
} from "@/features/admin/admin-data-table";
import {
  AdminStatusBadge,
  adminStatusLabel,
} from "@/features/admin/admin-status-badge";
import { useAdminOrders } from "@/hooks/useAdminCommerce";
import { formatINR } from "@/lib/utils";
import type { Order, OrderStatus } from "@/types/order";

const STATUSES: OrderStatus[] = [
  "pending",
  "paid",
  "confirmed",
  "packed",
  "transit",
  "delivered",
  "cancelled",
];

// A paid order that hasn't shipped yet, whose piece's tag isn't locked and hasn't been waved through.
function blockedByNfc(order: Order): boolean {
  const open = order.status === "paid" || order.status === "confirmed" || order.status === "packed";
  return open && order.nfc !== undefined && !order.nfc.locked && !order.nfc.gateOverridden;
}

function orderTotal(order: Order): number {
  return order.amount + order.gstAmount + order.deliveryCharge;
}

export function OrderAdminTable() {
  const { data: orders, isPending } = useAdminOrders();

  const columns: AdminDataTableColumn<Order>[] = [
    {
      key: "artwork",
      header: "Artwork",
      render: (row) => {
        const artwork = row.artwork;
        return (
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-foreground">
              {artwork?.title ?? row.artworkId}
            </p>
            <p className="truncate text-xs text-muted-foreground">
              {artwork?.artistName ?? "Unknown artist"}
            </p>
          </div>
        );
      },
      sortable: true,
      sortValue: (row) => row.artwork?.title ?? row.artworkId,
    },
    {
      key: "status",
      header: "Status",
      render: (row) => (
        <div className="flex flex-wrap items-center gap-1.5">
          <AdminStatusBadge status={row.status} size="sm" />
          {blockedByNfc(row) && (
            <span
              title="The tag isn't locked, so this can't be dispatched once the NFC gate is enforced"
              className="inline-flex items-center gap-1 rounded-full border border-red-500/40 bg-red-500/10 px-2 py-0.5 text-[11px] font-medium whitespace-nowrap text-red-300"
            >
              <Lock className="size-3" strokeWidth={2} />
              Unlocked
            </span>
          )}
        </div>
      ),
      sortable: true,
      sortValue: (row) => row.status,
    },
    {
      key: "total",
      header: "Total",
      render: (row) => (
        <span className="text-sm font-medium tabular-nums text-foreground">
          {formatINR(orderTotal(row))}
        </span>
      ),
      sortable: true,
      sortValue: (row) => orderTotal(row),
    },
    {
      key: "placed",
      header: "Placed",
      render: (row) => (
        <span className="text-sm text-muted-foreground">
          {new Date(row.createdAt).toLocaleDateString("en-IN", {
            day: "numeric",
            month: "short",
            year: "numeric",
          })}
        </span>
      ),
      sortable: true,
      sortValue: (row) => -new Date(row.createdAt).getTime(),
    },
  ];

  return (
    <AdminDataTable
      rows={orders ?? []}
      columns={columns}
      isLoading={isPending}
      getRowKey={(row) => row.id}
      getRowHref={(row) => `/admin/orders/${row.id}`}
      getRowLabel={(row) => `Open order ${row.id}`}
      searchPlaceholder="Search by artwork or order id"
      searchValue={(row) =>
        `${row.id} ${row.artwork?.title ?? ""}`
      }
      filters={[
        {
          key: "status",
          label: "Status",
          options: STATUSES.map((s) => ({
            value: s,
            label: adminStatusLabel(s),
          })),
          matches: (row, value) => row.status === value,
        },
      ]}
      emptyTitle="No orders"
      emptyDescription="Nothing matches the current filters."
      emptyIcon={ShoppingBag}
    />
  );
}
