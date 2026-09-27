"use client";

import { useState, type FormEvent } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import { User, Mail, Send, Check, Clock3 } from "lucide-react";
import { cn } from "@/lib/utils";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import {
  InstagramGlyph,
  XGlyph,
  LinkedinGlyph,
} from "@/components/social-icons";
import { ROLE_OPTIONS, CONTACT_EMAIL } from "./contact-data";

type ContactFormData = {
  fullName: string;
  email: string;
  role: string;
  message: string;
};

const EMPTY_FORM: ContactFormData = {
  fullName: "",
  email: "",
  role: "",
  message: "",
};

export function ContactSection() {
  const [form, setForm] = useState<ContactFormData>(EMPTY_FORM);
  const [submitted, setSubmitted] = useState(false);

  function updateField<K extends keyof ContactFormData>(
    field: K,
    value: string,
  ) {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSubmitted(true);
  }

  return (
    <section className="py-16 sm:py-20 md:py-28">
      <div className="mx-auto max-w-[1280px] px-6 lg:px-10">
        <div className="max-w-2xl">
          <p className="text-sm font-medium tracking-[0.14em] text-gold-bright">
            CONTACT
          </p>
          <h1 className="mt-4 text-balance font-display text-4xl leading-[1.15] font-semibold sm:text-5xl">
            Get in <span className="text-gold-bright">touch.</span>
          </h1>
          <p className="mt-5 text-balance text-base leading-relaxed text-muted-foreground">
            Questions about listing art, buying a piece, or partnering with us
            as a gallery. Send a message and our team will follow up.
          </p>
        </div>

        <div className="mt-14 grid grid-cols-1 gap-10 lg:grid-cols-5 lg:gap-14">
          <div className="lg:col-span-3">
            {submitted ? (
              <motion.div
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, ease: "easeOut" }}
                className="flex min-h-[22rem] flex-col items-start justify-center gap-4 rounded-lg border border-gold/30 bg-card p-8"
              >
                <span className="flex size-12 items-center justify-center rounded-full border border-gold/40 bg-gold/10">
                  <Check className="size-6 text-gold-bright" />
                </span>
                <h2 className="font-display text-2xl font-semibold text-foreground">
                  Message sent.
                </h2>
                <p className="max-w-sm text-balance text-base leading-relaxed text-muted-foreground">
                  Thanks, {form.fullName.split(" ")[0] || "we've got it"}. We
                  typically reply within 1 business day.
                </p>
              </motion.div>
            ) : (
              <form onSubmit={handleSubmit} className="flex flex-col gap-6">
                <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                  <div className="flex flex-col gap-2">
                    <Label htmlFor="fullName">Full name</Label>
                    <div className="relative">
                      <User className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
                      <Input
                        id="fullName"
                        required
                        placeholder="Devika Rao"
                        value={form.fullName}
                        onChange={(e) =>
                          updateField("fullName", e.target.value)
                        }
                        className="h-10 pl-9"
                      />
                    </div>
                  </div>

                  <div className="flex flex-col gap-2">
                    <Label htmlFor="email">Email address</Label>
                    <div className="relative">
                      <Mail className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
                      <Input
                        id="email"
                        type="email"
                        required
                        placeholder="you@example.com"
                        value={form.email}
                        onChange={(e) => updateField("email", e.target.value)}
                        className="h-10 pl-9"
                      />
                    </div>
                  </div>

                  <div className="flex flex-col gap-2 sm:col-span-2">
                    <Label>I am a...</Label>
                    <div
                      role="radiogroup"
                      aria-label="I am a..."
                      className="grid grid-cols-3 gap-2"
                    >
                      {ROLE_OPTIONS.map((option) => {
                        const isSelected = form.role === option.value;
                        return (
                          <button
                            key={option.value}
                            type="button"
                            role="radio"
                            aria-checked={isSelected}
                            onClick={() => updateField("role", option.value)}
                            className={cn(
                              "rounded-md border px-3 py-2.5 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50",
                              isSelected
                                ? "border-gold/60 bg-gold/10 text-gold-bright"
                                : "border-border text-muted-foreground hover:border-gold/30 hover:text-foreground",
                            )}
                          >
                            {option.label}
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  <div className="flex flex-col gap-2 sm:col-span-2">
                    <Label htmlFor="message">Message</Label>
                    <Textarea
                      id="message"
                      required
                      rows={5}
                      placeholder="Tell us more about your question or request."
                      value={form.message}
                      onChange={(e) => updateField("message", e.target.value)}
                      className="min-h-32 resize-none"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  className="group inline-flex w-fit items-center gap-2 rounded-md bg-gradient-to-b from-gold-bright to-gold px-6 py-3 text-sm font-semibold text-[#171310] shadow-[0_18px_40px_-14px_rgba(200,154,74,0.55)] transition-transform hover:scale-[1.02]"
                >
                  Send message
                  <Send className="size-4 transition-transform group-hover:translate-x-0.5" />
                </button>
              </form>
            )}
          </div>

          <div className="lg:col-span-2">
            <div className="flex flex-col gap-6">
              <div className="rounded-lg border border-border bg-card p-6">
                <h2 className="font-display text-base font-semibold text-foreground">
                  Reach us directly
                </h2>
                <Link
                  href={`https://mail.google.com/mail/?view=cm&fs=1&to=${CONTACT_EMAIL}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-3 inline-flex items-center gap-2 text-sm text-gold-bright hover:underline"
                >
                  <Mail className="size-4" />
                  {CONTACT_EMAIL}
                </Link>
                <div className="mt-5 flex items-center gap-3 border-t border-border pt-5">
                  {[
                    { Glyph: InstagramGlyph, href: "https://www.instagram.com/galleryzone.in", label: "Instagram" },
                    { Glyph: XGlyph, href: "#", label: "X" },
                    { Glyph: LinkedinGlyph, href: "#", label: "LinkedIn" },
                  ].map(({ Glyph, href, label }) => (
                    <Link
                      key={label}
                      href={href}
                      target={href.startsWith("http") ? "_blank" : undefined}
                      rel={href.startsWith("http") ? "noopener noreferrer" : undefined}
                      aria-label={label}
                      className="flex size-9 items-center justify-center rounded-md border border-gold/40 text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
                    >
                      <Glyph className="size-4" />
                    </Link>
                  ))}
                </div>
              </div>

              <div className="relative overflow-hidden rounded-lg bg-gradient-to-b from-gold-bright to-gold p-6 text-[#171310]">
                <div className="absolute -top-8 -right-8 size-32 rounded-full bg-black/5" />
                <div className="absolute -bottom-10 -left-10 size-28 rounded-full bg-black/5" />
                <Clock3 className="relative size-5" strokeWidth={1.75} />
                <p className="relative mt-4 font-display text-2xl font-semibold">
                  1 business day
                </p>
                <p className="relative mt-3 max-w-[220px] text-sm leading-relaxed opacity-80">
                  That&rsquo;s typically how long it takes us to reply. Order
                  and payment issues get priority.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
