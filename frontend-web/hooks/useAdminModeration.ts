import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { adminService } from "@/services/adminService";
import type { ArtworkRarity } from "@/types/artwork";

// ---------------------------------------------------------------------------
// The three approval workflows. Every mutation here changes a pending-queue
// count, so every one of them additionally invalidates ["admin-kpis"] — the
// overview tiles and the shell's nav badges would otherwise keep claiming
// work is waiting that you just cleared.
//
// Removing the acted-on row from its queue is the call site's job via
// queryClient.setQueryData (spec §6) — these hooks only invalidate what the
// action provably changed elsewhere.
// ---------------------------------------------------------------------------

// --- artwork moderation ----------------------------------------------------

export function useAdminPendingArtworks() {
  return useQuery({
    queryKey: ["admin-pending-artworks"],
    queryFn: () => adminService.listPendingArtworks(),
  });
}

export function useAdminPendingArtwork(artworkId: string) {
  return useQuery({
    queryKey: ["admin-pending-artwork", artworkId],
    queryFn: () => adminService.getPendingArtwork(artworkId),
    enabled: Boolean(artworkId),
  });
}

export function useApproveArtworkMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ artworkId, rarity }: { artworkId: string; rarity: ArtworkRarity }) =>
      adminService.approveArtwork(artworkId, rarity),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-pending-artworks"] });
      queryClient.invalidateQueries({ queryKey: ["admin-artworks"] });
      queryClient.invalidateQueries({ queryKey: ["admin-kpis"] });
    },
  });
}

export function useRejectArtworkMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      artworkId,
      reason,
    }: {
      artworkId: string;
      reason: string;
    }) => adminService.rejectArtwork(artworkId, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-pending-artworks"] });
      queryClient.invalidateQueries({ queryKey: ["admin-artworks"] });
      queryClient.invalidateQueries({ queryKey: ["admin-kpis"] });
    },
  });
}

// --- KYC -------------------------------------------------------------------

export function useAdminKycQueue() {
  return useQuery({
    queryKey: ["admin-kyc-queue"],
    queryFn: () => adminService.listKycQueue(),
  });
}

export function useApproveKycMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (userId: string) => adminService.approveKyc(userId),
    onSuccess: (_data, userId) => {
      queryClient.invalidateQueries({ queryKey: ["admin-kyc-queue"] });
      queryClient.invalidateQueries({ queryKey: ["admin-users"] });
      queryClient.invalidateQueries({ queryKey: ["admin-user", userId] });
      queryClient.invalidateQueries({ queryKey: ["admin-kpis"] });
    },
  });
}

export function useRejectKycMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, reason }: { userId: string; reason: string }) =>
      adminService.rejectKyc(userId, reason),
    onSuccess: (_data, { userId }) => {
      queryClient.invalidateQueries({ queryKey: ["admin-kyc-queue"] });
      queryClient.invalidateQueries({ queryKey: ["admin-users"] });
      queryClient.invalidateQueries({ queryKey: ["admin-user", userId] });
      queryClient.invalidateQueries({ queryKey: ["admin-kpis"] });
    },
  });
}

// --- GST -------------------------------------------------------------------

export function useAdminGstQueue() {
  return useQuery({
    queryKey: ["admin-gst-queue"],
    queryFn: () => adminService.listGstQueue(),
  });
}

export function useApproveGstMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (userId: string) => adminService.approveGst(userId),
    onSuccess: (_data, userId) => {
      queryClient.invalidateQueries({ queryKey: ["admin-gst-queue"] });
      queryClient.invalidateQueries({ queryKey: ["admin-users"] });
      queryClient.invalidateQueries({ queryKey: ["admin-user", userId] });
      queryClient.invalidateQueries({ queryKey: ["admin-kpis"] });
    },
  });
}

export function useRejectGstMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, reason }: { userId: string; reason: string }) =>
      adminService.rejectGst(userId, reason),
    onSuccess: (_data, { userId }) => {
      queryClient.invalidateQueries({ queryKey: ["admin-gst-queue"] });
      queryClient.invalidateQueries({ queryKey: ["admin-users"] });
      queryClient.invalidateQueries({ queryKey: ["admin-user", userId] });
      queryClient.invalidateQueries({ queryKey: ["admin-kpis"] });
    },
  });
}

// --- withdrawals -----------------------------------------------------------

export function useAdminWithdrawals() {
  return useQuery({
    queryKey: ["admin-withdrawals"],
    queryFn: () => adminService.listWithdrawals(),
  });
}

export function useApproveWithdrawalMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (withdrawalId: string) =>
      adminService.approveWithdrawal(withdrawalId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-withdrawals"] });
      queryClient.invalidateQueries({ queryKey: ["admin-kpis"] });
    },
  });
}

export function useRejectWithdrawalMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      withdrawalId,
      reason,
    }: {
      withdrawalId: string;
      reason: string;
    }) => adminService.rejectWithdrawal(withdrawalId, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-withdrawals"] });
      queryClient.invalidateQueries({ queryKey: ["admin-kpis"] });
    },
  });
}

// --- Account deactivation ---------------------------------------------------

export function useAdminDeactivationRequests() {
  return useQuery({
    queryKey: ["admin-deactivations"],
    queryFn: () => adminService.listDeactivationRequests(),
  });
}

export function useDecideDeactivationMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (input: { id: string; approve: boolean; note?: string }) =>
      adminService.decideDeactivation(input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-deactivations"] });
      // Approving suspends the account, so the people tables are stale too.
      queryClient.invalidateQueries({ queryKey: ["admin-users"] });
    },
  });
}

// --- Off-platform sale fees --------------------------------------------------

export function useAdminExternalSaleFees() {
  return useQuery({
    queryKey: ["admin-external-fees"],
    queryFn: () => adminService.listExternalSaleFees(),
  });
}

export function useDecideExternalSaleFeeMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (input: { id: string; approve: boolean; note?: string }) =>
      adminService.decideExternalSaleFee(input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-external-fees"] });
      // The artist's own view of the fee changes with the decision.
      queryClient.invalidateQueries({ queryKey: ["artist-penalties"] });
    },
  });
}
