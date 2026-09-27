"use client";

import "@/lib/motion-config";
import Image from "next/image";
import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowRight, Users, Sparkles } from "lucide-react";
import { OVERVIEW_PILLARS } from "./about-data";

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
};

const collageImage = "/artworks/landscape.png";

export function AboutOverviewSection() {
  return (
    <section className="relative overflow-hidden pt-12 pb-14 sm:pt-16 sm:pb-20 md:pt-20 md:pb-28">
      <div className="mx-auto max-w-[1400px] px-6 lg:px-10">
        {/* Hero */}
        <motion.div
          className="mx-auto max-w-2xl text-center"
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-10%" }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        >
          <span className="inline-flex items-center gap-2 rounded-full border border-border bg-card px-3 py-1 text-xs font-medium tracking-[0.1em] text-muted-foreground uppercase">
            About GalleryZone
          </span>
          <h1 className="mt-5 text-balance font-display text-4xl leading-[1.15] font-semibold sm:text-5xl">
            The art market,
            <br />
            built to protect{" "}
            <span className="text-gold-bright">the artist.</span>
          </h1>
          <p className="mt-5 text-balance text-base leading-relaxed text-muted-foreground">
            GalleryZone connects independent artists with verified galleries and
            collectors worldwide, keeping every listed price confidential and
            every artwork&rsquo;s authenticity verifiable.
          </p>

          <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
            <Link
              href="/artist-survey"
              className="inline-flex items-center gap-2 rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/80"
            >
              Become an Early Artist
              <ArrowRight className="size-4" />
            </Link>
            <Link
              href="#how-it-works"
              className="inline-flex items-center gap-2 rounded-md border border-border bg-card px-5 py-2.5 text-sm font-medium text-foreground transition-colors hover:bg-muted"
            >
              How it works
            </Link>
          </div>
        </motion.div>

        {/* Collage + community panel */}
        <motion.div
          className="mt-16 grid grid-cols-1 gap-5 lg:grid-cols-[1.6fr_1fr]"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-10%" }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        >
          <div className="relative aspect-4/3 overflow-hidden rounded-2xl border border-border sm:aspect-video lg:aspect-auto">
            <Image
              src={collageImage}
              alt=""
              fill
              sizes="(min-width: 1024px) 60vw, 100vw"
              className="object-cover"
              priority
            />
            {/* On a 4:3 phone crop the caption covers most of the image, so the scrim reaches higher there. */}
            <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/45 to-transparent sm:from-black/80 sm:via-black/10" />
            <div className="absolute inset-x-0 bottom-0 p-6">
              <p className="font-display text-xl font-medium text-white sm:text-2xl">
                Verified artists, real provenance.
              </p>
              <p className="mt-1.5 text-sm text-white/75">
                Every listing ships with a signed Certificate of Authenticity.
              </p>
            </div>
          </div>

          <div className="flex flex-col justify-between gap-8 rounded-2xl border border-border bg-card p-6">
            <div>
              <span className="flex size-11 items-center justify-center rounded-full border border-border bg-secondary">
                <Users className="size-5 text-gold-bright" strokeWidth={1.5} />
              </span>
              <h3 className="mt-5 font-display text-lg font-semibold text-foreground">
                A verified community
              </h3>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                Every artist clears a 3-tier verification system before earning
                platform trust: identity, activity, then a first confirmed sale.
              </p>
            </div>

          </div>
        </motion.div>

        {/* Mission */}
        <motion.div
          className="mt-20 grid grid-cols-1 gap-10 lg:grid-cols-2 lg:gap-16"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-10%" }}
          variants={{
            hidden: {},
            visible: { transition: { staggerChildren: 0.08 } },
          }}
        >
          <motion.div
            variants={fadeUp}
            transition={{ duration: 0.5, ease: "easeOut" }}
          >
            <h2 className="text-balance font-display text-3xl leading-[1.15] font-semibold sm:text-4xl">
              Built to protect the artist&rsquo;s price.
            </h2>
            <p className="mt-5 max-w-md text-balance text-base leading-relaxed text-muted-foreground">
              For too long, sharing your work meant losing control of its price.
              We built GalleryZone so a piece&rsquo;s price stays private
              everywhere it&rsquo;s shown, while its authenticity stays provable
              everywhere it travels.
            </p>
            <p className="mt-4 max-w-md text-balance text-base leading-relaxed text-muted-foreground">
              No public price tags, no guesswork on authenticity: just a signed
              certificate, a verifiable origin, and a market that works the way
              artists always wanted it to.
            </p>
          </motion.div>

          <div className="flex flex-col gap-6">
            {OVERVIEW_PILLARS.map((pillar) => {
              const Icon = pillar.icon;
              return (
                <motion.div
                  key={pillar.title}
                  variants={fadeUp}
                  transition={{ duration: 0.5, ease: "easeOut" }}
                  className="flex items-start gap-4"
                >
                  <span className="flex size-9 shrink-0 items-center justify-center rounded-lg border border-border bg-secondary">
                    <Icon
                      className="size-4 text-gold-bright"
                      strokeWidth={1.75}
                    />
                  </span>
                  <div>
                    <h3 className="font-medium text-foreground">
                      {pillar.title}
                    </h3>
                    <p className="mt-1 text-sm leading-relaxed text-muted-foreground">
                      {pillar.description}
                    </p>
                  </div>
                </motion.div>
              );
            })}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
