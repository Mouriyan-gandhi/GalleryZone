"use client";

import "@/lib/motion-config";
import { useEffect, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { JourneyStepper, JOURNEY_STEP_DURATION_MS } from "./journey-stepper";
import { JourneyStepDetail } from "./journey-step-detail";
import { JOURNEY_STEPS } from "./journey-data";

export function JourneySection() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [autoAdvancing, setAutoAdvancing] = useState(true);
  const step = JOURNEY_STEPS[activeIndex];

  useEffect(() => {
    if (!autoAdvancing) return;
    const timer = setTimeout(() => {
      setActiveIndex((i) => (i + 1) % JOURNEY_STEPS.length);
    }, JOURNEY_STEP_DURATION_MS);
    return () => clearTimeout(timer);
  }, [activeIndex, autoAdvancing]);

  function handleSelect(index: number) {
    setActiveIndex(index);
    setAutoAdvancing(false);
  }

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
              04 <span className="text-gold/50">•</span> THE ARTWORK JOURNEY
            </p>
            <h2 className="mt-4 text-balance font-display text-4xl leading-[1.15] font-semibold sm:text-5xl">
              From the artist&rsquo;s hands to the
              <br />
              <span className="text-gold-bright">collector&rsquo;s</span> walls.
            </h2>
          </div>
          <p className="max-w-sm text-balance text-base text-muted-foreground">
            Every artwork moves through a trusted journey, from submission and
            verification to sale and ownership.
          </p>
        </motion.div>

        <motion.div
          className="mt-12"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-10%" }}
          transition={{ duration: 0.6, ease: "easeOut", delay: 0.1 }}
        >
          {/* Desktop Top Stepper */}
          <div className="hidden lg:block">
            <JourneyStepper
              activeIndex={activeIndex}
              onSelect={handleSelect}
              autoAdvancing={autoAdvancing}
            />
          </div>

          <AnimatePresence mode="wait">
            <motion.p
              key={step.number}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.25, ease: "easeOut" }}
              className="mt-6 text-balance font-display text-xl font-semibold text-foreground sm:text-2xl"
            >
              {step.description}
            </motion.p>
          </AnimatePresence>

          <div className="mt-8">
            <AnimatePresence mode="wait">
              <motion.div
                key={step.number}
                initial={{ opacity: 0, x: 16 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -16 }}
                transition={{ duration: 0.35, ease: "easeOut" }}
                drag="x"
                dragConstraints={{ left: 0, right: 0 }}
                dragElastic={0.2}
                onDragEnd={(e, { offset, velocity }) => {
                  if (offset.x < -50 || velocity.x < -500) {
                    handleSelect((activeIndex + 1) % JOURNEY_STEPS.length);
                  } else if (offset.x > 50 || velocity.x > 500) {
                    handleSelect(
                      (activeIndex - 1 + JOURNEY_STEPS.length) %
                        JOURNEY_STEPS.length,
                    );
                  }
                }}
              >
                <JourneyStepDetail step={step} />
              </motion.div>
            </AnimatePresence>
          </div>

          {/* Mobile Bottom Stepper */}
          <div className="mt-8 flex flex-col items-center gap-6 lg:hidden">
            <div className="flex w-full items-center justify-between px-2 sm:px-10">
              {JOURNEY_STEPS.map((s, i) => (
                <button
                  key={s.number}
                  onClick={() => handleSelect(i)}
                  className="group flex flex-col items-center gap-2"
                >
                  <span
                    className={`relative flex h-2 w-full min-w-[40px] items-center justify-center rounded-full transition-colors sm:min-w-[60px] ${
                      i === activeIndex ? "bg-gold-bright" : "bg-border"
                    }`}
                  />
                  <span
                    className={`text-[10px] font-medium transition-colors sm:text-xs ${
                      i === activeIndex
                        ? "text-foreground"
                        : "text-muted-foreground"
                    }`}
                  >
                    {s.label}
                  </span>
                </button>
              ))}
            </div>
            <p className="text-[10px] font-medium tracking-[0.2em] text-muted-foreground/60 uppercase">
              &larr; Swipe to explore &rarr;
            </p>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
