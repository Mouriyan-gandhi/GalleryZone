"use client";

import { useState, useSyncExternalStore } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  Building2,
  ClipboardList,
  Heart,
  Menu,
  Palette,
  Search,
  ShieldCheck,
} from "lucide-react";
import { SwitchMode } from "./switch-mode";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  NavigationMenu,
  NavigationMenuContent,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
  NavigationMenuTrigger,
  navigationMenuTriggerStyle,
} from "@/components/ui/navigation-menu";
import { useMarketplaceOverview } from "@/hooks/useArtworks";
import {
  ROLE_SECTION_HOME,
  readSessionRole,
  subscribeToSession,
} from "@/lib/session";
import { authService } from "@/services/authService";

function titleCase(value: string): string {
  return value.replace(/\b\w/g, (char) => char.toUpperCase());
}

// Explore menu: the categories that are actually live, from the marketplace facets.
function exploreCategoriesFrom(categories: string[]) {
  return categories.map((category) => ({ category, label: titleCase(category) }));
}

const SELL_WITH_US = [
  {
    icon: Palette,
    title: "Sell as an Artist",
    description:
      "List original work, keep your price private, get paid in full 7 days after sale.",
    href: "/register?role=artist",
  },
  {
    icon: Building2,
    title: "Partner as an Aggregator",
    description:
      "Display verified artwork in your space and earn a share of every sale you help make.",
    href: "/register?role=aggregator",
  },
  {
    icon: ClipboardList,
    title: "Take the Artist Survey",
    description:
      "A 2 minute survey about your art and practice. No account needed.",
    href: "/artist-survey",
  },
];

const SIMPLE_LINKS = [
  { label: "Explore", href: "/marketplace" },
  { label: "Artists", href: "/artists" },
  { label: "About", href: "/about" },
  { label: "FAQ", href: "/faq" },
];

