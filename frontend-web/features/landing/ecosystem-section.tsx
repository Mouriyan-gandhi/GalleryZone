"use client";

import "@/lib/motion-config";
import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import { ArrowRight } from "lucide-react";
import { ECOSYSTEM_PERSONAS } from "./ecosystem-data";

export function EcosystemSection() {
  const [activeIndex, setActiveIndex] = useState(0);
  const persona = ECOSYSTEM_PERSONAS[activeIndex];

  return (
    <section className="relative overflow-hidden py-16 sm:py-28 md:py-36">
      <div className="mx-auto max-w-[1280px] px-6 lg:px-10">
        <motion.div
          className="flex flex-col gap-8 md:flex-row md:items-end md:justify-between"
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-10%" }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        >
          <div>
            <p className="text-sm font-medium tracking-[0.14em] text-gold-bright">
              03 <span className="text-gold/50">•</span> THE ART ECOSYSTEM
            </p>
            <h2 className="mt-4 text-balance font-display text-4xl leading-[1.15] font-semibold sm:text-5xl">
              Where art
              <br />
              <span className="text-gold-bright">finds its people.</span>
            </h2>
          </div>
          <p className="max-w-sm text-balance text-base text-muted-foreground">
            GalleryZone brings artists, collectors and art networks together
            around original work.
          </p>
        </motion.div>

        <motion.div
          className="mt-14 grid grid-cols-1 gap-5 lg:grid-cols-[1fr_2.4fr] lg:items-stretch"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-10%" }}
          transition={{ duration: 0.6, ease: "easeOut", delay: 0.1 }}
        >
          <nav className="hidden lg:flex flex-col gap-1 rounded-lg border border-border bg-card p-2">
            {ECOSYSTEM_PERSONAS.map((p, i) => {
              const Icon = p.navIcon;
              const active = i === activeIndex;
              return (
                <button
                  key={p.key}
                  type="button"
                  onMouseEnter={() => setActiveIndex(i)}
                  onFocus={() => setActiveIndex(i)}
                  onClick={() => setActiveIndex(i)}
                  className={`flex items-center gap-3 rounded-md border px-4 py-3.5 text-left text-sm transition-colors ${
                    active
                      ? "border-gold/50 bg-gold/10 text-foreground"
                      : "border-transparent text-muted-foreground hover:text-foreground"
                  }`}
                >
                  <Icon
                    className={`size-4 shrink-0 ${active ? "text-gold-bright" : "text-muted-foreground"}`}
                    strokeWidth={1.75}
                  />
                  <span className="flex-1">{p.navLabel}</span>
                  <ArrowRight
                    className={`size-3.5 shrink-0 ${active ? "text-gold-bright" : "text-muted-foreground/50"}`}
                  />
                </button>
              );
            })}
          </nav>

          {/* Mobile Navigation (2x2 Pill Grid) */}
          <div className="grid grid-cols-2 gap-2 sm:gap-3 lg:hidden">
            {ECOSYSTEM_PERSONAS.map((p, i) => (
              <button
                key={p.key}
                type="button"
                onClick={() => setActiveIndex(i)}
                className={`flex items-center justify-center text-center rounded-full px-2 py-2.5 text-xs font-medium transition-colors ${
                  i === activeIndex
                    ? "bg-gold/15 text-gold-bright border border-gold/40 shadow-[0_0_15px_rgba(200,154,74,0.1)]"
                    : "bg-card border border-border text-muted-foreground hover:bg-card/60"
                }`}
              >
                {p.navLabel === "For Galleries & Aggregators" ? "For Galleries" : p.navLabel}
              </button>
            ))}
          </div>

          <div className="relative min-h-[320px] overflow-hidden rounded-lg border border-border bg-card p-6 lg:p-7">
            <AnimatePresence mode="wait">
              <motion.div
                key={persona.key}
                className="relative z-10 max-w-[280px]"
                initial={{ opacity: 0, x: 16 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -16 }}
                transition={{ duration: 0.25, ease: "easeOut" }}
                drag="x"
                dragConstraints={{ left: 0, right: 0 }}
                dragElastic={0.2}
                onDragEnd={(e, { offset, velocity }) => {
                  if (offset.x < -50 || velocity.x < -500) {
                    setActiveIndex((activeIndex + 1) % ECOSYSTEM_PERSONAS.length);
                  } else if (offset.x > 50 || velocity.x > 500) {
                    setActiveIndex(
                      (activeIndex - 1 + ECOSYSTEM_PERSONAS.length) %
                        ECOSYSTEM_PERSONAS.length,
                    );
                  }
                }}
              >
                <p className="text-xs font-medium tracking-[0.14em] text-gold-bright">
                  {persona.eyebrow}
                </p>
                <h3 className="mt-2.5 font-display text-3xl font-semibold text-foreground">
                  {persona.headline}
                </h3>
                <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
                  {persona.body}
                </p>

                <div className="mt-4 border-t border-border pt-4 pointer-events-none">
                  <ul className="flex flex-col gap-3">
                    {persona.bullets.map((bullet) => {
                      const BulletIcon = bullet.icon;
                      return (
                        <li
                          key={bullet.text}
                          className="flex items-start gap-3.5"
                        >
                          <BulletIcon className="mt-0.5 size-4 shrink-0 text-gold-bright" />
                          <span className="text-sm leading-relaxed text-foreground/90">
                            {bullet.text}
                          </span>
                        </li>
                      );
                    })}
                  </ul>
                </div>

                <Link
                  href={persona.href}
                  className="group mt-5 inline-flex items-center gap-2 rounded-md border border-gold/60 px-5 py-3 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
                >
                  {persona.ctaLabel}
                  <ArrowRight className="size-4 transition-transform group-hover:translate-x-0.5" />
                </Link>
              </motion.div>
            </AnimatePresence>

            <div className="pointer-events-none absolute top-8 -right-14 bottom-0 hidden w-[380px] lg:block">
              <AnimatePresence mode="wait">
                <motion.div
                  key={persona.key}
                  className="h-full w-full overflow-hidden rounded-tl-xl border border-border bg-background shadow-[0_30px_70px_-20px_rgba(0,0,0,0.6)]"
                  initial={{ opacity: 0, x: 16 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -16 }}
                  transition={{ duration: 0.3, ease: "easeOut" }}
                >
                  <div className="flex items-center gap-1.5 border-b border-border bg-secondary px-3.5 py-2.5">
                    <span className="size-2 rounded-full bg-muted-foreground/35" />
                    <span className="size-2 rounded-full bg-muted-foreground/35" />
                    <span className="size-2 rounded-full bg-muted-foreground/35" />
                  </div>
                  <div className="relative h-[calc(100%-2.625rem)] w-full">
                    <Image
                      src={persona.previewImage}
                      alt={persona.previewAlt}
                      fill
                      sizes="380px"
                      className="object-cover"
                    />
                  </div>
                </motion.div>
              </AnimatePresence>
            </div>
          </div>
        </motion.div>

        <div className="mt-10 flex flex-col items-center gap-6">
          <div className="flex items-center justify-center gap-2">
            {ECOSYSTEM_PERSONAS.map((p, i) => (
              <button
                key={p.key}
                type="button"
                aria-label={`Show ${p.navLabel}`}
                onClick={() => setActiveIndex(i)}
                className={`rounded-full transition-all ${
                  i === activeIndex
                    ? "h-2 w-6 bg-gold"
                    : "size-2 bg-muted-foreground/40 hover:bg-muted-foreground/70"
                }`}
              />
            ))}
          </div>
          <p className="text-[10px] font-medium tracking-[0.2em] text-muted-foreground/60 uppercase lg:hidden">
            &larr; Swipe to explore &rarr;
          </p>
        </div>
      </div>
    </section>
  );
}
