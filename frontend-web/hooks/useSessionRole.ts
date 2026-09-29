import { useSyncExternalStore } from "react";
import { readSessionRole, subscribeToSession, type SessionRole } from "@/lib/session";

// The role cookie as a hook. Null on the server and on the first client
// render, so a page that is statically rendered for a signed-out visitor
// hydrates without a mismatch and then switches to the signed-in view.
export function useSessionRole(): SessionRole | null {
  return useSyncExternalStore(subscribeToSession, readSessionRole, () => null);
}
