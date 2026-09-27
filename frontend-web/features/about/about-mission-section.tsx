"use client";

import "@/lib/motion-config";
import { motion } from "framer-motion";

// Verbatim from the source document ("Gz Mission.pdf") — only "Galleryzone"
// was normalized to "GalleryZone" to match this site's brand spelling
// everywhere else; wording, sentences, and the bullet list are unchanged,
// not paraphrased or reordered. Distinct from AboutOverviewSection's short
// "protect the artist's price" mission blurb, which is separate marketing
// copy, not this statement.
//
// Split into two columns along the document's own seam: paragraphs 1-5 are
// the founding/origin narrative (left), paragraph 6 is the direct lead-in
// to "We strive to:" in the source, so it opens the right column with the
// commitments list and closing lines, exactly as the document orders them.
const MISSION_STORY = [
  "GalleryZone was founded with a simple yet ambitious vision: to create a trusted platform where artists can showcase their creativity, reach more people, and build sustainable careers through their work.",
  "Across India and beyond, countless talented artists create remarkable works of art. However, many face challenges in gaining visibility, finding buyers, receiving fair value, and accessing professional opportunities. GalleryZone was established to help bridge that gap.",
  "Our mission is to connect artists, collectors, businesses, and display partners through a transparent, technology-driven ecosystem. By combining an online marketplace with curated physical display opportunities, we aim to make original art more accessible while helping artists expand their reach and recognition.",
  "At GalleryZone, we believe that every artwork tells a story, every artist deserves respect, and every customer deserves authenticity and confidence in their purchase. These principles guide every decision we make.",
  "As we grow, we remain committed to innovation, integrity, quality, and long-term partnerships. We will continue improving our platform, expanding our network, and creating opportunities that benefit artists, customers, and business partners alike.",
];

const MISSION_LEAD_BRAND = "GalleryZone";
const MISSION_LEAD_REST =
  " is committed to building a technology-driven platform that empowers artists, simplifies art discovery, and creates meaningful opportunities for buyers and business partners.";

const MISSION_COMMITMENTS: string[] = [
  "Support artists by providing greater visibility and market access.",
  "Offer customers authentic, high-quality artwork through a transparent purchasing experience.",
  "Build partnerships with businesses that showcase original art in commercial spaces.",
  "Deliver professional services covering artwork verification, logistics, documentation, and customer support.",
  "Promote sustainable growth within the art community through ethical business practices.",
];

const MISSION_CLOSING = [
  "Thank you for taking the time to learn about GalleryZone. We invite you to join us as we work to build a stronger and more connected future for the art community.",
  "Together, we can create opportunities, inspire creativity, and help original art reach more people than ever before.",
];

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
};

const columnStagger = {
  hidden: {},
  visible: { transition: { staggerChildren: 0.08 } },
};

export function AboutMissionSection() {
  return (
    <section className="relative overflow-hidden py-14 sm:py-20 md:py-28">
      <div className="mx-auto max-w-[1400px] px-6 lg:px-10">
        <div className="relative grid grid-cols-1 gap-16 lg:grid-cols-2 lg:gap-14">
          {/* Vertical gold divider (desktop only), centered on the page */}
          <div className="absolute inset-y-0 left-1/2 hidden w-px -translate-x-1/2 bg-gradient-to-b from-gold/0 via-gold/30 to-gold/0 lg:block" />

          {/* LEFT: origin story */}
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-10%" }}
            variants={columnStagger}
          >
            <motion.div variants={fadeUp} transition={{ duration: 0.5, ease: "easeOut" }}>
              <p className="text-xs font-medium tracking-[0.14em] text-gold uppercase">
                Our Mission
              </p>
              <div className="mt-3 h-px w-9 bg-gold/60" />
              <h2 className="mt-5 text-balance font-display text-4xl leading-[1.08] font-semibold sm:text-5xl">
                Welcome to
                <br />
                <span className="text-gold">Gallery</span>Zone.
              </h2>
            </motion.div>

            <div className="mt-8 flex flex-col gap-5">
              {MISSION_STORY.map((paragraph, index) => (
                <motion.p
                  key={index}
                  variants={fadeUp}
                  transition={{ duration: 0.5, ease: "easeOut" }}
                  className="text-balance font-display text-base leading-relaxed text-foreground/85"
                >
                  {paragraph}
                </motion.p>
              ))}
            </div>
          </motion.div>

          {/* RIGHT: commitments */}
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-10%" }}
            variants={columnStagger}
          >
            <motion.p
              variants={fadeUp}
              transition={{ duration: 0.5, ease: "easeOut" }}
              className="text-balance font-display text-lg leading-relaxed text-foreground"
            >
              <span className="font-semibold text-gold">{MISSION_LEAD_BRAND}</span>
              {MISSION_LEAD_REST}
            </motion.p>

            <motion.div
              variants={fadeUp}
              transition={{ duration: 0.5, ease: "easeOut" }}
              className="mt-10"
            >
              <div className="flex items-center gap-4">
                <div className="h-px flex-1 bg-gold/40" />
                <p className="shrink-0 text-xs font-medium tracking-[0.14em] text-gold uppercase">
                  We strive to
                </p>
                <div className="h-px flex-1 bg-gold/40" />
              </div>
              <ul className="mt-6 flex flex-col gap-4">
                {MISSION_COMMITMENTS.map((item) => (
                  <li
                    key={item}
                    className="text-balance font-display text-base leading-relaxed text-foreground/85"
                  >
                    {item}
                  </li>
                ))}
              </ul>
            </motion.div>

            {/* Closing note, right after the commitments list */}
            <motion.div
              variants={fadeUp}
              transition={{ duration: 0.5, ease: "easeOut" }}
              className="mt-10"
            >
              <div className="flex items-center gap-4">
                <div className="h-px flex-1 bg-gold/30" />
                <div className="size-1.5 shrink-0 rotate-45 bg-gold/50" />
                <div className="h-px flex-1 bg-gold/30" />
              </div>

              <div className="mt-8 flex flex-col gap-4">
                {MISSION_CLOSING.map((paragraph, index) => (
                  <p
                    key={index}
                    className="text-balance font-display text-sm leading-relaxed text-foreground/70"
                  >
                    {paragraph}
                  </p>
                ))}
              </div>

              <p className="mt-8 font-display text-2xl leading-[1.2] font-medium italic text-gold-bright">
                &ldquo;Connecting Artists with the World.&rdquo;
              </p>
              <svg
                className="mt-2 text-gold/50"
                width="200"
                height="12"
                viewBox="0 0 200 12"
                fill="none"
                aria-hidden="true"
              >
                <path
                  d="M2 2C40 11 160 11 198 2"
                  stroke="currentColor"
                  strokeWidth="1.25"
                  strokeLinecap="round"
                />
              </svg>
            </motion.div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
