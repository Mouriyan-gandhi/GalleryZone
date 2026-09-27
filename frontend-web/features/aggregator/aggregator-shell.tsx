"use client";

import { UserAvatar } from "@/components/shared/user-avatar";

import { useCurrentUser } from "@/hooks/useCurrentUser";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { AggregatorMobileBottomNav } from "@/components/shared/aggregator-mobile-bottom-nav";
import { usePathname } from "next/navigation";
import {
  LayoutGrid,
  CircleUserRound,
  PackageSearch,
  GalleryVerticalEnd,
  ShoppingBag,
  Users,
  Building2,
  Truck,
  Wallet,
  Landmark,
  LineChart,
  MessageSquare,
  LifeBuoy,
  Settings as SettingsIcon,
  Menu,
  X,
  PanelLeftClose,
  PanelLeftOpen,
  LogOut,
  type LucideIcon,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { SidebarBrand } from "@/components/shared/sidebar-brand";
import { SwitchMode } from "@/components/switch-mode";
import { NotificationsPopover } from "@/components/notifications-popover";
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "@/components/ui/accordion";
import {
  Popover,
  PopoverTrigger,
  PopoverContent,
} from "@/components/ui/popover";
import { useAggregatorMessages } from "@/hooks/useAggregatorMessages";
import { authService } from "@/services/authService";

// Deliberately a parallel sibling to features/dashboard/dashboard-shell.tsx,
// not a shared/generalized abstraction over it — same reasoning as before:
// DashboardShell is hardcoded to artist nav items, AdminShell to admin nav
// items, this one to aggregator nav items. Grouped/collapsible nav is new
// here; if Admin or Artist want it too, extract then, against two real call
// sites instead of one.
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
      { label: "Dashboard", href: "/aggregator/dashboard", icon: LayoutGrid },
      {
        label: "My Profile",
        href: "/aggregator/profile",
        icon: CircleUserRound,
      },
      {
        label: "Browse GalleryZone",
        href: "/aggregator/inventory",
        icon: PackageSearch,
      },
      {
        label: "My Inventory",
        href: "/aggregator/collection",
        icon: GalleryVerticalEnd,
      },
    ],
  },
  {
    id: "operations",
    label: "Operations",
    items: [
      {
        label: "Orders & Sales",
        href: "/aggregator/orders",
        icon: ShoppingBag,
      },
      { label: "Customers", href: "/aggregator/customers", icon: Users },
      {
        label: "Display Spaces",
        href: "/aggregator/gallery-spaces",
        icon: Building2,
      },
      {
        label: "Shipping & Logistics",
        href: "/aggregator/shipping",
        icon: Truck,
      },
    ],
  },
  {
    id: "finance",
    label: "Finance",
    items: [
      { label: "Earnings & Wallet", href: "/aggregator/wallet", icon: Wallet },
      { label: "Settlements", href: "/aggregator/settlements", icon: Landmark },
    ],
  },
  {
    id: "growth",
    label: "Growth",
    items: [
      { label: "Analytics", href: "/aggregator/analytics", icon: LineChart },
      { label: "Messages", href: "/aggregator/messages", icon: MessageSquare },
    ],
  },
  {
    id: "support",
    label: "Support & Account",
    items: [
      { label: "Support", href: "/aggregator/support", icon: LifeBuoy },
      { label: "Settings", href: "/aggregator/settings", icon: SettingsIcon },
    ],
  },
];

const ALL_GROUP_IDS = NAV_GROUPS.map((g) => g.id);
const ALL_ITEMS = NAV_GROUPS.flatMap((g) => g.items);

export function AggregatorShell({ children }: { children: React.ReactNode }) {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <div className="flex min-h-[100dvh] bg-background">
      <Sidebar mobileOpen={mobileOpen} onClose={() => setMobileOpen(false)} />

      <div className="flex min-w-0 flex-1 flex-col">
        <Topbar onMenuClick={() => setMobileOpen(true)} />
        <main className="relative flex-1 overflow-hidden px-5 py-6 sm:px-8 sm:py-8 lg:px-10 pb-20 lg:pb-6">
          {children}
        </main>
      </div>

      {/* Mobile bottom navigation — only shown on small screens */}
      <AggregatorMobileBottomNav />
    </div>
  );
}

