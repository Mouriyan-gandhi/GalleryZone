"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import { Cookie } from "lucide-react";
import { Button } from "@/components/ui/button";

const STORAGE_KEY = "gz-cookie-consent";

// Bottom-anchored bar, not a full-screen modal — reading the page should
// never be blocked by this. Accept and Dismiss both just record that the
// visitor has been shown the notice and stop it from reappearing; there's
// no cookie-blocking mechanism to actually gate in this mock phase (only
// the Essential session cookie and Functional localStorage entries exist
// at all — see /cookies), so the two choices differ only in the stored
// value, not in behavior.
export function CookieConsentBanner() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const stored = window.localStorage.getItem(STORAGE_KEY);
    // localStorage doesn't exist during SSR — this has to be a post-mount
    // read, and `visible` must default to false so first paint matches the
    // server, hence the direct setState here rather than a lazy initializer.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    if (!stored) setVisible(true);
  }, []);

  function respond(value: "accepted" | "dismissed") {
    window.localStorage.setItem(STORAGE_KEY, value);
    setVisible(false);
  }

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          initial={{ y: 96, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: 96, opacity: 0 }}
          transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
          role="region"
          aria-label="Cookie notice"
          className="fixed inset-x-0 bottom-0 z-50 px-3 pb-3 sm:px-6 sm:pb-4"
        >
          {/* Compact on phones: the full-size card covered ~40% of a 360px screen. */}
          <div className="mx-auto flex max-w-3xl flex-col items-start gap-3 rounded-xl border border-border/60 bg-card/95 p-3 shadow-lg ring-1 ring-foreground/10 backdrop-blur-md sm:flex-row sm:items-center sm:gap-4 sm:p-5">
            <span className="hidden size-9 shrink-0 items-center justify-center rounded-full border border-gold/40 bg-gold/10 sm:flex">
              <Cookie className="size-4 text-gold-bright" strokeWidth={1.75} />
            </span>
            <p className="flex-1 text-sm leading-snug text-muted-foreground sm:leading-relaxed">
              We use essential cookies to keep GalleryZone secure, and
              functional storage to remember things like your theme and
              wishlist. See our{" "}
              <Link
                href="/cookies"
                className="font-medium text-gold-bright hover:underline"
              >
                Cookie Policy
              </Link>{" "}
              for details.
            </p>
            <div className="flex w-full shrink-0 items-center gap-2 sm:w-auto">
              <Button
                variant="ghost"
                size="sm"
                className="flex-1 sm:flex-none"
                onClick={() => respond("dismissed")}
              >
                Dismiss
              </Button>
              <Button
                size="sm"
                className="flex-1 sm:flex-none"
                onClick={() => respond("accepted")}
              >
                Accept
              </Button>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
