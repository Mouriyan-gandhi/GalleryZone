"use client";

import { useEffect, useState } from "react";
import { qrDataUrl } from "@/lib/qr";

// A QR for any URL (the artwork QR has its own component: it always encodes the
// artwork's verify URL). Used where a phone has to be pointed at something, such
// as the app's store page.
export function QrImage({ value, size = 128, alt }: { value: string; size?: number; alt: string }) {
  const [src, setSrc] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    qrDataUrl(value, size * 2)
      .then((url) => {
        if (!cancelled) setSrc(url);
      })
      .catch(() => {
        if (!cancelled) setSrc(null);
      });
    return () => {
      cancelled = true;
    };
  }, [value, size]);

  return (
    <div className="overflow-hidden rounded-md border border-gold/30 bg-white p-1.5" style={{ width: size + 12, height: size + 12 }}>
      {src ? (
        // eslint-disable-next-line @next/next/no-img-element -- data URL, not an optimisable asset
        <img src={src} alt={alt} width={size} height={size} />
      ) : (
        <div className="size-full animate-pulse bg-muted" aria-hidden="true" />
      )}
    </div>
  );
}
