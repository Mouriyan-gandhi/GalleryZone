"use client";

import { UserAvatar } from "@/components/shared/user-avatar";

import { useMemo, useRef, useState } from "react";
import Image from "next/image";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { toast } from "sonner";
import {
  Check,
  Loader2,
  ShieldCheck,
  Building2,
  Lock,
  UserRoundCog,
  BellRing,
  Fingerprint,
  Camera,
} from "lucide-react";
import { Input } from "@/components/ui/input";
import { GSTIN_PATTERN } from "@/components/shared/gst-number-card";
import { GstStatusBadge } from "@/components/shared/gst-status-badge";
import { UniSwapDialog, type Country } from "@/components/shared/uniswap-dialog";
import { Field, FieldLabel, FieldError } from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  useAggregatorProfile,
  useUpdateAggregatorProfileMutation,
} from "@/hooks/useAggregatorProfile";
import {
  COUNTRY_CODES,
  DEFAULT_COUNTRY_DIAL,
  joinPhone,
  splitPhone,
} from "./country-codes";

const DESIGNATION_PRESETS = [
  "Gallery Manager",
  "Owner or Director",
  "Operations Manager",
] as const;
const DESIGNATION_OTHER = "__other__";

const EMAIL_DOMAIN_SUGGESTIONS = ["gmail.com", "yahoo.com"];

// The business-address country picker (UniSwapDialog) speaks {name, code};
// reuse the same curated list the phone dial-code field already has rather
// than inventing a second country list.
const COUNTRY_OPTIONS: Country[] = COUNTRY_CODES.map((c) => ({ name: c.label, code: c.iso }));

// Same flag picker, keyed by ISO for the flag image, but the phone field
// actually stores/needs the dial code — map dial <-> iso through
// COUNTRY_CODES rather than teaching UniSwapDialog a second identity shape.
const DIAL_OPTIONS: Country[] = COUNTRY_CODES.map((c) => ({ name: `${c.dial} ${c.label}`, code: c.iso }));

function DialCodePicker({
  value,
  onChange,
}: {
  value: string;
  onChange: (dial: string) => void;
}) {
  const iso = COUNTRY_CODES.find((c) => c.dial === value)?.iso ?? COUNTRY_CODES[0].iso;
  const selected = DIAL_OPTIONS.find((o) => o.code === iso) ?? DIAL_OPTIONS[0];
  return (
    <div className="shrink-0">
      <UniSwapDialog
        value={selected}
        countries={DIAL_OPTIONS}
        title="Select dial code"
        onChange={(country) => {
          const dial = COUNTRY_CODES.find((c) => c.iso === country.code)?.dial ?? DEFAULT_COUNTRY_DIAL;
          onChange(dial);
        }}
      />
    </div>
  );
}

// A number's local part (dial code stripped off) has to fall in this range
// regardless of which country it's from -- E.164 caps the whole number at 15
// digits, and nothing real is shorter than 6.
const PHONE_NUMBER_PATTERN = /^[0-9]{6,14}$/;
function isValidPhoneNumber(value: string): boolean {
  return PHONE_NUMBER_PATTERN.test(value.replace(/\s+/g, ""));
}

// 12 digits, optionally grouped as 4-4-4 the way Aadhaar is normally printed.
const AADHAAR_PATTERN = /^[0-9]{12}$/;

type AggregatorProfileData = NonNullable<
  ReturnType<typeof useAggregatorProfile>["data"]
>;

