"use client";

import "@/lib/motion-config";
import { useState } from "react";
import Image from "next/image";
import { motion } from "framer-motion";
import {
  QrCode,
  AudioLines,
  Scan,
  ShieldCheck,
  FileSearch,
  Fingerprint,
} from "lucide-react";
import { IdentityTimeline } from "./identity-timeline";
import { IdentityCard, type IdentityCardData } from "./identity-card";

const CARDS: IdentityCardData[] = [
  {
    title: "Identity",
    description: "A unique digital identity created for every artwork.",
    linkLabel: "Scan to view",
    href: "/verify",
    icon: Scan,
    badgePosition: "top-right",
    variant: "image",
    image: "/identity/identity-art.jpg",
    imageAlt: "Original portrait artwork with an archival identity tag",
    digitalId: "GZ-8F3A-7021",
  },
  {
    title: "Certificate",
    description: "Verified authenticity and ownership, digitally secured.",
    linkLabel: "View certificate",
    href: "/verify",
    icon: ShieldCheck,
    badgePosition: "bottom-right",
    variant: "image",
    image: "/identity/certificate-art.png",
    imageAlt: "Certificate still life with an embossed authenticity seal",
  },
  {
    title: "Provenance",
    description: "A transparent record of every ownership and transfer.",
    linkLabel: "View history",
    href: "/verify",
    icon: FileSearch,
    badgePosition: "bottom-right",
    variant: "image",
    image: "/identity/provenance-art.jpg",
    imageAlt: "Certificate of provenance document beside a classic masterpiece painting",
  },
  {
    title: "Legacy",
    description: "Preserving your artwork's story for future generations.",
    linkLabel: "Built to last",
    href: "/verify",
    icon: Fingerprint,
    badgePosition: "bottom-right",
    variant: "image",
    image: "/identity/legacy-art.png",
    imageAlt: "Curated art archive room with a legacy artwork",
  },
];

export function IdentitySection() {
  const [hovered, setHovered] = useState<number | null>(null);

  return (
    <section className="relative overflow-hidden py-16 sm:py-28 md:py-36">
      <div className="mx-auto max-w-[1280px] px-6 lg:px-10">
        <motion.div
          className="mx-auto max-w-2xl text-center"
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-10%" }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        >
          <p className="text-sm font-medium tracking-[0.14em] text-gold-bright">
            02 <span className="text-gold/50">•</span> THE IDENTITY OF ART
          </p>
          <h2 className="mt-4 text-balance font-display text-4xl leading-[1.15] font-semibold sm:text-5xl">
            Every artwork has a story.
            <br />
            <span className="text-gold-bright">We give it an identity.</span>
          </h2>
          <p className="mt-5 text-balance text-base text-muted-foreground">
            GalleryZone connects original art to a trusted digital identity that
            stays with it forever.
          </p>
        </motion.div>

        <div className="relative mt-16">
          <IdentityTimeline activeIndex={hovered} />

          <motion.div
            className="grid grid-cols-1 items-center gap-x-4 gap-y-10 sm:grid-cols-2 sm:gap-y-14 lg:grid-cols-[1fr_1fr_1.05fr_1fr_1fr]"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-10%" }}
            variants={{
              hidden: {},
              visible: { transition: { staggerChildren: 0.08 } },
            }}
          >
            <FadeItem className="flex justify-center">
              <IdentityCard
                card={CARDS[0]}
                onHover={(h) => setHovered(h ? 0 : null)}
              />
            </FadeItem>
            <FadeItem className="flex justify-center">
              <IdentityCard
                card={CARDS[1]}
                onHover={(h) => setHovered(h ? 1 : null)}
              />
            </FadeItem>

            <FadeItem className="hidden justify-center lg:flex lg:col-span-1 lg:-mt-[169px]">
              <div className="relative aspect-[3/4] w-40 sm:w-48 lg:w-full lg:max-w-[224px]">
                <motion.div
                  className="absolute inset-0 -z-10 scale-[1.7] rounded-full bg-gold/[0.08] blur-3xl"
                  animate={{
                    opacity: hovered !== null ? 1 : 0.7,
                    scale: hovered !== null ? 1.85 : 1.7,
                  }}
                  transition={{ duration: 0.5, ease: "easeOut" }}
                  aria-hidden
                />
                <div className="relative h-full w-full overflow-hidden rounded-sm border-2 border-gold/70 shadow-[0_28px_60px_-16px_rgba(0,0,0,0.75)]">
                  <Image
                    src="/identity/identity-painting.png"
                    alt="Original landscape painting representing an authenticated artwork"
                    fill
                    sizes="224px"
                    className="object-cover"
                  />
                </div>
              </div>
            </FadeItem>

            <FadeItem className="flex justify-center">
              <IdentityCard
                card={CARDS[2]}
                onHover={(h) => setHovered(h ? 2 : null)}
              />
            </FadeItem>
            <FadeItem className="flex justify-center">
              <IdentityCard
                card={CARDS[3]}
                onHover={(h) => setHovered(h ? 3 : null)}
              />
            </FadeItem>
          </motion.div>
        </div>

        <motion.div
          className="mx-auto mt-16 flex w-fit items-center gap-4 rounded-full border border-border bg-card px-5 py-3"
          initial={{ opacity: 0, y: 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.2 }}
        >
          <QrCode className="size-9 text-gold-bright" strokeWidth={1.25} />
          <div className="text-left">
            <p className="font-mono text-xs tracking-wide text-muted-foreground">
              DIGITAL ID: <span className="text-foreground">GZ-8F3A-7021</span>
            </p>
            <p className="text-xs text-muted-foreground">
              Scan to view artwork identity
            </p>
          </div>
          <AudioLines className="ml-2 size-5 text-gold/70" strokeWidth={1.5} />
        </motion.div>
      </div>
    </section>
  );
}

function FadeItem({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <motion.div
      className={className}
      variants={{
        hidden: { opacity: 0, y: 20 },
        visible: { opacity: 1, y: 0 },
      }}
      transition={{ duration: 0.5, ease: "easeOut" }}
    >
      {children}
    </motion.div>
  );
}
