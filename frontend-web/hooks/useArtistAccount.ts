import { notify } from "@/lib/notify";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { artistDashboardService } from "@/services/artistDashboardService";
import { mouDateTime } from "@/features/mou/mou-document";

// Named "Account" rather than "Profile" to avoid colliding with
// hooks/useArtistProfile.ts, which is for *viewing another artist's* public
// profile (Marketplace/Artist Directory) — a different domain entirely from
// the logged-in artist's own Profile & KYC form this file backs.
export function useArtistAccountProfile() {
  return useQuery({
    queryKey: ["artist-account-profile"],
    queryFn: () => artistDashboardService.getProfile(),
  });
}

export function useSaveArtistProfileMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (
      patch: Parameters<typeof artistDashboardService.updateProfile>[0],
    ) => artistDashboardService.updateProfile(patch),
    onError: notify.error("Profile not saved"),
    onSuccess: (_profile, patch) => {
      notify.success(
        "bankAccountNumber" in patch || "ifsc" in patch ? "Payout account saved" : "pickupLine1" in patch ? "Pickup address saved" : "Profile saved",
      );
      queryClient.invalidateQueries({ queryKey: ["artist-account-profile"] });
    },
  });
}

export function useAcceptMouMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (
      input: Parameters<typeof artistDashboardService.acceptMou>[0],
    ) => artistDashboardService.acceptMou(input),
    onError: notify.error("The agreement wasn't signed"),
    onSuccess: (profile) => {
      notify.success("Agreement signed", profile.mouAcceptance ? `Signed ${mouDateTime(profile.mouAcceptance.acceptedAt)}. A copy is on your profile.` : undefined);
      queryClient.invalidateQueries({ queryKey: ["artist-account-profile"] });
      queryClient.invalidateQueries({ queryKey: ["artist-activity"] });
    },
  });
}

// --- Account deactivation ---------------------------------------------------

export function useDeactivationRequest() {
  return useQuery({
    queryKey: ["artist-deactivation-request"],
    queryFn: () => artistDashboardService.getDeactivationRequest(),
  });
}

function useDeactivationMutation<TInput>(
  mutationFn: (input: TInput) => Promise<unknown>,
) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn,
    onError: notify.error("That didn't go through"),
    onSuccess: () => {
      notify.success("Request recorded", "An admin will review it and you'll get an email.");
      queryClient.invalidateQueries({
        queryKey: ["artist-deactivation-request"],
      });
      queryClient.invalidateQueries({ queryKey: ["artist-activity"] });
    },
  });
}

export function useRequestDeactivationMutation() {
  return useDeactivationMutation((input: { reason: string }) =>
    artistDashboardService.requestDeactivation(input),
  );
}

export function useWithdrawDeactivationMutation() {
  return useDeactivationMutation((requestId: string) =>
    artistDashboardService.withdrawDeactivation(requestId),
  );
}
