"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { ArrowRight, BadgeCheck, History, QrCode } from "lucide-react";
import { artworkQrDataUrl } from "@/lib/qr";
import { isPlaceholderImage } from "@/lib/api-mappers";
import type { ArtworkSummary } from "@/types/artwork";

const FEATURES = [
  { icon: BadgeCheck, label: "Verified artist identity" },
  { icon: History, label: "Provenance history" },
  { icon: QrCode, label: "Verify with one scan" },
];

// The passport shown is a real one: this piece's details, and a QR code that
// opens its public verification page.
export function PassportBand({ artwork }: { artwork?: ArtworkSummary }) {
  const [qr, setQr] = useState<string | null>(null);
  const artworkId = artwork?.id;

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

  if (!artwork) return null;

  return (
    <section className="mx-auto w-full max-w-[1440px] px-5 pb-16 sm:px-6 lg:px-10 lg:pb-20">
      <div className="grid items-center gap-10 rounded-2xl border border-border bg-card/40 p-6 sm:p-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)_minmax(0,0.75fr)] lg:gap-12 lg:p-12">
        <div className="flex flex-col">
          <p className="text-[11px] font-medium tracking-[0.22em] text-gold-bright uppercase">
            Trust in every artwork
          </p>
          <h2 className="mt-3 font-display text-3xl leading-tight font-semibold text-foreground sm:text-4xl">
            GZ Digital Passport
          </h2>
          <p className="mt-4 max-w-md text-[0.95rem] leading-relaxed text-muted-foreground">
            Every artwork comes with a digital passport: provenance details and
            artist verification, so you can collect with complete confidence.
          </p>
          <Link
            href="/about#how-it-works"
            className="mt-7 inline-flex h-11 w-fit items-center gap-2 rounded-full border border-gold/60 px-5 text-sm font-medium text-gold-bright transition-[background-color,transform] duration-150 ease-out hover:bg-gold/10 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.97]"
          >
            Learn more
            <ArrowRight className="size-4" strokeWidth={1.75} />
          </Link>
        </div>

        <PassportCard artwork={artwork} qr={qr} />

        <ul className="flex flex-col gap-4">
          {FEATURES.map(({ icon: Icon, label }) => (
            <li key={label} className="flex items-center gap-3 text-sm text-foreground/85">
              <span className="flex size-9 shrink-0 items-center justify-center rounded-lg border border-gold/40 text-gold-bright">
                <Icon className="size-4" strokeWidth={1.75} />
              </span>
              {label}
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}

// A physical-feeling card, dark in both themes, so its ink is fixed rather
// than theme tokens.
function PassportCard({ artwork, qr }: { artwork: ArtworkSummary; qr: string | null }) {
  return (
    <div className="relative mx-auto w-full max-w-md overflow-hidden rounded-xl border border-[#e9c57a]/25 bg-[linear-gradient(145deg,#1f1a11,#0e0c08_65%)] p-5 text-[#f1ece0] shadow-[0_30px_60px_-25px_rgb(0_0_0/0.8)] sm:p-6 lg:-rotate-3">
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
