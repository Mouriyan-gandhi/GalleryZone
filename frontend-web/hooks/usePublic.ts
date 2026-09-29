import { useQuery } from "@tanstack/react-query";
import { artistService } from "@/services/artworkService";

export function useArtistDirectory() {
  return useQuery({ queryKey: ["artists", "directory"], queryFn: () => artistService.list(), staleTime: 60_000 });
}
