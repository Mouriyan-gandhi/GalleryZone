import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { aggregatorSalesService } from "@/services/aggregatorSalesService";

export function useAggregatorSettlements() {
  return useQuery({
    queryKey: ["aggregator-settlements"],
    queryFn: () => aggregatorSalesService.listSettlements(),
  });
}

export function useRemittancesDue() {
  return useQuery({
    queryKey: ["aggregator-remittances"],
    queryFn: () => aggregatorSalesService.listRemittancesDue(),
  });
}

export function useMarkRemittedMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ saleId, via }: { saleId: string; via: "wallet" | "bank" }) =>
      aggregatorSalesService.markRemitted(saleId, via),
    // Paying from the wallet moves the balance, so the wallet reads refresh too.
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["aggregator-remittances"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-settlements"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-wallet"] });
      queryClient.invalidateQueries({
        queryKey: ["aggregator-wallet-transactions"],
      });
    },
  });
}

export function useProcessSettlementMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (saleId: string) =>
      aggregatorSalesService.processSettlement(saleId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["aggregator-settlements"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-wallet"] });
      queryClient.invalidateQueries({
        queryKey: ["aggregator-wallet-transactions"],
      });
    },
  });
}
