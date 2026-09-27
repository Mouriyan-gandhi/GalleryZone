"use client";

import { useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Plus, Minus } from "lucide-react";
import { FAQ_ITEMS } from "./faq-data";

export function FaqSection() {
  return (
    <section className="relative overflow-hidden py-14 sm:py-20 md:py-28">
      <div className="mx-auto max-w-[1280px] px-6 lg:px-10">
        <div className="grid grid-cols-1 gap-10 lg:grid-cols-[1fr_1.6fr] lg:gap-16">
          <div className="lg:self-start">
            <motion.div
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true, margin: "-10%" }}
              transition={{ duration: 0.6, ease: "easeOut" }}
            >
              <span className="flex items-center gap-2">
                <span className="size-1.5 rounded-full bg-gold-bright" />
                <span className="text-xs font-medium tracking-[0.16em] text-gold-bright">
                  FAQs
                </span>
              </span>
              <h2 className="mt-4 text-balance font-display text-4xl leading-[1.15] font-semibold sm:text-5xl">
                Frequently
                <br />
                asked{" "}
                <span className="underline decoration-gold decoration-2 underline-offset-8 decoration-double">
                  questions
                </span>
                .
              </h2>
              <p className="mt-5 max-w-sm text-balance text-sm leading-relaxed text-muted-foreground">
                A few clear answers to help you understand how everything works.
              </p>
            </motion.div>
          </div>

          <motion.div
            className="flex flex-col gap-4"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-10%" }}
            variants={{
              hidden: {},
              visible: { transition: { staggerChildren: 0.06 } },
            }}
          >
            {FAQ_ITEMS.map((item) => (
              <FaqAccordionItem key={item.question} item={item} />
            ))}
          </motion.div>
        </div>
      </div>
    </section>
  );
}

function FaqAccordionItem({ item }: { item: (typeof FAQ_ITEMS)[number] }) {
  const [open, setOpen] = useState(false);

  return (
    <motion.div
      variants={{
        hidden: { opacity: 0, y: 16 },
        visible: { opacity: 1, y: 0 },
      }}
      transition={{ duration: 0.5, ease: "easeOut" }}
      className="overflow-hidden rounded-2xl border border-border bg-card transition-colors hover:border-gold/35"
    >
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        className="flex w-full items-center justify-between gap-4 px-6 py-5 text-left sm:px-7"
      >
        <span className="text-base font-semibold text-foreground">
          {item.question}
        </span>
        <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-secondary text-foreground">
          {open ? <Minus className="size-4" /> : <Plus className="size-4" />}
        </span>
      </button>

      <AnimatePresence initial={false}>
        {open && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.3, ease: "easeOut" }}
            className="overflow-hidden"
          >
            <div className="border-t border-border px-6 pt-4 pb-6 sm:px-7">
              <p className="text-sm leading-relaxed text-muted-foreground">
                {item.answer}
              </p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
