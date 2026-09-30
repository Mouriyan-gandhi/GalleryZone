"use client";

import { UserAvatar } from "@/components/shared/user-avatar";

import { useCurrentUser } from "@/hooks/useCurrentUser";

import { useState, type FormEvent } from "react";
import Image from "next/image";
import Link from "next/link";
import { motion } from "framer-motion";
import {
  Camera,
  ShieldCheck,
  Check,
  Lock,
  Globe2,
  Video,
  ChevronRight,
  Receipt,
  Truck,
  CreditCard,
  ExternalLink,
  PlayCircle,
  TriangleAlert,
  Palette,
  Landmark,
} from "lucide-react";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { FileUploader } from "@/components/ui/file-uploader";
import { GstStatusBadge } from "@/components/shared/gst-status-badge";
import { formatINR } from "@/lib/utils";
import { InstagramGlyph } from "@/components/social-icons";
import {
  useArtistAccountProfile,
  useSaveArtistProfileMutation,
} from "@/hooks/useArtistAccount";
import { ArtistNetworkPanel } from "./artist-network-panel";
import { ArtistProfileSummary } from "./artist-profile-summary";
import { MouAgreement } from "./mou-agreement";

// Standard GSTIN shape: 2-digit state code, 10-char PAN, entity number, a
// literal "Z", then a checksum character.
const GSTIN_PATTERN = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/;

// Standard PAN shape: 5 letters, 4 digits, 1 letter.
const PAN_PATTERN = /^[A-Z]{5}[0-9]{4}[A-Z]$/;

// Income above which the GST field suggests registering — not enforced, just
// shown as a hint next to the field. See the 9 Sep 2026 payout rules.
const GST_SUGGESTED_INCOME_THRESHOLD = 2_000_000;

type ProfileFormState = {
  fullName: string;
  email: string;
  phone: string;
  bio: string;
  instagram: string;
  website: string;
  socialProofVideoUrl: string;
  gstin: string;
  pan: string;
};

type PickupFormState = {
  pickupLine1: string;
  pickupLine2: string;
  pickupCity: string;
  pickupState: string;
  pickupPincode: string;
};

// Six digits, and the first can't be 0 — no Indian pincode starts with one.
const PINCODE_PATTERN = /^[1-9][0-9]{5}$/;

type ArtistAccountProfile = NonNullable<
  ReturnType<typeof useArtistAccountProfile>["data"]
>;

// Fetches, then hands off to ProfileKycFormBody once loaded — the body's
// local form state is seeded straight from `profile` in its useState
// initializer (no effect needed) because the body only ever mounts after
// `profile` exists, matching every other query-backed form in this codebase.
export function ProfileKycForm() {
  const { data: profile } = useArtistAccountProfile();

  if (!profile) {
    return (
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1.3fr_1fr]">
        <div className="h-96 animate-pulse rounded-lg border border-border bg-card" />
        <div className="h-96 animate-pulse rounded-lg border border-border bg-card" />
      </div>
    );
  }

  return <ProfileKycFormBody profile={profile} />;
}

