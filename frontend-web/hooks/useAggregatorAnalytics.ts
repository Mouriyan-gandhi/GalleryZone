import { useQuery } from "@tanstack/react-query";
import { aggregatorSalesService } from "@/services/aggregatorSalesService";

// Live summary derived from sales/wallet/holdings: the KPI source for counts
// that must match Orders & Sales / Wallet.
export function useAggregatorAnalytics() {
  return useQuery({
    queryKey: ["aggregator-analytics"],
    queryFn: () => aggregatorSalesService.getAnalytics(),
  });
}
