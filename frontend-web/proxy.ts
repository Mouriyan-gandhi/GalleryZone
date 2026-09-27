import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import {
  ROLE_LANDING,
  ROLE_SECTION_HOME,
  SESSION_COOKIE,
  isSessionRole,
} from "@/lib/session";

// Fake-auth route guard. There is no backend/session token — signing in just
// writes a `gz_session` cookie holding the demo role (see lib/session.ts).
// Next 16 renamed middleware.ts to proxy.ts (same API, `proxy` export instead
// of `middleware`) — see
// node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md.

const GUARDED_PREFIXES = ["/dashboard", "/aggregator", "/admin", "/account"];

// Only the site root redirects a signed-in person to their own home. /login
// and /register stay reachable on purpose: signing in again is how you switch
// roles or sign in as someone else, and bouncing people off those pages leaves
// them with no way out of a session.
const ROOT_PATH = "/";

function guardedPrefix(pathname: string): string | undefined {
  return GUARDED_PREFIXES.find(
    (prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`),
  );
}

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const cookieRole = request.cookies.get(SESSION_COOKIE)?.value;
  const role = isSessionRole(cookieRole) ? cookieRole : undefined;

  // We previously redirected authenticated users away from the home page.
  // This has been removed so that users can freely access the Home (Discover) page.

  const prefix = guardedPrefix(pathname);
  if (!prefix) return NextResponse.next();

  if (!role) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("next", pathname + request.nextUrl.search);
    return NextResponse.redirect(loginUrl);
  }

  // Signed in as the wrong role for this section (e.g. a customer hitting
  // /admin) — bounce to their own home instead of a bare 404/blank guard.
  const sectionHome = ROLE_SECTION_HOME[role];
  if (!sectionHome.startsWith(prefix)) {
    return NextResponse.redirect(new URL(sectionHome, request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/",
    "/dashboard/:path*",
    "/aggregator/:path*",
    "/admin/:path*",
    "/account/:path*",
  ],
};
