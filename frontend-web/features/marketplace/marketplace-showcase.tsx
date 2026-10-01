"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useReducedMotion } from "framer-motion";
import {
  ArrowRight,
  BadgeCheck,
  ChevronLeft,
  ChevronRight,
  FileCheck2,
  History,
  Nfc,
  Pause,
  Play,
  QrCode,
  Smartphone,
} from "lucide-react";
import { isPlaceholderImage } from "@/lib/api-mappers";
import { artworkQrDataUrl } from "@/lib/qr";
import { cn } from "@/lib/utils";
import {
  ARTWORK_RARITY_OPTIONS,
  type ArtworkRarity,
  type ArtworkSummary,
} from "@/types/artwork";

const SLIDE_MS = 7000;

// The one paid placement. Swap this object for a real advertiser's creative;
// the slide, its "Ad" label and its place in the rotation stay the same.
const AD = {
  sponsor: "GalleryZone Advertising",
  headline: "Your brand, in front of art lovers",
  body: "This slot sits between the passport story and the rank guide on every marketplace visit. Tell us about your gallery, frame shop or studio and we will send rates.",
  cta: "Advertise with us",
  href: "/contact",
  images: ["/artworks/landscape.png", "/artworks/portrait-woman.png", "/artworks/bird.png"],
};

type SlideId = "passport" | "nfc" | "ad" | "ranks";

const SLIDE_LABEL: Record<SlideId, string> = {
  passport: "GZ Digital Passport",
  nfc: "Tap to verify",
  ad: "Advertisement",
  ranks: "Ranks",
};

// Dark in both themes, like a physical card, so its ink is fixed rather than theme tokens.
const DARK_CARD =
  "relative overflow-hidden rounded-xl border border-[#e9c57a]/25 bg-[linear-gradient(145deg,#1f1a11,#0e0c08_65%)] text-[#f1ece0] shadow-[0_30px_60px_-25px_rgb(0_0_0/0.8)]";


const EYEBROW = "text-[11px] font-medium tracking-[0.22em] text-gold-bright uppercase";
const HEADING =
  "mt-3 font-display text-3xl leading-tight font-semibold text-foreground sm:text-4xl";
const BODY = "mt-4 max-w-md text-[0.95rem] leading-relaxed text-muted-foreground";
const OUTLINE_CTA =
  "mt-7 inline-flex h-11 w-fit items-center gap-2 rounded-full border border-gold/60 px-5 text-sm font-medium text-gold-bright transition-[background-color,transform] duration-150 ease-out hover:bg-gold/10 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.97]";
const SOLID_CTA =
  "mt-7 inline-flex h-11 w-fit items-center gap-2 rounded-full bg-gold px-6 text-sm font-semibold text-[#171310] transition-[background-color,transform] duration-150 ease-out hover:bg-gold-bright focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.97] dark:bg-gold-bright dark:hover:bg-gold";
const THREE_COLUMNS =
  "grid w-full items-center gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)_minmax(0,0.75fr)] lg:gap-12";
const TWO_COLUMNS = "grid w-full items-center gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.9fr)] lg:gap-12";

interface MarketplaceShowcaseProps {
  /** A real listed piece, used for the passport and tag examples. */
  artwork?: ArtworkSummary;
  /** Live count of works per rank. */
  rankCounts: Partial<Record<ArtworkRarity, number>>;
  /** Filters the catalogue to one rank. */
  onPickRank: (rank: ArtworkRarity) => void;
  loading: boolean;
}

