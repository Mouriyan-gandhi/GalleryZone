"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutGrid,
  Compass,
  Heart,
  Frame,
  ShoppingBag,
  Wallet,
  Repeat2,
  CircleUserRound,
  MapPin,
  LifeBuoy,
  Menu,
  X,
  type LucideIcon,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { SidebarHeader } from "@/components/shared/sidebar-brand";
import { SwitchMode } from "@/components/switch-mode";
import { NotificationsPopover } from "@/components/notifications-popover";
import { AccountMenu } from "@/components/shared/account-menu";
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "@/components/ui/accordion";

// A third independent copy-and-adapt of the DashboardShell/AggregatorShell
// structural pattern (same reasoning as AggregatorShell's own header
// comment: unrelated, fixed nav structures don't warrant a shared RoleShell
// abstraction). Grouped/collapsible nav mirrors AggregatorShell's — Collector
// nav grew from 4 flat items to 9 across 6 sections, past the point a flat
// list stays scannable.
interface NavItem {
  label: string;
  href: string;
  icon: LucideIcon;
}

interface NavGroup {
  id: string;
  label: string;
  items: NavItem[];
}

const NAV_GROUPS: NavGroup[] = [
  {
    id: "main",
    label: "Main",
    items: [
      { label: "Dashboard", href: "/account", icon: LayoutGrid },
      { label: "Discover", href: "/marketplace", icon: Compass },
      { label: "Wishlist", href: "/wishlist", icon: Heart },
    ],
  },
  {
    id: "collection",
    label: "My Collection",
    items: [
      { label: "My Collection", href: "/account/collection", icon: Frame },
    ],
  },
  {
    id: "purchases",
    label: "Purchases",
    items: [{ label: "Orders", href: "/account/orders", icon: ShoppingBag }],
  },
  {
    id: "finance",
    label: "Finance",
    items: [{ label: "Wallet", href: "/account/wallet", icon: Wallet }],
  },
  {
    id: "resale",
    label: "Resale",
    items: [
      { label: "Resell Artwork", href: "/account/resale", icon: Repeat2 },
    ],
  },
  {
    id: "account",
    label: "Account",
    items: [
      { label: "Profile", href: "/account/settings", icon: CircleUserRound },
      { label: "Addresses", href: "/account/addresses", icon: MapPin },
      { label: "Support", href: "/account/support", icon: LifeBuoy },
    ],
  },
];

const ALL_GROUP_IDS = NAV_GROUPS.map((g) => g.id);
const ALL_ITEMS = NAV_GROUPS.flatMap((g) => g.items);

// Mobile navigation for /account is the root-level MobileBottomNav
// (components/shared/mobile-bottom-nav.tsx) — one bar, everywhere, rather
// than a second account-only bottom nav that only matched this section and
// had to be carefully hidden from/shown to avoid stacking with the global
// one. Root layout's `pb-16` already reserves room for it.
export function AccountShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-[100dvh] bg-background">
      <Sidebar />

      <div className="flex min-w-0 flex-1 flex-col">
        <Topbar />
        <main className="relative flex-1 overflow-x-hidden px-4 py-5 sm:px-8 sm:py-8 lg:px-10">
          {children}
        </main>
      </div>
    </div>
  );
}

function isItemActive(pathname: string, href: string) {
  if (href === "/account") return pathname === "/account";
  return pathname.startsWith(href);
}

function NavLink({
  item,
  collapsed,
  onClick,
  active,
}: {
  item: NavItem;
  collapsed: boolean;
  onClick: () => void;
  active: boolean;
}) {
  return (
    <Link
      href={item.href}
      onClick={onClick}
      title={collapsed ? item.label : undefined}
      className={cn(
        "flex items-center gap-3 rounded-md px-3 py-2.5 text-sm transition-colors",
        collapsed && "lg:justify-center lg:px-2",
        active
          ? "bg-sidebar-accent text-sidebar-accent-foreground"
          : "text-sidebar-foreground/70 hover:bg-sidebar-accent/60 hover:text-sidebar-foreground",
      )}
    >
      <item.icon
        className={cn("size-4 shrink-0", active && "text-gold-bright")}
        strokeWidth={1.75}
      />
      <span className={cn("flex-1 truncate", collapsed && "lg:hidden")}>
        {item.label}
      </span>
    </Link>
  );
}

