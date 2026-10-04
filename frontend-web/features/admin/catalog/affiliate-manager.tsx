"use client";

import { useState } from "react";
import Image from "next/image";
import { toast } from "sonner";
import { ExternalLink, Pencil, Plus, ShoppingBag, Trash2, TriangleAlert, WandSparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Field, FieldDescription, FieldLabel } from "@/components/ui/field";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { AdminDataTable, type AdminDataTableColumn } from "@/features/admin/admin-data-table";
import { ConfirmActionDialog } from "@/features/admin/confirm-action-dialog";
import {
  useAdminAffiliateProducts,
  useAmazonLookupMutation,
  useCreateAffiliateProductMutation,
  useDeleteAffiliateProductMutation,
  useUpdateAffiliateProductMutation,
} from "@/hooks/useAffiliateProducts";
import { amazonImageAt, type AffiliateProduct } from "@/types/affiliate";

export function AffiliateManager() {
  const { data: products, isPending } = useAdminAffiliateProducts();
  const [editing, setEditing] = useState<AffiliateProduct | "new" | null>(null);
  const [deleting, setDeleting] = useState<AffiliateProduct | null>(null);
  const update = useUpdateAffiliateProductMutation();
  const remove = useDeleteAffiliateProductMutation();
  const categories = [...new Set((products ?? []).map((p) => p.category))].sort();

  async function toggleActive(product: AffiliateProduct, active: boolean) {
    try {
      await update.mutateAsync({ id: product.id, patch: { active } });
      toast.success(active ? "Back on the page" : "Hidden from the page");
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Could not update the product.");
    }
  }

  async function handleDelete() {
    if (!deleting) return;
    try {
      await remove.mutateAsync(deleting.id);
      toast.success("Product removed");
      setDeleting(null);
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Could not remove the product.");
    }
  }

  const columns: AdminDataTableColumn<AffiliateProduct>[] = [
    {
      key: "title",
      header: "Product",
      render: (row) => (
        <div className="flex min-w-0 items-center gap-3">
          <div className="relative size-12 shrink-0 overflow-hidden rounded-md border border-border bg-white">
            {row.images[0] && (
              <Image src={amazonImageAt(row.images[0], 100)} alt="" fill unoptimized sizes="48px" className="object-contain p-1" />
            )}
          </div>
          <div className="min-w-0">
            <p className="line-clamp-2 max-w-md text-sm font-medium text-foreground">{row.title}</p>
            <p className="truncate text-xs text-muted-foreground">
              {[row.brand, row.asin].filter(Boolean).join(" · ") || "No brand"}
            </p>
          </div>
        </div>
      ),
      sortable: true,
      sortValue: (row) => row.title,
    },
    {
      key: "category",
      header: "Category",
      render: (row) => <span className="text-sm text-muted-foreground">{row.category}</span>,
      sortable: true,
      sortValue: (row) => row.category,
    },
    {
      key: "active",
      header: "On the page",
      render: (row) => (
        <Switch
          checked={row.active}
          onCheckedChange={(checked) => toggleActive(row, checked)}
          aria-label={row.active ? `Hide ${row.title}` : `Show ${row.title}`}
        />
      ),
      sortable: true,
      sortValue: (row) => (row.active ? 1 : 0),
    },
    {
      key: "actions",
      header: "",
      render: (row) => (
        <div className="flex justify-end gap-1">
          <Button
            size="sm"
            variant="ghost"
            nativeButton={false}
            render={<a href={row.url} target="_blank" rel="noopener noreferrer" aria-label={`Open ${row.title} on Amazon`} />}
          >
            <ExternalLink className="size-3.5" />
          </Button>
          <Button size="sm" variant="ghost" onClick={() => setEditing(row)} aria-label={`Edit ${row.title}`}>
            <Pencil className="size-3.5" />
          </Button>
          <Button size="sm" variant="ghost" onClick={() => setDeleting(row)} aria-label={`Remove ${row.title}`}>
            <Trash2 className="size-3.5" />
          </Button>
        </div>
      ),
      className: "text-right",
    },
  ];

  return (
    <>
      <div className="flex justify-end">
        <Button onClick={() => setEditing("new")}>
          <Plus className="size-4" />
          Add product
        </Button>
      </div>

      <AdminDataTable
        rows={products ?? []}
        columns={columns}
        isLoading={isPending}
        getRowKey={(row) => row.id}
        searchPlaceholder="Search title, brand or ASIN"
        searchValue={(row) => `${row.title} ${row.brand ?? ""} ${row.asin ?? ""} ${row.category}`}
        filters={[
          {
            key: "category",
            label: "Category",
            options: categories.map((c) => ({ value: c, label: c })),
            matches: (row, value) => row.category === value,
          },
          {
            key: "active",
            label: "Visibility",
            options: [
              { value: "shown", label: "On the page" },
              { value: "hidden", label: "Hidden" },
            ],
            matches: (row, value) => row.active === (value === "shown"),
          },
        ]}
        pageSize={25}
        emptyTitle="No products yet"
        emptyDescription="Add an Amazon link to put the first product on the Art supplies page."
        emptyIcon={ShoppingBag}
      />

      {editing && (
        <ProductFormDialog
          product={editing === "new" ? null : editing}
          categories={categories}
          onClose={() => setEditing(null)}
        />
      )}

      <ConfirmActionDialog
        open={deleting !== null}
        onOpenChange={(open) => !open && setDeleting(null)}
        title="Remove this product?"
        description={
          <span>
            “{deleting?.title}” leaves the Art supplies page and this list. To take it down for a while
            instead, switch it off and it keeps its details.
          </span>
        }
        confirmLabel="Remove"
        destructive
        isPending={remove.isPending}
        onConfirm={handleDelete}
      />
    </>
  );
}

