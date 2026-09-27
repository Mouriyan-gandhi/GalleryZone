"use client";

import { useState } from "react";
import {
  Controller,
  type Control,
  type FieldPath,
  type FieldValues,
} from "react-hook-form";
import { Eye, EyeOff, type LucideIcon } from "lucide-react";
import { Input } from "@/components/ui/input";
import {
  Field,
  FieldLabel,
  FieldDescription,
  FieldError,
} from "@/components/ui/field";
import { cn } from "@/lib/utils";

interface AuthTextFieldProps<TFieldValues extends FieldValues> {
  control: Control<TFieldValues>;
  name: FieldPath<TFieldValues>;
  label: string;
  type?: string;
  placeholder?: string;
  autoComplete?: string;
  description?: string;
  icon?: LucideIcon;
}

const EMAIL_DOMAINS = [
  "gmail.com",
  "yahoo.com",
  "outlook.com",
  "icloud.com",
  "zoho.com",
];

const PHONE_LENGTH = 10;

// Every Auth form (Register/Login/Forgot/Reset) needs the same
// Controller + Field/FieldLabel/FieldError wiring (see plan Global
// Constraints: this project's shadcn style has no real Form/FormField, so
// every field is Controller + Field by hand) for a handful of plain text/
// email/password/tel inputs. Generic over TFieldValues so one component
// serves every form's distinct Zod-inferred input type without a cast.
export function AuthTextField<TFieldValues extends FieldValues>({
  control,
  name,
  label,
  type = "text",
  placeholder,
  autoComplete,
  description,
  icon: Icon,
}: AuthTextFieldProps<TFieldValues>) {
  // Toggle lives here (not per-caller) so every password field in the app
  // gets show/hide for free — see auth-schemas.ts / register-form.tsx.
  const [revealed, setRevealed] = useState(false);
  const isPassword = type === "password";
  const isEmail = type === "email";
  const isPhone = type === "tel";
  const inputType = isPassword && revealed ? "text" : type;

  // Same reasoning for the @domain dropdown: lives here once so every email
  // field (login, register, forgot-password) gets it for free.
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [activeIndex, setActiveIndex] = useState(-1);

  return (
    <Controller
      control={control}
      name={name}
      render={({ field, fieldState }) => {
        const value = typeof field.value === "string" ? field.value : "";
        const atIndex = value.lastIndexOf("@");
        const localPart = atIndex >= 0 ? value.slice(0, atIndex) : "";
        const domainQuery = atIndex >= 0 ? value.slice(atIndex + 1) : null;

        let suggestions: string[] = [];
        if (isEmail && domainQuery !== null) {
          suggestions = EMAIL_DOMAINS.filter((domain) =>
            domain.startsWith(domainQuery.toLowerCase()),
          );
          // Nothing left to suggest once the typed domain already matches one
          // exactly — a dropdown offering the value already in the box is noise.
          if (
            suggestions.length === 1 &&
            suggestions[0] === domainQuery.toLowerCase()
          ) {
            suggestions = [];
          }
        }
        const suggestionsOpen =
          isEmail && showSuggestions && suggestions.length > 0;

        function selectDomain(domain: string) {
          field.onChange(`${localPart}@${domain}`);
          setShowSuggestions(false);
          setActiveIndex(-1);
        }

        return (
          <Field data-invalid={fieldState.invalid}>
            <FieldLabel htmlFor={field.name}>{label}</FieldLabel>
            <div className="relative">
              {Icon && (
                <Icon
                  aria-hidden="true"
                  className="pointer-events-none absolute top-1/2 left-3.5 size-4 -translate-y-1/2 text-muted-foreground"
                />
              )}
              <Input
                id={field.name}
                type={inputType}
                placeholder={placeholder}
                autoComplete={autoComplete}
                inputMode={isPhone ? "numeric" : undefined}
                maxLength={isPhone ? PHONE_LENGTH : undefined}
                aria-invalid={fieldState.invalid}
                aria-expanded={isEmail ? suggestionsOpen : undefined}
                role={isEmail ? "combobox" : undefined}
                name={field.name}
                ref={field.ref}
                value={value}
                onChange={(e) => {
                  if (isPhone) {
                    field.onChange(
                      e.target.value.replace(/\D/g, "").slice(0, PHONE_LENGTH),
                    );
                    return;
                  }
                  field.onChange(e);
                  if (isEmail) {
                    setShowSuggestions(true);
                    setActiveIndex(-1);
                  }
                }}
                onFocus={() => isEmail && setShowSuggestions(true)}
                onBlur={() => {
                  field.onBlur();
                  setShowSuggestions(false);
                  setActiveIndex(-1);
                }}
                onKeyDown={(e) => {
                  if (!suggestionsOpen) return;
                  if (e.key === "ArrowDown") {
                    e.preventDefault();
                    setActiveIndex((i) => Math.min(i + 1, suggestions.length - 1));
                  } else if (e.key === "ArrowUp") {
                    e.preventDefault();
                    setActiveIndex((i) => Math.max(i - 1, 0));
                  } else if (e.key === "Enter" && activeIndex >= 0) {
                    e.preventDefault();
                    selectDomain(suggestions[activeIndex]);
                  } else if (e.key === "Escape") {
                    setShowSuggestions(false);
                    setActiveIndex(-1);
                  }
                }}
                className={cn(
                  "h-11 rounded-xl bg-muted/30 px-4",
                  Icon && "pl-10",
                  isPassword && "pr-12",
                )}
              />
              {isPassword && (
                <button
                  type="button"
                  onClick={() => setRevealed((current) => !current)}
                  aria-label={revealed ? "Hide password" : "Show password"}
                  className="absolute top-1/2 right-1 flex size-10 -translate-y-1/2 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground"
                >
                  {revealed ? (
                    <EyeOff className="size-4" />
                  ) : (
                    <Eye className="size-4" />
                  )}
                </button>
              )}

              {suggestionsOpen && (
                <div
                  role="listbox"
                  className="absolute top-full left-0 z-20 mt-1.5 w-full overflow-hidden rounded-xl border border-border bg-popover py-1 shadow-lg"
                >
                  {suggestions.map((domain, index) => (
                    <button
                      key={domain}
                      type="button"
                      role="option"
                      aria-selected={index === activeIndex}
                      // mousedown + preventDefault fires before the input's
                      // blur, so the click registers instead of the dropdown
                      // closing out from under it.
                      onMouseDown={(e) => {
                        e.preventDefault();
                        selectDomain(domain);
                      }}
                      onMouseEnter={() => setActiveIndex(index)}
                      className={cn(
                        "flex w-full items-center px-4 py-2 text-left text-sm transition-colors",
                        index === activeIndex
                          ? "bg-muted"
                          : "hover:bg-muted",
                      )}
                    >
                      <span className="text-muted-foreground">
                        {localPart}@
                      </span>
                      <span className="font-medium text-foreground">
                        {domain}
                      </span>
                    </button>
                  ))}
                </div>
              )}
            </div>
            {description && <FieldDescription>{description}</FieldDescription>}
            <FieldError errors={[fieldState.error]} />
          </Field>
        );
      }}
    />
  );
}
