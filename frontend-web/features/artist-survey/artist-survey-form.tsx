"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import {
  AlertCircle,
  ArrowRight,
  Check,
  ChevronsUpDown,
  Loader2,
  Star,
} from "lucide-react";
import { toast } from "sonner";
import { cn } from "@/lib/utils";
import { Button, buttonVariants } from "@/components/ui/button";
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { supabase } from "@/lib/supabase";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import {
  ART_TYPES,
  PAINTING_METHODS,
  REGIONAL_PAINTING_STYLES,
} from "./artist-survey-data";

interface SurveyData {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  country: string;
  state: string;
  city: string;
  artType: string;
  artTypeOther: string;
  paintingMethods: string[];
  paintingMethodOther: string;
  regionalStyle: string;
  regionalStyleOther: string;
  monthlyEarnings: string;
  experience: string;
  satisfaction: number;
}

type FormErrors = Partial<Record<keyof SurveyData, string>>;

const EMPTY_SURVEY: SurveyData = {
  firstName: "",
  lastName: "",
  email: "",
  phone: "",
  country: "",
  state: "",
  city: "",
  artType: "",
  artTypeOther: "",
  paintingMethods: [],
  paintingMethodOther: "",
  regionalStyle: "",
  regionalStyleOther: "",
  monthlyEarnings: "",
  experience: "",
  satisfaction: 0,
};

function toggle(list: string[], value: string): string[] {
  return list.includes(value)
    ? list.filter((v) => v !== value)
    : [...list, value];
}

function validateSurvey(d: SurveyData): FormErrors {
  const errs: FormErrors = {};

  if (!d.firstName.trim()) {
    errs.firstName = "First name is required";
  }

  if (!d.lastName.trim()) {
    errs.lastName = "Last name is required";
  }

  if (!d.email.trim()) {
    errs.email = "Email address is required";
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(d.email.trim())) {
    errs.email = "Please enter a valid email address";
  }

  if (!d.phone.trim()) {
    errs.phone = "Phone number is required";
  } else if (d.phone.trim().length < 5) {
    errs.phone = "Please enter a valid phone number";
  }

  if (!d.country.trim()) {
    errs.country = "Country is required";
  }

  if (!d.state.trim()) {
    errs.state = "State is required";
  }

  if (!d.city.trim()) {
    errs.city = "City is required";
  }

  if (!d.artType) {
    errs.artType = "Please select the type of art you primarily create";
  } else if (d.artType === "Other" && !d.artTypeOther.trim()) {
    errs.artTypeOther = "Please specify your art type";
  }

  if (d.artType === "Painting") {
    if (!d.paintingMethods || d.paintingMethods.length === 0) {
      errs.paintingMethods = "Please select at least one painting method";
    } else if (
      d.paintingMethods.includes("Other") &&
      !d.paintingMethodOther.trim()
    ) {
      errs.paintingMethodOther = "Please specify your painting method";
    }

    if (!d.regionalStyle) {
      errs.regionalStyle = "Please select your type of painting";
    } else if (
      d.regionalStyle === "Other" &&
      !d.regionalStyleOther.trim()
    ) {
      errs.regionalStyleOther = "Please specify your painting style";
    }
  }

  if (!d.monthlyEarnings.trim()) {
    errs.monthlyEarnings = "Monthly earnings is required";
  }

  if (!d.experience.trim()) {
    errs.experience = "Experience duration is required";
  }

  if (!d.satisfaction || d.satisfaction < 1) {
    errs.satisfaction = "Please rate your overall career satisfaction";
  }

  return errs;
}

const FIELD_SCROLL_ORDER: (keyof SurveyData)[] = [
  "firstName",
  "lastName",
  "email",
  "phone",
  "country",
  "state",
  "city",
  "artType",
  "artTypeOther",
  "paintingMethods",
  "paintingMethodOther",
  "regionalStyle",
  "regionalStyleOther",
  "monthlyEarnings",
  "experience",
  "satisfaction",
];

