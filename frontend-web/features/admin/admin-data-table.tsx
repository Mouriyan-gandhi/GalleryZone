"use client";

import { Fragment, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ArrowDown,
  ArrowUp,
  ArrowUpDown,
  Inbox,
  Search,
  SearchX,
  type LucideIcon,
} from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Pagination,
  PaginationContent,
  PaginationEllipsis,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from "@/components/ui/pagination";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { EmptyState } from "@/components/shared/empty-state";
import { cn } from "@/lib/utils";

// ---------------------------------------------------------------------------
// The one table every admin section renders. Column config in, search +
// dropdown filters + click-to-sort + offset pagination + skeleton + empty
// state out.
//
// Offset pagination with numbered pages rather than infinite scroll or a
// cursor, per SAD Section 9.3: jump-to-page is the navigation admins actually
// use. Row virtualization (SAD 9.6) is deliberately absent -- see spec Section 7:
// it exists for 10,000-row production tables, and this build's fixtures are
// dozens of rows, so it would be complexity with no visible benefit.
// ---------------------------------------------------------------------------

export interface AdminDataTableColumn<T> {
  key: string;
  header: string;
  render: (row: T) => React.ReactNode;
  sortable?: boolean;
  /**
   * The value this column sorts by. Optional: when a column is `sortable`
   * without one, the table falls back to `row[key]` if that happens to be a
   * string or number. Pass it explicitly whenever the cell renders something
   * derived (a formatted date, a joined name, a badge).
   */
  sortValue?: (row: T) => string | number;
  className?: string;
}

export interface AdminDataTableFilter<T> {
  key: string;
  label: string;
  options: Array<{ value: string; label: string }>;
  /** Called only for real option values; the "All" case never reaches it. */
  matches: (row: T, value: string) => boolean;
  /**
   * Which option is selected on first render. Defaults to "all". The
   * withdrawal queue uses this to open on `pending` while still offering the
   * full list.
   */
  defaultValue?: string;
}

export interface AdminDataTableProps<T> {
  rows: T[];
  columns: AdminDataTableColumn<T>[];
  isLoading?: boolean;
  getRowKey: (row: T) => string;
  /** Whole-row link when provided. */
  getRowHref?: (row: T) => string;
  /** Row click without navigation, for detail drawers. Ignored if getRowHref is set. */
  onRowClick?: (row: T) => void;
  /** Accessible name for the row link/button. Defaults to getRowKey. */
  getRowLabel?: (row: T) => string;
  searchPlaceholder?: string;
  /** The concatenated text a row is searched by. Omit to hide the search input. */
  searchValue?: (row: T) => string;
  filters?: Array<AdminDataTableFilter<T>>;
  pageSize?: number;
  emptyTitle: string;
  emptyDescription: string;
  emptyIcon?: LucideIcon;
  className?: string;
}

const ALL = "all";

type SortState = { key: string; direction: "asc" | "desc" } | null;

function readField<T>(row: T, key: string): string | number {
  const value = (row as unknown as Record<string, unknown>)[key];
  return typeof value === "number" || typeof value === "string" ? value : "";
}

function compareValues(a: string | number, b: string | number) {
  if (typeof a === "number" && typeof b === "number") return a - b;
  // numeric: true so "Order 2" sorts before "Order 10", sensitivity: "base" so
  // casing doesn't split otherwise-identical names.
  return String(a).localeCompare(String(b), undefined, {
    numeric: true,
    sensitivity: "base",
  });
}

// 1 ... 4 5 6 ... 20 -- always shows first, last, and the current page's
// neighbours, so the control keeps a stable width however many pages exist.
function pageWindow(current: number, total: number): Array<number | "gap"> {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);

  const pages = new Set<number>([1, total, current, current - 1, current + 1]);
  const sorted = [...pages]
    .filter((p) => p >= 1 && p <= total)
    .sort((a, b) => a - b);

  const result: Array<number | "gap"> = [];
  let previous = 0;
  for (const page of sorted) {
    if (previous && page - previous > 1) result.push("gap");
    result.push(page);
    previous = page;
  }
  return result;
}

