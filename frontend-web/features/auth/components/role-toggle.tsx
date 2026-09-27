"use client";

import type { LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

interface RoleToggleOption<T extends string> {
  value: T;
  label: string;
  icon?: LucideIcon;
}

interface RoleToggleProps<T extends string> {
  options: RoleToggleOption<T>[];
  value: T;
  onChange: (value: T) => void;
  className?: string;
}

// Separate standalone buttons, not one connected segmented pill — each role
// is its own discrete choice, not steps along a single track. Shared by
// Register (3 self-service roles) and Login (those 3 plus Admin — this
// toggle IS how "sign in as" works here, since there's no backend to know
// an account's role).
export function RoleToggle<T extends string>({
  options,
  value,
  onChange,
  className,
}: RoleToggleProps<T>) {
  return (
    <div role="radiogroup" className={cn("flex gap-2", className)}>
      {options.map((option) => {
        const isActive = option.value === value;
        const Icon = option.icon;
        return (
          <button
            key={option.value}
            type="button"
            role="radio"
            aria-checked={isActive}
            onClick={() => onChange(option.value)}
            className={cn(
              "flex min-w-0 flex-1 items-center justify-center gap-1.5 rounded-full border px-2 py-2 text-[13px] font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/50 sm:px-3 sm:text-sm",
              isActive
                ? "border-gold-bright bg-gold-bright text-[#171310]"
                : "border-border text-muted-foreground hover:border-gold-bright/50 hover:text-foreground",
            )}
          >
            {/* Icons return from sm up; without them all three roles fit one row on a 320px phone. */}
            {Icon && <Icon className="hidden size-4 shrink-0 sm:block" />}
            <span className="truncate">{option.label}</span>
          </button>
        );
      })}
    </div>
  );
}
