"use client";

import "@/lib/motion-config";
import Image from "next/image";
import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowRight, ScanLine, type LucideIcon } from "lucide-react";

export type IdentityCardData = {
  title: string;
  description: string;
  linkLabel: string;
  href: string;
  icon: LucideIcon;
  badgePosition: "top-right" | "bottom-right";
} & (
  | {
      variant: "image";
      image: string;
      imageAlt: string;
      digitalId?: string;
    }
  | { variant: "provenance"; events: { date: string; label: string }[] }
);

export function IdentityCard({
  card,
  onHover,
}: {
  card: IdentityCardData;
  onHover?: (hovered: boolean) => void;
}) {
  const Icon = card.icon;
  const badgeClass =
    card.badgePosition === "top-right"
      ? "top-2.5 right-2.5"
      : "-bottom-2.5 -right-2.5";

  return (
    <motion.div
      className="group relative flex w-full max-w-sm flex-col rounded-lg sm:max-w-[230px] border border-border bg-card p-2.5 shadow-[inset_0_1px_0_0_rgba(255,255,255,0.03)] transition-colors duration-300 hover:border-gold/55"
      onHoverStart={() => onHover?.(true)}
      onHoverEnd={() => onHover?.(false)}
      whileHover={{ y: -5 }}
      transition={{ type: "spring", stiffness: 340, damping: 26 }}
    >
      <div className="relative aspect-[16/9] overflow-hidden rounded-sm">
        {card.variant === "image" ? (
          <Image
            src={card.image}
            alt={card.imageAlt}
            fill
            sizes="230px"
            className="object-cover transition-transform duration-500 ease-out group-hover:scale-[1.06]"
          />
        ) : (
          <ProvenanceTimeline events={card.events} />
        )}
        {card.variant === "image" && card.digitalId && (
          <div className="absolute inset-x-1.5 bottom-1.5 flex items-center gap-2 rounded-md border border-gold/50 bg-background/85 px-2 py-1.5 backdrop-blur-sm">
            <div className="min-w-0">
              <p className="text-[7px] tracking-wide text-muted-foreground uppercase">
                Digital ID
              </p>
              <p className="truncate font-mono text-[10px] font-medium text-gold-bright">
                {card.digitalId}
              </p>
            </div>
            <ScanLine className="ml-auto size-3 shrink-0 text-gold/70" />
          </div>
        )}
        <span
          className={`absolute ${badgeClass} flex size-7 items-center justify-center rounded-md border border-gold/40 bg-background/90`}
        >
          <Icon className="size-3.5 text-gold-bright" strokeWidth={1.75} />
        </span>
      </div>

      <h3 className="mt-3.5 text-base font-semibold text-foreground">
        {card.title}
      </h3>
      <span className="mt-1.5 h-px w-5 bg-gold/60" />
      <p className="mt-2 text-[13px] leading-relaxed text-muted-foreground">
        {card.description}
      </p>
      <Link
        href={card.href}
        className="group/link mt-3 inline-flex items-center gap-1.5 text-[13px] font-medium text-gold-bright"
      >
        {card.linkLabel}
        <ArrowRight className="size-3 transition-transform group-hover/link:translate-x-0.5" />
      </Link>
    </motion.div>
  );
}

function ProvenanceTimeline({
  events,
}: {
  events: { date: string; label: string }[];
}) {
  return (
    <div className="flex h-full flex-col justify-center gap-1.5 overflow-hidden bg-[#e7dfcc] px-3.5 py-2">
      {events.map((event, i) => (
        <div key={event.date} className="relative flex gap-2.5 pl-0.5">
          <div className="flex flex-col items-center pt-1">
            <span className="size-1.5 shrink-0 rounded-full bg-[#8a6423]" />
            {i < events.length - 1 && (
              <span className="mt-1 w-px flex-1 bg-[#8a6423]/35" />
            )}
          </div>
          <div className="pb-0.5">
            <p className="text-[10px] font-medium whitespace-nowrap text-[#5c5340]">
              {event.date}
            </p>
            <p className="truncate text-[10px] leading-snug text-[#3a3527]">
              {event.label}
            </p>
          </div>
        </div>
      ))}
    </div>
  );
}