export function MarketplaceShowcase({ artwork, rankCounts, onPickRank, loading }: MarketplaceShowcaseProps) {
  const reduceMotion = useReducedMotion();
  const sectionRef = useRef<HTMLElement>(null);
  const swipe = useRef<{ x: number; y: number } | null>(null);
  const [index, setIndex] = useState(0);
  const [paused, setPaused] = useState(false);
  const [hovering, setHovering] = useState(false);
  const [keyboardFocus, setKeyboardFocus] = useState(false);
  const [inView, setInView] = useState(true);
  const [qr, setQr] = useState<string | null>(null);
  const artworkId = artwork?.id;

  const slides = useMemo<SlideId[]>(
    () => (artworkId ? ["passport", "nfc", "ad", "ranks"] : ["ad", "ranks"]),
    [artworkId],
  );

  useEffect(() => {
    if (!artworkId) return;
    let live = true;
    void artworkQrDataUrl(artworkId, 240).then((url) => {
      if (live) setQr(url);
    });
    return () => {
      live = false;
    };
  }, [artworkId]);

  // A slideshow nobody can see should not burn through its slides.
  useEffect(() => {
    const node = sectionRef.current;
    if (!node) return;
    const observer = new IntersectionObserver(([entry]) => setInView(entry.isIntersecting), { threshold: 0.35 });
    observer.observe(node);
    return () => observer.disconnect();
  }, [loading]);

  const count = slides.length;
  const running = !loading && !reduceMotion && !paused && !hovering && !keyboardFocus && inView;

  // Advances on a plain timeout; any click, swipe or hover restarts the wait.
  useEffect(() => {
    if (!running) return;
    const timer = window.setTimeout(() => setIndex((i) => (i + 1) % count), SLIDE_MS);
    return () => window.clearTimeout(timer);
  }, [running, index, count]);

  if (loading) return null;

  const go = (to: number) => setIndex(((to % count) + count) % count);

  return (
    <section
      ref={sectionRef}
      aria-roledescription="carousel"
      aria-label="About GalleryZone"
      onMouseEnter={() => setHovering(true)}
      onMouseLeave={() => setHovering(false)}
      // Only keyboard focus holds the show: a mouse click on a dot must not freeze it.
      onFocus={(e) => setKeyboardFocus(e.target.matches(":focus-visible"))}
      onBlur={(e) => {
        if (!e.currentTarget.contains(e.relatedTarget)) setKeyboardFocus(false);
      }}
      className="mx-auto w-full max-w-[1440px] px-5 pb-16 sm:px-6 lg:px-10 lg:pb-20"
    >
      <div className="overflow-hidden rounded-2xl border border-border bg-card/40">
        <div
          aria-live={running ? "off" : "polite"}
          className="grid touch-pan-y"
          onPointerDown={(e) => {
            if (e.pointerType !== "mouse") swipe.current = { x: e.clientX, y: e.clientY };
          }}
          onPointerUp={(e) => {
            const start = swipe.current;
            swipe.current = null;
            if (!start) return;
            const dx = e.clientX - start.x;
            if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(e.clientY - start.y) * 1.5) go(index + (dx < 0 ? 1 : -1));
          }}
          onPointerCancel={() => (swipe.current = null)}
        >
          {slides.map((id, i) => {
            const active = i === index;
            return (
              // All slides share one grid cell, so the box is as tall as the tallest and never jumps.
              <div
                key={id}
                role="group"
                aria-roledescription="slide"
                aria-label={`${i + 1} of ${count}: ${SLIDE_LABEL[id]}`}
                aria-hidden={!active}
                inert={!active}
                data-active={active}
                className="group/slide relative col-start-1 row-start-1 flex flex-col justify-center p-6 transition-opacity duration-300 motion-reduce:transition-none data-[active=false]:pointer-events-none data-[active=false]:opacity-0 sm:p-10 lg:p-12"
              >
                {id === "passport" && artwork && <PassportSlide artwork={artwork} qr={qr} />}
                {id === "nfc" && artwork && <NfcSlide artwork={artwork} />}
                {id === "ad" && <AdSlide />}
                {id === "ranks" && <RanksSlide counts={rankCounts} onPick={onPickRank} />}
              </div>
            );
          })}
        </div>

        <div className="flex items-center justify-between gap-4 border-t border-border/60 px-6 py-3 sm:px-10 lg:px-12">
          <div className="flex items-center gap-1">
            {slides.map((id, i) => (
              <button
                key={id}
                type="button"
                aria-label={`Show slide ${i + 1}: ${SLIDE_LABEL[id]}`}
                aria-current={i === index}
                onClick={() => go(i)}
                className="flex h-6 items-center rounded-full px-0.5 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
              >
                <span
                  className={cn(
                    "block h-1.5 rounded-full",
                    i === index ? "w-6 bg-gold-bright" : "w-1.5 bg-foreground/25 hover:bg-foreground/40",
                  )}
                />
              </button>
            ))}
          </div>

          <div className="flex items-center gap-1">
            {!reduceMotion && (
              <ControlButton
                label={paused ? "Play slideshow" : "Pause slideshow"}
                onClick={() => setPaused((p) => !p)}
              >
                {paused ? <Play className="size-4" strokeWidth={1.75} /> : <Pause className="size-4" strokeWidth={1.75} />}
              </ControlButton>
            )}
            <ControlButton label="Previous slide" onClick={() => go(index - 1)}>
              <ChevronLeft className="size-4" strokeWidth={1.75} />
            </ControlButton>
            <ControlButton label="Next slide" onClick={() => go(index + 1)}>
              <ChevronRight className="size-4" strokeWidth={1.75} />
            </ControlButton>
          </div>
        </div>
      </div>
    </section>
  );
}

