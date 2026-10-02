import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";

interface ArtworkCardSkeletonProps {
  className?: string;
}

// Mirrors ArtworkCard's footprint so a grid doesn't jump when skeletons swap
// for real cards.
export function ArtworkCardSkeleton({ className }: ArtworkCardSkeletonProps) {
  return (
    <div className={cn("flex flex-col rounded-lg border border-border bg-card p-2", className)}>
      <Skeleton className="aspect-[4/5] w-full rounded-md" />
      <div className="flex flex-col gap-1.5 px-1.5 pt-3 pb-1">
        <Skeleton className="h-4 w-3/4" />
        <Skeleton className="h-3.5 w-1/2" />
        <Skeleton className="mt-1 h-3 w-2/3" />
        <Skeleton className="h-3 w-1/3" />
        <Skeleton className="mt-1.5 h-4 w-1/3" />
      </div>
    </div>
  );
}
