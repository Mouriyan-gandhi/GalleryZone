import { useQuery } from "@tanstack/react-query";
import { isApiError } from "@/lib/api";
import { passportService } from "@/services/passportService";

// ['my-passports'] — the pieces the signed-in person owns, made or holds.
// `enabled` is the session cookie: it is only a hint, so a 401 (expired or
// missing token) is not retried and the caller falls back to the public view.
export function useMyPassports(enabled: boolean) {
  return useQuery({
    queryKey: ["my-passports"],
    queryFn: () => passportService.mine(),
    enabled,
    staleTime: 30_000,
    retry: (count, error) => !isApiError(error, 401) && count < 2,
  });
}
