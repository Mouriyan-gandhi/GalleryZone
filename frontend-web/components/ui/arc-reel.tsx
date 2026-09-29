"use client";

import * as React from "react";
import {
  animate,
  motion,
  useMotionValue,
  useReducedMotion,
  useTransform,
  type MotionValue,
} from "framer-motion";
import { cn } from "@/lib/utils";

/* ── Arc Reel ────────────────────────────────────────────────────
 * A vertical carousel that bows toward one side. `pos` is a continuous card
 * index; card i sits at offset d = i − pos (wrapped), and everything about it
 * derives from d:
 *
 *   scale   s(d) = max(minScale, 1 − shrink·|d|)
 *   y       ∫ (cardHeight·s(u) + gap) du  from 0 to d
 *   x       bow · d²
 *
 * y is the running sum of card heights plus the gap, so neighbours are always
 * exactly `gap` apart in every frame of a spin. The cards can never overlap or
 * drift apart the way they can on a fixed ellipse. Cards fade out by |d| = 1.75
 * and wrap around unseen, so the column loops without a visible seam.
 * ─────────────────────────────────────────────────────────────── */

export type ArcReelItem = { src: string; alt?: string };

export interface ArcReelProps
  extends Omit<React.ComponentPropsWithoutRef<"div">, "children"> {
  items: ArcReelItem[];
  /** Front card size in px. */
  cardWidth?: number;
  cardHeight?: number;
  /** Space between neighbouring cards in px. @default 16 */
  gap?: number;
  /** How fast cards shrink per step away from the front. @default 0.2 */
  shrink?: number;
  /** Smallest card scale. @default 0.5 */
  minScale?: number;
  /** Sideways shift in px per step², signed: positive bows right, negative
   *  left. @default 44 */
  bow?: number;
  /** Where the front card is centred across the stage. @default 0.5 */
  anchorRatio?: number;
  /** @default true */
  autoPlay?: boolean;
  /** Ms the front card is held. @default 2200 */
  holdDuration?: number;
  /** Ms one step takes. @default 900 */
  stepDuration?: number;
}

const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v));
const EASE = [0.4, 0, 0.2, 1] as const;