export function ArtistSurveyForm() {
  const [data, setData] = useState<SurveyData>(EMPTY_SURVEY);
  const [errors, setErrors] = useState<FormErrors>({});
  const [hasAttemptedSubmit, setHasAttemptedSubmit] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [openStyleCombo, setOpenStyleCombo] = useState(false);

  useEffect(() => {
    if (submitted) {
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  }, [submitted]);

  function update<K extends keyof SurveyData>(field: K, value: SurveyData[K]) {
    setData((prev) => {
      const next = { ...prev, [field]: value };
      if (hasAttemptedSubmit) {
        setErrors(validateSurvey(next));
      }
      return next;
    });
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setHasAttemptedSubmit(true);

    const validationErrors = validateSurvey(data);
    setErrors(validationErrors);

    const errorKeys = Object.keys(validationErrors) as (keyof SurveyData)[];
    if (errorKeys.length > 0) {
      toast.error("Please fill in all compulsory fields.");

      const firstErrorKey = FIELD_SCROLL_ORDER.find((key) =>
        validationErrors[key],
      );
      if (firstErrorKey) {
        const targetElement =
          document.getElementById(`field-${firstErrorKey}`) ||
          document.getElementById(firstErrorKey);
        if (targetElement) {
          targetElement.scrollIntoView({ behavior: "smooth", block: "center" });
          if (
            targetElement instanceof HTMLInputElement ||
            targetElement instanceof HTMLButtonElement
          ) {
            targetElement.focus();
          }
        }
      }
      return;
    }

    setIsSubmitting(true);

    // This repo builds without Supabase credentials, so the client can be
    // null here where production always has one. Fail loudly rather than
    // throwing on a null client.
    if (!supabase) {
      setIsSubmitting(false);
      toast.error(
        "Survey submission isn't configured in this environment.",
      );
      return;
    }

    const { error } = await supabase.from("artist_survey_responses").insert([
      {
        first_name: data.firstName.trim() || null,
        last_name: data.lastName.trim() || null,
        email: data.email.trim(),
        phone: data.phone.trim(),
        country: data.country.trim() || null,
        state: data.state.trim(),
        city: data.city.trim(),
        art_type: data.artType || null,
        art_type_other:
          data.artType === "Other" ? data.artTypeOther.trim() || null : null,
        painting_methods:
          data.artType === "Painting" && data.paintingMethods.length
            ? data.paintingMethods
            : null,
        painting_method_other:
          data.artType === "Painting" &&
          data.paintingMethods.includes("Other")
            ? data.paintingMethodOther.trim() || null
            : null,
        regional_styles:
          data.artType === "Painting" && data.regionalStyle
            ? [data.regionalStyle]
            : null,
        regional_style_other:
          data.artType === "Painting" && data.regionalStyle === "Other"
            ? data.regionalStyleOther.trim() || null
            : null,
        monthly_earnings: data.monthlyEarnings.trim(),
        experience: data.experience.trim(),
        satisfaction: data.satisfaction || null,
      },
    ]);

    setIsSubmitting(false);

    if (error) {
      toast.error("Failed to submit survey: " + error.message);
    } else {
      setSubmitted(true);
      toast.success("Thanks, your artist survey is in.");
    }
  }

  if (submitted) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: "easeOut" }}
        className="relative mx-auto flex min-h-[26rem] w-full max-w-2xl flex-col items-center justify-center gap-6 overflow-hidden rounded-2xl border border-gold/30 bg-card px-6 py-16 text-center sm:px-12"
      >
        <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-gold/0 via-gold/50 to-gold/0" />
        <span className="flex size-16 items-center justify-center rounded-full border border-gold/40 bg-gold/10">
          <Check className="size-7 text-gold-bright" strokeWidth={1.75} />
        </span>
        <div className="flex flex-col gap-3">
          <h1 className="font-display text-2xl font-semibold text-foreground sm:text-3xl">
            Thanks for filling this in
          </h1>
          <p className="max-w-md text-balance text-sm leading-relaxed text-muted-foreground">
            Your details now have what our curation team needs to feature your
            work well on GalleryZone. We&apos;ll be in touch as our early
            artist program moves forward.
          </p>
        </div>
        <Link
          href="/"
          className={cn(
            buttonVariants({ variant: "default" }),
            "h-10 gap-2 px-5",
          )}
        >
          Back to GalleryZone
          <ArrowRight className="size-4" />
        </Link>
      </motion.div>
    );
  }

  return (
    <form
      noValidate
      onSubmit={handleSubmit}
      className="mx-auto w-full max-w-3xl rounded-2xl border border-border bg-card shadow-sm"
    >
      <div className="border-b border-border px-5 py-7 sm:px-12">
        <h1 className="text-center font-display text-2xl font-semibold text-foreground sm:text-3xl">
          Artist Information and Art Type Survey
        </h1>
      </div>

      <div className="border-b border-border px-5 py-6 sm:px-12">
        <p className="text-sm leading-relaxed text-muted-foreground">
          GalleryZone is a multi-role verified art e-commerce marketplace
          that connects independent artists, curated aggregators
          (distributors), and buyers through a structured, ownership-tracked,
          and finance-transparent platform. Every transaction, transfer, and
          payment is governed by defined rules to protect all parties.
        </p>
        <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
          As our app is in its development phase, we are reaching out to you
          for a collaboration with your content. We believe this
          collaboration will be mutually beneficial, giving you the
          opportunity to become one of the pioneer users of our platform and
          benefit from our future developments. As one of our early
          collaborators, you will also receive a few exclusive benefits and
          privileges that will not be available to other artists.
        </p>
      </div>

      {/* First Name & Last Name */}
      <Question>
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
          <div className="space-y-2" id="field-firstName">
            <SurveyFieldLabel
              htmlFor="firstName"
              hasError={hasAttemptedSubmit && !!errors.firstName}
            >
              First Name
            </SurveyFieldLabel>
            <Input
              id="firstName"
              placeholder="e.g. Rahul"
              value={data.firstName}
              aria-invalid={hasAttemptedSubmit && !!errors.firstName}
              className={cn(
                hasAttemptedSubmit &&
                  errors.firstName &&
                  "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
              )}
              onChange={(e) => update("firstName", e.target.value)}
            />
            {hasAttemptedSubmit && errors.firstName && (
              <FieldError error={errors.firstName} />
            )}
          </div>

          <div className="space-y-2" id="field-lastName">
            <SurveyFieldLabel
              htmlFor="lastName"
              hasError={hasAttemptedSubmit && !!errors.lastName}
            >
              Last Name
            </SurveyFieldLabel>
            <Input
              id="lastName"
              placeholder="e.g. Sharma"
              value={data.lastName}
              aria-invalid={hasAttemptedSubmit && !!errors.lastName}
              className={cn(
                hasAttemptedSubmit &&
                  errors.lastName &&
                  "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
              )}
              onChange={(e) => update("lastName", e.target.value)}
            />
            {hasAttemptedSubmit && errors.lastName && (
              <FieldError error={errors.lastName} />
            )}
          </div>
        </div>
      </Question>

      {/* Email */}
      <Question>
        <div className="space-y-2" id="field-email">
          <SurveyFieldLabel
            htmlFor="email"
            hasError={hasAttemptedSubmit && !!errors.email}
          >
            What is your email address?
          </SurveyFieldLabel>
          <Input
            id="email"
            type="email"
            placeholder="artist@example.com"
            value={data.email}
            aria-invalid={hasAttemptedSubmit && !!errors.email}
            className={cn(
              hasAttemptedSubmit &&
                errors.email &&
                "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
            )}
            onChange={(e) => update("email", e.target.value)}
          />
          {hasAttemptedSubmit && errors.email && (
            <FieldError error={errors.email} />
          )}
        </div>
      </Question>

      {/* Phone */}
      <Question>
        <div className="space-y-2" id="field-phone">
          <SurveyFieldLabel
            htmlFor="phone"
            hasError={hasAttemptedSubmit && !!errors.phone}
          >
            What is your phone number?
          </SurveyFieldLabel>
          <Input
            id="phone"
            type="tel"
            placeholder="+91 98765 43210"
            value={data.phone}
            aria-invalid={hasAttemptedSubmit && !!errors.phone}
            className={cn(
              hasAttemptedSubmit &&
                errors.phone &&
                "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
            )}
            onChange={(e) => update("phone", e.target.value)}
          />
          {hasAttemptedSubmit && errors.phone && (
            <FieldError error={errors.phone} />
          )}
        </div>
      </Question>

      {/* Country, State, City */}
      <Question>
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-3">
          <div className="space-y-2" id="field-country">
            <SurveyFieldLabel
              htmlFor="country"
              hasError={hasAttemptedSubmit && !!errors.country}
            >
              What is your country?
            </SurveyFieldLabel>
            <Input
              id="country"
              placeholder="e.g. India"
              value={data.country}
              aria-invalid={hasAttemptedSubmit && !!errors.country}
              className={cn(
                hasAttemptedSubmit &&
                  errors.country &&
                  "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
              )}
              onChange={(e) => update("country", e.target.value)}
            />
            {hasAttemptedSubmit && errors.country && (
              <FieldError error={errors.country} />
            )}
          </div>

          <div className="space-y-2" id="field-state">
            <SurveyFieldLabel
              htmlFor="state"
              hasError={hasAttemptedSubmit && !!errors.state}
            >
              What is your state?
            </SurveyFieldLabel>
            <Input
              id="state"
              placeholder="e.g. Maharashtra"
              value={data.state}
              aria-invalid={hasAttemptedSubmit && !!errors.state}
              className={cn(
                hasAttemptedSubmit &&
                  errors.state &&
                  "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
              )}
              onChange={(e) => update("state", e.target.value)}
            />
            {hasAttemptedSubmit && errors.state && (
              <FieldError error={errors.state} />
            )}
          </div>

          <div className="space-y-2" id="field-city">
            <SurveyFieldLabel
              htmlFor="city"
              hasError={hasAttemptedSubmit && !!errors.city}
            >
              What is your city?
            </SurveyFieldLabel>
            <Input
              id="city"
              placeholder="e.g. Mumbai"
              value={data.city}
              aria-invalid={hasAttemptedSubmit && !!errors.city}
              className={cn(
                hasAttemptedSubmit &&
                  errors.city &&
                  "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
              )}
              onChange={(e) => update("city", e.target.value)}
            />
            {hasAttemptedSubmit && errors.city && (
              <FieldError error={errors.city} />
            )}
          </div>
        </div>
      </Question>

      {/* Art Type */}
      <Question>
        <div className="space-y-3" id="field-artType">
          <SurveyFieldLabel
            hasError={hasAttemptedSubmit && !!errors.artType}
          >
            What type of art do you primarily create?
          </SurveyFieldLabel>
          <div
            className={cn(
              "rounded-xl transition-colors",
              hasAttemptedSubmit &&
                errors.artType &&
                "p-3 border border-destructive/40 bg-destructive/[0.02]",
            )}
          >
            <RadioGroup
              value={data.artType}
              onValueChange={(value) => update("artType", value)}
              className="gap-2.5"
            >
              {ART_TYPES.map((type) => (
                <div key={type} className="flex items-center gap-2">
                  <RadioGroupItem value={type} id={`art-type-${type}`} />
                  <Label
                    htmlFor={`art-type-${type}`}
                    className="cursor-pointer font-normal"
                  >
                    {type}
                  </Label>
                </div>
              ))}
            </RadioGroup>
          </div>
          {hasAttemptedSubmit && errors.artType && (
            <FieldError error={errors.artType} />
          )}

          {data.artType === "Other" && (
            <div className="space-y-2 pt-1" id="field-artTypeOther">
              <SurveyFieldLabel
                htmlFor="artTypeOther"
                hasError={hasAttemptedSubmit && !!errors.artTypeOther}
              >
                Please specify your art type
              </SurveyFieldLabel>
              <Input
                id="artTypeOther"
                placeholder="e.g. Sculptures, Digital Mixed Media, Ceramic"
                value={data.artTypeOther}
                aria-invalid={hasAttemptedSubmit && !!errors.artTypeOther}
                className={cn(
                  hasAttemptedSubmit &&
                    errors.artTypeOther &&
                    "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
                )}
                onChange={(e) => update("artTypeOther", e.target.value)}
              />
              {hasAttemptedSubmit && errors.artTypeOther && (
                <FieldError error={errors.artTypeOther} />
              )}
            </div>
          )}
        </div>
      </Question>

      {/* Painting conditional fields */}
      {data.artType === "Painting" && (
        <>
          <Question>
            <div className="space-y-3" id="field-paintingMethods">
              <SurveyFieldLabel
                hasError={hasAttemptedSubmit && !!errors.paintingMethods}
              >
                What method of painting do you use?
              </SurveyFieldLabel>
              <div
                className={cn(
                  "flex flex-col gap-2.5 rounded-xl transition-colors",
                  hasAttemptedSubmit &&
                    errors.paintingMethods &&
                    "p-3 border border-destructive/40 bg-destructive/[0.02]",
                )}
              >
                {PAINTING_METHODS.map((method) => (
                  <div key={method} className="flex items-center gap-2">
                    <Checkbox
                      id={`method-${method}`}
                      checked={data.paintingMethods.includes(method)}
                      onCheckedChange={() =>
                        update(
                          "paintingMethods",
                          toggle(data.paintingMethods, method),
                        )
                      }
                    />
                    <Label
                      htmlFor={`method-${method}`}
                      className="cursor-pointer font-normal"
                    >
                      {method}
                    </Label>
                  </div>
                ))}
                <div className="flex items-center gap-2">
                  <Checkbox
                    id="method-other"
                    checked={data.paintingMethods.includes("Other")}
                    onCheckedChange={() =>
                      update(
                        "paintingMethods",
                        toggle(data.paintingMethods, "Other"),
                      )
                    }
                  />
                  <Label
                    htmlFor="method-other"
                    className="cursor-pointer font-normal"
                  >
                    Other
                  </Label>
                </div>
              </div>
              {hasAttemptedSubmit && errors.paintingMethods && (
                <FieldError error={errors.paintingMethods} />
              )}

              {data.paintingMethods.includes("Other") && (
                <div className="space-y-2 pt-1" id="field-paintingMethodOther">
                  <SurveyFieldLabel
                    htmlFor="paintingMethodOther"
                    hasError={hasAttemptedSubmit && !!errors.paintingMethodOther}
                  >
                    Please specify your painting method
                  </SurveyFieldLabel>
                  <Input
                    id="paintingMethodOther"
                    placeholder="e.g. Encaustic, Ink Wash, Spray Paint"
                    value={data.paintingMethodOther}
                    aria-invalid={
                      hasAttemptedSubmit && !!errors.paintingMethodOther
                    }
                    className={cn(
                      hasAttemptedSubmit &&
                        errors.paintingMethodOther &&
                        "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
                    )}
                    onChange={(e) =>
                      update("paintingMethodOther", e.target.value)
                    }
                  />
                  {hasAttemptedSubmit && errors.paintingMethodOther && (
                    <FieldError error={errors.paintingMethodOther} />
                  )}
                </div>
              )}
            </div>
          </Question>

          <Question>
            <div className="space-y-3" id="field-regionalStyle">
              <SurveyFieldLabel
                hasError={hasAttemptedSubmit && !!errors.regionalStyle}
              >
                Type of Painting ?
              </SurveyFieldLabel>
              <div className="block">
                <Popover
                  open={openStyleCombo}
                  onOpenChange={setOpenStyleCombo}
                >
                  <PopoverTrigger
                    id="regionalStyle"
                    className={cn(
                      buttonVariants({ variant: "outline" }),
                      "w-full max-w-sm justify-between text-left font-normal",
                      hasAttemptedSubmit &&
                        errors.regionalStyle &&
                        "border-destructive ring-1 ring-destructive/30 text-destructive-foreground bg-destructive/[0.02]",
                    )}
                    aria-expanded={openStyleCombo}
                  >
                    <span className="truncate">
                      {data.regionalStyle
                        ? data.regionalStyle
                        : "Select painting style..."}
                    </span>
                    <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                  </PopoverTrigger>
                  <PopoverContent className="w-[300px] sm:w-[350px] p-0">
                    <Command>
                      <CommandInput placeholder="Search style..." />
                      <CommandList>
                        <CommandEmpty>No style found.</CommandEmpty>
                        <CommandGroup>
                          {[...REGIONAL_PAINTING_STYLES, "Other"].map(
                            (style) => (
                              <CommandItem
                                key={style}
                                value={style}
                                onSelect={() => {
                                  update(
                                    "regionalStyle",
                                    data.regionalStyle === style
                                      ? ""
                                      : style,
                                  );
                                  setOpenStyleCombo(false);
                                }}
                              >
                                <Check
                                  className={cn(
                                    "mr-2 h-4 w-4",
                                    data.regionalStyle === style
                                      ? "opacity-100"
                                      : "opacity-0",
                                  )}
                                />
                                {style}
                              </CommandItem>
                            ),
                          )}
                        </CommandGroup>
                      </CommandList>
                    </Command>
                  </PopoverContent>
                </Popover>
              </div>
              {hasAttemptedSubmit && errors.regionalStyle && (
                <FieldError error={errors.regionalStyle} />
              )}

              {data.regionalStyle === "Other" && (
                <div className="space-y-2 pt-1" id="field-regionalStyleOther">
                  <SurveyFieldLabel
                    htmlFor="regionalStyleOther"
                    hasError={hasAttemptedSubmit && !!errors.regionalStyleOther}
                  >
                    Please specify your painting style
                  </SurveyFieldLabel>
                  <Input
                    id="regionalStyleOther"
                    placeholder="e.g. Contemporary Impressionism, Abstract Expressionism"
                    value={data.regionalStyleOther}
                    aria-invalid={
                      hasAttemptedSubmit && !!errors.regionalStyleOther
                    }
                    className={cn(
                      hasAttemptedSubmit &&
                        errors.regionalStyleOther &&
                        "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
                    )}
                    onChange={(e) =>
                      update("regionalStyleOther", e.target.value)
                    }
                  />
                  {hasAttemptedSubmit && errors.regionalStyleOther && (
                    <FieldError error={errors.regionalStyleOther} />
                  )}
                </div>
              )}
            </div>
          </Question>
        </>
      )}

      {/* Monthly Earnings */}
      <Question>
        <div className="space-y-2" id="field-monthlyEarnings">
          <SurveyFieldLabel
            htmlFor="monthlyEarnings"
            hasError={hasAttemptedSubmit && !!errors.monthlyEarnings}
          >
            On average, how much do you earn from your art sales per month?
          </SurveyFieldLabel>
          <Input
            id="monthlyEarnings"
            placeholder="e.g. ₹15,000"
            value={data.monthlyEarnings}
            aria-invalid={hasAttemptedSubmit && !!errors.monthlyEarnings}
            className={cn(
              hasAttemptedSubmit &&
                errors.monthlyEarnings &&
                "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
            )}
            onChange={(e) => update("monthlyEarnings", e.target.value)}
          />
          {hasAttemptedSubmit && errors.monthlyEarnings && (
            <FieldError error={errors.monthlyEarnings} />
          )}
        </div>
      </Question>

      {/* Experience */}
      <Question>
        <div className="space-y-2" id="field-experience">
          <SurveyFieldLabel
            htmlFor="experience"
            hasError={hasAttemptedSubmit && !!errors.experience}
          >
            How long have you been creating art professionally?
          </SurveyFieldLabel>
          <Input
            id="experience"
            placeholder="e.g. 3 years"
            value={data.experience}
            aria-invalid={hasAttemptedSubmit && !!errors.experience}
            className={cn(
              hasAttemptedSubmit &&
                errors.experience &&
                "border-destructive ring-1 ring-destructive/30 focus-visible:ring-destructive/40 bg-destructive/[0.02]",
            )}
            onChange={(e) => update("experience", e.target.value)}
          />
          {hasAttemptedSubmit && errors.experience && (
            <FieldError error={errors.experience} />
          )}
        </div>
      </Question>

      {/* Satisfaction Rating */}
      <Question last>
        <div className="space-y-3" id="field-satisfaction">
          <SurveyFieldLabel
            hasError={hasAttemptedSubmit && !!errors.satisfaction}
          >
            How would you rate your overall satisfaction with your current art
            career?
          </SurveyFieldLabel>
          <div
            className={cn(
              "inline-flex items-center gap-2 rounded-xl p-1.5 transition-colors",
              hasAttemptedSubmit &&
                errors.satisfaction &&
                "border border-destructive/40 bg-destructive/[0.02] ring-1 ring-destructive/20",
            )}
          >
            {[1, 2, 3, 4, 5].map((n) => (
              <button
                key={n}
                type="button"
                aria-label={`${n} star${n > 1 ? "s" : ""}`}
                onClick={() =>
                  update("satisfaction", n === data.satisfaction ? 0 : n)
                }
                className="rounded-md p-1 transition-transform hover:scale-110 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              >
                <Star
                  className={cn(
                    "size-7 transition-colors",
                    n <= data.satisfaction
                      ? "fill-gold-bright text-gold-bright"
                      : "text-muted-foreground/40 hover:text-gold-bright/60",
                  )}
                  strokeWidth={1.5}
                />
              </button>
            ))}
          </div>
          {hasAttemptedSubmit && errors.satisfaction && (
            <FieldError error={errors.satisfaction} />
          )}
        </div>
      </Question>

      {/* Submit Button */}
      <div className="flex flex-col items-center gap-3 px-5 py-8 sm:px-12">
        <Button
          type="submit"
          disabled={isSubmitting}
          className="h-11 w-full max-w-xs text-sm font-medium"
        >
          {isSubmitting && <Loader2 className="size-4 animate-spin" />}
          Submit Survey
        </Button>
        <p className="text-center text-xs text-muted-foreground">
          We&apos;ll never ask for passwords or payment details in this survey.
        </p>
      </div>
    </form>
  );
}

function Question({
  children,
  last = false,
}: {
  children: React.ReactNode;
  last?: boolean;
}) {
  return (
    <div
      className={cn("px-5 py-6 sm:px-12", !last && "border-b border-border")}
    >
      {children}
    </div>
  );
}

function SurveyFieldLabel({
  htmlFor,
  hasError,
  children,
  className,
}: {
  htmlFor?: string;
  hasError?: boolean;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <Label
      htmlFor={htmlFor}
      className={cn("inline-flex items-center gap-1 font-medium", className)}
    >
      <span>{children}</span>
      {hasError && (
        <span
          className="font-bold text-destructive animate-in fade-in zoom-in-75 duration-200"
          aria-hidden="true"
          title="Required field"
        >
          *
        </span>
      )}
    </Label>
  );
}

function FieldError({ error }: { error: string }) {
  return (
    <p className="mt-1.5 flex items-center gap-1.5 text-xs font-medium text-destructive animate-in fade-in slide-in-from-top-1 duration-200">
      <AlertCircle className="size-3.5 shrink-0" />
      <span>{error}</span>
    </p>
  );
}
