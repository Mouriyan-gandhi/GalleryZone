import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { aggregatorService } from "@/services/aggregatorService";

export function useReservableInventory() {
  return useQuery({
    queryKey: ["aggregator-inventory"],
    queryFn: () => aggregatorService.listReservableInventory(),
  });
}

export function useReservableArtwork(artworkId: string) {
  return useQuery({
    queryKey: ["aggregator-inventory", artworkId],
    queryFn: () => aggregatorService.getReservableArtwork(artworkId),
  });
}

// Reserving moves an artwork out of Inventory and into Collection, and
// changes the "active reservations" KPI on the Dashboard — all three
// queries are invalidated together so every page reflects the new state on
// its next visit/refetch.
export function useReserveArtworkMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ artworkId, sellingPrice }: { artworkId: string; sellingPrice?: number | undefined }) =>
      aggregatorService.reserve(artworkId, sellingPrice),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["aggregator-inventory"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-collection"] });
      queryClient.invalidateQueries({ queryKey: ["aggregator-dashboard"] });
      // The advance and delivery are held from the wallet, so the balance and
      // its ledger moved too.
      queryClient.invalidateQueries({ queryKey: ["aggregator-wallet"] });
      queryClient.invalidateQueries({
        queryKey: ["aggregator-wallet-transactions"],
      });
    },
    // A failed reserve is nearly always the grid disagreeing with the store —
    // the piece has gone, or someone took it. Refetching is what stops the
    // next click failing identically, and the one after that.
    onError: () => {
      queryClient.invalidateQueries({ queryKey: ["aggregator-inventory"] });
    },
  });
}
