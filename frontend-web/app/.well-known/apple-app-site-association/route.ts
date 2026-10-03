import { APP_LINK_HEADERS, buildAppleAppSiteAssociation } from "@/lib/app-links";

// iOS Universal Links. The file has no extension and must be served as JSON, not
// redirected, with no sign-in in front of it.
export async function GET() {
  return Response.json(buildAppleAppSiteAssociation(process.env), { headers: APP_LINK_HEADERS });
}
