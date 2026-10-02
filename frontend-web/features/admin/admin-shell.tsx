"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutGrid,
  ChartNoAxesCombined,
  Images,
  IdCard,
  FileCheck2,
  Banknote,
  UserMinus,
  ReceiptText,
  Frame,
  Tags,
  Palette,
  Building2,
  Users,
  Receipt,
  Scale,
  ScrollText,
  FileChartColumn,
  SlidersHorizontal,
  Menu,
  X,
  ChevronDown,
} from "lucide-react";
import { SidebarHeader } from "@/components/shared/sidebar-brand";
import { cn } from "@/lib/utils";
import { SwitchMode } from "@/components/switch-mode";
import { NotificationsPopover } from "@/components/notifications-popover";
import { AccountMenu } from "@/components/shared/account-menu";
import { useAdminKpis } from "@/hooks/useAdminDashboard";

// The fourth independent copy-and-adapt of the shell pattern established by
// features/dashboard/dashboard-shell.tsx and repeated by AggregatorShell and
// AccountShell (see AggregatorShell's header comment for why these are four
// parallel siblings rather than one generalized RoleShell: four fixed,
// unrelated nav structures don't warrant the abstraction, and generalizing
// would risk regressing three already-shipped portals).
//
// Two things are genuinely different here, both because admin has 15 sections
// where the other portals have three or four:
//   1. Nav is GROUPED under section headings instead of being a flat list,
//      and each group can be individually expanded/collapsed.
//   2. The three Moderation items carry live pending-count badges from
//      ["admin-kpis"], so waiting work stays visible from anywhere in the
//      console. Every moderation mutation invalidates that key (see
//      hooks/useAdminModeration.ts), so the badges stay truthful after you act.
//
// The sidebar also supports a desktop icon-only rail mode (collapsed) shared
// in spirit across all four shells - each shell keeps its own local
// `collapsed` state rather than lifting it into a shared component, same
// reasoning as the rest of this file being a deliberate standalone copy.

type BadgeKey = "artworks" | "kyc" | "gst" | "withdrawals";

interface AdminNavItem {
  label: string;
  href: string;
  icon: typeof LayoutGrid;
  badge?: BadgeKey;
}

interface AdminNavGroup {
  // The first group is deliberately unheaded: Overview and Analytics are the
  // console's two "whole platform" views, not a category of anything.
  heading: string | null;
  items: AdminNavItem[];
}

const NAV_GROUPS: AdminNavGroup[] = [
  {
    heading: null,
    items: [
      { label: "Overview", href: "/admin", icon: LayoutGrid },
      {
        label: "Analytics",
        href: "/admin/analytics",
        icon: ChartNoAxesCombined,
      },
    ],
  },
  {
    heading: "Moderation",
    items: [
      {
        label: "Artwork Queue",
        href: "/admin/moderation/artworks",
        icon: Images,
        badge: "artworks",
      },
      {
        label: "KYC",
        href: "/admin/moderation/kyc",
        icon: IdCard,
        badge: "kyc",
      },
      {
        label: "GST",
        href: "/admin/moderation/gst",
        icon: FileCheck2,
        badge: "gst",
      },
      {
        label: "Withdrawals",
        href: "/admin/moderation/withdrawals",
        icon: Banknote,
        badge: "withdrawals",
      },
      // No badge: the pending count comes from adminService's KPI set, which
      // does not carry deactivations. Adding one there is a change to the
      // dashboard's numbers, not to this nav.
      {
        label: "Off-platform fees",
        href: "/admin/moderation/external-fees",
        icon: ReceiptText,
      },
      {
        label: "Deactivations",
        href: "/admin/moderation/deactivations",
        icon: UserMinus,
      },
    ],
  },
  {
    heading: "Catalog",
    items: [
      { label: "Artworks", href: "/admin/artworks", icon: Frame },
      { label: "Categories", href: "/admin/categories", icon: Tags },
    ],
  },
  {
    heading: "People",
    items: [
      { label: "Artists", href: "/admin/artists", icon: Palette },
      { label: "Aggregators", href: "/admin/aggregators", icon: Building2 },
      { label: "Customers", href: "/admin/customers", icon: Users },
    ],
  },
  {
    heading: "Commerce",
    items: [
      { label: "Orders", href: "/admin/orders", icon: Receipt },
      { label: "Settlements", href: "/admin/settlements", icon: Scale },
    ],
  },
  {
    heading: "System",
    items: [
      { label: "Audit Logs", href: "/admin/audit-logs", icon: ScrollText },
      { label: "Reports", href: "/admin/reports", icon: FileChartColumn },
      { label: "Settings", href: "/admin/settings", icon: SlidersHorizontal },
    ],
  },
];