function ControlButton({
  label,
  onClick,
  children,
}: {
  label: string;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      aria-label={label}
      title={label}
      onClick={onClick}
      className="flex size-9 items-center justify-center rounded-full border border-border text-foreground/80 transition-[background-color,border-color,color,transform] duration-150 ease-out hover:border-gold/50 hover:text-foreground focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.94]"
    >
      {children}
    </button>
  );
}

function Checklist({ items }: { items: { icon: typeof BadgeCheck; label: string }[] }) {
  return (
    <ul className={"grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-1"}>
      {items.map(({ icon: Icon, label }) => (
        <li key={label} className="flex items-center gap-3 text-sm text-foreground/85">
          <span className="flex size-9 shrink-0 items-center justify-center rounded-lg border border-gold/40 text-gold-bright">
            <Icon className="size-4" strokeWidth={1.75} />
          </span>
          {label}
        </li>
      ))}
    </ul>
  );
}

/* ── slide 1: passport ─────────────────────────────────────────── */

const PASSPORT_FEATURES = [
  { icon: BadgeCheck, label: "Verified artist identity" },
  { icon: History, label: "Provenance history" },
  { icon: QrCode, label: "Verify with one scan" },
];

// The passport shown is a real one: this piece's details, and a QR code that
// opens its public verification page.
function PassportSlide({ artwork, qr }: { artwork: ArtworkSummary; qr: string | null }) {
  return (
    <div className={THREE_COLUMNS}>
      <div className={"flex flex-col"}>
        <p className={EYEBROW}>Trust in every artwork</p>
        <h2 className={HEADING}>GZ Digital Passport</h2>
        <p className={BODY}>
          Every artwork comes with a digital passport: provenance details and
          artist verification, so you can collect with complete confidence.
        </p>
        <Link href="/about#how-it-works" className={OUTLINE_CTA}>
          Learn more
          <ArrowRight className="size-4" strokeWidth={1.75} />
        </Link>
      </div>

      <div >
        <PassportCard artwork={artwork} qr={qr} />
      </div>

      <Checklist items={PASSPORT_FEATURES} />
    </div>
  );
}

function PassportCard({ artwork, qr }: { artwork: ArtworkSummary; qr: string | null }) {
  return (
    <div className={cn(DARK_CARD, "mx-auto w-full max-w-md p-5 sm:p-6 lg:-rotate-3")}>
      <div className="pointer-events-none absolute -top-20 -right-20 size-56 rounded-full bg-[radial-gradient(circle,rgb(233_197_122/0.14),transparent_70%)]" />

      <div className="relative flex items-center gap-3 border-b border-white/10 pb-3">
        <Image src="/brand/gz-logo.png" alt="" width={822} height={560} className="h-7 w-auto" />
        <p className="font-display text-lg">Digital Passport</p>
      </div>

      <div className="relative mt-4 grid grid-cols-[minmax(0,1fr)_auto] items-start gap-4 sm:grid-cols-[4.5rem_minmax(0,1fr)_auto]">
        <div className="relative hidden aspect-[4/5] overflow-hidden rounded-md bg-white/5 ring-1 ring-white/10 sm:block">
          {!isPlaceholderImage(artwork.thumbnailUrl) && (
            <Image src={artwork.thumbnailUrl} alt="" fill sizes="72px" className="object-cover" />
          )}
        </div>

        <dl className="flex min-w-0 flex-col gap-2.5">
          <PassportField label="Title" value={artwork.title} />
          <PassportField label="Artist" value={artwork.artistName} />
        </dl>

        <div className="flex flex-col items-center gap-1.5">
          {qr ? (
            <Image
              src={qr}
              alt={`QR code for the passport of ${artwork.title}`}
              width={80}
              height={80}
              unoptimized
              className="size-20 rounded bg-white"
            />
          ) : (
            <div className="size-20 animate-pulse rounded bg-white/10" />
          )}
          <span className="text-[10px] text-[#9c9686]">Scan to verify</span>
        </div>
      </div>
    </div>
  );
}

