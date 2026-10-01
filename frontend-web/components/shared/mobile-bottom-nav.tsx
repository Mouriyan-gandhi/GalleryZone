"use client";

import { useCurrentUser } from "@/hooks/useCurrentUser";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useSyncExternalStore, useEffect, useState } from "react";
import {
  Home,
  Compass,
  PlusSquare,
  Heart,
  User,
  Frame,
  ShoppingBag,
  Wallet,
  Repeat2,
  CircleUserRound,
  MapPin,
  LifeBuoy,
  Menu,
  type LucideIcon,
} from "lucide-react";
import { cn } from "@/lib/utils";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
  SheetClose,
} from "@/components/ui/sheet";
import { useCustomerProfile } from "@/hooks/useCustomerProfile";
import { initials } from "@/features/account/account-data";
import { readSessionRole, subscribeToSession } from "@/lib/session";
import { useMounted } from "@/hooks/useMounted";

interface NavItem {
  href: string;
  label: string;
  icon: LucideIcon;
  /** Only this exact path counts as active — otherwise every nested route
   * under it (e.g. /account/collection under /account) would also light up
   * the item that merely happens to share its prefix. */
  exact?: boolean;
}

const GUEST_NAV: NavItem[] = [
  { href: "/", label: "Home", icon: Home, exact: true },
  { href: "/marketplace", label: "Explore", icon: Compass },
  { href: "/wishlist", label: "Wishlist", icon: Heart },
  { href: "/login", label: "Sign In", icon: User },
];

// "Sell" opens the artist's own upload flow — a customer or aggregator
// tapping it would just get bounced back by the route guard, so it's
// artist-only.
const ARTIST_NAV: NavItem[] = [
  { href: "/", label: "Home", icon: Home, exact: true },
  { href: "/marketplace", label: "Explore", icon: Compass },
  { href: "/dashboard/artworks/upload", label: "Sell", icon: PlusSquare },
  { href: "/wishlist", label: "Wishlist", icon: Heart },
  { href: "/dashboard", label: "Dashboard", icon: User },
];

const AGGREGATOR_NAV: NavItem[] = [
  { href: "/", label: "Home", icon: Home, exact: true },
  { href: "/marketplace", label: "Explore", icon: Compass },
  { href: "/wishlist", label: "Wishlist", icon: Heart },
  { href: "/aggregator/dashboard", label: "Dashboard", icon: User },
];

// One flow for the collector, everywhere — browsing the public marketplace
// or inside their own account uses the exact same five tabs, rather than
// the account section swapping to a differently-shaped nav the moment you
// land there. "Home" means the collector's own dashboard, not the public
// landing page — this bar only ever shows the customer's own app.
const CUSTOMER_MAIN_NAV: NavItem[] = [
  { href: "/account", label: "Home", icon: Home, exact: true },
  { href: "/account/collection", label: "Collection", icon: Frame },
  { href: "/marketplace", label: "Explore", icon: Compass },
  { href: "/wishlist", label: "Wishlist", icon: Heart },
];

const CUSTOMER_MORE_NAV: NavItem[] = [
  { href: "/account/orders", label: "Orders", icon: ShoppingBag },
  { href: "/account/wallet", label: "Wallet", icon: Wallet },
  { href: "/account/resale", label: "Resell Artwork", icon: Repeat2 },
  { href: "/account/settings", label: "Profile", icon: CircleUserRound },
  { href: "/account/addresses", label: "Addresses", icon: MapPin },
  { href: "/account/support", label: "Support", icon: LifeBuoy },
];

const HIDDEN_ROUTES = ["/login", "/register", "/forgot-password", "/reset-password"];
const HIDDEN_PREFIXES = ["/aggregator", "/admin", "/dashboard"];

function isActive(pathname: string, item: NavItem) {
  return item.exact ? pathname === item.href : pathname.startsWith(item.href);
}

function NavLink({
  item,
  active,
  onClick,
}: {
  item: NavItem;
  active: boolean;
  onClick?: (e: React.MouseEvent<HTMLAnchorElement>) => void;
}) {
  return (
    <Link
      href={item.href}
      onClick={onClick}
      className={cn(
        "flex flex-1 flex-col items-center justify-center gap-0.5 pt-1 text-[10px] font-medium transition-colors",
        active ? "text-gold-bright" : "text-muted-foreground hover:text-foreground",
      )}
    >
      <item.icon className="size-5 transition-colors" strokeWidth={active ? 2 : 1.75} />
      <span>{item.label}</span>
    </Link>
  );
}

