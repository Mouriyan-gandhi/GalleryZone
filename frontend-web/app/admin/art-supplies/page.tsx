import { AdminPageHeader } from "@/features/admin/admin-page-header";
import { AffiliateManager } from "@/features/admin/catalog/affiliate-manager";

export const metadata = {
  title: "Art supplies | GalleryZone Admin",
};

export default function AdminArtSuppliesPage() {
  return (
    <div className="space-y-6">
      <AdminPageHeader
        title="Art supplies"
        description="Amazon products on the public Art supplies page. Every link earns GalleryZone a commission on the sale."
      />
      <AffiliateManager />
    </div>
  );
}
