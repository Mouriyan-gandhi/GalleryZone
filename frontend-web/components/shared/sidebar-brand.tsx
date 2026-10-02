"use client";

import Link from "next/link";
import Image from "next/image";
import { PanelLeftClose, PanelLeftOpen } from "lucide-react";
import { cn } from "@/lib/utils";

// The wordmark shown above every portal's side navbar (dashboard, aggregator,
// admin, account) — one shared component so the four shells can never drift
// on which logo file, size, or link they point at.
export function SidebarBrand({ collapsed }: { collapsed?: boolean }) {
  return (
    <Link href="/" className="flex shrink-0 items-center gap-2">
      <Image
        src="/brand/gz-logo.png"
        alt="GalleryZone"
        width={822}
        height={560}
        priority
        className="h-8 w-auto shrink-0"
      />
      <span
        className={cn(
          "text-xs font-medium tracking-[0.18em] text-sidebar-foreground",
          collapsed && "lg:hidden",
        )}
      >
        GALLERYZONE
      </span>
    </Link>
  );
}

// The brand row at the top of every desktop sidebar: brand on the left and the
// collapse toggle on the right. Collapsed, the rail is only 5rem wide, so the
// two stack and centre instead — side by side they leave the logo about 16px,
// which squashes it into a sliver. `children` is for a mobile-only control
// (the drawer's close button) that sits between the two.
export function SidebarHeader({
  collapsed,
  onToggle,
  className,
  children,
}: {
  collapsed: boolean;
  onToggle: () => void;
  className?: string;
  children?: React.ReactNode;
}) {
  return (
    <div
      className={cn(
        "flex h-16 shrink-0 items-center justify-between px-5",
        collapsed && "lg:h-auto lg:flex-col lg:justify-center lg:gap-2 lg:px-0 lg:py-3",
        className,
      )}
    >
      <SidebarBrand collapsed={collapsed} />
      {children}
      <button
        aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
        onClick={onToggle}
        className="hidden rounded-md p-1 text-sidebar-foreground/70 hover:text-sidebar-foreground lg:inline-flex"
      >
        {collapsed ? <PanelLeftOpen className="size-4" /> : <PanelLeftClose className="size-4" />}
      </button>
    </div>
  );
}
