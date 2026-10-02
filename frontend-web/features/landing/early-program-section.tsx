"use client";

import "@/lib/motion-config";
import Image from "next/image";
import Link from "next/link";
import { motion } from "framer-motion";
import {
  Calendar,
  ShieldCheck,
  Fingerprint,
  Gift,
  Check,
  ArrowRight,
} from "lucide-react";

const AVATARS = [
  { src: "/early-program/avatar-1.png", size: 56 },
  { src: "/early-program/avatar-2.png", size: 60 },
  { src: "/early-program/avatar-3.png", size: 84, featured: true },
  { src: "/early-program/avatar-4.png", size: 60 },
  { src: "/early-program/avatar-5.png", size: 56 },
];

const BENEFITS = [
  {
    icon: Calendar,
    title: "6 Months Free Access",
    description: "Enjoy all premium features free for your first six months.",
  },
  {
    icon: ShieldCheck,
    title: "Exclusive Verification",
    description:
      "Priority review and verification to establish your artwork's authenticity.",
  },
  {
    icon: Fingerprint,
    title: "Authentic Digital Footprint",
    description:
      "Your artwork gets a unique digital identity that lasts forever.",
  },
  {
    icon: Gift,
    title: "Early-bird Benefits",
    description:
      "Be featured, get visibility boosts and access exclusive opportunities.",
  },
];

export function EarlyProgramSection() {
  const [left, right] = [BENEFITS.slice(0, 2), BENEFITS.slice(2)];

  return (
    <section className="relative overflow-hidden py-14 sm:py-20 md:py-28">
      <div className="mx-auto max-w-[1280px] px-6 lg:px-10">
        <motion.div
          className="rounded-2xl border border-gold/25 bg-card px-5 py-10 sm:px-8 sm:py-14 md:px-14 md:py-16"
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-10%" }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        >
          <div className="grid grid-cols-1 items-center gap-12 lg:grid-cols-[1fr_1.5fr_1fr]">
            <div className="hidden lg:block">
              <BenefitColumn items={left} align="left" />
            </div>

            <div className="flex flex-col items-center text-center">
              <div className="mb-7 flex origin-center scale-[0.72] items-center sm:scale-100">
                {AVATARS.map((avatar, i) => (
                  <div
                    key={avatar.src}
                    className={`relative shrink-0 overflow-hidden rounded-full border-2 ${
                      avatar.featured ? "z-10 border-gold" : "border-background"
                    }`}
                    style={{
                      width: avatar.size,
                      height: avatar.size,
                      marginLeft: i === 0 ? 0 : -14,
                    }}
                  >
                    <Image
                      src={avatar.src}
                      alt=""
                      fill
                      sizes={`${avatar.size}px`}
                      className="object-cover"
                    />
                  </div>
                ))}
              </div>

              <p className="text-xs font-medium tracking-[0.16em] text-gold-bright">
                BE AMONG THE FIRST
              </p>
              <h2 className="mt-4 text-balance font-display text-4xl leading-[1.2] font-semibold sm:text-[2.6rem]">
                Join the <span className="text-gold-bright">GalleryZone</span>
                <br />
                <span className="text-gold-bright">Early Artist</span> Program.
              </h2>
              <p className="mt-5 max-w-md text-balance text-sm leading-relaxed text-muted-foreground">
                Get six months of free access, exclusive verification, and all
                the tools you need to build your art&rsquo;s presence. Artists
                who filled in our survey get a full year.
              </p>

              <Link
                href="/register?role=artist"
                className="group mt-8 inline-flex items-center gap-2 rounded-md bg-gradient-to-b from-gold-bright to-gold px-8 py-4 text-sm font-semibold text-[#171310] shadow-[0_18px_40px_-14px_rgba(200,154,74,0.55)] transition-transform hover:scale-[1.02]"
              >
                Become an Early Artist
                <ArrowRight className="size-4 transition-transform group-hover:translate-x-0.5" />
              </Link>

              <p className="mt-5 flex items-center gap-1.5 text-xs text-muted-foreground">
                <Check className="size-3.5 text-gold-bright" />
                Limited to early members only
              </p>

              <div className="mt-8 grid w-full grid-cols-2 gap-x-4 gap-y-6 text-center lg:hidden">
                {BENEFITS.map((benefit) => (
                  <div key={benefit.title} className="flex flex-col items-center gap-2">
                    <benefit.icon
                      className="size-5 text-gold-bright"
                      strokeWidth={1.5}
                    />
                    <h3 className="font-display text-xs font-semibold text-foreground sm:text-sm">
                      {benefit.title}
                    </h3>
                  </div>
                ))}
              </div>
            </div>

            <div className="hidden lg:block">
              <BenefitColumn items={right} align="right" />
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}

function BenefitColumn({
  items,
  align,
}: {
  items: typeof BENEFITS;
  align: "left" | "right";
}) {
  return (
    <div className="flex flex-col gap-6 sm:gap-10">
      {items.map((benefit) => (
        <div
          key={benefit.title}
          className={`flex flex-col gap-2 sm:gap-3 ${align === "right" ? "lg:items-end lg:text-right" : ""}`}
        >
          <benefit.icon
            className="size-5 text-gold-bright sm:size-6"
            strokeWidth={1.5}
          />
          <div
            className={`flex flex-col gap-1 border-t border-border pt-2.5 sm:pt-3 ${
              align === "right" ? "lg:items-end" : ""
            }`}
          >
            <h3 className="font-display text-sm font-semibold text-foreground sm:text-lg">
              {benefit.title}
            </h3>
            <p className="hidden text-sm leading-relaxed text-muted-foreground lg:block">
              {benefit.description}
            </p>
          </div>
        </div>
      ))}
    </div>
  );
}
