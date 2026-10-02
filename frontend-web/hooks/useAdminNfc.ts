import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { nfcTagService } from "@/services/nfcTagService";

// The admin's side of the NFC tags (NFC_IMPLEMENTATION.md §4.3, §4.4, §13): the
// catalogue-wide overview, and the three things an admin can do to one piece.

export function useNfcOverview() {
  return useQuery({
    queryKey: ["admin-nfc-overview"],
    queryFn: () => nfcTagService.adminOverview(),
  });
}

/** After any change, the piece, the artwork list, the orders queue (red "Unlocked" chips) and the overview all move. */
function useRefreshAfterNfcChange() {
  const queryClient = useQueryClient();
  return (artworkId: string) => {
    queryClient.invalidateQueries({ queryKey: ["admin-artwork", artworkId] });
    queryClient.invalidateQueries({ queryKey: ["admin-artworks"] });
    queryClient.invalidateQueries({ queryKey: ["admin-orders"] });
    queryClient.invalidateQueries({ queryKey: ["admin-order"] });
    queryClient.invalidateQueries({ queryKey: ["admin-nfc-overview"] });
    queryClient.invalidateQueries({ queryKey: ["verify", artworkId] });
  };
}

export function useAdminUnlinkNfcMutation() {
  const refresh = useRefreshAfterNfcChange();
  return useMutation({
    mutationFn: ({ artworkId, reason }: { artworkId: string; reason: string }) => nfcTagService.adminUnlink(artworkId, reason),
    onSuccess: (_data, { artworkId }) => refresh(artworkId),
  });
}

export function useAdminSkipShipmentGateMutation() {
  const refresh = useRefreshAfterNfcChange();
  return useMutation({
    mutationFn: ({ artworkId, reason }: { artworkId: string; reason: string }) => nfcTagService.adminSkipShipmentGate(artworkId, reason),
    onSuccess: (_data, { artworkId }) => refresh(artworkId),
  });
}

export function useAdminRemindNfcMutation() {
  return useMutation({
    mutationFn: (artworkId: string) => nfcTagService.adminRemind(artworkId),
  });
}