function ProfileKycFormBody({ profile }: { profile: ArtistAccountProfile }) {
  const { data: me } = useCurrentUser();
  const saveProfileMutation = useSaveArtistProfileMutation();

  const [profileForm, setProfileForm] = useState<ProfileFormState>({
    fullName: profile.fullName,
    email: profile.email,
    phone: profile.phone,
    bio: profile.bio,
    instagram: profile.instagram,
    website: profile.website,
    socialProofVideoUrl: profile.socialProofVideoUrl ?? "",
    gstin: profile.gstin ?? "",
    pan: profile.pan ?? "",
  });
  const [profileSaved, setProfileSaved] = useState(false);

  const [pickupForm, setPickupForm] = useState<PickupFormState>({
    pickupLine1: profile.pickupLine1 ?? "",
    pickupLine2: profile.pickupLine2 ?? "",
    pickupCity: profile.pickupCity ?? "",
    pickupState: profile.pickupState ?? "",
    pickupPincode: profile.pickupPincode ?? "",
  });
  const [pickupSaved, setPickupSaved] = useState(false);

  function updatePickup<K extends keyof PickupFormState>(
    field: K,
    value: PickupFormState[K],
  ) {
    setPickupForm((prev) => ({ ...prev, [field]: value }));
    setPickupSaved(false);
  }

  const pincodeInvalid =
    pickupForm.pickupPincode.trim().length > 0 &&
    !PINCODE_PATTERN.test(pickupForm.pickupPincode.trim());
  const pickupComplete =
    pickupForm.pickupLine1.trim() !== "" &&
    pickupForm.pickupCity.trim() !== "" &&
    pickupForm.pickupState.trim() !== "" &&
    PINCODE_PATTERN.test(pickupForm.pickupPincode.trim());

  function handlePickupSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (pincodeInvalid) return;
    saveProfileMutation.mutate(pickupForm, {
      onSuccess: () => setPickupSaved(true),
    });
  }

  const [docsSubmitted, setDocsSubmitted] = useState(false);

  // Payout account. The number is write-only: the API stores it where no
  // read route reaches and returns only the last four digits.
  const [bankForm, setBankForm] = useState({ bankAccountNumber: "", bankAccountNumberConfirm: "", ifsc: profile.ifsc ?? "" });
  const [bankSaved, setBankSaved] = useState(false);
  // Account numbers are typed twice and can never be pasted between the
  // two fields, so a slip in one shows up as a mismatch instead of a
  // payout to a stranger. 9–18 digits, not all the same digit, not a
  // straight run (1234567890…), which is what a test entry looks like.
  const acct = bankForm.bankAccountNumber;
  const bankNumberInvalid =
    acct !== "" &&
    (!/^\d{9,18}$/.test(acct) || /^(\d)\1+$/.test(acct) || "01234567890123456789".includes(acct) || "98765432109876543210".includes(acct));
  const bankNumberMismatch = bankForm.bankAccountNumberConfirm !== "" && bankForm.bankAccountNumberConfirm !== acct;
  const bankNumberUnconfirmed = acct !== "" && bankForm.bankAccountNumberConfirm === "";
  const ifscInvalid = bankForm.ifsc !== "" && !/^[A-Z]{4}0[A-Z0-9]{6}$/.test(bankForm.ifsc.toUpperCase());
  function handleBankSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (bankNumberInvalid || bankNumberMismatch || bankNumberUnconfirmed || ifscInvalid) return;
    saveProfileMutation.mutate(
      { ...(bankForm.bankAccountNumber ? { bankAccountNumber: bankForm.bankAccountNumber } : {}), ifsc: bankForm.ifsc.toUpperCase() },
      {
        onSuccess: () => {
          setBankSaved(true);
          setBankForm((prev) => ({ ...prev, bankAccountNumber: "", bankAccountNumberConfirm: "" }));
        },
      },
    );
  }

  // Signing reorders this page (unsigned artists get the agreement first)
  // and is what gates listing work for aggregator display.
  const mouSigned = profile.mouAcceptance !== null;

  function updateProfile<K extends keyof ProfileFormState>(
    field: K,
    value: ProfileFormState[K],
  ) {
    setProfileForm((prev) => ({ ...prev, [field]: value }));
    setProfileSaved(false);
  }

  // GST is optional for artists (preferred, not required) — leaving it blank
  // is valid. When something IS entered, its shape is still checked locally
  // (2-digit state code, PAN, entity digit, Z, checksum char). There is still
  // no GST portal *integration* (the business doesn't want one); artists
  // apply on the official portal themselves and paste the number in here.
  const gstinTrimmed = profileForm.gstin.trim();
  const gstinInvalid =
    gstinTrimmed.length > 0 && !GSTIN_PATTERN.test(gstinTrimmed);
  // PAN, unlike GST, is compulsory — this is what actually gates listing
  // (see the gate in artwork-submit-form.tsx).
  const panTrimmed = profileForm.pan.trim();
  const panInvalid = panTrimmed.length === 0 || !PAN_PATTERN.test(panTrimmed);
  const instagramInvalid = profileForm.instagram.trim().length === 0;
  const gstStatus = profile.gstStatus;

  function handleProfileSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (gstinInvalid || panInvalid || instagramInvalid) return;
    saveProfileMutation.mutate(
      {
        ...profileForm,
        socialProofVideoUrl: profileForm.socialProofVideoUrl || null,
      },
      { onSuccess: () => setProfileSaved(true) },
    );
  }

  return (
    <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1.3fr_1fr] lg:items-start">
      {/* The MOU leads the page until it is signed — it is the one thing an
          artist has to do here. Once signed it moves to the bottom (below),
          where it stays as reference rather than a task. */}
      {!mouSigned && (
        <div className="lg:col-span-2">
          <MouAgreement />
        </div>
      )}

      {/* Both halves of their profile, side by side and labelled — the one
          place the public and private figures legitimately appear together. */}
      <ArtistProfileSummary location={[profile.pickupCity, profile.pickupState].filter(Boolean).join(", ") || undefined} />

      <Link
        href="/dashboard/verification"
        className="flex items-center justify-between gap-3 rounded-lg border border-gold/30 bg-gold/5 px-4 py-3 text-sm font-medium text-gold-bright transition-colors hover:bg-gold/10 lg:col-span-2"
      >
        View verification status
        <ChevronRight className="size-4" />
      </Link>

      <form
        onSubmit={handleProfileSubmit}
        className="flex flex-col gap-5 rounded-lg border border-border bg-card p-5 sm:p-6"
      >
        <h2 className="font-display text-base font-semibold text-foreground">
          Public profile
        </h2>

        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="text-sm font-medium text-foreground">Profile photo</p>
            <p className="text-xs text-muted-foreground">
              Shown on your public artist page.
            </p>
          </div>
          <div className="relative size-16 shrink-0 overflow-hidden rounded-full border border-gold/40">
            <UserAvatar name={me?.name} className="size-full text-base" />
            <button
              type="button"
              aria-label="Change photo"
              className="absolute inset-0 flex items-center justify-center bg-background/0 text-transparent transition-colors hover:bg-background/60 hover:text-foreground"
            >
              <Camera className="size-4" />
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
          <div className="flex flex-col gap-2">
            <Label htmlFor="fullName">Full name</Label>
            <Input
              id="fullName"
              required
              value={profileForm.fullName}
              onChange={(e) => updateProfile("fullName", e.target.value)}
              className="h-10"
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              required
              value={profileForm.email}
              onChange={(e) => updateProfile("email", e.target.value)}
              className="h-10"
            />
          </div>
          <div className="flex flex-col gap-2 sm:col-span-2">
            <Label htmlFor="phone">Phone</Label>
            <Input
              id="phone"
              type="tel"
              value={profileForm.phone}
              onChange={(e) => updateProfile("phone", e.target.value)}
              className="h-10 sm:max-w-xs"
            />
          </div>
        </div>

        <div className="flex flex-col gap-2">
          <Label htmlFor="bio">Bio</Label>
          <Textarea
            id="bio"
            rows={4}
            placeholder="Tell collectors about your practice."
            value={profileForm.bio}
            onChange={(e) => updateProfile("bio", e.target.value)}
            className="min-h-28 resize-none"
          />
        </div>

        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
          <div className="flex flex-col gap-2">
            <Label htmlFor="instagram">
              Instagram handle{" "}
              <span className="font-normal text-muted-foreground">
                (required, private)
              </span>
            </Label>
            <div className="relative">
              <InstagramGlyph className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                id="instagram"
                required
                placeholder="yourhandle"
                value={profileForm.instagram}
                onChange={(e) => updateProfile("instagram", e.target.value)}
                aria-invalid={instagramInvalid}
                className="h-10 pl-9"
              />
            </div>
            <p className="text-xs text-muted-foreground">
              Used by GalleryZone for verification and analytics only — never
              shown on your public profile.
            </p>
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="website">
              Website{" "}
              <span className="font-normal text-muted-foreground">
                (optional)
              </span>
            </Label>
            <div className="relative">
              <Globe2 className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                id="website"
                placeholder="yoursite.com"
                value={profileForm.website}
                onChange={(e) => updateProfile("website", e.target.value)}
                className="h-10 pl-9"
              />
            </div>
          </div>
          <div className="flex flex-col gap-2 sm:col-span-2">
            <Label htmlFor="socialProofVideoUrl">
              Behind-the-scenes video (YouTube / TikTok){" "}
              <span className="font-normal text-muted-foreground">
                (optional)
              </span>
            </Label>
            <div className="relative">
              <Video className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                id="socialProofVideoUrl"
                placeholder="https://youtube.com/watch?v=..."
                value={profileForm.socialProofVideoUrl}
                onChange={(e) =>
                  updateProfile("socialProofVideoUrl", e.target.value)
                }
                className="h-10 pl-9"
              />
            </div>
            <p className="text-xs text-muted-foreground">
              A studio or process video collectors can watch as proof of your
              practice.
            </p>
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="pan">
              PAN{" "}
              <span className="font-normal text-muted-foreground">
                (admin-only &middot; required)
              </span>
            </Label>
            <div className="relative sm:max-w-xs">
              <CreditCard className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                id="pan"
                required
                maxLength={10}
                placeholder="ABCDE1234F"
                value={profileForm.pan}
                onChange={(e) =>
                  updateProfile("pan", e.target.value.toUpperCase())
                }
                aria-invalid={panInvalid}
                className="h-10 pl-9 font-mono"
              />
            </div>
            {panInvalid ? (
              <p className="text-xs text-destructive">
                {panTrimmed.length === 0
                  ? "PAN is required before you can list artwork."
                  : "That doesn't look like a valid PAN."}
              </p>
            ) : (
              <p className="text-xs text-muted-foreground">
                Seen only by GalleryZone admins — never shown on your public
                profile.
              </p>
            )}
          </div>

          <div className="flex flex-col gap-2 sm:col-span-2">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <Label htmlFor="gstin">
                GSTIN{" "}
                <span className="font-normal text-muted-foreground">
                  (optional &middot; preferred)
                </span>
              </Label>
              <GstStatusBadge status={gstStatus} />
            </div>
            <div className="relative sm:max-w-xs">
              <Receipt className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                id="gstin"
                maxLength={15}
                placeholder="22AAAAA0000A1Z5"
                value={profileForm.gstin}
                onChange={(e) =>
                  updateProfile("gstin", e.target.value.toUpperCase())
                }
                aria-invalid={gstinInvalid}
                className="h-10 pl-9 font-mono"
              />
            </div>
            {gstinInvalid ? (
              <p className="text-xs text-destructive">
                That doesn&rsquo;t look like a valid GSTIN. Leave it blank if
                you don&rsquo;t have one.
              </p>
            ) : (
              <p className="text-xs text-muted-foreground">
                Not required to list or sell, but worth adding: a GSTIN lets
                you claim input tax credit on your art costs and gives you
                better access to sales channels. If your yearly income is
                above {formatINR(GST_SUGGESTED_INCOME_THRESHOLD)}, we
                recommend it. Used only for invoicing and settlement, never
                shown on your public profile or to buyers.
              </p>
            )}

            <a
              href="https://www.gst.gov.in/"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex w-fit items-center gap-1.5 text-xs font-medium text-gold-bright hover:underline"
            >
              <ExternalLink className="size-3.5" />
              Don&rsquo;t have a GSTIN? Apply on the government GST portal
            </a>

            {/* Placeholder for the GST application walkthrough video — drop
                the embed or a YouTube link in here when it's ready. */}
            <div className="flex items-center gap-3 rounded-md border border-dashed border-gold/40 px-3.5 py-3">
              <PlayCircle
                className="size-5 shrink-0 text-gold-bright"
                strokeWidth={1.5}
              />
              <div>
                <p className="text-xs font-medium text-foreground">
                  GST application guide
                </p>
                <p className="text-[11px] text-muted-foreground">
                  A short walkthrough of registering for GST goes here. Coming
                  soon.
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <button
            type="submit"
            disabled={
              saveProfileMutation.isPending || gstinInvalid || instagramInvalid
            }
            className="inline-flex items-center gap-2 rounded-md bg-gradient-to-b from-gold-bright to-gold px-5 py-2.5 text-sm font-semibold text-[#171310] transition-transform hover:scale-[1.02] disabled:pointer-events-none disabled:opacity-60"
          >
            Save profile
          </button>
          {profileSaved && (
            <motion.span
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="flex items-center gap-1.5 text-sm text-gold-bright"
            >
              <Check className="size-3.5" />
              Saved
            </motion.span>
          )}
        </div>
      </form>

      {/* Sits to the right of Public profile in the same row — identity/KYC
          proof paired beside the profile it verifies. */}
      <div className="flex flex-col gap-6">
        <div className="rounded-lg border border-border bg-card p-5 sm:p-6">
          <div className="flex items-center justify-between">
            <h2 className="font-display text-base font-semibold text-foreground">
              Aadhaar verification
            </h2>
            <span className="flex items-center gap-1.5 rounded-full border border-emerald-500/30 bg-emerald-500/10 px-2.5 py-1 text-xs font-medium text-emerald-400">
              <ShieldCheck className="size-3" />
              Verified
            </span>
          </div>
          <p className="mt-3 flex items-center gap-2 font-mono text-sm text-foreground">
            <Lock className="size-3.5 text-muted-foreground" />
            {profile.aadhaarMasked}
          </p>
          <p className="mt-2 text-xs leading-relaxed text-muted-foreground">
            Encrypted at rest and used only for identity verification. Contact
            support to update your Aadhaar details.
          </p>
        </div>

        <div className="flex flex-col gap-3 rounded-lg border border-border bg-card p-5 sm:p-6">
          <div>
            <h2 className="font-display text-base font-semibold text-foreground">
              Identity documents
            </h2>
            <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
              Submit an additional ID or address proof if support has requested
              one for your account.{" "}
              <span className="text-muted-foreground/80">(optional)</span>
            </p>
          </div>

          <FileUploader
            title="Upload documents"
            acceptedFormats={["jpg", "pdf", "svg", "png", "docx"]}
            maxFiles={3}
            maxSizeMB={10}
            submitLabel="Submit for review"
            onSubmit={() => setDocsSubmitted(true)}
            className="max-w-none shadow-none ring-1 ring-border"
          />

          {docsSubmitted && (
            <motion.p
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="flex items-center gap-1.5 text-sm text-gold-bright"
            >
              <Check className="size-3.5" />
              Submitted for review
            </motion.p>
          )}
        </div>

        <div className="flex items-start gap-3 rounded-lg border border-dashed border-gold/40 bg-card p-5 sm:p-6">
          <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-gold/30 bg-background">
            <Palette className="size-4 text-gold-bright" strokeWidth={1.75} />
          </span>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="font-display text-base font-semibold text-foreground">
                Commissions
              </h2>
              <span className="rounded-full border border-gold/40 bg-gold/10 px-2 py-0.5 text-[11px] font-medium text-gold-bright">
                Coming soon
              </span>
            </div>
            <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
              Let collectors commission a custom piece directly from you, start
              to finish, through GalleryZone.
            </p>
          </div>
        </div>
      </div>

      {/* Its own card, and its own save, because it is the opposite of the one
          above: the public profile is what buyers see, this is what only a
          courier ever sees. Without a pincode here no delivery can be priced —
          Shiprocket quotes on the distance between two of them. */}
      <form
        onSubmit={handlePickupSubmit}
        className="flex flex-col gap-5 rounded-lg border border-border bg-card p-5 sm:p-6 lg:order-last lg:col-span-2"
      >
        <div className="flex items-start gap-3">
          <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-gold/30 bg-background">
            <Truck className="size-4 text-gold-bright" strokeWidth={1.75} />
          </span>
          <div>
            <h2 className="font-display text-base font-semibold text-foreground">
              Pickup address
            </h2>
            <p className="mt-0.5 text-sm leading-relaxed text-muted-foreground">
              Where your work is collected from. Private — buyers never see it.
            </p>
          </div>
        </div>

        {!pickupComplete && (
          <p className="rounded-md border border-gold/30 bg-gold/5 px-3.5 py-2.5 text-xs leading-relaxed text-gold-bright">
            Add this before your first sale. Delivery is priced on the distance
            between your address and the buyer&rsquo;s, so without it we
            can&rsquo;t quote a shipping cost for your work.
          </p>
        )}

        <div className="flex flex-col gap-2">
          <Label htmlFor="pickupLine1">Address</Label>
          <Input
            id="pickupLine1"
            placeholder="House / studio number and street"
            value={pickupForm.pickupLine1}
            onChange={(e) => updatePickup("pickupLine1", e.target.value)}
            className="h-10"
          />
        </div>

        <div className="flex flex-col gap-2">
          <Label htmlFor="pickupLine2">
            Area, landmark{" "}
            <span className="font-normal text-muted-foreground">
              (optional)
            </span>
          </Label>
          <Input
            id="pickupLine2"
            placeholder="Locality or a nearby landmark"
            value={pickupForm.pickupLine2}
            onChange={(e) => updatePickup("pickupLine2", e.target.value)}
            className="h-10"
          />
        </div>

        <div className="grid grid-cols-1 gap-5 sm:grid-cols-3">
          <div className="flex flex-col gap-2">
            <Label htmlFor="pickupCity">City</Label>
            <Input
              id="pickupCity"
              placeholder="Udaipur"
              value={pickupForm.pickupCity}
              onChange={(e) => updatePickup("pickupCity", e.target.value)}
              className="h-10"
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="pickupState">State</Label>
            <Input
              id="pickupState"
              placeholder="Rajasthan"
              value={pickupForm.pickupState}
              onChange={(e) => updatePickup("pickupState", e.target.value)}
              className="h-10"
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="pickupPincode">PIN code</Label>
            <Input
              id="pickupPincode"
              inputMode="numeric"
              maxLength={6}
              placeholder="313001"
              value={pickupForm.pickupPincode}
              onChange={(e) =>
                updatePickup(
                  "pickupPincode",
                  e.target.value.replace(/[^0-9]/g, ""),
                )
              }
              aria-invalid={pincodeInvalid}
              className="h-10 font-mono"
            />
            {pincodeInvalid && (
              <p className="text-xs text-destructive">
                A PIN code is six digits.
              </p>
            )}
          </div>
        </div>

        <div className="flex items-center gap-3">
          <button
            type="submit"
            disabled={saveProfileMutation.isPending || pincodeInvalid}
            className="inline-flex items-center gap-2 rounded-md border border-gold/50 px-5 py-2.5 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10 disabled:pointer-events-none disabled:opacity-40"
          >
            Save pickup address
          </button>
          {pickupSaved && (
            <motion.span
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="flex items-center gap-1.5 text-sm text-gold-bright"
            >
              <Check className="size-3.5" />
              Saved
            </motion.span>
          )}
        </div>
      </form>

      <form
        onSubmit={handleBankSubmit}
        className="flex flex-col gap-5 rounded-lg border border-border bg-card p-5 sm:p-6 lg:order-last lg:col-span-2"
      >
        <div className="flex items-start gap-3">
          <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-gold/30 bg-background">
            <Landmark className="size-4 text-gold-bright" strokeWidth={1.75} />
          </span>
          <div>
            <h2 className="font-display text-base font-semibold text-foreground">Payout account</h2>
            <p className="mt-0.5 text-sm leading-relaxed text-muted-foreground">
              Where your settlements are paid. {profile.bankAccountMasked ? `On file: ${profile.bankAccountMasked}${profile.ifsc ? ` · ${profile.ifsc}` : ""}.` : "Nothing on file yet — withdrawals need this."}
            </p>
          </div>
        </div>
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
          <div className="flex flex-col gap-2">
            <Label htmlFor="bankAccountNumber">Account number</Label>
            <Input
              id="bankAccountNumber"
              inputMode="numeric"
              autoComplete="off"
              placeholder={profile.bankAccountMasked ? "Enter a new number to replace it" : "9–18 digits"}
              value={bankForm.bankAccountNumber}
              onChange={(e) => { setBankForm((p) => ({ ...p, bankAccountNumber: e.target.value.replace(/\s/g, "") })); setBankSaved(false); }}
              className="h-10"
            />
            {bankNumberInvalid && <p className="text-xs text-destructive">Enter the real 9–18 digit account number printed on your passbook or cheque.</p>}
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="bankAccountNumberConfirm">Re-enter account number</Label>
            <Input
              id="bankAccountNumberConfirm"
              inputMode="numeric"
              autoComplete="off"
              placeholder="Type it again — pasting is disabled"
              value={bankForm.bankAccountNumberConfirm}
              onPaste={(e) => e.preventDefault()}
              onChange={(e) => { setBankForm((p) => ({ ...p, bankAccountNumberConfirm: e.target.value.replace(/\s/g, "") })); setBankSaved(false); }}
              className="h-10"
            />
            {bankNumberMismatch && <p className="text-xs text-destructive">The two account numbers don&rsquo;t match.</p>}
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="ifsc">IFSC</Label>
            <Input
              id="ifsc"
              autoComplete="off"
              placeholder="HDFC0001234"
              value={bankForm.ifsc}
              onChange={(e) => { setBankForm((p) => ({ ...p, ifsc: e.target.value.toUpperCase() })); setBankSaved(false); }}
              className="h-10 uppercase"
            />
            {ifscInvalid && <p className="text-xs text-destructive">IFSC looks like HDFC0001234.</p>}
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button
            type="submit"
            disabled={saveProfileMutation.isPending || bankNumberInvalid || bankNumberMismatch || bankNumberUnconfirmed || ifscInvalid || (!bankForm.bankAccountNumber && !bankForm.ifsc)}
            className="inline-flex items-center gap-2 rounded-md border border-gold/50 px-5 py-2.5 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10 disabled:pointer-events-none disabled:opacity-40"
          >
            Save payout account
          </button>
          {bankSaved && (
            <motion.span initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex items-center gap-1.5 text-sm text-gold-bright">
              <Check className="size-3.5" />
              Saved
            </motion.span>
          )}
        </div>
      </form>

      {panInvalid && (
        <a
          href="#pan"
          className="flex items-center gap-3 rounded-lg border border-gold/40 bg-gold/5 px-4 py-3.5 text-sm text-gold-bright transition-colors hover:bg-gold/10 lg:col-span-2"
        >
          <TriangleAlert className="size-4 shrink-0" strokeWidth={1.75} />
          <span>
            <span className="font-medium">Add your PAN.</span>{" "}
            <span className="text-muted-foreground">
              Required before any artwork can go live — GST is optional.
            </span>
          </span>
        </a>
      )}
      {gstStatus === "submitted" && (
        <div className="flex items-center gap-3 rounded-lg border border-border bg-card px-4 py-3.5 text-sm lg:col-span-2">
          <Receipt
            className="size-4 shrink-0 text-muted-foreground"
            strokeWidth={1.75}
          />
          <span className="text-muted-foreground">
            Your GST registration is with GalleryZone for review — this
            doesn&rsquo;t block listing, and we&rsquo;ll update the status
            here once it&rsquo;s reviewed.
          </span>
        </div>
      )}

      <ArtistNetworkPanel />

      {mouSigned && (
        <div className="lg:col-span-2">
          <MouAgreement />
        </div>
      )}
    </div>
  );
}