function ProductFormDialog({
  product,
  categories,
  onClose,
}: {
  product: AffiliateProduct | null;
  categories: string[];
  onClose: () => void;
}) {
  const [url, setUrl] = useState(product?.url ?? "");
  const [asin, setAsin] = useState<string | null>(product?.asin ?? null);
  const [title, setTitle] = useState(product?.title ?? "");
  const [brand, setBrand] = useState(product?.brand ?? "");
  const [category, setCategory] = useState(product?.category ?? "");
  const [images, setImages] = useState((product?.images ?? []).join("\n"));
  const [active, setActive] = useState(product?.active ?? true);
  const [error, setError] = useState<string | null>(null);

  const lookup = useAmazonLookupMutation();
  const create = useCreateAffiliateProductMutation();
  const update = useUpdateAffiliateProductMutation();
  const saving = create.isPending || update.isPending;
  const imageList = images.split(/\s+/).filter(Boolean);

  async function fetchDetails() {
    setError(null);
    try {
      const found = await lookup.mutateAsync(url.trim());
      setAsin(found.asin);
      setTitle(found.title);
      setBrand(found.brand ?? "");
      setImages(found.images.join("\n"));
      if (!category && found.categoryPath.length) setCategory(found.categoryPath.at(-1)!);
      toast.success("Filled in from Amazon. Check the category before saving.");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not read that Amazon page.");
    }
  }

  async function save(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    const fields = { url: url.trim(), title: title.trim(), brand: brand.trim() || null, category: category.trim(), images: imageList, active };
    try {
      if (product) await update.mutateAsync({ id: product.id, patch: fields });
      else await create.mutateAsync({ ...fields, asin });
      toast.success(product ? "Product saved" : "Product added");
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not save the product.");
    }
  }

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-xl">
        <DialogHeader>
          <DialogTitle>{product ? "Edit product" : "Add product"}</DialogTitle>
        </DialogHeader>

        <form onSubmit={save} className="space-y-4">
          <Field>
            <FieldLabel htmlFor="aff-url">Amazon link</FieldLabel>
            <div className="flex gap-2">
              <Input
                id="aff-url"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                placeholder="https://link.amazon/…"
                required
                autoComplete="off"
              />
              <Button type="button" variant="outline" onClick={fetchDetails} disabled={!url.trim() || lookup.isPending}>
                <WandSparkles className="size-4" />
                {lookup.isPending ? "Reading…" : "Fill from Amazon"}
              </Button>
            </div>
            <FieldDescription>
              Paste the link from Amazon Associates (SiteStripe) so it carries GalleryZone&apos;s tag.
              {asin && <span className="ml-1 font-mono">ASIN {asin}</span>}
            </FieldDescription>
          </Field>

          <Field>
            <FieldLabel htmlFor="aff-title">Title</FieldLabel>
            <Textarea id="aff-title" value={title} onChange={(e) => setTitle(e.target.value)} rows={2} required minLength={2} maxLength={300} />
          </Field>

          <div className="grid gap-4 sm:grid-cols-2">
            <Field>
              <FieldLabel htmlFor="aff-brand">Brand</FieldLabel>
              <Input id="aff-brand" value={brand} onChange={(e) => setBrand(e.target.value)} maxLength={80} autoComplete="off" />
            </Field>
            <Field>
              <FieldLabel htmlFor="aff-category">Category</FieldLabel>
              <Input
                id="aff-category"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                list="aff-categories"
                required
                minLength={2}
                maxLength={60}
                autoComplete="off"
              />
              <datalist id="aff-categories">
                {categories.map((c) => (
                  <option key={c} value={c} />
                ))}
              </datalist>
            </Field>
          </div>

          <Field>
            <FieldLabel htmlFor="aff-images">Photos</FieldLabel>
            <Textarea
              id="aff-images"
              value={images}
              onChange={(e) => setImages(e.target.value)}
              rows={3}
              placeholder="One or two image URLs, one per line, cover first"
              className="font-mono text-xs"
              required
            />
            {imageList.length > 0 && (
              <div className="flex gap-2 overflow-x-auto pt-1">
                {imageList.slice(0, 8).map((src) => (
                  <div key={src} className="relative size-14 shrink-0 overflow-hidden rounded-md border border-border bg-white">
                    <Image src={amazonImageAt(src, 100)} alt="" fill unoptimized sizes="56px" className="object-contain p-1" />
                  </div>
                ))}
              </div>
            )}
          </Field>

          <label className="flex items-center justify-between gap-4 rounded-md border border-border px-3 py-2.5">
            <span className="text-sm">
              <span className="font-medium text-foreground">Show on the Art supplies page</span>
              <span className="block text-xs text-muted-foreground">Off keeps it here without showing it to visitors.</span>
            </span>
            <Switch checked={active} onCheckedChange={setActive} />
          </label>

          {error && (
            <p className="flex items-start gap-2 rounded-md border border-destructive/50 bg-destructive/[0.06] p-3 text-xs text-foreground">
              <TriangleAlert className="mt-px size-3.5 shrink-0 text-destructive" />
              {error}
            </p>
          )}

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button type="submit" disabled={saving}>
              {saving ? "Saving…" : product ? "Save" : "Add product"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
