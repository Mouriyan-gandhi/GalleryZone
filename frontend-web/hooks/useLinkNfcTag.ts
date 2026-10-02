import { useMutation, useQueryClient } from "@tanstack/react-query";
import { nfcTagService } from "@/services/nfcTagService";
import { NfcWriteError, tapAndWriteUrl } from "@/lib/nfc";
import { verifyUrlFor } from "@/lib/verify-url";

/**
 * Taps a chip, writes the artwork's verify URL to it with Web NFC, and records the link.
 *
 * Order matters: the server is asked BEFORE the chip is touched, so a chip that already
 * belongs to another piece (or a piece whose tag is locked) is refused while the chip is
 * still untouched. Only then is the URL written, and only after a successful write is the
 * link recorded. On success the artist's list and the public passport are refetched so the
 * pill and the badge move without a reload.
 */
export function useLinkNfcTagMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ artworkId }: { artworkId: string }) => {
      const tagUid = await tapAndWriteUrl(verifyUrlFor(artworkId), async (serialNumber) => {
        await nfcTagService.checkLink(artworkId, serialNumber);
      });
      return nfcTagService.confirmLinked(artworkId, tagUid);
    },
    onError: (error, { artworkId }) => {
      // A failure after a good write is the confirm call; anything before it names its own step.
      const step = error instanceof NfcWriteError ? error.step : "confirm";
      void nfcTagService.reportFailure(artworkId, step, error instanceof Error ? error.message : "link failed");
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["artist-artworks"] });
      queryClient.invalidateQueries({ queryKey: ["verify"] });
    },
  });
}
