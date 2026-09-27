"use client";

import { useEffect, useRef, useState, useSyncExternalStore } from "react";
import Link from "next/link";
import { Check } from "lucide-react";
import { cn } from "@/lib/utils";
import { readSessionRole, subscribeToSession } from "@/lib/session";
import { useMounted } from "@/hooks/useMounted";
import { CheckoutAddressStep } from "./checkout-address-step";
import { CheckoutReviewStep } from "./checkout-review-step";
import { CheckoutConfirmStep } from "./checkout-confirm-step";
import type { Artwork } from "@/types/artwork";
import type { Address } from "@/types/customer";
import type { Order } from "@/types/order";

type CheckoutStep = "address" | "review" | "confirm";

const STEPS: { key: CheckoutStep; label: string }[] = [
  { key: "address", label: "Address" },
  { key: "review", label: "Review" },
  { key: "confirm", label: "Confirm" },
];

interface CheckoutFlowProps {
  artwork: Artwork;
}

// Client-side orchestrator for the three checkout steps — one page, no
// separate routes per step, same "internal step transition" shape as the
// Register page's role-picker-then-form flow. Holds the selected Address
// object (not just an id) so Review/Confirm never need to re-derive it from
// a query cache that (per the mock-service pattern) won't reflect a
// same-session newly-added address after refetch.
export function CheckoutFlow({ artwork }: CheckoutFlowProps) {
  const [step, setStep] = useState<CheckoutStep>("address");
  const [address, setAddress] = useState<Address | null>(null);
  const [placedOrder, setPlacedOrder] = useState<Order | null>(null);

  const topRef = useRef<HTMLDivElement>(null);
  const isFirstRender = useRef(true);
  const mounted = useMounted();
  const sessionRole = useSyncExternalStore(subscribeToSession, readSessionRole, () => null);

  // Each step is shorter than the one before it, so moving forward leaves the
  // window scrolled past the new step — you land looking at the footer. Pull
  // the flow back into view on every step change, but not on first render,
  // where the page should stay where the browser put it.
  useEffect(() => {
    if (isFirstRender.current) {
      isFirstRender.current = false;
      return;
    }
    const prefersReducedMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)",
    ).matches;
    topRef.current?.scrollIntoView({
      behavior: prefersReducedMotion ? "auto" : "smooth",
      block: "start",
    });
  }, [step, placedOrder]);

  const stepIndex = STEPS.findIndex((s) => s.key === step);

  // Orders are placed from a customer account (the API refuses anyone else);
  // without this, a signed-out visitor sat on address skeletons that never resolved.
  if (mounted && sessionRole !== "customer") {
    const next = `/checkout?artworkId=${encodeURIComponent(artwork.id)}`;
    return (
      <div className="mx-auto flex w-full max-w-md flex-col items-center gap-4 rounded-2xl border border-border bg-card p-6 text-center sm:p-8">
        <h2 className="font-display text-2xl font-semibold text-balance">
          {sessionRole ? "Buying needs a collector account" : "Sign in to buy this artwork"}
        </h2>
        <p className="text-sm text-muted-foreground text-balance">
          The certificate and ownership record are issued to the collector who places the order.
        </p>
        <div className="flex w-full flex-col gap-3 sm:flex-row">
          <Link
            href={`/login?next=${encodeURIComponent(next)}`}
            className="inline-flex flex-1 items-center justify-center rounded-md bg-gold-bright px-5 py-3 text-sm font-semibold text-background transition-colors hover:bg-gold"
          >
            {sessionRole ? "Sign in as a collector" : "Sign in"}
          </Link>
          <Link
            href="/register?role=customer"
            className="inline-flex flex-1 items-center justify-center rounded-md border border-border px-5 py-3 text-sm font-medium text-foreground/85 transition-colors hover:border-gold/40 hover:text-gold-bright"
          >
            Create an account
          </Link>
        </div>
      </div>
    );
  }

  function goToStep(index: number) {
    // Only allow jumping backward, and never once the order is placed.
    if (placedOrder) return;
    if (index < 0 || index > stepIndex) return;
    setStep(STEPS[index].key);
  }

  return (
    <div className="mx-auto flex w-full max-w-2xl flex-col gap-8">
      {/* Scroll anchor: sits above the progress bar with enough offset to
          clear the sticky header. */}
      <div ref={topRef} className="scroll-mt-24" aria-hidden="true" />

      <ol className="flex items-center gap-2" aria-label="Checkout progress">
        {STEPS.map((s, index) => {
          const isComplete =
            index < stepIndex || Boolean(placedOrder && index <= stepIndex);
          const isCurrent = index === stepIndex;
          return (
            <li key={s.key} className="flex flex-1 items-center gap-2">
              <button
                type="button"
                onClick={() => goToStep(index)}
                disabled={index > stepIndex || Boolean(placedOrder)}
                aria-current={isCurrent ? "step" : undefined}
                className={cn(
                  "flex items-center gap-2 rounded-full py-1 pr-3 pl-1 text-sm font-medium transition-colors disabled:cursor-default",
                  isCurrent ? "text-foreground" : "text-muted-foreground",
                )}
              >
                <span
                  className={cn(
                    "flex size-6 shrink-0 items-center justify-center rounded-full border text-xs font-semibold",
                    isComplete
                      ? "border-gold bg-gold-bright text-background"
                      : isCurrent
                        ? "border-gold-bright text-gold-bright"
                        : "border-border text-muted-foreground",
                  )}
                >
                  {isComplete ? (
                    <Check className="size-3.5" strokeWidth={2.5} />
                  ) : (
                    index + 1
                  )}
                </span>
                <span className="hidden sm:inline">{s.label}</span>
              </button>
              {index < STEPS.length - 1 && (
                <span
                  className={cn(
                    "h-px flex-1",
                    index < stepIndex ? "bg-gold/50" : "bg-border",
                  )}
                  aria-hidden="true"
                />
              )}
            </li>
          );
        })}
      </ol>

      <div className="rounded-xl border border-border bg-background/60 p-5 sm:p-7">
        {step === "address" && (
          <CheckoutAddressStep
            selectedAddressId={address?.id ?? null}
            onSelect={setAddress}
            onContinue={() => setStep("review")}
          />
        )}

        {step === "review" && address && (
          <CheckoutReviewStep
            artwork={artwork}
            address={address}
            onBack={() => setStep("address")}
            onContinue={() => setStep("confirm")}
          />
        )}

        {step === "confirm" && address && (
          <CheckoutConfirmStep
            artwork={artwork}
            address={address}
            onBack={() => setStep("review")}
            onOrderPlaced={setPlacedOrder}
            placedOrder={placedOrder}
          />
        )}
      </div>
    </div>
  );
}
