import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { aggregatorService } from "@/services/aggregatorService";
import type { RecordSalePayload } from "@/types/aggregator";

export function useAggregatorCollection() {
  return useQuery({
    queryKey: ["aggregator-collection"],
    queryFn: () => aggregatorService.listCollection(),
  });
}

export function useAggregatorHolding(holdingId: string) {
  return useQuery({
    queryKey: ["aggregator-collection", holdingId],
    queryFn: () => aggregatorService.getHolding(holdingId),
  });
}

// Recording a sale changes a holding's status in place within Collection
// and changes the "pending settlements" / "commission earned" KPIs on the
// Dashboard.
export function useRecordSaleMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: RecordSalePayload) =>
      aggregatorService.recordSale(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["aggregator-collection"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-dashboard"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-wallet"] });
      queryClient.invalidateQueries({
        queryKey: ["aggregator-wallet-transactions"],
      });
      queryClient.invalidateQueries({ queryKey: ["aggregator-sales"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-customers"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-shipments"] });
    },
  });
}

// Asking to keep a piece changes the holding in place, and GalleryZone's answer
// arrives the same way, so only the collection needs to re-read.
export function useRequestExtensionMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ holdingId, assurance }: { holdingId: string; assurance: string }) =>
      aggregatorService.requestExtension(holdingId, assurance),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["aggregator-collection"] }),
  });
}

// Dev-only time travel (see aggregatorService.debugSkipAheadDays). Same
// invalidation set as reserving/releasing: back-dating a holding can also
// change whether its artwork is placeable again, so Inventory's eligibility
// has to be re-read too, not just the collection row.
export function useDebugSkipAheadMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ holdingId, days }: { holdingId: string; days?: number }) =>
      aggregatorService.debugSkipAheadDays(holdingId, days),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["aggregator-collection"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-inventory"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-dashboard"] });
    },
  });
}

// Returning an unsold piece frees it for another aggregator, so Inventory has
// to be invalidated too — same set as reserving, in reverse.
export function useReleaseHoldingMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (holdingId: string) =>
      aggregatorService.releaseHolding(holdingId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["aggregator-collection"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-inventory"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-dashboard"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-wallet"] });
      queryClient.invalidateQueries({
        queryKey: ["aggregator-wallet-transactions"],
      });
    },
  });
}
