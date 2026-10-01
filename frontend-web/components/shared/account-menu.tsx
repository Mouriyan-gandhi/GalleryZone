"use client";

import { useState } from "react";
import Link from "next/link";
import { CircleUserRound, LogOut, Settings } from "lucide-react";
import { UserAvatar } from "@/components/shared/user-avatar";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { useCurrentUser } from "@/hooks/useCurrentUser";
import { authService } from "@/services/authService";

const ITEM =
  "flex w-full items-center gap-2.5 rounded-md px-2.5 py-2 text-left text-sm text-foreground/90 transition-colors hover:bg-muted";

// The one place every portal signs out from: the avatar at the right end of the
// topbar (artist, collector, aggregator and admin), on every screen size. It
// also carries the shortcuts to the account's own pages; leave `profileHref` /
// `settingsHref` off for a portal that doesn't have them (admin has neither).
export function AccountMenu({
  role,
  profileHref,
  settingsHref,
}: {
  role: string;
  profileHref?: string;
  settingsHref?: string;
}) {
  const { data: me } = useCurrentUser();
  const [open, setOpen] = useState(false);

  async function handleSignOut() {
    try {
      await authService.logout();
    } finally {
      // logout() clears the session cookie before it touches Firebase, so
      // /login is the right place to land even if the Firebase call fails.
      // A full navigation rather than router.push: it drops every cached
      // query, so the next person to sign in on this browser can't see this
      // account's data from the cache.
      // eslint-disable-next-line @next/next/no-location-assign-relative-destination
      window.location.href = "/login";
    }
  }

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger
        aria-label="Account menu"
        className="flex items-center rounded-full p-1 transition-colors hover:bg-muted focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
      >
        <UserAvatar name={me?.name} className="size-8" />
      </PopoverTrigger>
      <PopoverContent side="bottom" align="end" className="w-60 gap-0 p-1.5">
        <div className="px-2.5 py-2">
          <p className="truncate text-sm font-medium text-foreground">
            {me?.name ?? role}
          </p>
          <p className="truncate text-xs text-muted-foreground">
            {me?.email || role}
          </p>
        </div>
        {(profileHref || settingsHref) && (
          <div className="mt-1 flex flex-col border-t border-border pt-1">
            {profileHref && (
              <Link href={profileHref} onClick={() => setOpen(false)} className={ITEM}>
                <CircleUserRound className="size-4 text-muted-foreground" strokeWidth={1.75} />
                My Profile
              </Link>
            )}
            {settingsHref && (
              <Link href={settingsHref} onClick={() => setOpen(false)} className={ITEM}>
                <Settings className="size-4 text-muted-foreground" strokeWidth={1.75} />
                Settings
              </Link>
            )}
          </div>
        )}
        <div className="mt-1 border-t border-border pt-1">
          <button type="button" onClick={handleSignOut} className={ITEM}>
            <LogOut className="size-4 text-muted-foreground" strokeWidth={1.75} />
            Sign out
          </button>
        </div>
      </PopoverContent>
    </Popover>
  );
}