const NAV_ITEMS = NAV_GROUPS.flatMap((group) => group.items);

// "/admin" is a prefix of every other admin route, so it only counts as active
// on an exact match; everything else matches by prefix so detail routes
// (/admin/artists/[artistId]) keep their parent section highlighted.
function isActive(pathname: string, href: string) {
  if (href === "/admin") return pathname === "/admin";
  return pathname === href || pathname.startsWith(`${href}/`);
}

export function AdminShell({ children }: { children: React.ReactNode }) {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <div className="flex min-h-[100dvh] bg-background">
      <Sidebar mobileOpen={mobileOpen} onClose={() => setMobileOpen(false)} />

      <div className="flex min-w-0 flex-1 flex-col">
        <Topbar onMenuClick={() => setMobileOpen(true)} />
        <main className="flex-1 px-5 py-6 sm:px-8 sm:py-8 lg:px-10">
          {children}
        </main>
      </div>
    </div>
  );
}

function Sidebar({
  mobileOpen,
  onClose,
}: {
  mobileOpen: boolean;
  onClose: () => void;
}) {
  const pathname = usePathname();
  const { data: kpis } = useAdminKpis();
  const [collapsed, setCollapsed] = useState(false);
  const [closedGroups, setClosedGroups] = useState<Set<string>>(new Set());

  function toggleGroup(heading: string) {
    setClosedGroups((prev) => {
      const next = new Set(prev);
      if (next.has(heading)) next.delete(heading);
      else next.add(heading);
      return next;
    });
  }

  const badgeCounts: Record<BadgeKey, number | undefined> = {
    artworks: kpis?.pendingArtworkApprovals,
    kyc: kpis?.pendingKyc,
    gst: kpis?.pendingGst,
    withdrawals: kpis?.pendingWithdrawals,
  };

  return (
    <>
      {mobileOpen && (
        <button
          aria-label="Close menu"
          onClick={onClose}
          className="fixed inset-0 z-40 bg-background backdrop-blur-sm lg:hidden"
        />
      )}

      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 flex w-64 shrink-0 flex-col border-r border-sidebar-border bg-sidebar transition-[transform,width] lg:sticky lg:top-0 lg:h-[100dvh] lg:translate-x-0",
          mobileOpen ? "translate-x-0" : "-translate-x-full",
          collapsed ? "lg:w-20" : "lg:w-64",
        )}
      >
        <SidebarHeader
          collapsed={collapsed}
          onToggle={() => setCollapsed((c) => !c)}
        >
          <button
            aria-label="Close menu"
            onClick={onClose}
            className="rounded-md p-1 text-sidebar-foreground/70 hover:text-sidebar-foreground lg:hidden"
          >
            <X className="size-5" />
          </button>
        </SidebarHeader>

        <span
          className={cn(
            "mx-5 mt-1 mb-2 shrink-0 text-[11px] font-medium tracking-[0.14em] text-muted-foreground uppercase",
            collapsed && "lg:hidden",
          )}
        >
          Admin Console
        </span>

        {/* 15 sections don't fit a 100dvh sidebar on a laptop, so the nav
            scrolls independently while the brand header stays pinned. */}
        <nav className="flex min-h-0 flex-1 flex-col gap-0.5 overflow-y-auto px-3 pt-2 pb-4">
          {NAV_GROUPS.map((group, groupIndex) => {
            const heading = group.heading;
            const groupOpen =
              collapsed || !heading || !closedGroups.has(heading);

            return (
              <div key={heading ?? "primary"} className="flex flex-col gap-0.5">
                {heading && (
                  <button
                    type="button"
                    onClick={() => toggleGroup(heading)}
                    className={cn(
                      "flex items-center justify-between px-3 pb-1 text-[10px] font-medium tracking-[0.16em] text-muted-foreground/80 uppercase transition-colors hover:text-sidebar-foreground",
                      groupIndex === 0 ? "pt-1" : "pt-4",
                      collapsed && "lg:hidden",
                    )}
                  >
                    {heading}
                    <ChevronDown
                      className={cn(
                        "size-3.5 transition-transform",
                        groupOpen && "rotate-180",
                      )}
                    />
                  </button>
                )}

                {groupOpen && (
                  <div
                    className={cn(
                      "flex flex-col gap-0.5",
                      heading &&
                        "ml-[13px] border-l border-sidebar-border pl-2.5",
                      heading && collapsed && "lg:m-0 lg:border-0 lg:pl-0",
                    )}
                  >
                    {group.items.map((item) => {
                      const active = isActive(pathname, item.href);
                      const count = item.badge
                        ? badgeCounts[item.badge]
                        : undefined;
                      const hasCount = count !== undefined && count > 0;

                      return (
                        <Link
                          key={item.href}
                          href={item.href}
                          onClick={onClose}
                          aria-current={active ? "page" : undefined}
                          title={collapsed ? item.label : undefined}
                          className={cn(
                            "relative flex items-center gap-3 rounded-md px-3 py-2 text-[13px] transition-colors",
                            collapsed && "lg:justify-center lg:px-2",
                            active
                              ? "bg-sidebar-accent text-sidebar-accent-foreground"
                              : "text-sidebar-foreground/70 hover:bg-sidebar-accent/60 hover:text-sidebar-foreground",
                          )}
                        >
                          <item.icon
                            className={cn(
                              "size-4 shrink-0",
                              active && "text-gold-bright",
                            )}
                            strokeWidth={1.75}
                          />
                          <span
                            className={cn(
                              "min-w-0 flex-1 truncate",
                              collapsed && "lg:hidden",
                            )}
                          >
                            {item.label}
                          </span>
                          {hasCount && (
                            <>
                              <span
                                aria-label={`${count} waiting`}
                                className={cn(
                                  "inline-flex h-5 min-w-5 shrink-0 items-center justify-center rounded-full border border-gold/35 bg-gold/10 px-1.5 text-[11px] font-medium text-gold-bright tabular-nums",
                                  collapsed && "lg:hidden",
                                )}
                              >
                                {count}
                              </span>
                              {collapsed && (
                                <span className="absolute top-1.5 right-1.5 hidden size-2 rounded-full bg-gold-bright lg:block" />
                              )}
                            </>
                          )}
                        </Link>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })}
        </nav>
      </aside>
    </>
  );
}

// Derived from NAV_ITEMS rather than a hand-maintained PAGE_TITLES map (the
// other shells' approach) because admin has detail routes under most sections
// -- longest matching prefix keeps /admin/artists/[artistId] titled "Artists"
// instead of falling through to the generic label.
function pageTitle(pathname: string) {
  const match = NAV_ITEMS.filter((item) => isActive(pathname, item.href)).sort(
    (a, b) => b.href.length - a.href.length,
  )[0];
  return match?.label ?? "Admin Console";
}

function Topbar({ onMenuClick }: { onMenuClick: () => void }) {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-border bg-background/80 px-5 backdrop-blur-md sm:px-8 lg:px-10">
      <div className="flex items-center gap-3">
        <button
          aria-label="Open menu"
          onClick={onMenuClick}
          className="rounded-md p-1.5 text-foreground/80 hover:text-foreground lg:hidden"
        >
          <Menu className="size-5" />
        </button>
        <h1 className="font-display text-lg font-semibold text-foreground">
          {pageTitle(pathname)}
        </h1>
      </div>
      <div className="flex items-center gap-2">
        <NotificationsPopover />
        <SwitchMode />
        <AccountMenu role="Admin" />
      </div>
    </header>
  );
}