const profileSchema = z.object({
  companyName: z.string().trim().min(2, "Enter your company name"),
  contactPerson: z.string().trim().min(2, "Enter a contact person"),
  // Blank still saves, so the rest of the profile can be filled in first, but
  // an aggregator can't reserve until an approved GST number is on file
  // (client, 30 Sep 2026). A number that IS entered has to be the right shape.
  gstNumber: z
    .string()
    .trim()
    .refine(
      (value) => value.length === 0 || GSTIN_PATTERN.test(value),
      "Enter a valid 15-character GSTIN, or leave it blank",
    ),
  phone: z
    .string()
    .trim()
    .refine(isValidPhoneNumber, "Enter a valid phone number"),
  country: z.string().trim().min(2, "Select a country"),
  addressLine1: z.string().trim().min(5, "Enter your business address"),
  // The MOU's Address blank and GalleryZone's shipments both need the full address.
  addressCity: z.string().trim().min(2, "Enter the city"),
  addressState: z.string().trim().min(2, "Enter the state"),
  addressPincode: z.string().trim().regex(/^[1-9][0-9]{5}$/, "Enter the 6-digit PIN code"),
  // MOU §10 requires one nominated GalleryZone coordinator per premises. All
  // three are required: audit notices, expiry reminders and inbound shipment
  // alerts go to this person, so a half-filled contact is no contact.
  coordinatorDesignation: z
    .string()
    .trim()
    .min(2, "Enter their role, e.g. Gallery Manager"),
  coordinatorPhone: z
    .string()
    .trim()
    .refine(isValidPhoneNumber, "Enter a valid phone number"),
  coordinatorEmail: z.string().trim().email("Enter a valid email address"),
});
type ProfileFormValues = z.infer<typeof profileSchema>;

const identitySchema = z.object({
  aadhaarNumber: z
    .string()
    .trim()
    .refine(
      (value) => AADHAAR_PATTERN.test(value.replace(/\s+/g, "")),
      "Enter a valid 12-digit Aadhaar number",
    ),
});
type IdentityFormValues = z.infer<typeof identitySchema>;

// Mirrors artistDashboardService.updateBankDetails's masking contract:
// only the last 4 digits are ever persisted/displayed, so the full number
// never round-trips to the mock backend.
const bankSchema = z.object({
  bankAccountNumber: z.string().trim().min(4, "Enter your account number"),
  ifsc: z
    .string()
    .trim()
    .regex(/^[A-Z]{4}0[A-Z0-9]{6}$/, "Enter a valid IFSC code"),
});
type BankFormValues = z.infer<typeof bankSchema>;

// Fetches, then hands off to ProfileFormBody once loaded — same
// query-backed-form pattern as features/dashboard/profile-kyc-form.tsx
// (ProfileFormBody only ever mounts after `profile` exists, so its forms
// can seed local state straight from the loaded data).
export function ProfileForm() {
  const { data: profile } = useAggregatorProfile();

  if (!profile) {
    return (
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1.3fr_1fr]">
        <div className="h-80 animate-pulse rounded-lg border border-border bg-card" />
        <div className="h-80 animate-pulse rounded-lg border border-border bg-card" />
      </div>
    );
  }

  return <ProfileFormBody profile={profile} />;
}