function isItemActive(pathname: string, href: string) {
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
  const { data: messages } = useAggregatorMessages();
  const unreadMessages =
    item.label === "Messages"
      ? (messages?.filter((m) => m.unread).length ?? 0)
      : 0;

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
      {unreadMessages > 0 && (
        <span
          className={cn(
            "flex size-4.5 shrink-0 items-center justify-center rounded-full bg-gold-bright text-[10px] font-semibold text-[#171310]",
            collapsed && "lg:hidden",
          )}
        >
          {unreadMessages}
        </span>
      )}
    </Link>
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
  const [collapsed, setCollapsed] = useState(false);
  // All 5 groups open by default. Base UI's <Accordion multiple> makes this
  // controllable via an array of open item values — every nav Link is
  // always reachable on first load, and a user who collapses a group stays
  // collapsed until they reopen it themselves (no auto-expand-on-navigate:
  // you can only land on a page whose group is collapsed by typing a URL or
  // using browser back/forward, since the link itself is hidden while
  // collapsed — a minor, acceptable edge case, not worth the extra state
  // sync this would take to close).
  const [openGroups, setOpenGroups] = useState<string[]>(ALL_GROUP_IDS);

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
        <div className="flex h-16 items-center justify-between px-5">
          <SidebarBrand collapsed={collapsed} />
          <button
            aria-label="Close menu"
            onClick={onClose}
            className="rounded-md p-1 text-sidebar-foreground/70 hover:text-sidebar-foreground lg:hidden"
          >
            <X className="size-5" />
          </button>
          <button
            aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
            onClick={() => setCollapsed((c) => !c)}
            className="hidden rounded-md p-1 text-sidebar-foreground/70 hover:text-sidebar-foreground lg:inline-flex"
          >
            {collapsed ? (
              <PanelLeftOpen className="size-4" />
            ) : (
              <PanelLeftClose className="size-4" />
            )}
          </button>
        </div>

        <span
          className={cn(
            "mx-5 mt-1 mb-3 text-[11px] font-medium tracking-[0.14em] text-muted-foreground uppercase",
            collapsed && "lg:hidden",
          )}
        >
          Aggregator Portal
        </span>

        <div className="min-h-0 flex-1 overflow-y-auto px-3 py-1">
          {collapsed ? (
            // Rail-collapsed: grouping is a full-width-sidebar concept only
            // (a group header with no room for its label is meaningless) —
            // render every item as one flat icon list instead.
            <nav className="flex flex-col gap-1">
              {ALL_ITEMS.map((item) => (
                <NavLink
                  key={item.href}
                  item={item}
                  collapsed={collapsed}
                  onClick={onClose}
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
                          onClick={onClose}
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

// Compact account menu for the desktop topbar — sits next to SwitchMode
// instead of the old full-width card pinned at the bottom of the sidebar.
function AccountMenu() {
  const { data: me } = useCurrentUser();
  const [open, setOpen] = useState(false);

  function handleSignOut() {
    void authService.logout();
    window.location.href = "/login";
  }

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger
        aria-label="Account menu"
        className="flex items-center gap-1.5 rounded-full p-1 text-sidebar-foreground/70 transition-colors hover:text-sidebar-foreground"
      >
        <UserAvatar name={me?.name} className="size-8" />
      </PopoverTrigger>
      <PopoverContent side="bottom" align="end" className="w-56 p-1.5">
        <div className="px-2.5 py-2">
          <p className="truncate text-sm font-medium text-foreground">
            {me?.name ?? "Aggregator"}
          </p>
          <p className="truncate text-xs text-muted-foreground">Aggregator</p>
        </div>
        <div className="my-1 border-t border-border" />
        <Link
          href="/aggregator/profile"
          onClick={() => setOpen(false)}
          className="flex items-center gap-2.5 rounded-md px-2.5 py-2 text-sm text-foreground/90 transition-colors hover:bg-muted"
        >
          <CircleUserRound
            className="size-4 text-muted-foreground"
            strokeWidth={1.75}
          />
          My Profile
        </Link>
        <Link
          href="/aggregator/settings"
          onClick={() => setOpen(false)}
          className="flex items-center gap-2.5 rounded-md px-2.5 py-2 text-sm text-foreground/90 transition-colors hover:bg-muted"
        >
          <SettingsIcon
            className="size-4 text-muted-foreground"
            strokeWidth={1.75}
          />
          Settings
        </Link>
        <div className="my-1 border-t border-border" />
        <button
          type="button"
          onClick={handleSignOut}
          className="flex w-full items-center gap-2.5 rounded-md px-2.5 py-2 text-left text-sm text-foreground/90 transition-colors hover:bg-muted"
        >
          <LogOut className="size-4 text-muted-foreground" strokeWidth={1.75} />
          Sign out
        </button>
      </PopoverContent>
    </Popover>
  );
}

const PAGE_TITLES: Record<string, string> = Object.fromEntries(
  ALL_ITEMS.map((item) => [item.href, item.label]),
);

function Topbar({ onMenuClick }: { onMenuClick: () => void }) {
  const { data: me } = useCurrentUser();
  const pathname = usePathname();
  const title = PAGE_TITLES[pathname] ?? "Aggregator Portal";

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-border bg-background/80 px-4 backdrop-blur-md sm:px-8 lg:px-10">
      {/* Mobile layout: hamburger + GZ logo centered + bell + avatar */}
      <div className="flex flex-1 items-center gap-3 lg:hidden">
        <button
          aria-label="Open menu"
          onClick={onMenuClick}
          className="rounded-md p-1.5 text-foreground/80 hover:text-foreground"
        >
          <Menu className="size-5" />
        </button>
        <div className="flex flex-1 flex-col">
          <span className="font-display text-xs font-bold uppercase tracking-widest text-gold-bright leading-none">GZ GalleryZone</span>
          <span className="text-[10px] text-muted-foreground leading-none mt-0.5">Aggregator Portal</span>
        </div>
        <NotificationsPopover groups={[]} />
        <Link href="/aggregator/profile" className="relative size-8 overflow-hidden rounded-full border border-gold/40 shrink-0">
          <UserAvatar name={me?.name} className="size-8" />
        </Link>
      </div>

      {/* Desktop layout: page title + controls */}
      <div className="hidden lg:flex lg:flex-1 lg:items-center lg:gap-3">
        <h1 className="font-display text-lg font-semibold text-foreground">
          {title}
        </h1>
      </div>
      <div className="hidden lg:flex lg:items-center lg:gap-2">
        <NotificationsPopover groups={[]} />
        <SwitchMode />
        <AccountMenu />
      </div>
    </header>
  );
}
