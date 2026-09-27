"use client";

import "@/lib/motion-config";
import { motion, Variants } from "framer-motion";
import type { LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";
import { VERIFICATION_TIERS, GOLD_VERIFIED } from "./about-data";

const fadeUp: Variants = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { type: "spring", stiffness: 100, damping: 20 } },
};

export function VerificationTiersSection() {
  return (
    <section
      id="how-it-works"
      className="relative overflow-hidden py-16 sm:py-24 md:py-32 bg-background"
    >
      <div className="mx-auto max-w-[1400px] px-6 lg:px-10">
        <motion.div
          className="max-w-3xl"
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-10%" }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        >
          <h2 className="text-balance font-display text-4xl leading-[1.1] font-semibold sm:text-5xl tracking-tight text-foreground">
            How verification works.
          </h2>
          <p className="mt-6 max-w-xl text-balance text-lg leading-relaxed text-muted-foreground">
            Three tiers confirm an artist&rsquo;s identity, activity, and track
            record, so anyone browsing a listing can see exactly how established
            the artist is.
          </p>
        </motion.div>

        <div className="mt-24 relative">
          {/* Animated timeline connecting line */}
          <div className="absolute left-[27px] top-8 bottom-8 w-px bg-border/40 lg:left-0 lg:top-[27px] lg:h-px lg:w-full lg:bottom-auto overflow-hidden">
            <motion.div 
              className="w-full h-full bg-gradient-to-b lg:bg-gradient-to-r from-transparent via-foreground/20 to-transparent"
              initial={{ x: "-100%", y: "-100%" }}
              whileInView={{ x: "100%", y: "100%" }}
              transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
            />
          </div>
          
          <motion.div
            className="relative grid grid-cols-1 gap-16 lg:grid-cols-4 lg:gap-12"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-10%" }}
            variants={{
              hidden: {},
              visible: { transition: { staggerChildren: 0.15 } },
            }}
          >
            {VERIFICATION_TIERS.map((tier) => (
              <TierNode
                key={tier.tier}
                label={`Tier ${tier.tier}`}
                title={tier.title}
                description={tier.description}
                icon={tier.icon}
              />
            ))}
            
            {/* The Result Node */}
            <TierNode
              label="Result"
              title={GOLD_VERIFIED.title}
              description={GOLD_VERIFIED.description}
              icon={GOLD_VERIFIED.icon}
              gold
            />
          </motion.div>
        </div>
      </div>
    </section>
  );
}

function TierNode({
  label,
  title,
  description,
  icon: Icon,
  gold = false,
}: {
  label: string;
  title: string;
  description: string;
  icon: LucideIcon;
  gold?: boolean;
}) {
  return (
    <motion.div
      variants={fadeUp}
      className="relative flex flex-row gap-8 lg:flex-col lg:gap-10 group"
    >
      {/* Subtle hover background for desktop */}
      <div 
        className="absolute -inset-6 z-0 rounded-[2rem] opacity-0 transition-opacity duration-500 hidden lg:block group-hover:opacity-100 bg-secondary/30" 
      />
      
      {/* Node Icon Container */}
      <div className="relative z-10 shrink-0">
        <div 
          className="flex size-14 items-center justify-center rounded-full border shadow-sm backdrop-blur-md transition-transform duration-500 group-hover:scale-110 border-border/50 bg-background/50 dark:bg-black/40 group-hover:border-foreground/20"
        >
          <Icon
            className="size-6 transition-colors duration-300 text-muted-foreground group-hover:text-foreground"
            strokeWidth={1.5}
          />
        </div>
      </div>

      {/* Content */}
      <div className="pt-1 lg:pt-0 relative z-10">
        <div className="flex items-center gap-3">
          <span 
            className="inline-flex items-center rounded-full px-3 py-1 text-[11px] font-semibold tracking-[0.15em] uppercase transition-colors duration-300 bg-secondary/80 text-muted-foreground group-hover:bg-foreground/5 group-hover:text-foreground"
          >
            {label}
          </span>
        </div>
        
        <h3 className="mt-5 font-display text-2xl font-medium tracking-tight text-foreground">
          {title}
        </h3>
        
        <p className="mt-3 text-base leading-relaxed text-muted-foreground/90">
          {description}
        </p>
      </div>
    </motion.div>
  );
}