function ProfileFormBody({ profile }: { profile: AggregatorProfileData }) {
  const updateProfileMutation = useUpdateAggregatorProfileMutation();
  const updateBankMutation = useUpdateAggregatorProfileMutation();
  const updateIdentityMutation = useUpdateAggregatorProfileMutation();

  const initialPhone = splitPhone(profile.coordinatorPhone);
  const initialCompanyPhone = splitPhone(profile.phone);
  const [coordinatorDial, setCoordinatorDial] = useState(initialPhone.dial);
  const [companyDial, setCompanyDial] = useState(initialCompanyPhone.dial);
  const [designationOption, setDesignationOption] = useState<string>(
    (DESIGNATION_PRESETS as readonly string[]).includes(
      profile.coordinatorDesignation,
    )
      ? profile.coordinatorDesignation
      : DESIGNATION_OTHER,
  );
  const [emailFocused, setEmailFocused] = useState(false);
  const [identitySubmitted, setIdentitySubmitted] = useState(false);
  const avatarInputRef = useRef<HTMLInputElement>(null);

  // No real backend to upload to (see NEXT_SESSION_PROMPT.md) — this reads
  // the file locally and stores it as a data URL, same as every other field
  // on this profile. Capped well under localStorage's per-origin quota so one
  // large photo can't crowd out the rest of the mock DB.
  const MAX_AVATAR_BYTES = 2 * 1024 * 1024;
  function handleAvatarChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      toast.error("Choose an image file");
      return;
    }
    if (file.size > MAX_AVATAR_BYTES) {
      toast.error("Image is too large", {
        description: "Keep it under 2MB.",
      });
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      updateProfileMutation.mutate(
        { avatar: reader.result as string },
        {
          onSuccess: () => toast.success("Photo updated"),
          onError: (error) => toast.error(error.message),
        },
      );
    };
    reader.readAsDataURL(file);
  }

  const {
    register,
    control,
    handleSubmit,
    setValue,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<ProfileFormValues>({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      companyName: profile.companyName,
      contactPerson: profile.contactPerson,
      gstNumber: profile.gstNumber,
      phone: initialCompanyPhone.number,
      country: profile.country,
      addressLine1: profile.addressLine1,
      addressCity: profile.addressCity,
      addressState: profile.addressState,
      addressPincode: profile.addressPincode,
      coordinatorDesignation: profile.coordinatorDesignation,
      coordinatorPhone: initialPhone.number,
      coordinatorEmail: profile.coordinatorEmail,
    },
  });

  const coordinatorEmailField = register("coordinatorEmail");
  const emailValue = watch("coordinatorEmail");
  const emailSuggestions = useMemo(() => {
    const at = emailValue?.indexOf("@") ?? -1;
    if (at <= 0) return [];
    const local = emailValue.slice(0, at);
    const domainTyped = emailValue.slice(at + 1).toLowerCase();
    return EMAIL_DOMAIN_SUGGESTIONS.filter(
      (domain) => domain.startsWith(domainTyped) && domain !== domainTyped,
    ).map((domain) => `${local}@${domain}`);
  }, [emailValue]);

  function onProfileSubmit(values: ProfileFormValues) {
    updateProfileMutation.mutate(
      {
        ...values,
        phone: joinPhone(companyDial, values.phone),
        coordinatorPhone: joinPhone(coordinatorDial, values.coordinatorPhone),
      },
      {
        onError: (error) => toast.error(error.message),
      },
    );
  }

  const {
    control: bankControl,
    handleSubmit: handleBankSubmit,
    reset: resetBank,
    formState: { errors: bankErrors, isSubmitting: isBankSubmitting },
  } = useForm<BankFormValues>({
    resolver: zodResolver(bankSchema),
    defaultValues: { bankAccountNumber: "", ifsc: profile.ifsc },
  });

  function onBankSubmit(values: BankFormValues) {
    const last4 = values.bankAccountNumber.slice(-4);
    updateBankMutation.mutate(
      { bankAccountMasked: `•••• •••• •••• ${last4}`, ifsc: values.ifsc },
      {
        onSuccess: () => {
          toast.success("Bank details updated");
          resetBank({ bankAccountNumber: "", ifsc: values.ifsc });
        },
        onError: (error) => toast.error(error.message),
      },
    );
  }

  const {
    register: registerIdentity,
    handleSubmit: handleIdentitySubmit,
    reset: resetIdentity,
    formState: { errors: identityErrors, isSubmitting: isIdentitySubmitting },
  } = useForm<IdentityFormValues>({
    resolver: zodResolver(identitySchema),
    defaultValues: { aadhaarNumber: "" },
  });

  function onIdentitySubmit(values: IdentityFormValues) {
    const digits = values.aadhaarNumber.replace(/\s+/g, "");
    const last4 = digits.slice(-4);
    updateIdentityMutation.mutate(
      { aadhaarMasked: `XXXX XXXX ${last4}` },
      {
        onSuccess: () => {
          setIdentitySubmitted(true);
          resetIdentity({ aadhaarNumber: "" });
        },
        onError: (error) => toast.error(error.message),
      },
    );
  }

  return (
    <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1.3fr_1fr] lg:items-start">
      <form
        onSubmit={handleSubmit(onProfileSubmit)}
        className="flex flex-col gap-5 rounded-lg border border-border bg-card p-5 sm:p-6"
      >
        <h2 className="font-display text-base font-semibold text-foreground">
          Company profile
        </h2>

        <div className="flex items-center gap-4">
          <div className="relative size-16 shrink-0 overflow-hidden rounded-full border border-gold/40">
            {profile.avatar ? (
              <Image src={profile.avatar} alt="" fill sizes="64px" className="object-cover" />
            ) : (
              <UserAvatar name={profile.contactPerson} className="size-full text-base" />
            )}
            <button
              type="button"
              aria-label="Change photo"
              onClick={() => avatarInputRef.current?.click()}
              disabled={updateProfileMutation.isPending}
              className="absolute inset-0 flex items-center justify-center bg-background/0 text-transparent transition-colors hover:bg-background/60 hover:text-foreground disabled:cursor-not-allowed"
            >
              {updateProfileMutation.isPending ? (
                <Loader2 className="size-4 animate-spin text-foreground" />
              ) : (
                <Camera className="size-4" />
              )}
            </button>
            <input
              ref={avatarInputRef}
              type="file"
              accept="image/*"
              onChange={handleAvatarChange}
              className="hidden"
            />
          </div>
          <div>
            <p className="text-sm font-medium text-foreground">
              {profile.companyName}
            </p>
            <p className="text-xs text-muted-foreground">
              Shown to GalleryZone admin and support.
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
          <Field data-invalid={Boolean(errors.companyName)}>
            <FieldLabel htmlFor="companyName">Company name</FieldLabel>
            <Input
              id="companyName"
              className="h-10"
              {...register("companyName")}
              aria-invalid={Boolean(errors.companyName)}
            />
            <FieldError errors={[errors.companyName]} />
          </Field>

          <Field data-invalid={Boolean(errors.contactPerson)}>
            <FieldLabel htmlFor="contactPerson">Contact person</FieldLabel>
            <Input
              id="contactPerson"
              className="h-10"
              {...register("contactPerson")}
              aria-invalid={Boolean(errors.contactPerson)}
            />
            <FieldError errors={[errors.contactPerson]} />
          </Field>

          <Controller
            control={control}
            name="gstNumber"
            render={({ field, fieldState }) => (
              <Field data-invalid={fieldState.invalid}>
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <FieldLabel htmlFor="gstNumber">
                    GST number{" "}
                    <span className="font-normal text-muted-foreground">
                      (required to reserve)
                    </span>
                  </FieldLabel>
                  <GstStatusBadge status={profile.gstStatus} />
                </div>
                <Input
                  id="gstNumber"
                  maxLength={15}
                  className="h-10 font-mono uppercase"
                  value={field.value}
                  onChange={(e) => field.onChange(e.target.value.toUpperCase())}
                  onBlur={field.onBlur}
                  aria-invalid={fieldState.invalid}
                />
                <p className="text-xs text-muted-foreground">
                  GalleryZone reviews it before you can reserve artwork.
                </p>
                <FieldError errors={[fieldState.error]} />
              </Field>
            )}
          />

          <Field data-invalid={Boolean(errors.phone)}>
            <FieldLabel htmlFor="phone">Phone</FieldLabel>
            <div className="flex items-center gap-2">
              <DialCodePicker value={companyDial} onChange={setCompanyDial} />
              <Input
                id="phone"
                type="tel"
                className="h-10"
                {...register("phone")}
                aria-invalid={Boolean(errors.phone)}
              />
            </div>
            <FieldError errors={[errors.phone]} />
          </Field>

          <Field data-invalid={Boolean(errors.country)}>
            <FieldLabel htmlFor="country">Country</FieldLabel>
            <UniSwapDialog
              value={COUNTRY_OPTIONS.find((c) => c.code === watch("country")) ?? COUNTRY_OPTIONS[0]}
              onChange={(country: Country) =>
                setValue("country", country.code, { shouldValidate: true })
              }
              countries={COUNTRY_OPTIONS}
            />
            <FieldError errors={[errors.country]} />
          </Field>

          <Field
            data-invalid={Boolean(errors.addressLine1)}
            className="sm:col-span-2"
          >
            <FieldLabel htmlFor="addressLine1">Business address</FieldLabel>
            <Input
              id="addressLine1"
              className="h-10"
              placeholder="Building, street, area"
              {...register("addressLine1")}
              aria-invalid={Boolean(errors.addressLine1)}
            />
            <FieldError errors={[errors.addressLine1]} />
          </Field>

          <div className="grid grid-cols-1 gap-4 sm:col-span-2 sm:grid-cols-3">
            <Field data-invalid={Boolean(errors.addressCity)}>
              <FieldLabel htmlFor="addressCity">City</FieldLabel>
              <Input id="addressCity" className="h-10" autoComplete="address-level2" {...register("addressCity")} aria-invalid={Boolean(errors.addressCity)} />
              <FieldError errors={[errors.addressCity]} />
            </Field>
            <Field data-invalid={Boolean(errors.addressState)}>
              <FieldLabel htmlFor="addressState">State</FieldLabel>
              <Input id="addressState" className="h-10" autoComplete="address-level1" {...register("addressState")} aria-invalid={Boolean(errors.addressState)} />
              <FieldError errors={[errors.addressState]} />
            </Field>
            <Field data-invalid={Boolean(errors.addressPincode)}>
              <FieldLabel htmlFor="addressPincode">PIN code</FieldLabel>
              <Input id="addressPincode" className="h-10" inputMode="numeric" maxLength={6} autoComplete="postal-code" {...register("addressPincode")} aria-invalid={Boolean(errors.addressPincode)} />
              <FieldError errors={[errors.addressPincode]} />
            </Field>
          </div>
        </div>

        {/* MOU §10: one nominated GalleryZone coordinator per premises. The
            company's contact person above is who GalleryZone deals with
            commercially; this is the named person on the floor who receives
            audit notices, expiry reminders and inbound shipments. */}
        <div className="flex flex-col gap-4 rounded-md border border-gold/25 bg-gold/5 p-4">
          <div className="flex items-start gap-2.5">
            <UserRoundCog
              className="mt-0.5 size-4 shrink-0 text-gold-bright"
              strokeWidth={1.75}
            />
            <div>
              <p className="text-sm font-medium text-foreground">
                Nominated GalleryZone coordinator
              </p>
              <p className="mt-0.5 text-xs leading-relaxed text-muted-foreground">
                Required by your MOU (§10). This person receives audit notices,
                display-expiry reminders and inbound shipment alerts on your
                behalf.
              </p>
              <p className="mt-2 flex items-center gap-1.5 text-xs text-muted-foreground">
                <BellRing
                  className="size-3.5 shrink-0 text-gold-bright"
                  strokeWidth={1.75}
                />
                We&rsquo;ll send a reminder every month to keep this contact
                current.
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field className="sm:col-span-2">
              <FieldLabel htmlFor="coordinatorName">Name</FieldLabel>
              <Input
                id="coordinatorName"
                className="h-10"
                value={profile.contactPerson}
                readOnly
                aria-describedby="coordinatorNameHint"
              />
              <p
                id="coordinatorNameHint"
                className="text-xs text-muted-foreground"
              >
                Taken from the contact person above — change it there.
              </p>
            </Field>

            <Field data-invalid={Boolean(errors.coordinatorDesignation)}>
              <FieldLabel htmlFor="coordinatorDesignation">
                Designation
              </FieldLabel>
              <Select
                value={designationOption}
                onValueChange={(value) => {
                  if (value === null) return;
                  setDesignationOption(value);
                  if (value !== DESIGNATION_OTHER) {
                    setValue("coordinatorDesignation", value, {
                      shouldValidate: true,
                    });
                  } else {
                    setValue("coordinatorDesignation", "", {
                      shouldValidate: true,
                    });
                  }
                }}
              >
                <SelectTrigger
                  id="coordinatorDesignation"
                  className="h-10 w-full"
                >
                  <SelectValue placeholder="Choose a designation" />
                </SelectTrigger>
                <SelectContent>
                  {DESIGNATION_PRESETS.map((preset) => (
                    <SelectItem key={preset} value={preset}>
                      {preset}
                    </SelectItem>
                  ))}
                  <SelectItem value={DESIGNATION_OTHER}>Other</SelectItem>
                </SelectContent>
              </Select>
              {designationOption === DESIGNATION_OTHER && (
                <Input
                  className="h-10"
                  placeholder="Enter their designation"
                  {...register("coordinatorDesignation")}
                  aria-invalid={Boolean(errors.coordinatorDesignation)}
                />
              )}
              <FieldError errors={[errors.coordinatorDesignation]} />
            </Field>

            <Field data-invalid={Boolean(errors.coordinatorPhone)}>
              <FieldLabel htmlFor="coordinatorPhone">Direct phone</FieldLabel>
              <div className="flex items-center gap-2">
                <DialCodePicker value={coordinatorDial} onChange={setCoordinatorDial} />
                <Input
                  id="coordinatorPhone"
                  type="tel"
                  className="h-10"
                  {...register("coordinatorPhone")}
                  aria-invalid={Boolean(errors.coordinatorPhone)}
                />
              </div>
              <FieldError errors={[errors.coordinatorPhone]} />
            </Field>

            <Field
              data-invalid={Boolean(errors.coordinatorEmail)}
              className="relative sm:col-span-2"
            >
              <FieldLabel htmlFor="coordinatorEmail">Email</FieldLabel>
              <Input
                id="coordinatorEmail"
                type="email"
                className="h-10"
                autoComplete="off"
                {...coordinatorEmailField}
                onFocus={() => setEmailFocused(true)}
                onBlur={(e) => {
                  coordinatorEmailField.onBlur(e);
                  setTimeout(() => setEmailFocused(false), 150);
                }}
                aria-invalid={Boolean(errors.coordinatorEmail)}
              />
              {emailFocused && emailSuggestions.length > 0 && (
                <ul className="absolute top-full z-10 mt-1 w-full overflow-hidden rounded-md border border-border bg-popover shadow-md">
                  {emailSuggestions.map((suggestion) => (
                    <li key={suggestion}>
                      <button
                        type="button"
                        className="block w-full px-3 py-2 text-left text-sm text-foreground hover:bg-accent"
                        onClick={() => {
                          setValue("coordinatorEmail", suggestion, {
                            shouldValidate: true,
                          });
                          setEmailFocused(false);
                        }}
                      >
                        {suggestion}
                      </button>
                    </li>
                  ))}
                </ul>
              )}
              <FieldError errors={[errors.coordinatorEmail]} />
            </Field>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <button
            type="submit"
            disabled={isSubmitting || updateProfileMutation.isPending}
            className="inline-flex items-center gap-2 rounded-md bg-gradient-to-b from-gold-bright to-gold px-5 py-2.5 text-sm font-semibold text-[#171310] transition-transform hover:scale-[1.02] disabled:pointer-events-none disabled:opacity-60"
          >
            {updateProfileMutation.isPending && (
              <Loader2 className="size-4 animate-spin" />
            )}
            Save profile
          </button>
          {updateProfileMutation.isSuccess && (
            <span className="flex items-center gap-1.5 text-sm text-gold-bright">
              <Check className="size-3.5" />
              Saved
            </span>
          )}
        </div>
      </form>

      <div className="flex flex-col gap-6">
        <div className="rounded-lg border border-border bg-card p-5 sm:p-6">
          <div className="flex items-center justify-between">
            <h2 className="font-display text-base font-semibold text-foreground">
              Security deposit
            </h2>
            <span className="flex items-center gap-1.5 rounded-full border border-emerald-500/30 bg-emerald-500/10 px-2.5 py-1 text-xs font-medium text-emerald-400">
              <ShieldCheck className="size-3" />
              Active
            </span>
          </div>
          <p className="mt-3 text-xs leading-relaxed text-muted-foreground">
            Held per your onboarding MOU and refunded after a final audit if you
            exit the program. This is managed by GalleryZone admin — contact
            support with questions.
          </p>
        </div>

        <form
          onSubmit={handleBankSubmit(onBankSubmit)}
          className="flex flex-col gap-4 rounded-lg border border-border bg-card p-5 sm:p-6"
        >
          <h2 className="font-display text-base font-semibold text-foreground">
            Bank account
          </h2>

          <div className="flex items-center gap-3 rounded-md border border-border p-3.5">
            <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-gold/30 bg-background">
              <Building2
                className="size-4 text-gold-bright"
                strokeWidth={1.5}
              />
            </span>
            <div className="min-w-0">
              <p className="flex items-center gap-1.5 truncate text-sm font-medium text-foreground">
                <Lock className="size-3 shrink-0 text-muted-foreground" />
                {profile.bankAccountMasked}
              </p>
              <p className="text-xs text-muted-foreground">Currently on file</p>
            </div>
          </div>

          <Controller
            control={bankControl}
            name="bankAccountNumber"
            render={({ field, fieldState }) => (
              <Field data-invalid={fieldState.invalid}>
                <FieldLabel htmlFor="bankAccountNumber">
                  New account number
                </FieldLabel>
                <Input
                  id="bankAccountNumber"
                  inputMode="numeric"
                  placeholder="Enter to update"
                  className="h-10"
                  {...field}
                  aria-invalid={fieldState.invalid}
                />
                <FieldError errors={[fieldState.error]} />
              </Field>
            )}
          />

          <Controller
            control={bankControl}
            name="ifsc"
            render={({ field, fieldState }) => (
              <Field data-invalid={fieldState.invalid}>
                <FieldLabel htmlFor="ifsc">IFSC code</FieldLabel>
                <Input
                  id="ifsc"
                  maxLength={11}
                  className="h-10"
                  value={field.value}
                  onChange={(e) => field.onChange(e.target.value.toUpperCase())}
                  onBlur={field.onBlur}
                  aria-invalid={fieldState.invalid}
                />
                <FieldError errors={[fieldState.error]} />
              </Field>
            )}
          />

          <div className="flex items-center gap-3">
            <button
              type="submit"
              disabled={isBankSubmitting || updateBankMutation.isPending}
              className="inline-flex items-center gap-2 rounded-md border border-gold/50 px-5 py-2.5 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10 disabled:pointer-events-none disabled:opacity-40"
            >
              {updateBankMutation.isPending && (
                <Loader2 className="size-4 animate-spin" />
              )}
              Update bank details
            </button>
            {updateBankMutation.isSuccess && (
              <span className="flex items-center gap-1.5 text-sm text-gold-bright">
                <Check className="size-3.5" />
                Updated
              </span>
            )}
          </div>
        </form>

        <form
          onSubmit={handleIdentitySubmit(onIdentitySubmit)}
          className="flex flex-col gap-4 rounded-lg border border-border bg-card p-5 sm:p-6"
        >
          <div className="flex items-center justify-between">
            <h2 className="font-display text-base font-semibold text-foreground">
              Identity verification
            </h2>
            {profile.aadhaarMasked ? (
              <span className="flex items-center gap-1.5 rounded-full border border-gold/35 bg-gold/10 px-2.5 py-1 text-xs font-medium text-gold-bright">
                <ShieldCheck className="size-3" />
                Submitted
              </span>
            ) : (
              <span className="flex items-center gap-1.5 rounded-full border border-border bg-muted/40 px-2.5 py-1 text-xs font-medium text-muted-foreground">
                Not submitted
              </span>
            )}
          </div>

          {profile.aadhaarMasked && (
            <div className="flex items-center gap-3 rounded-md border border-border p-3.5">
              <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-gold/30 bg-background">
                <Fingerprint
                  className="size-4 text-gold-bright"
                  strokeWidth={1.5}
                />
              </span>
              <div className="min-w-0">
                <p className="flex items-center gap-1.5 truncate text-sm font-medium text-foreground">
                  <Lock className="size-3 shrink-0 text-muted-foreground" />
                  {profile.aadhaarMasked}
                </p>
                <p className="text-xs text-muted-foreground">
                  Aadhaar currently on file
                </p>
              </div>
            </div>
          )}

          <Field data-invalid={Boolean(identityErrors.aadhaarNumber)}>
            <FieldLabel htmlFor="aadhaarNumber">
              {profile.aadhaarMasked
                ? "Replace Aadhaar number"
                : "Aadhaar number"}
            </FieldLabel>
            <Input
              id="aadhaarNumber"
              inputMode="numeric"
              placeholder="XXXX XXXX XXXX"
              className="h-10"
              {...registerIdentity("aadhaarNumber")}
              aria-invalid={Boolean(identityErrors.aadhaarNumber)}
            />
            <FieldError errors={[identityErrors.aadhaarNumber]} />
          </Field>
          <p className="text-xs leading-relaxed text-muted-foreground">
            Encrypted at rest and used only for identity verification.
            GalleryZone admin reviews every submission before approving it.
          </p>

          <div className="flex items-center gap-3">
            <button
              type="submit"
              disabled={
                isIdentitySubmitting || updateIdentityMutation.isPending
              }
              className="inline-flex items-center gap-2 rounded-md border border-gold/50 px-5 py-2.5 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10 disabled:pointer-events-none disabled:opacity-40"
            >
              {updateIdentityMutation.isPending && (
                <Loader2 className="size-4 animate-spin" />
              )}
              Submit for review
            </button>
            {identitySubmitted && (
              <span className="flex items-center gap-1.5 text-sm text-gold-bright">
                <Check className="size-3.5" />
                Submitted for review
              </span>
            )}
          </div>
        </form>
      </div>
    </div>
  );
}
