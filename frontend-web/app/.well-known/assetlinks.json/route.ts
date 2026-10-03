import { APP_LINK_HEADERS, buildAssetLinks } from "@/lib/app-links";

// Android App Links: the proof that the GalleryZone app may open https://<site>/verify/*.
// Read per request, so a rotated signing key is one env change and a redeploy of nothing.
export async function GET() {
  return Response.json(buildAssetLinks(process.env), { headers: APP_LINK_HEADERS });
}