function PassportField({ label, value }: { label: string; value: string }) {
  return (
    <div className="min-w-0">
      <dt className="text-[10px] text-[#9c9686]">{label}</dt>
      <dd className="truncate text-sm">{value}</dd>
    </div>
  );
}

/* ── slide 2: NFC tag ──────────────────────────────────────────── */

const NFC_FEATURES = [
  { icon: Nfc, label: "Tap the tag with a phone" },
  { icon: QrCode, label: "Or scan the QR code" },
  { icon: FileCheck2, label: "Opens the public passport" },
  { icon: Smartphone, label: "No app or account needed" },
];

// The tag and the QR code resolve to the same page, /verify/<id>, so the
// example links to a real one.
function NfcSlide({ artwork }: { artwork: ArtworkSummary }) {
  return (
    <div className={THREE_COLUMNS}>
      <div className={"flex flex-col"}>
        <p className={EYEBROW}>Physical pieces</p>
        <h2 className={HEADING}>Tap to verify</h2>
        <p className={BODY}>
          A physical piece carries a tag linked to its passport. Tap a phone to
          the tag, or scan the QR code, and the passport opens straight away.
        </p>
        <Link href={`/verify/${artwork.id}`} className={OUTLINE_CTA}>
          Try it on this piece
          <ArrowRight className="size-4" strokeWidth={1.75} />
        </Link>
      </div>

      <div
        className="mx-auto flex w-full max-w-md items-center justify-between gap-2 sm:gap-4"
      >
        <div className="flex shrink-0 flex-col items-center gap-2">
          <div className="flex size-20 items-center justify-center rounded-full border border-gold/50 bg-[radial-gradient(circle_at_30%_25%,#3a2f1a,#14100a)] text-gold-bright shadow-[0_18px_40px_-18px_rgb(0_0_0/0.8)] sm:size-24">
            <Nfc className="size-9" strokeWidth={1.5} />
          </div>
          <span className="text-xs text-muted-foreground">NFC tag</span>
        </div>

        <div aria-hidden="true" className="flex items-center text-gold-bright">
          {[0, 1, 2].map((n) => (
            <ChevronRight
              key={n}
              strokeWidth={2}
              className="-mx-1 size-5"
            />
          ))}
        </div>

        <div className={cn(DARK_CARD, "w-full max-w-[13rem] p-4")}>
          <div className="relative flex items-center gap-1.5 text-[11px] font-medium text-emerald-400">
            <BadgeCheck className="size-4" strokeWidth={1.75} />
            Verified
          </div>
          <div className="relative mt-3 aspect-[4/3] overflow-hidden rounded-md bg-white/5 ring-1 ring-white/10">
            {!isPlaceholderImage(artwork.thumbnailUrl) && (
              <Image src={artwork.thumbnailUrl} alt="" fill sizes="208px" className="object-cover" />
            )}
          </div>
          <p className="relative mt-3 truncate font-display text-base">{artwork.title}</p>
          <p className="relative truncate text-xs text-[#9c9686]">{artwork.artistName}</p>
        </div>
      </div>

      <Checklist items={NFC_FEATURES} />
    </div>
  );
}

/* ── slide 3: ad ───────────────────────────────────────────────── */

function AdSlide() {
  return (
    <div className={TWO_COLUMNS}>
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(60%_90%_at_88%_15%,color-mix(in_oklab,var(--gold-bright)_11%,transparent),transparent)]"
      />
      <div className={"flex flex-col"}>
        <p className="flex items-center gap-2">
          <span className="rounded border border-foreground/40 px-1.5 py-0.5 text-[10px] font-semibold tracking-[0.14em] text-foreground/80 uppercase">
            Ad
          </span>
          <span className="text-xs text-muted-foreground">{AD.sponsor}</span>
        </p>
        <h2 className={HEADING}>{AD.headline}</h2>
        <p className={BODY}>{AD.body}</p>
        <Link href={AD.href} className={SOLID_CTA}>
          {AD.cta}
          <ArrowRight className="size-4" strokeWidth={2} />
        </Link>
      </div>

      <div
        aria-hidden="true"
        className={"grid grid-cols-3 gap-3 sm:gap-4"}
      >
        {AD.images.map((src) => (
          <div
            key={src}
            className={cn(
              "relative aspect-[6/7] overflow-hidden rounded-xl ring-1 ring-border",
            )}
          >
            <Image src={src} alt="" fill sizes="(min-width: 1024px) 22vw, 30vw" className="object-cover" />
          </div>
        ))}
      </div>
    </div>
  );
}