function Sidebar() {
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);
  // All groups open by default — see AggregatorShell's identical note on
  // why a collapsed group doesn't auto-reopen when you land on its page.
  const [openGroups, setOpenGroups] = useState<string[]>(ALL_GROUP_IDS);

  return (
    <>
      <aside
        className={cn(
          "hidden inset-y-0 left-0 z-50 lg:flex w-64 shrink-0 flex-col border-r border-sidebar-border bg-sidebar transition-[width] lg:sticky lg:top-0 lg:h-[100dvh]",
          collapsed ? "lg:w-20" : "lg:w-64",
        )}
      >
        <SidebarHeader
          collapsed={collapsed}
          onToggle={() => setCollapsed((c) => !c)}
        />

        <span
          className={cn(
            "mx-5 mt-1 mb-3 text-[11px] font-medium tracking-[0.14em] text-muted-foreground uppercase",
            collapsed && "lg:hidden",
          )}
        >
          Collector Portal
        </span>

        <div className="min-h-0 flex-1 overflow-y-auto px-3 py-1">
          {collapsed ? (
            <nav className="flex flex-col gap-1">
              {ALL_ITEMS.map((item) => (
                <NavLink
                  key={item.href}
                  item={item}
                  collapsed={collapsed}
                  onClick={() => {}}
                  active={isItemActive(pathname, item.href)}
                />
              ))}
            </nav>
          ) : (
            <Accordion
              multiple
              value={openGroups}
              onValueChange={(value) => setOpenGroups(value as string[])}
            >
              {NAV_GROUPS.map((group) => (
                <AccordionItem
                  key={group.id}
                  value={group.id}
                  className="border-b-0"
                >
                  <AccordionTrigger className="rounded-md px-2 py-2 text-[11px] font-medium tracking-[0.12em] text-muted-foreground uppercase no-underline hover:bg-sidebar-accent/40 hover:text-muted-foreground hover:no-underline **:data-[slot=accordion-trigger-icon]:size-3.5">
                    {group.label}
                  </AccordionTrigger>
                  <AccordionContent className="pb-1">
                    <nav className="flex flex-col gap-1 pt-1">
                      {group.items.map((item) => (
                        <NavLink
                          key={item.href}
                          item={item}
                          collapsed={collapsed}
                          onClick={() => {}}
                          active={isItemActive(pathname, item.href)}
                        />
                      ))}
                    </nav>
                  </AccordionContent>
                </AccordionItem>
              ))}
            </Accordion>
          )}
        </div>
      </aside>
    </>
  );
}

const PAGE_TITLES: Record<string, string> = Object.fromEntries(
  ALL_ITEMS.filter((item) => item.href.startsWith("/account")).map((item) => [
    item.href,
    item.label,
  ]),
);
PAGE_TITLES["/account"] = "Dashboard";

function Topbar() {
  const pathname = usePathname();
  const title =
    PAGE_TITLES[pathname] ??
    (pathname.startsWith("/account/orders/")
      ? "Order details"
      : "Collector Portal");

  return (
    <header className="sticky top-0 z-30 flex h-14 sm:h-16 items-center justify-between border-b border-border bg-background/90 px-4 sm:px-8 lg:px-10 backdrop-blur-md">
      <div className="flex items-center gap-3">
        {/* Mobile Logo replacing hamburger */}
        <Link href="/account" className="flex items-center lg:hidden">
          <span className="font-display text-xl font-bold tracking-tight text-foreground">
            Gallery<span className="text-gold-bright">Zone</span>
          </span>
        </Link>
        <h1 className="hidden lg:block font-display text-lg font-semibold text-foreground">
          {title}
        </h1>
      </div>
      <div className="flex items-center gap-2">
        <NotificationsPopover />
        <SwitchMode />
        <AccountMenu role="Collector" profileHref="/account/settings" />
      </div>
    </header>
  );
}
