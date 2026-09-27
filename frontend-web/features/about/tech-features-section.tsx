"use client";

import "@/lib/motion-config";
import { motion, Variants } from "framer-motion";
import { Plus } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { TECH_FEATURES } from "./about-data";

export function TechFeaturesSection() {
  const featureSmall = TECH_FEATURES[1]; // AI Search & Chat
  const featureMedium = TECH_FEATURES[2]; // Wallet & Auto Notifications
  const featureLarge = TECH_FEATURES[0]; // QR Tagging

  return (
    <section className="relative overflow-hidden py-16 sm:py-24 md:py-32 bg-background">
      <div className="mx-auto max-w-[1400px] px-6 lg:px-10">
        <div className="flex flex-col gap-10">
          
          {/* Text Content - Top */}
          <motion.div 
            className="max-w-2xl"
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-10%" }}
            transition={{ duration: 0.6, ease: "easeOut" }}
          >
            <h2 className="text-balance font-display text-4xl leading-[1.1] font-semibold sm:text-5xl tracking-tight text-foreground">
              Technology built into every artwork.
            </h2>
            <p className="mt-4 text-balance text-lg leading-relaxed text-muted-foreground">
              Every listing carries a growing layer of technology, tracked through
              the artwork&rsquo;s life on the platform.
            </p>
          </motion.div>

          {/* Cards - Bottom */}
          <motion.div 
            className="grid grid-cols-1 sm:grid-cols-3 gap-6 items-end -mt-8"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-10%" }}
            variants={{
              hidden: {},
              visible: { transition: { staggerChildren: 0.1 } },
            }}
          >
            {/* Smallest Card */}
            <FeatureCard 
              feature={featureSmall} 
              heightClass="h-[260px] sm:h-[300px]" 
              bgImage="/tech-feature-1.png"
            />
            
            {/* Medium Card */}
            <FeatureCard 
              feature={featureMedium} 
              heightClass="h-[260px] sm:h-[380px]"
              bgImage="/tech-feature-2.png"
            />
            
            {/* Largest Card */}
            <FeatureCard 
              feature={featureLarge} 
              heightClass="h-[260px] sm:h-[460px]"
              bgImage="/tech-feature-3.png"
            />
          </motion.div>
        </div>
      </div>
    </section>
  );
}

const cardVariants: Variants = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { type: "spring", stiffness: 100, damping: 20 } },
};

function FeatureCard({
  feature,
  heightClass,
  bgImage
}: {
  feature: { title: string; description: string; icon: LucideIcon };
  heightClass: string;
  bgImage?: string;
}) {
  const Icon = feature.icon;

  return (
    <motion.div
      variants={cardVariants}
      className={`dark group relative flex flex-col justify-between overflow-hidden rounded-[2.5rem] p-8 border border-white/10 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)] transition-all duration-300 hover:-translate-y-1 hover:shadow-xl ${heightClass} bg-gradient-to-br from-[#0c0a09] to-[#171412]`}
    >
      {/* Background Image Layer */}
      {bgImage && (
        <>
          <div className="absolute inset-0 z-0 flex items-center justify-center p-6 sm:p-12 transition-transform duration-700 group-hover:scale-105 pointer-events-none">
            <img src={bgImage} alt="" className="w-full h-full object-contain" />
          </div>
          <div className="absolute inset-0 z-0 bg-gradient-to-t from-black/80 via-transparent to-transparent pointer-events-none" />
        </>
      )}

      <div className="relative z-10 flex size-12 items-center justify-center rounded-full bg-white/10 backdrop-blur-md shadow-sm border border-white/10 transition-transform duration-300 group-hover:scale-110">
        <Icon className="size-5 text-foreground" strokeWidth={1.75} />
      </div>
      
      <div className="mt-8 relative z-10 flex flex-col gap-4">
        <div className="flex items-center justify-between">
          <h3 className="font-display text-lg font-medium text-foreground tracking-tight">
            {feature.title}
          </h3>
          <div className="flex size-8 shrink-0 items-center justify-center rounded-full bg-white/10 transition-transform duration-300 group-hover:rotate-45">
            <Plus className="size-4 text-foreground" strokeWidth={2} />
          </div>
        </div>
        
        <div className="grid grid-rows-[0fr] transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] group-hover:grid-rows-[1fr]">
          <p className="overflow-hidden text-sm leading-relaxed text-muted-foreground/90 opacity-0 transition-opacity duration-300 group-hover:opacity-100">
            {feature.description}
          </p>
        </div>
      </div>
    </motion.div>
  );
}
