import Image from "next/image";
import { cn } from "@/lib/utils";

// Honest "no image yet" state for artworks with no uploaded photo — shown
// instead of the shared stock fallback image so unrelated listings don't
// render as visual duplicates of each other.
export function ArtworkImagePlaceholder({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        "flex h-full w-full flex-col items-center justify-center gap-2 bg-muted/60",
        className,
      )}
    >
      <Image
        src="/brand/gz-logo-mark.png"
        alt=""
        width={80}
        height={80}
        className="h-8 w-8 opacity-25 grayscale sm:h-10 sm:w-10"
      />
      <span className="text-[10px] font-medium tracking-wide text-muted-foreground sm:text-[11px]">
        Image coming soon
      </span>
    </div>
  );
}
