"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { FOOTER_COLUMNS, SOCIAL_LINKS } from "./site-footer-data";
import type { FooterLink } from "./site-footer-data";

function FooterLinkItem({ link }: { link: FooterLink }) {
  if (link.comingSoon) {
    return (
      <span className="text-sm text-foreground/40 cursor-default select-none">
        {link.label}
        <span className="ml-2 inline-block rounded-sm bg-gold/15 px-1.5 py-0.5 align-middle text-[10px] font-semibold tracking-[0.1em] text-gold uppercase leading-none">
          Soon
        </span>
      </span>
    );
  }
  return (
    <Link
      href={link.href}
      className="text-sm text-foreground/85 transition-colors hover:text-gold-bright"
    >
      {link.label}
    </Link>
  );
}

const footerStagger = {
  hidden: {},
  visible: { transition: { staggerChildren: 0.08 } },
};

const footerFadeItem = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
};

export function SiteFooter() {
  return (
    <footer className="relative overflow-hidden pb-10">
      <FooterGlow />

      <div className="relative z-10 mx-auto max-w-[1280px] px-6 lg:px-10">
        <motion.div
          className="grid grid-cols-1 gap-10 pt-14 sm:gap-14 sm:pt-20 lg:grid-cols-[1fr_2.2fr] lg:gap-10 lg:pt-24"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-10%" }}
          variants={footerStagger}
        >
          <motion.div
            variants={footerFadeItem}
            transition={{ duration: 0.5, ease: "easeOut" }}
            className="flex max-w-sm flex-col"
          >
            <div className="flex items-baseline gap-2.5">
              <span className="font-display text-2xl font-semibold text-gold-bright italic">
                GZ
              </span>
              <span className="text-sm font-medium tracking-[0.18em] text-foreground">
                GALLERYZONE
              </span>
            </div>

            <h3 className="mt-6 text-balance font-display text-3xl leading-[1.2] font-semibold">
              Where original art
              <br />
              finds its <span className="text-gold-bright">identity.</span>
            </h3>
            <span className="mt-4 h-px w-6 bg-gold/60" />
            <p className="mt-4 text-sm leading-relaxed text-muted-foreground">
              GalleryZone gives every artwork a trusted digital identity, a
              verifiable history, and a global stage to be discovered.
            </p>

            <div className="mt-6 flex items-center gap-3">
              {SOCIAL_LINKS.map((social) => (
                <Link
                  key={social.label}
                  href={social.href}
                  target={social.target}
                  rel={social.rel}
                  aria-label={social.label}
                  className="flex size-9 items-center justify-center rounded-md border border-gold/40 text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
                >
                  <social.icon className="size-4" />
                </Link>
              ))}
            </div>
          </motion.div>

          <motion.div
            variants={footerFadeItem}
            transition={{ duration: 0.5, ease: "easeOut", delay: 0.06 }}
            className="grid grid-cols-2 gap-x-6 gap-y-10 sm:grid-cols-3 lg:grid-cols-6"
          >
            {FOOTER_COLUMNS.map((column) => (
              <div key={column.title} className="flex flex-col">
                <p className="text-xs font-medium tracking-[0.12em] text-gold-bright">
                  {column.title}
                </p>
                <span className="mt-3 h-px w-4 bg-gold/50" />
                <ul className="mt-4 flex flex-col gap-3">
                  {column.links.map((link) => (
                    <li key={link.label}>
                      <FooterLinkItem link={link} />
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </motion.div>
        </motion.div>

        <div
          className="-mb-6 mt-16 overflow-hidden text-center sm:-mb-10 lg:-mb-14"
          aria-hidden
        >
          <p className="translate-y-[0.1em] bg-gradient-to-b from-gold/25 to-gold/0 bg-clip-text font-display text-[12vw] leading-none font-bold tracking-tight text-transparent select-none lg:text-[11vw]">
            GALLERYZONE
          </p>
        </div>
      </div>
    </footer>
  );
}

function FooterGlow() {
  return (
    <div
      className="pointer-events-none absolute inset-0 overflow-hidden"
      aria-hidden
    >
      <div
        className="absolute inset-0 opacity-[0.05]"
        style={{
          backgroundImage:
            "radial-gradient(circle, rgba(255,255,255,0.9) 1px, transparent 1px)",
          backgroundSize: "3px 3px",
        }}
      />
      <div className="absolute top-0 left-1/2 size-[720px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-gold/10 blur-[140px]" />
      <div className="absolute -right-24 -bottom-40 size-[560px] rounded-full bg-gold/20 blur-[100px]" />
    </div>
  );
}
