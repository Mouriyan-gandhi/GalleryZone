import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { affiliateService } from "@/services/affiliateService";
import type { AffiliateProductInput } from "@/types/affiliate";

export function useAffiliateProducts() {
  return useQuery({ queryKey: ["affiliate-products"], queryFn: () => affiliateService.list(), staleTime: 5 * 60_000 });
}

export function useAdminAffiliateProducts() {
  return useQuery({ queryKey: ["admin-affiliate-products"], queryFn: () => affiliateService.listForAdmin() });
}

function useInvalidate() {
  const queryClient = useQueryClient();
  return () => {
    queryClient.invalidateQueries({ queryKey: ["admin-affiliate-products"] });
    queryClient.invalidateQueries({ queryKey: ["affiliate-products"] });
  };
}

export function useAmazonLookupMutation() {
  return useMutation({ mutationFn: (url: string) => affiliateService.lookup(url) });
}

export function useCreateAffiliateProductMutation() {
  const onSuccess = useInvalidate();
  return useMutation({ mutationFn: (input: AffiliateProductInput) => affiliateService.create(input), onSuccess });
}

export function useUpdateAffiliateProductMutation() {
  const onSuccess = useInvalidate();
  return useMutation({
    mutationFn: ({ id, patch }: { id: string; patch: Partial<Omit<AffiliateProductInput, "asin">> }) => affiliateService.update(id, patch),
    onSuccess,
  });
}

export function useDeleteAffiliateProductMutation() {
  const onSuccess = useInvalidate();
  return useMutation({ mutationFn: (id: string) => affiliateService.remove(id), onSuccess });
}