export function MobileBottomNav() {
  const { data: me } = useCurrentUser();
  const pathname = usePathname();
  const mounted = useMounted();
  const sessionRole = useSyncExternalStore(
    subscribeToSession,
    readSessionRole,
    () => null,
  );
  const { data: profile } = useCustomerProfile();
  const customer = profile ?? { name: me?.name ?? "", email: me?.email ?? "" };
  // The sheet belongs to whatever page it was opened from — leaving it open
  // across a navigation would show stale content behind the new page. Keyed
  // to that path rather than closed by an effect, so there is no second
  // render pass on every route change.
  const [openedAt, setOpenedAt] = useState<string | null>(null);
  const moreOpen = openedAt === pathname;
  const setMoreOpen = (next: boolean) => setOpenedAt(next ? pathname : null);

  if (HIDDEN_ROUTES.includes(pathname)) return null;
  if (HIDDEN_PREFIXES.some((p) => pathname.startsWith(p))) return null;
  if (!mounted) return null;

  if (sessionRole === "customer") {
    return (
      <nav
        aria-label="Bottom navigation"
        className="fixed bottom-0 inset-x-0 z-50 flex h-16 items-stretch border-t border-border bg-background/95 backdrop-blur-md safe-area-pb lg:hidden"
      >
        {CUSTOMER_MAIN_NAV.map((item) => (
          <NavLink key={item.href} item={item} active={isActive(pathname, item)} />
        ))}

        <Sheet open={moreOpen} onOpenChange={setMoreOpen}>
          <SheetTrigger
            className={cn(
              "flex flex-1 flex-col items-center justify-center gap-0.5 pt-1 text-[10px] font-medium transition-colors hover:text-foreground",
              moreOpen ? "text-gold-bright" : "text-muted-foreground",
            )}
          >
            <Menu className="size-5" strokeWidth={moreOpen ? 2 : 1.75} />
            <span>More</span>
          </SheetTrigger>
          <SheetContent side="bottom" className="rounded-t-[20px] px-0 pb-6 focus-visible:outline-none">
            <SheetHeader className="px-6 text-left">
              <SheetTitle className="sr-only">More options</SheetTitle>
              <Link
                href="/account/settings"
                onClick={() => setMoreOpen(false)}
                className="flex items-center gap-3 rounded-lg bg-muted/40 p-3"
              >
                <span className="flex size-10 shrink-0 items-center justify-center rounded-full border border-gold/40 bg-gold/10 text-sm font-semibold text-gold-bright">
                  {initials(customer.name)}
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium text-foreground">{customer.name}</p>
                  <p className="truncate text-xs text-muted-foreground">{customer.email}</p>
                </div>
              </Link>
            </SheetHeader>

            <div className="mt-4 flex flex-col px-4">
              {CUSTOMER_MORE_NAV.map((item) => {
                const active = isActive(pathname, item);
                return (
                  <SheetClose
                    key={item.href}
                    nativeButton={false}
                    render={
                      <Link
                        href={item.href}
                        className={cn(
                          "flex items-center gap-3 rounded-lg px-4 py-3 text-sm transition-colors",
                          active
                            ? "bg-sidebar-accent text-sidebar-accent-foreground font-medium"
                            : "text-muted-foreground hover:bg-sidebar-accent hover:text-foreground",
                        )}
                      />
                    }
                  >
                    <item.icon
                      className={cn("size-4.5 shrink-0", active && "text-gold-bright")}
                      strokeWidth={1.75}
                    />
                    {item.label}
                  </SheetClose>
                );
              })}
            </div>
          </SheetContent>
        </Sheet>
      </nav>
    );
  }

  const nav =
    sessionRole === "artist"
      ? ARTIST_NAV
      : sessionRole === "aggregator"
        ? AGGREGATOR_NAV
        : GUEST_NAV;

  return (
    <nav
      aria-label="Bottom navigation"
      className="fixed bottom-0 inset-x-0 z-50 flex h-16 items-stretch border-t border-border bg-background/95 backdrop-blur-md safe-area-pb lg:hidden"
    >
      {nav.map((item) => {
        const active = isActive(pathname, item);
        const onClick = (e: React.MouseEvent<HTMLAnchorElement>) => {
          if (active) {
            e.preventDefault();
            window.scrollTo({ top: 0, behavior: "smooth" });
          }
        };
        return <NavLink key={item.href} item={item} active={active} onClick={onClick} />;
      })}
    </nav>
  );
}
