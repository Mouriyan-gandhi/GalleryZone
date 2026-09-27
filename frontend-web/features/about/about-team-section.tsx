"use client";

import "@/lib/motion-config";
import { motion } from "framer-motion";
import { Compass, Palette, Landmark } from "lucide-react";

// Demo/placeholder roster -- GalleryZone has no public team page or roster
// today, so these are illustrative names, not real people. Initials-only
// avatars (no generated headshots) keep that honest at a glance.
interface TeamMember {
  name: string;
  initials: string;
  role: string;
  imageUrl?: string;
}

const TEAM: TeamMember[] = [
  {
    name: "Manish Khandarkar",
    initials: "MK",
    role: "Founder",
    imageUrl: "/team/manish-khandarkar.jpg",
  },
  {
    name: "Yata Sai Pawan",
    initials: "YSP",
    role: "Co-founder",
    imageUrl: "/team/yata-sai-pawan.png",
  },
];

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
};

export function AboutTeamSection() {
  return (
    <section className="relative overflow-hidden py-14 sm:py-20 md:py-28">
      <div className="mx-auto max-w-[1400px] px-6 lg:px-10">
        
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-16 lg:gap-24">
          
          {/* LEFT COLUMN: TEAM */}
          <div className="lg:col-span-6 flex flex-col">
            <motion.div
              initial={{ opacity: 0, y: 16 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-10%" }}
              transition={{ duration: 0.6, ease: "easeOut" }}
            >
              <span className="inline-flex items-center rounded-full border border-border bg-card px-3 py-1 text-xs font-medium text-muted-foreground">
                Team
              </span>
              <h2 className="mt-4 text-balance font-display text-3xl leading-[1.15] font-semibold sm:text-4xl">
                The people behind it.
              </h2>
              <p className="mt-3 max-w-md text-balance text-base leading-relaxed text-muted-foreground">
                A small crew building the trust layer between artists, galleries,
                and collectors.
              </p>
            </motion.div>

            <motion.div
              className="mt-12 grid grid-cols-1 gap-6 sm:grid-cols-2"
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true, margin: "-10%" }}
              variants={{
                hidden: {},
                visible: { transition: { staggerChildren: 0.1 } },
              }}
            >
              {TEAM.map((member) => (
                <motion.div
                  key={member.name}
                  variants={fadeUp}
                  transition={{ duration: 0.5, ease: "easeOut" }}
                  className="group relative flex flex-col overflow-hidden rounded-[2rem] border border-white/10 bg-white/5 p-2 shadow-2xl transition-all duration-300 hover:-translate-y-2 hover:border-white/20 hover:shadow-white/5 dark:border-white/5 dark:bg-white/5"
                >
                  {/* Image / Placeholder Area */}
                  <div className="relative aspect-square w-full overflow-hidden rounded-[1.5rem]">
                    {member.imageUrl ? (
                      <img 
                        src={member.imageUrl} 
                        alt={member.name} 
                        className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-105"
                      />
                    ) : (
                      <div className="relative flex h-full w-full flex-col items-center justify-center bg-gradient-to-br from-neutral-800 to-black transition-transform duration-700 group-hover:scale-105 overflow-hidden">
                        {/* Abstract placeholder background shapes */}
                        <div className="absolute -left-1/4 top-0 h-64 w-64 rounded-full bg-white/5 blur-3xl mix-blend-overlay" />
                        <div className="absolute -right-1/4 bottom-0 h-64 w-64 rounded-full bg-white/5 blur-3xl mix-blend-overlay" />
                        <span className="relative z-10 font-display text-5xl font-light tracking-widest text-white/20">
                          {member.initials}
                        </span>
                      </div>
                    )}
                    {/* Subtle inner shadow/border overlay for the image area */}
                    <div className="absolute inset-0 rounded-[1.5rem] ring-1 ring-inset ring-white/10" />
                  </div>
                  
                  {/* Info Area */}
                  <div className="flex flex-col items-center justify-center p-6 text-center">
                    <h3 className="font-display text-xl font-medium tracking-tight text-foreground transition-colors duration-300">
                      {member.name}
                    </h3>
                    <p className="mt-1.5 text-sm tracking-wide text-muted-foreground/80">
                      {member.role}
                    </p>
                  </div>
                </motion.div>
              ))}
            </motion.div>
          </div>

          {/* RIGHT COLUMN: BUILT WITH INTENT */}
          <motion.div 
            className="lg:col-span-6 flex flex-col justify-center lg:pl-16 relative mt-16 lg:mt-0"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-10%" }}
            variants={fadeUp}
            transition={{ duration: 0.6, ease: "easeOut" }}
          >
            {/* Vertical gold line on the left (desktop only) */}
            <div className="hidden lg:block absolute left-0 top-0 bottom-0 w-px bg-gradient-to-b from-gold/0 via-gold/30 to-gold/0" />

            <div className="mb-8">
              <p className="text-[11px] font-bold tracking-[0.2em] uppercase text-gold mb-4">
                Built with intent.
              </p>
              <h3 className="font-display text-2xl md:text-3xl leading-[1.3] font-medium tracking-tight text-foreground max-w-xl text-balance">
                GalleryZone is being built deliberately with a focus on the people, details, and relationships that make original art <span className="text-gold">matter.</span>
              </h3>
            </div>

            {/* Divider */}
            <div className="flex items-center gap-4 mb-8 max-w-xl">
              <div className="h-px bg-border/40 flex-1" />
              <div className="size-1.5 rotate-45 bg-gold/40" />
              <div className="h-px bg-border/40 flex-[4]" />
            </div>

            {/* List Items */}
            <div className="flex flex-col gap-6">
              {/* Item 1 */}
              <div className="flex gap-5 items-start group">
                <div className="flex size-12 shrink-0 items-center justify-center rounded-full border border-border/40 bg-background/50 backdrop-blur transition-all duration-500 group-hover:border-gold/40 group-hover:bg-gold/5">
                  <Compass className="size-5 text-gold transition-transform duration-500 group-hover:scale-110" strokeWidth={1.25} />
                </div>
                <div className="pt-1">
                  <h4 className="text-[11px] font-bold tracking-[0.15em] uppercase text-gold mb-2">
                    Independent Thinking
                  </h4>
                  <p className="text-sm text-muted-foreground/90 leading-relaxed max-w-md">
                    Building outside the traditional marketplace model with clarity and conviction.
                  </p>
                </div>
              </div>

              {/* Item 2 */}
              <div className="flex gap-5 items-start group">
                <div className="flex size-12 shrink-0 items-center justify-center rounded-full border border-border/40 bg-background/50 backdrop-blur transition-all duration-500 group-hover:border-gold/40 group-hover:bg-gold/5">
                  <Palette className="size-5 text-gold transition-transform duration-500 group-hover:scale-110" strokeWidth={1.25} />
                </div>
                <div className="pt-1">
                  <h4 className="text-[11px] font-bold tracking-[0.15em] uppercase text-gold mb-2">
                    Artist-First Mindset
                  </h4>
                  <p className="text-sm text-muted-foreground/90 leading-relaxed max-w-md">
                    Every decision we make is centered around protecting and empowering artists.
                  </p>
                </div>
              </div>

              {/* Item 3 */}
              <div className="flex gap-5 items-start group">
                <div className="flex size-12 shrink-0 items-center justify-center rounded-full border border-border/40 bg-background/50 backdrop-blur transition-all duration-500 group-hover:border-gold/40 group-hover:bg-gold/5">
                  <Landmark className="size-5 text-gold transition-transform duration-500 group-hover:scale-110" strokeWidth={1.25} />
                </div>
                <div className="pt-1">
                  <h4 className="text-[11px] font-bold tracking-[0.15em] uppercase text-gold mb-2">
                    Long-Term Vision
                  </h4>
                  <p className="text-sm text-muted-foreground/90 leading-relaxed max-w-md">
                    Creating an ecosystem that grows with the art community for generations to come.
                  </p>
                </div>
              </div>
            </div>
            
          </motion.div>

        </div>
      </div>
    </section>
  );
}
