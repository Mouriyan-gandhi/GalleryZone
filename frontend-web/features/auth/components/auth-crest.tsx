import Image from "next/image";

// Centered wordmark shown atop the form card on every Auth screen — distinct
// from AuthLayoutPanel's small top-left Wordmark, which lives in the
// separate artwork showcase panel and stays untouched.
export function AuthCrest() {
  return (
    <div className="flex flex-col items-center gap-1 text-center">
      <Image
        src="/brand/gz-logo.png"
        alt="GalleryZone"
        width={822}
        height={560}
        priority
        className="h-24 w-auto"
      />
      <span className="text-sm font-medium tracking-[0.25em] text-foreground">
        GALLERYZONE
      </span>
      {/* The old line was two words, which is why it carried 0.3em tracking.
          A full sentence at that spacing runs past the form card and breaks in
          the wrong places, so the letterspacing comes down and the line is
          allowed to balance across two rows on narrow screens. */}
      <span className="max-w-[15rem] text-[0.7rem] leading-relaxed tracking-[0.12em] text-balance text-muted-foreground">
        Art, that Connects. Culture that inspires.
      </span>
      <span className="mt-2 h-px w-10 bg-gold/60" />
    </div>
  );
}