export function ArcReel({
  items,
  cardWidth = 165,
  cardHeight = 210,
  gap = 16,
  shrink = 0.2,
  minScale = 0.5,
  bow = 44,
  anchorRatio = 0.5,
  autoPlay = true,
  holdDuration = 2200,
  stepDuration = 900,
  className,
  ...props
}: ArcReelProps) {
  const reduceMotion = useReducedMotion();
  const count = items.length;
  const pos = useMotionValue(0);
  const hoverRef = React.useRef(false);
  const dragRef = React.useRef<{ y: number; pos: number; moved: boolean } | null>(null);

  // Offset of card i from the front, wrapped into [−count/2, count/2).
  const offset = React.useCallback(
    (i: number, p: number) => ((((i - p) % count) + count * 1.5) % count) - count / 2,
    [count],
  );

  // ∫0..a (1 − shrink·u) du, capped where the scale reaches minScale.
  const area = React.useCallback(
    (a: number) => {
      const knee = (1 - minScale) / shrink;
      return a <= knee
        ? a - (shrink * a * a) / 2
        : knee - (shrink * knee * knee) / 2 + minScale * (a - knee);
    },
    [minScale, shrink],
  );

  const spinTo = React.useCallback(
    (target: number, duration = stepDuration / 1000) => {
      if (reduceMotion) pos.set(target);
      else animate(pos, target, { duration, ease: EASE });
    },
    [pos, reduceMotion, stepDuration],
  );

  React.useEffect(() => {
    if (!autoPlay || reduceMotion || !count) return;
    let timer = 0;
    let controls: ReturnType<typeof animate> | undefined;
    const tick = () => {
      timer = window.setTimeout(() => {
        if (hoverRef.current || dragRef.current) return tick();
        controls = animate(pos, Math.round(pos.get()) + 1, {
          duration: stepDuration / 1000,
          ease: EASE,
          onComplete: tick,
        });
      }, holdDuration);
    };
    tick();
    return () => {
      window.clearTimeout(timer);
      controls?.stop();
    };
  }, [autoPlay, count, holdDuration, pos, reduceMotion, stepDuration]);

  const stepPx = cardHeight * (1 - shrink / 2) + gap;

  function onPointerDown(e: React.PointerEvent<HTMLDivElement>) {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    dragRef.current = { y: e.clientY, pos: pos.get(), moved: false };
    e.currentTarget.setPointerCapture(e.pointerId);
  }
  function onPointerMove(e: React.PointerEvent<HTMLDivElement>) {
    const drag = dragRef.current;
    if (!drag) return;
    const dy = e.clientY - drag.y;
    if (Math.abs(dy) > 4) drag.moved = true;
    // Dragging up brings the next card forward.
    if (drag.moved) pos.set(drag.pos - dy / stepPx);
  }
  function endDrag(e: React.PointerEvent<HTMLDivElement>) {
    const drag = dragRef.current;
    dragRef.current = null;
    if (e.currentTarget.hasPointerCapture(e.pointerId)) e.currentTarget.releasePointerCapture(e.pointerId);
    if (drag?.moved) spinTo(Math.round(pos.get()), 0.5);
  }
  function onKeyDown(e: React.KeyboardEvent<HTMLDivElement>) {
    const dir = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 }[e.key];
    if (!dir) return;
    e.preventDefault();
    spinTo(Math.round(pos.get()) + dir);
  }

  if (!count) return null;

  return (
    <div
      role="region"
      aria-roledescription="carousel"
      aria-label={props["aria-label"] ?? "Image carousel"}
      tabIndex={0}
      onKeyDown={onKeyDown}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={endDrag}
      onPointerCancel={endDrag}
      onPointerEnter={() => (hoverRef.current = true)}
      onPointerLeave={() => (hoverRef.current = false)}
      className={cn(
        "relative h-full w-full touch-pan-x cursor-grab overflow-hidden outline-none select-none active:cursor-grabbing",
        "focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset",
        className,
      )}
      {...props}
    >
      {items.map((item, i) => (
        <ArcCard
          key={item.src}
          item={item}
          pos={pos}
          offset={(p) => offset(i, p)}
          area={area}
          width={cardWidth}
          height={cardHeight}
          gap={gap}
          shrink={shrink}
          minScale={minScale}
          bow={bow}
          anchorRatio={anchorRatio}
          onSelect={() => {
            if (dragRef.current?.moved) return;
            spinTo(Math.round(pos.get() + offset(i, pos.get())));
          }}
        />
      ))}
    </div>
  );
}

function ArcCard({
  item,
  pos,
  offset,
  area,
  width,
  height,
  gap,
  shrink,
  minScale,
  bow,
  anchorRatio,
  onSelect,
}: {
  item: ArcReelItem;
  pos: MotionValue<number>;
  offset: (p: number) => number;
  area: (a: number) => number;
  width: number;
  height: number;
  gap: number;
  shrink: number;
  minScale: number;
  bow: number;
  anchorRatio: number;
  onSelect: () => void;
}) {
  const d = useTransform(pos, offset);
  const y = useTransform(d, (v) => Math.sign(v) * (height * area(Math.abs(v)) + gap * Math.abs(v)));
  const x = useTransform(d, (v) => bow * v * v);
  const scale = useTransform(d, (v) => Math.max(minScale, 1 - shrink * Math.abs(v)));
  const opacity = useTransform(d, (v) => clamp((1.75 - Math.abs(v)) / 0.65, 0, 1));
  const zIndex = useTransform(d, (v) => Math.round((3 - Math.abs(v)) * 100));
  // A card that has faded out must not catch the pointer.
  const pointerEvents = useTransform(opacity, (o) => (o < 0.2 ? "none" : "auto"));

  return (
    <motion.button
      type="button"
      tabIndex={-1}
      onClick={onSelect}
      style={{
        x,
        y,
        scale,
        opacity,
        zIndex,
        pointerEvents,
        width,
        height,
        left: `${anchorRatio * 100}%`,
        top: "50%",
        marginLeft: -width / 2,
        marginTop: -height / 2,
      }}
      className="absolute overflow-hidden rounded-xl shadow-[0_24px_40px_-18px_rgb(0_0_0/0.7)] ring-1 ring-white/10"
    >
      <img
        src={item.src}
        alt={item.alt ?? ""}
        draggable={false}
        className="pointer-events-none absolute inset-0 h-full w-full object-cover"
      />
    </motion.button>
  );
}

export default ArcReel;