export function AdminDataTable<T>({
  rows,
  columns,
  isLoading = false,
  getRowKey,
  getRowHref,
  onRowClick,
  getRowLabel,
  searchPlaceholder = "Search...",
  searchValue,
  filters,
  pageSize = 15,
  emptyTitle,
  emptyDescription,
  emptyIcon = Inbox,
  className,
}: AdminDataTableProps<T>) {
  const router = useRouter();
  const [draft, setDraft] = useState("");
  const [query, setQuery] = useState("");
  const [sort, setSort] = useState<SortState>(null);
  const [page, setPage] = useState(1);
  const [filterValues, setFilterValues] = useState<Record<string, string>>(() =>
    Object.fromEntries(
      (filters ?? []).map((f) => [f.key, f.defaultValue ?? ALL]),
    ),
  );

  // Same 300ms debounce as features/marketplace/marketplace-search-bar.tsx:
  // typing shouldn't re-filter (and reset pagination) on every keystroke.
  useEffect(() => {
    const timeout = setTimeout(() => {
      setQuery(draft);
      setPage(1);
    }, 300);
    return () => clearTimeout(timeout);
  }, [draft]);

  const activeFilters = useMemo(
    () => (filters ?? []).filter((f) => (filterValues[f.key] ?? ALL) !== ALL),
    [filters, filterValues],
  );

  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return rows.filter((row) => {
      if (
        needle &&
        searchValue &&
        !searchValue(row).toLowerCase().includes(needle)
      ) {
        return false;
      }
      return activeFilters.every((filter) =>
        filter.matches(row, filterValues[filter.key]),
      );
    });
  }, [rows, query, searchValue, activeFilters, filterValues]);

  const sorted = useMemo(() => {
    if (!sort) return filtered;
    const column = columns.find((c) => c.key === sort.key);
    if (!column) return filtered;

    const value = (row: T) =>
      column.sortValue ? column.sortValue(row) : readField(row, column.key);

    // Copied before sorting: `rows` is query-cache data and must not be mutated.
    return [...filtered].sort((a, b) => {
      const result = compareValues(value(a), value(b));
      return sort.direction === "asc" ? result : -result;
    });
  }, [filtered, sort, columns]);

  const totalPages = Math.max(1, Math.ceil(sorted.length / pageSize));
  // Clamped during render rather than corrected in an effect, so deleting the
  // last row of the last page can't flash an empty table before it settles.
  const currentPage = Math.min(page, totalPages);
  const start = (currentPage - 1) * pageSize;
  const pageRows = sorted.slice(start, start + pageSize);

  // One click rule for the table row and the phone card. The click is a mouse
  // convenience on top of a real link/button, and bails out when it landed on
  // something already interactive, so action buttons inside cells keep working
  // without every call site having to stopPropagation.
  function activateRow(row: T, href: string | undefined) {
    return (event: React.MouseEvent) => {
      const target = event.target as HTMLElement;
      if (target.closest("a,button,input,select,textarea")) return;
      if (href) router.push(href);
      else onRowClick?.(row);
    };
  }

  const hasToolbar = Boolean(searchValue) || Boolean(filters?.length);
  const isFilteredEmpty = !isLoading && rows.length > 0 && sorted.length === 0;

  function toggleSort(column: AdminDataTableColumn<T>) {
    if (!column.sortable) return;
    setPage(1);
    setSort((current) => {
      if (current?.key !== column.key)
        return { key: column.key, direction: "asc" };
      if (current.direction === "asc")
        return { key: column.key, direction: "desc" };
      // Third click clears, restoring whatever order the caller passed in
      // (queues arrive oldest-first and that ordering is meaningful).
      return null;
    });
  }

  function clearAll() {
    setDraft("");
    setQuery("");
    setFilterValues(
      Object.fromEntries((filters ?? []).map((f) => [f.key, ALL])),
    );
    setPage(1);
  }

  return (
    <div
      className={cn(
        "overflow-hidden rounded-lg border border-border bg-card",
        className,
      )}
    >
      {hasToolbar && (
        <div className="flex flex-col gap-2 border-b border-border px-3 py-2.5 sm:flex-row sm:items-center">
          {searchValue && (
            <div className="relative sm:max-w-xs sm:flex-1">
              <Search
                className="pointer-events-none absolute top-1/2 left-2.5 size-3.5 -translate-y-1/2 text-muted-foreground"
                strokeWidth={1.75}
              />
              <Input
                type="search"
                value={draft}
                onChange={(event) => setDraft(event.target.value)}
                placeholder={searchPlaceholder}
                aria-label={searchPlaceholder}
                className="h-8 pl-7.5"
              />
            </div>
          )}

          {filters && filters.length > 0 && (
            <div className="grid grid-cols-2 gap-2 sm:ml-auto sm:flex sm:flex-wrap sm:items-center">
              {filters.map((filter, filterIndex) => {
                // A caller may or may not include its own "all" option; inject
                // one only when it hasn't, so the choice is never duplicated.
                const hasAllOption = filter.options.some(
                  (o) => o.value === ALL,
                );
                const allLabel = `All ${filter.label}`;
                return (
                  <Select
                    key={filter.key}
                    value={filterValues[filter.key] ?? ALL}
                    onValueChange={(value) => {
                      setFilterValues((current) => ({
                        ...current,
                        [filter.key]: String(value),
                      }));
                      setPage(1);
                    }}
                  >
                    <SelectTrigger
                      size="sm"
                      className={cn(
                        "h-8 w-full sm:w-[160px]",
                        // An odd last filter takes the whole row on phones.
                        filters.length % 2 === 1 &&
                          filterIndex === filters.length - 1 &&
                          "col-span-2 sm:col-span-1",
                      )}
                      aria-label={filter.label}
                    >
                      {/* Base UI's Select.Value renders the raw value unless
                          given a formatter, and "pending" in a trigger reads
                          worse than the option's own label. */}
                      <SelectValue>
                        {(value: unknown) =>
                          filter.options.find((o) => o.value === value)
                            ?.label ?? allLabel
                        }
                      </SelectValue>
                    </SelectTrigger>
                    <SelectContent>
                      {!hasAllOption && (
                        <SelectItem value={ALL}>{allLabel}</SelectItem>
                      )}
                      {filter.options.map((option) => (
                        <SelectItem key={option.value} value={option.value}>
                          {option.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                );
              })}
            </div>
          )}
        </div>
      )}

      {!isLoading && rows.length === 0 ? (
        <EmptyState
          icon={emptyIcon}
          title={emptyTitle}
          description={emptyDescription}
          className="rounded-none border-0"
        />
      ) : isFilteredEmpty ? (
        <EmptyState
          icon={SearchX}
          title="No matching results"
          description="Nothing here matches the current search and filters."
          className="rounded-none border-0"
          action={
            <Button variant="outline" size="sm" onClick={clearAll}>
              Clear search and filters
            </Button>
          }
        />
      ) : (
        <>
        {/* Below lg the same columns render as a card list (see below): a
            5-6 column table is unreadable in a 280px window, and nothing about
            it says "scroll sideways". */}
        <div className="hidden overflow-x-auto lg:block">
          <table className="w-full border-collapse text-left">
            <thead className="border-b border-border bg-muted/40">
              <tr>
                {columns.map((column) => {
                  const active = sort?.key === column.key;
                  const SortIcon = !active
                    ? ArrowUpDown
                    : sort.direction === "asc"
                      ? ArrowUp
                      : ArrowDown;

                  return (
                    <th
                      key={column.key}
                      scope="col"
                      aria-sort={
                        active
                          ? sort.direction === "asc"
                            ? "ascending"
                            : "descending"
                          : undefined
                      }
                      className={cn(
                        "px-4 py-2.5 text-[11px] font-medium tracking-[0.08em] whitespace-nowrap text-muted-foreground uppercase",
                        column.className,
                      )}
                    >
                      {column.sortable ? (
                        <button
                          type="button"
                          onClick={() => toggleSort(column)}
                          className={cn(
                            "inline-flex items-center gap-1.5 rounded-sm transition-colors hover:text-foreground focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
                            active && "text-foreground",
                          )}
                        >
                          {column.header}
                          <SortIcon
                            className={cn(
                              "size-3 transition-opacity",
                              active ? "text-gold-bright" : "opacity-50",
                            )}
                            strokeWidth={2}
                          />
                        </button>
                      ) : (
                        column.header
                      )}
                    </th>
                  );
                })}
              </tr>
            </thead>

            <tbody>
              {isLoading
                ? Array.from({ length: Math.min(pageSize, 8) }).map(
                    (_, rowIndex) => (
                      <tr
                        key={rowIndex}
                        className="border-b border-border/60 last:border-0"
                      >
                        {columns.map((column) => (
                          <td key={column.key} className="px-4 py-3">
                            <Skeleton className="h-4 w-[70%] min-w-16" />
                          </td>
                        ))}
                      </tr>
                    ),
                  )
                : pageRows.map((row) => {
                    const href = getRowHref?.(row);
                    const label = getRowLabel?.(row) ?? getRowKey(row);
                    const interactive = Boolean(href) || Boolean(onRowClick);

                    return (
                      <tr
                        key={getRowKey(row)}
                        // `relative` scopes the stretched link below to this
                        // row. The row-level click is a mouse convenience on
                        // top of that real link, and bails out when the click
                        // landed on something already interactive, so action
                        // buttons inside cells keep working without every call
                        // site having to stopPropagation.
                        onClick={
                          interactive ? activateRow(row, href) : undefined
                        }
                        className={cn(
                          "relative border-b border-border/60 transition-colors last:border-0",
                          interactive && "cursor-pointer hover:bg-muted/40",
                        )}
                      >
                        {columns.map((column, columnIndex) => (
                          <td
                            key={column.key}
                            className={cn(
                              "px-4 py-3 align-middle text-sm text-foreground",
                              column.className,
                            )}
                          >
                            {columnIndex === 0 && href && (
                              // z-0 keeps the overlay under the cell contents,
                              // so text stays selectable and in-cell controls
                              // stay clickable, while the anchor itself is
                              // still focusable and shows a full-row ring.
                              <Link
                                href={href}
                                className="absolute inset-0 z-0 rounded-md focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
                              >
                                <span className="sr-only">{label}</span>
                              </Link>
                            )}
                            {columnIndex === 0 && !href && onRowClick && (
                              <button
                                type="button"
                                onClick={() => onRowClick(row)}
                                className="absolute inset-0 z-0 rounded-md focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
                              >
                                <span className="sr-only">{label}</span>
                              </button>
                            )}
                            {/* `relative` stacks the cell's own content above
                                the row overlay so text stays selectable. */}
                            <div className="relative">{column.render(row)}</div>
                          </td>
                        ))}
                      </tr>
                    );
                  })}
            </tbody>
          </table>
        </div>

        <ul className="divide-y divide-border/60 lg:hidden">
          {isLoading
            ? Array.from({ length: Math.min(pageSize, 4) }).map((_, i) => (
                <li key={i} className="space-y-2 px-4 py-3">
                  <Skeleton className="h-4 w-3/5" />
                  <Skeleton className="h-3 w-4/5" />
                </li>
              ))
            : pageRows.map((row) => {
                const href = getRowHref?.(row);
                const label = getRowLabel?.(row) ?? getRowKey(row);
                const interactive = Boolean(href) || Boolean(onRowClick);
                const [primary, ...rest] = columns;
                // Same overlay + content stacking as the table row: the
                // stretched link sits at z-0, content is `relative` above it.
                const cells = rest.map((c) => ({ c, node: c.render(row) }));
                const fields = cells.filter(({ c, node }) => c.header && node != null && node !== false);
                const actions = cells.filter(({ c, node }) => !c.header && node != null && node !== false);

                return (
                  <li
                    key={getRowKey(row)}
                    onClick={interactive ? activateRow(row, href) : undefined}
                    className={cn(
                      "relative px-4 py-3",
                      interactive && "cursor-pointer active:bg-muted/40",
                    )}
                  >
                    {href && (
                      <Link
                        href={href}
                        className="absolute inset-0 z-0 rounded-md focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
                      >
                        <span className="sr-only">{label}</span>
                      </Link>
                    )}
                    {!href && onRowClick && (
                      <button
                        type="button"
                        onClick={() => onRowClick(row)}
                        className="absolute inset-0 z-0 rounded-md focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
                      >
                        <span className="sr-only">{label}</span>
                      </button>
                    )}
                    <div className="relative min-w-0">{primary.render(row)}</div>
                    {fields.length > 0 && (
                      <dl className="relative mt-2.5 grid grid-cols-[auto_minmax(0,1fr)] items-center gap-x-4 gap-y-1.5 text-sm">
                        {fields.map(({ c, node }) => (
                          <Fragment key={c.key}>
                            <dt className="text-xs text-muted-foreground">{c.header}</dt>
                            <dd className="flex min-w-0 justify-end text-right">{node}</dd>
                          </Fragment>
                        ))}
                      </dl>
                    )}
                    {actions.map(({ c, node }) => (
                      <div key={c.key} className="relative mt-3">{node}</div>
                    ))}
                  </li>
                );
              })}
        </ul>
        </>
      )}

      {!isLoading && sorted.length > 0 && (
        <div className="flex flex-col gap-2 border-t border-border px-3 py-2.5 text-xs text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
          <span className="tabular-nums">
            Showing {start + 1} to {Math.min(start + pageSize, sorted.length)}{" "}
            of {sorted.length}
          </span>

          {totalPages > 1 && (
            <Pagination className="mx-0 w-auto justify-start">
              <PaginationContent className="gap-1.5">
                <PaginationItem>
                  <PaginationPrevious
                    href="#"
                    text="Back"
                    aria-disabled={currentPage === 1}
                    tabIndex={currentPage === 1 ? -1 : undefined}
                    onClick={(event) => {
                      event.preventDefault();
                      if (currentPage > 1) setPage(currentPage - 1);
                    }}
                    className={cn(
                      "h-7 px-2.5 text-xs transition-colors hover:bg-muted",
                      currentPage === 1 && "pointer-events-none opacity-40",
                    )}
                  />
                </PaginationItem>

                {pageWindow(currentPage, totalPages).map((entry, index) =>
                  entry === "gap" ? (
                    <PaginationItem key={`gap-${index}`}>
                      <PaginationEllipsis />
                    </PaginationItem>
                  ) : (
                    <PaginationItem key={entry}>
                      <PaginationLink
                        href="#"
                        size="icon-sm"
                        isActive={entry === currentPage}
                        aria-label={`Page ${entry}`}
                        onClick={(event) => {
                          event.preventDefault();
                          setPage(entry);
                        }}
                        className={cn(
                          "tabular-nums transition-all",
                          entry === currentPage
                            ? "!border-primary/50 scale-110 text-gold-bright shadow-md"
                            : "hover:bg-muted active:scale-90",
                        )}
                      >
                        {entry}
                      </PaginationLink>
                    </PaginationItem>
                  ),
                )}

                <PaginationItem>
                  <PaginationNext
                    href="#"
                    text="Next"
                    aria-disabled={currentPage === totalPages}
                    tabIndex={currentPage === totalPages ? -1 : undefined}
                    onClick={(event) => {
                      event.preventDefault();
                      if (currentPage < totalPages) setPage(currentPage + 1);
                    }}
                    className={cn(
                      "h-7 px-2.5 text-xs transition-colors hover:bg-muted",
                      currentPage === totalPages &&
                        "pointer-events-none opacity-40",
                    )}
                  />
                </PaginationItem>
              </PaginationContent>
            </Pagination>
          )}
        </div>
      )}
    </div>
  );
}