export function SiteHeader() {
  const router = useRouter();
  const pathname = usePathname();
  // The landing page is pure storytelling/onboarding, not a browsing
  // surface — search and wishlist only make sense once there's a catalog
  // on screen to act on (marketplace, artists, etc.), so both are hidden
  // here and nowhere else.
  const isLandingPage = pathname === "/";
  const [mobileOpen, setMobileOpen] = useState(false);
  const EXPLORE_CATEGORIES = exploreCategoriesFrom(useMarketplaceOverview().data?.facets.categories ?? []);

  // The cookie isn't available during the server render, and rendering
  // "Sign In" to someone who is already signed in is exactly the trap this
  // fixes — so the header subscribes to the session instead of assuming.
  const sessionRole = useSyncExternalStore(
    subscribeToSession,
    readSessionRole,
    () => null,
  );

  function handleSignOut() {
    void authService.logout();
    router.push("/");
    router.refresh();
  }
  const [mobileQuery, setMobileQuery] = useState("");
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  function handleSearchSubmit(query: string) {
    const trimmed = query.trim();
    router.push(
      trimmed
        ? `/marketplace?q=${encodeURIComponent(trimmed)}`
        : "/marketplace",
    );
    setMobileOpen(false);
    setSearchOpen(false);
  }

  return (
    <div className="sticky top-0 z-50 flex flex-col">
      <header className="w-full border-b border-border/60 bg-background/75 backdrop-blur-md">
        <div className="mx-auto flex h-20 max-w-[1440px] items-center justify-between gap-4 px-6 lg:px-10">
          <div className="flex flex-1 items-center">
            <Link
              href={sessionRole ? ROLE_SECTION_HOME[sessionRole] : "/"}
              className="flex items-baseline gap-2.5"
            >
            <span className="font-display text-2xl font-semibold italic text-gold-bright">
              GZ
            </span>
            <span className="text-sm font-medium tracking-[0.18em] text-foreground">
              GALLERYZONE
            </span>
            </Link>
          </div>

          <NavigationMenu className="hidden justify-center lg:flex">
            <NavigationMenuList>
              {SIMPLE_LINKS.map((link) => (
                <NavigationMenuItem key={link.href}>
                  <NavigationMenuLink
                    render={<Link href={link.href} />}
                    className={navigationMenuTriggerStyle()}
                  >
                    {link.label}
                  </NavigationMenuLink>
                </NavigationMenuItem>
              ))}

              {/* Pitches registering as an artist/aggregator — not useful
                  once someone is already signed in, whatever their role. */}
              {!sessionRole && (
                <NavigationMenuItem>
                  <NavigationMenuTrigger>Sell With Us</NavigationMenuTrigger>
                  <NavigationMenuContent>
                    <div className="grid w-[420px] gap-1 p-2">
                      {SELL_WITH_US.map((option) => (
                        <NavigationMenuLink
                          key={option.href}
                          render={
                            <Link
                              href={option.href}
                              className="items-start gap-3"
                            />
                          }
                        >
                          <option.icon
                            className="mt-0.5 size-4 text-gold-bright"
                            strokeWidth={1.75}
                          />
                          <span className="flex flex-col gap-0.5">
                            <span className="font-medium">{option.title}</span>
                            <span className="text-xs text-muted-foreground">
                              {option.description}
                            </span>
                          </span>
                        </NavigationMenuLink>
                      ))}
                      <NavigationMenuLink
                        render={
                          <Link href="/about#how-it-works" className="gap-2" />
                        }
                      >
                        <ShieldCheck
                          className="size-4 text-gold-bright"
                          strokeWidth={1.75}
                        />
                        <span className="font-medium">
                          How Price Privacy &amp; Verification Work
                        </span>
                      </NavigationMenuLink>
                    </div>
                  </NavigationMenuContent>
                </NavigationMenuItem>
              )}
            </NavigationMenuList>
          </NavigationMenu>

          <div className="flex flex-1 items-center justify-end gap-1.5 sm:gap-2.5">
            {!isLandingPage && (
              <>
                <Popover open={searchOpen} onOpenChange={setSearchOpen}>
                  <PopoverTrigger
                    render={
                      <Button
                        variant="ghost"
                        size="icon"
                        aria-label="Search artworks"
                        className="hidden size-10 sm:inline-flex"
                      />
                    }
                  >
                    <Search className="size-4" strokeWidth={1.75} />
                  </PopoverTrigger>
                  <PopoverContent align="end" className="w-72">
                    <form
                      onSubmit={(e) => {
                        e.preventDefault();
                        handleSearchSubmit(searchQuery);
                      }}
                      className="flex items-center gap-2"
                    >
                      <Input
                        autoFocus
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        placeholder="Search artworks"
                        className="h-9"
                      />
                      <Button
                        type="submit"
                        size="icon-sm"
                        variant="outline"
                        aria-label="Search"
                      >
                        <Search className="size-3.5" />
                      </Button>
                    </form>
                  </PopoverContent>
                </Popover>

                <Button
                  variant="ghost"
                  size="icon"
                  className="hidden size-10 sm:inline-flex"
                  nativeButton={false}
                  render={
                    <Link href="/wishlist" aria-label="Wishlist" />
                  }
                >
                  <Heart className="size-4" strokeWidth={1.75} />
                </Button>
              </>
            )}

            {sessionRole ? (
              <div className="hidden items-center gap-4 md:flex">
                <Link
                  href={ROLE_SECTION_HOME[sessionRole]}
                  className="text-sm font-medium text-foreground/85 transition-colors hover:text-foreground"
                >
                  {sessionRole === "customer" ? "My account" : "My dashboard"}
                </Link>
                <button
                  type="button"
                  onClick={handleSignOut}
                  className="text-sm font-medium text-foreground/85 transition-colors hover:text-foreground"
                >
                  Sign out
                </button>
              </div>
            ) : (
              // Phones already have Sign In in the bottom nav; here it only
              // crowded the row (wrapping at 360px, overflowing at 320px).
              <Link
                href="/login"
                className="hidden whitespace-nowrap text-sm font-medium text-foreground/85 transition-colors hover:text-foreground sm:inline"
              >
                Sign In
              </Link>
            )}

            <SwitchMode />

            <Button
              variant="ghost"
              size="icon"
              aria-label="Open menu"
              className="size-10 lg:hidden"
              onClick={() => setMobileOpen(true)}
            >
              <Menu className="size-5" strokeWidth={1.75} />
            </Button>
          </div>
        </div>

        <Dialog open={mobileOpen} onOpenChange={setMobileOpen}>
          <DialogContent className="top-0 right-0 left-auto flex h-full max-h-none w-full max-w-xs translate-x-0 translate-y-0 flex-col overflow-y-auto rounded-none border-l border-border/60 p-6 sm:max-w-xs">
            <DialogTitle className="sr-only">Navigation menu</DialogTitle>

            {/* Brand + account block — always at the top */}
            <div className="flex items-start justify-between gap-3">
              <Link
                href={sessionRole ? ROLE_SECTION_HOME[sessionRole] : "/"}
                onClick={() => setMobileOpen(false)}
                className="flex items-baseline gap-2"
              >
                <span className="font-display text-xl font-semibold italic text-gold-bright">
                  GZ
                </span>
                <span className="text-xs font-medium tracking-[0.18em] text-foreground">
                  GALLERYZONE
                </span>
              </Link>

              {sessionRole ? (
                <div className="flex flex-col items-end gap-1">
                  <Link
                    href={ROLE_SECTION_HOME[sessionRole]}
                    onClick={() => setMobileOpen(false)}
                    className="text-sm font-medium text-gold-bright transition-colors hover:text-gold"
                  >
                    {sessionRole === "customer" ? "My account" : "My dashboard"}
                  </Link>
                  <button
                    type="button"
                    onClick={() => {
                      setMobileOpen(false);
                      handleSignOut();
                    }}
                    className="text-xs text-muted-foreground transition-colors hover:text-foreground"
                  >
                    Sign out
                  </button>
                </div>
              ) : (
                <Link
                  href="/login"
                  onClick={() => setMobileOpen(false)}
                  className="text-sm font-medium text-foreground/85 transition-colors hover:text-foreground"
                >
                  Sign In
                </Link>
              )}
            </div>

            {/* Quick links: Wishlist */}
            {!isLandingPage && (
              <div className="mt-4 flex items-center gap-2 border-t border-border/60 pt-4">
                <Link
                  href="/wishlist"
                  onClick={() => setMobileOpen(false)}
                  className="flex items-center gap-2 rounded-lg px-3 py-2 text-sm text-foreground/90 transition-colors hover:bg-muted"
                >
                  <Heart className="size-4 text-gold-bright" strokeWidth={1.75} />
                  Wishlist
                </Link>
              </div>
            )}

            {!isLandingPage && (
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  handleSearchSubmit(mobileQuery);
                }}
                className="mt-4 flex items-center gap-2"
              >
                <Input
                  value={mobileQuery}
                  onChange={(e) => setMobileQuery(e.target.value)}
                  placeholder="Search artworks"
                  className="h-10"
                />
                <Button
                  type="submit"
                  size="icon"
                  variant="outline"
                  aria-label="Search"
                >
                  <Search className="size-4" />
                </Button>
              </form>
            )}

            <nav className="mt-8 flex flex-col gap-1">
              <p className="px-3 text-xs font-medium tracking-[0.14em] text-muted-foreground uppercase">
                Explore
              </p>
              {EXPLORE_CATEGORIES.map(({ category, label }) => (
                <Link
                  key={category}
                  href={`/marketplace?category=${encodeURIComponent(category)}`}
                  onClick={() => setMobileOpen(false)}
                  className="rounded-lg px-3 py-3 font-display text-lg font-medium text-foreground transition-colors hover:bg-muted"
                >
                  {label}
                </Link>
              ))}
              <Link
                href="/marketplace"
                onClick={() => setMobileOpen(false)}
                className="rounded-lg px-3 py-3 font-display text-lg font-medium text-gold-bright transition-colors hover:bg-muted"
              >
                Browse all artworks
              </Link>

              {SIMPLE_LINKS.filter((link) => link.href !== "/marketplace").map(
                (link) => (
                  <Link
                    key={link.href}
                    href={link.href}
                    onClick={() => setMobileOpen(false)}
                    className="rounded-lg px-3 py-3 font-display text-lg font-medium text-foreground transition-colors hover:bg-muted"
                  >
                    {link.label}
                  </Link>
                ),
              )}
            </nav>

            {/* Only pitches registering as an artist/aggregator — meaningless
                (and the links go to /register while already authenticated)
                once someone is signed in, whatever their role. */}
            {!sessionRole && (
              <div className="mt-6 border-t border-border/60 pt-6">
                <p className="px-3 text-xs font-medium tracking-[0.14em] text-muted-foreground uppercase">
                  Sell With Us
                </p>
                <nav className="mt-2 flex flex-col gap-1">
                  {SELL_WITH_US.map((option) => (
                    <Link
                      key={option.title}
                      href={option.href}
                      onClick={() => setMobileOpen(false)}
                      className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm text-foreground/90 transition-colors hover:bg-muted"
                    >
                      <option.icon
                        className="size-4 shrink-0 text-gold-bright"
                        strokeWidth={1.75}
                      />
                      {option.title}
                    </Link>
                  ))}
                </nav>
              </div>
            )}

            <div className="mt-auto flex items-center justify-between border-t border-border/60 pt-6">
              <span className="text-xs text-muted-foreground">Theme</span>
              <SwitchMode />
            </div>
          </DialogContent>
        </Dialog>
      </header>
    </div>
  );
}