/* ── slide 4: ranks ────────────────────────────────────────────── */

function RanksSlide({
  counts,
  onPick,
}: {
  counts: Partial<Record<ArtworkRarity, number>>;
  onPick: (rank: ArtworkRarity) => void;
}) {
  return (
    <div className={TWO_COLUMNS}>
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(55%_85%_at_8%_35%,color-mix(in_oklab,var(--gold-bright)_13%,transparent),transparent)]"
      />
      <div className={"flex flex-col"}>
        <p className={EYEBROW}>Ranked by GalleryZone</p>
        <h2 className={HEADING}>Every painting has a rank</h2>
        <p className="mt-4 max-w-md text-[0.95rem] leading-relaxed text-foreground/80">
          Artists do not pick it. GalleryZone reviews each work and gives it
          one of four ranks before it goes live. Choose one to see its works.
        </p>
      </div>

      <div className={"grid gap-4 sm:grid-cols-2"}>
        {ARTWORK_RARITY_OPTIONS.map((option) => (
          <RankCard
            key={option.value}
            option={option}
            n={counts[option.value] ?? 0}
            onPick={() => onPick(option.value)}
          />
        ))}
      </div>
    </div>
  );
}

// Each rank's own colour: its tile, the card's tint and its edge. The same
// four hues the marketplace cards stamp on a piece, a little brighter so they
// hold up on the dark card.
const RANK_COLOR: Record<ArtworkRarity, string> = {
  R: "#e5484d",
  U: "#12b886",
  O: "#e0a63e",
  S: "#9aa4b2",
};

const RANK_CARD =
  "relative flex items-start gap-4 overflow-hidden rounded-xl border border-[color-mix(in_oklab,var(--rank)_38%,var(--border))] bg-[linear-gradient(135deg,color-mix(in_oklab,var(--rank)_17%,transparent),transparent_70%)] p-5 text-left";

function RankCard({
  option,
  n,
  onPick,
}: {
  option: (typeof ARTWORK_RARITY_OPTIONS)[number];
  n: number;
  onPick: () => void;
}) {
  const style = { "--rank": RANK_COLOR[option.value] } as React.CSSProperties;
  const body = (
    <>
      <span className="flex size-14 shrink-0 items-center justify-center rounded-xl bg-[linear-gradient(145deg,var(--rank),color-mix(in_oklab,var(--rank)_52%,black))] text-2xl font-bold text-white shadow-[0_10px_24px_-10px_var(--rank)] ring-1 ring-white/25">
        {option.value}
      </span>
      <span className="flex min-w-0 flex-1 flex-col gap-1.5">
        <span className="flex flex-wrap items-center gap-x-2.5 gap-y-1">
          <span className="font-display text-lg font-semibold text-foreground">{option.label}</span>
          <span
            className={cn(
              "rounded-full px-2.5 py-0.5 text-xs font-medium tabular-nums",
              n > 0
                ? "bg-[color-mix(in_oklab,var(--rank)_26%,transparent)] text-foreground"
                : "bg-foreground/10 text-foreground/70",
            )}
          >
            {n === 0 ? "None yet" : `${n} ${n === 1 ? "work" : "works"}`}
          </span>
        </span>
        <span className="text-sm leading-snug text-foreground/75">{option.description}</span>
        {n > 0 && (
          <span className="mt-0.5 inline-flex items-center gap-1 text-xs font-medium text-gold-bright">
            View works
            <ArrowRight className="size-3.5 transition-transform duration-150 group-hover/rank:translate-x-0.5" strokeWidth={2} />
          </span>
        )}
      </span>
    </>
  );

  // A rank with no works is still part of the guide, so it stays at full
  // strength; it just isn't a link to an empty list.
  if (n === 0) {
    return (
      <div className={RANK_CARD} style={style}>
        {body}
      </div>
    );
  }
  return (
    <button
      type="button"
      onClick={onPick}
      style={style}
      className={cn(
        RANK_CARD,
        "group/rank transition-[border-color,box-shadow,transform] duration-150 ease-out hover:-translate-y-0.5 hover:border-[color-mix(in_oklab,var(--rank)_75%,transparent)] hover:shadow-[0_18px_40px_-26px_var(--rank)] focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.98]",
      )}
    >
      {body}
    </button>
  );
}
