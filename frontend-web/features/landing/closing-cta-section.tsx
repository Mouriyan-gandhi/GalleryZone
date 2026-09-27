"use client";

import "@/lib/motion-config";
import Link from "next/link";
import { motion } from "framer-motion";
import { Mail, Clock3, ArrowRight } from "lucide-react";
import { SideRays } from "@/components/ui/side-rays";

const CONTACT_POINTS = [
  {
    icon: Mail,
    title: "Real people, real answers",
    description: "No bots: a person from our team replies.",
  },
  {
    icon: Clock3,
    title: "Fast response",
    description: "We typically reply within 1 business day.",
  },
];

export function ClosingCtaSection() {
  return (
    <section className="relative overflow-hidden py-14 sm:py-20 md:py-28">
      <div className="mx-auto max-w-[1280px] px-6 lg:px-10">
        <motion.div
          className="relative overflow-hidden rounded-2xl border border-gold/25 bg-card"
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-10%" }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        >
          <div className="pointer-events-none absolute inset-0 z-0" aria-hidden>
            <SideRays
              origin="bottom-right"
              rayColor1="#e9c57a"
              rayColor2="#8a6423"
              speed={1.5}
              intensity={1.6}
              spread={1.8}
              saturation={1.3}
              blend={0.6}
              falloff={1.8}
              opacity={0.9}
            />
          </div>
          <div className="relative z-10 grid grid-cols-1 lg:grid-cols-[1.2fr_1fr]">
            <div className="px-6 py-10 sm:px-8 md:px-12 md:py-12">
              <p className="text-sm font-medium tracking-[0.14em] text-gold-bright">
                GET IN TOUCH
              </p>

              <h2 className="mt-4 text-balance font-display text-4xl leading-[1.15] font-semibold sm:text-5xl">
                Questions? We&rsquo;re happy to{" "}
                <span className="bg-gradient-to-r from-gold-deep via-gold to-gold-bright bg-clip-text text-transparent">
                  help.
                </span>
              </h2>

              <p className="mt-4 max-w-md text-balance text-base leading-relaxed text-muted-foreground">
                Whichever you are, reach out and our team will follow up.
              </p>

              <div className="mt-8 grid grid-cols-1 gap-x-6 gap-y-5 sm:grid-cols-2">
                {CONTACT_POINTS.map((point) => (
                  <div key={point.title} className="flex items-start gap-3">
                    <span className="flex size-9 shrink-0 items-center justify-center rounded-lg border border-gold/25 bg-gold/10">
                      <point.icon
                        className="size-4 text-gold-bright"
                        strokeWidth={1.75}
                      />
                    </span>
                    <div>
                      <h3 className="text-sm font-medium text-foreground">
                        {point.title}
                      </h3>
                      <p className="mt-0.5 text-xs leading-relaxed text-muted-foreground">
                        {point.description}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="relative flex items-center justify-center px-6 pt-8 pb-10 sm:px-8 lg:pb-0 lg:pt-0">
              <Link
                href="/contact"
                className="group relative z-10 inline-flex items-center justify-center gap-2.5 rounded-xl bg-gradient-to-b from-gold-bright to-gold px-6 py-4 text-sm font-semibold text-[#171310] shadow-[0_28px_70px_-14px_rgba(200,154,74,0.65)] transition-transform hover:scale-[1.02] sm:px-8 sm:py-5 sm:text-base lg:px-12 lg:py-7 lg:text-lg"
              >
                Contact Us
                <ArrowRight className="size-5 transition-transform group-hover:translate-x-0.5" />
              </Link>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
