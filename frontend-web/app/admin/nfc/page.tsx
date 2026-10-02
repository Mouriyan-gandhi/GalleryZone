import { AdminPageHeader } from "@/features/admin/admin-page-header";
import { NfcOverviewPanel } from "@/features/admin/catalog/nfc-overview";

export const metadata = {
  title: "NFC tags | GalleryZone Admin",
};

export default function AdminNfcPage() {
  return (
    <div className="space-y-6">
      <AdminPageHeader
        title="NFC tags"
        description="Which pieces have a chip, which of those are locked, and where the process is being bypassed."
      />
      <NfcOverviewPanel />
    </div>
  );
}
