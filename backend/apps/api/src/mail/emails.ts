// Every product email, as a function: look up what's needed, render the
// template, hand it to the Mailer. Callers `void` these from the request
// path — a mail failure is logged, never surfaced as an API error.
//
// Templates are deliberately plain HTML (table layout, inline styles,
// system fonts): they render the same in Gmail, Outlook and Apple Mail,
// and there is nothing to build. Money arrives in paise and is formatted
// here.

import { Inject, Injectable, Logger } from "@nestjs/common";
import { Collections, type Db, type UserDoc } from "@galleryzone/db";
import type { OrderStatus } from "@galleryzone/domain";
import type { AppEnv } from "@galleryzone/config";
import { DB, ENV } from "../db.module.ts";
import { Mailer } from "./mailer.ts";

const BRAND = "GalleryZone";
const GOLD = "#b8892b";

// Support lives under each role's own section — there is no shared /support.
const SUPPORT_PATH: Record<string, string> = {
  artist: "/dashboard/support",
  aggregator: "/aggregator/support",
  customer: "/account/support",
};

function esc(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);
}

export function inr(paise: number): string {
  return `₹${(paise / 100).toLocaleString("en-IN", { maximumFractionDigits: 2 })}`;
}

interface Layout {
  preheader?: string;
  heading: string;
  /** Paragraphs, already escaped where user data is involved. */
  paragraphs: string[];
  cta?: { label: string; url: string };
  footnote?: string;
}

function render(site: string, l: Layout): { html: string; text: string } {
  const paragraphs = l.paragraphs.map((p) => `<p style="margin:0 0 14px;font-size:15px;line-height:1.55;color:#2a2521;">${p}</p>`).join("");
  const cta = l.cta
    ? `<p style="margin:22px 0;"><a href="${l.cta.url}" style="display:inline-block;background:${GOLD};color:#fff;text-decoration:none;font-weight:600;font-size:14px;padding:12px 22px;border-radius:8px;">${esc(l.cta.label)}</a></p>
       <p style="margin:0 0 14px;font-size:12px;color:#6b635c;">If the button doesn't work, copy this link: <a href="${l.cta.url}" style="color:${GOLD};">${l.cta.url}</a></p>`
    : "";
  const html = `<!doctype html><html><body style="margin:0;background:#f5f1ea;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
${l.preheader ? `<div style="display:none;max-height:0;overflow:hidden;">${esc(l.preheader)}</div>` : ""}
<table role="presentation" width="100%" cellspacing="0" cellpadding="0"><tr><td align="center" style="padding:32px 16px;">
<table role="presentation" width="560" cellspacing="0" cellpadding="0" style="max-width:560px;background:#ffffff;border-radius:12px;border:1px solid #e8e0d4;">
<tr><td style="padding:28px 32px 8px;"><a href="${site}" style="font-size:20px;font-weight:700;letter-spacing:.02em;color:#1a1410;text-decoration:none;">${BRAND}</a></td></tr>
<tr><td style="padding:8px 32px 0;"><h1 style="margin:0 0 16px;font-size:22px;line-height:1.3;color:#1a1410;">${esc(l.heading)}</h1>${paragraphs}${cta}
${l.footnote ? `<p style="margin:18px 0 0;font-size:12px;line-height:1.5;color:#6b635c;">${l.footnote}</p>` : ""}</td></tr>
<tr><td style="padding:24px 32px 28px;font-size:12px;color:#8a817a;border-top:1px solid #efe8de;margin-top:16px;">Every piece on ${BRAND} carries a verifiable identity — who made it, who owns it, and where it has been.<br><a href="${site}" style="color:#8a817a;">${site.replace(/^https?:\/\//, "")}</a></td></tr>
</table></td></tr></table></body></html>`;
  const text = [l.heading, "", ...l.paragraphs.map((p) => p.replace(/<[^>]+>/g, "")), l.cta ? `\n${l.cta.label}: ${l.cta.url}` : "", l.footnote ? `\n${l.footnote.replace(/<[^>]+>/g, "")}` : ""].join("\n");
  return { html, text };
}

/** Pulls the oobCode out of a Firebase action link so the email can point at OUR page, not Firebase's handler. */
export function oobCodeOf(actionLink: string): string | null {
  try {
    return new URL(actionLink).searchParams.get("oobCode");
  } catch {
    return null;
  }
}

@Injectable()
export class Emails {
  private readonly logger = new Logger(Emails.name);
  private readonly site: string;

  constructor(
    @Inject(DB) private readonly db: Db,
    @Inject(ENV) env: AppEnv,
    private readonly mailer: Mailer,
  ) {
    this.site = (process.env.PUBLIC_SITE_URL || env.corsOrigins[0] || "https://www.galleryzone.art").replace(/\/$/, "");
  }

  private async user(uid: string): Promise<(UserDoc & { uid: string }) | null> {
    const snap = await this.db.collection(Collections.users).doc(uid).get();
    const doc = snap.data() as UserDoc | undefined;
    return doc ? { uid, ...doc } : null;
  }

  private async admins(): Promise<string[]> {
    const snap = await this.db.collection(Collections.users).where("role", "==", "admin").get();
    return snap.docs.map((d) => (d.data() as UserDoc).email).filter(Boolean);
  }

  private async deliver(key: string, to: string | string[], subject: string, layout: Layout, replyTo?: string) {
    const recipients = Array.isArray(to) ? to.filter(Boolean) : [to].filter(Boolean);
    if (!recipients.length) return;
    const { html, text } = render(this.site, layout);
    await this.mailer.send({ to: recipients, subject, html, text, idempotencyKey: key, replyTo });
  }

  // ── Account ──────────────────────────────────────────────────────────

  async welcome(uid: string, verifyUrl: string | null) {
    const u = await this.user(uid);
    if (!u) return;
    const roleLine = { artist: "You can now list your work, sign the artist agreement and start selling.", aggregator: "You can now browse the catalogue and reserve pieces for display.", customer: "You can now collect original artworks with a verifiable provenance record.", admin: "" }[u.role];
    await this.deliver(`welcome/${uid}`, u.email, `Welcome to ${BRAND}, ${u.name.split(" ")[0]}`, {
      preheader: verifyUrl ? "Confirm your email to finish setting up." : "Your account is ready.",
      heading: `Welcome, ${esc(u.name)}`,
      paragraphs: [`Your ${BRAND} account is ready. ${roleLine}`, ...(verifyUrl ? ["Please confirm your email address so we can reach you about orders and your account."] : [])],
      ...(verifyUrl ? { cta: { label: "Confirm my email", url: verifyUrl } } : { cta: { label: `Open ${BRAND}`, url: this.site } }),
    });
  }

  async passwordReset(email: string, name: string | null, resetUrl: string) {
    await this.deliver(`password-reset/${email}/${Date.now().toString(36)}`, email, `Reset your ${BRAND} password`, {
      preheader: "This link works once and expires in an hour.",
      heading: "Reset your password",
      paragraphs: [`Hi${name ? ` ${esc(name.split(" ")[0]!)}` : ""}, someone asked to reset the password for this account. If that was you, choose a new one below.`, "If you didn't ask for this, you can ignore this email — your password stays the same."],
      cta: { label: "Choose a new password", url: resetUrl },
      footnote: "The link works once and expires after one hour.",
    });
  }

  // ── Artworks ─────────────────────────────────────────────────────────

  async artworkSubmitted(artworkId: string, artistId: string, title: string) {
    const [artist, admins] = await Promise.all([this.user(artistId), this.admins()]);
    if (artist) {
      await this.deliver(`artwork-submitted/${artworkId}`, artist.email, `“${title}” is in review`, {
        heading: "Your artwork is in review",
        paragraphs: [`“${esc(title)}” has been submitted. Our team reviews every piece before it goes live; you'll get an email as soon as it's listed.`],
        cta: { label: "View my artworks", url: `${this.site}/dashboard/artworks` },
      });
    }
    await this.deliver(`artwork-submitted-admin/${artworkId}`, admins, `Review: “${title}” by ${artist?.name ?? "an artist"}`, {
      heading: "New artwork awaiting approval",
      paragraphs: [`<strong>${esc(artist?.name ?? "An artist")}</strong> submitted “${esc(title)}”.`],
      cta: { label: "Open moderation queue", url: `${this.site}/admin/artworks` },
    });
  }

  async artworkApproved(artworkId: string, artistId: string, title: string, certificateNumber: string | null) {
    const artist = await this.user(artistId);
    if (!artist) return;
    await this.deliver(`artwork-approved/${artworkId}`, artist.email, `“${title}” is now live`, {
      heading: "Your artwork is live on the marketplace",
      paragraphs: [`“${esc(title)}” has been approved and is now listed.`, ...(certificateNumber ? [`Certificate of Authenticity <strong>${esc(certificateNumber)}</strong> has been issued for it.`] : [])],
      cta: { label: "See the listing", url: `${this.site}/marketplace/${artworkId}` },
    });
  }

  async artworkRejected(artworkId: string, artistId: string, title: string, reason: string) {
    const artist = await this.user(artistId);
    if (!artist) return;
    await this.deliver(`artwork-rejected/${artworkId}/${Date.now().toString(36)}`, artist.email, `“${title}” needs changes`, {
      heading: "Your artwork was returned",
      paragraphs: [`“${esc(title)}” wasn't approved this time. The reviewer's note:`, `<em>${esc(reason)}</em>`, "You can edit the piece and submit it again."],
      cta: { label: "Edit the artwork", url: `${this.site}/dashboard/artworks/${artworkId}/edit` },
    });
  }

  // ── Orders ───────────────────────────────────────────────────────────

  async orderPaid(input: { orderId: string; customerId: string; artistId: string; title: string; totalPaise: number; artistNetPaise: number }) {
    const [buyer, artist] = await Promise.all([this.user(input.customerId), this.user(input.artistId)]);
    if (buyer) {
      await this.deliver(`order-paid-buyer/${input.orderId}`, buyer.email, `Order confirmed — “${input.title}”`, {
        preheader: `We've received ${inr(input.totalPaise)}.`,
        heading: "Thank you — your order is confirmed",
        paragraphs: [`We've received your payment of <strong>${inr(input.totalPaise)}</strong> for “${esc(input.title)}”.`, "Ownership has been recorded in the artwork's provenance passport under your name. We'll email you when it ships."],
        cta: { label: "View my order", url: `${this.site}/account/orders/${input.orderId}` },
      });
    }
    if (artist) {
      await this.deliver(`order-paid-artist/${input.orderId}`, artist.email, `Sold: “${input.title}”`, {
        heading: "Congratulations — your artwork sold",
        paragraphs: [`“${esc(input.title)}” has been purchased. Your payout of <strong>${inr(input.artistNetPaise)}</strong> will be released to your wallet once the piece is delivered.`, "Please pack the artwork to the shipping standard in your agreement and wait for pickup instructions."],
        cta: { label: "Open my dashboard", url: `${this.site}/dashboard/orders` },
      });
    }
  }

  /**
   * Keyed to the real OrderStatus values from @galleryzone/contracts. It used
   * to be keyed to "shipped" and "refunded", which are not order statuses, so
   * nothing ever matched except delivered and cancelled. "pending" and "paid"
   * are deliberately absent — orderPaid() already covers that moment.
   */
  async orderStatus(input: { orderId: string; customerId: string; artistId: string | null; title: string; status: OrderStatus }) {
    const copy: Partial<Record<OrderStatus, { subject: string; heading: string; buyer: string; artist?: string }>> = {
      confirmed: {
        subject: `Order confirmed — “${input.title}”`,
        heading: "Your order is confirmed",
        buyer: "We've confirmed your order with the artist. The next step is packing — we'll email you when it's on its way.",
        artist: "Please pack the piece to the standard in your agreement and mark it packed in your dashboard.",
      },
      packed: {
        subject: `“${input.title}” is packed and ready`,
        heading: "Packed and ready to ship",
        buyer: "The artist has packed your piece. It hands over to the courier next, and you'll get a note the moment it moves.",
      },
      transit: {
        subject: `“${input.title}” is on its way`,
        heading: "Your artwork is in transit",
        buyer: "The piece has been dispatched and is on its way to you. We'll confirm once it's delivered.",
        artist: "The piece you sold is in transit to its new owner.",
      },
      delivered: {
        subject: `“${input.title}” was delivered`,
        heading: "Delivered",
        buyer: "Your artwork has been delivered. Its certificate and provenance passport are in your account.",
        artist: "The piece has been delivered. Your settlement is released to your wallet after the return window closes.",
      },
      cancelled: {
        subject: `Order cancelled — “${input.title}”`,
        heading: "Your order was cancelled",
        buyer: "This order has been cancelled. If you were charged, the refund is on its way to the original payment method.",
        artist: "This order was cancelled, so the piece returns to the marketplace.",
      },
    };
    const c = copy[input.status];
    if (!c) return;

    const buyer = await this.user(input.customerId);
    if (buyer) {
      await this.deliver(`order-${input.status}-buyer/${input.orderId}`, buyer.email, c.subject, {
        heading: c.heading,
        paragraphs: [c.buyer],
        cta: { label: "View my order", url: `${this.site}/account/orders/${input.orderId}` },
      });
    }
    // The artist could not see where their own piece was either. Only the
    // stages that are actually theirs to act on carry artist copy.
    if (c.artist && input.artistId) {
      const artist = await this.user(input.artistId);
      if (artist) {
        await this.deliver(`order-${input.status}-artist/${input.orderId}`, artist.email, `${c.subject} — your sale`, {
          heading: c.heading,
          paragraphs: [`“${esc(input.title)}” — ${c.artist}`],
          cta: { label: "Open my orders", url: `${this.site}/dashboard/orders` },
        });
      }
    }
  }

  // ── Ownership / CoA ──────────────────────────────────────────────────

  async transferInvite(input: { transferId: string; toEmail: string; toName: string; fromName: string; title: string; kind: string }) {
    const what = input.kind === "ownership" ? "transfer ownership of" : "lend for display";
    await this.deliver(`transfer-invite/${input.transferId}`, input.toEmail, `${input.fromName} wants to ${what} “${input.title}”`, {
      heading: `A ${input.kind === "ownership" ? "transfer" : "display loan"} is waiting for you`,
      paragraphs: [`<strong>${esc(input.fromName)}</strong> wants to ${what} “${esc(input.title)}” to you (${esc(input.toName)}).`, `Sign in with this email address to accept or decline. Once accepted, the artwork's provenance passport records the change.`],
      cta: { label: "Review the transfer", url: `${this.site}/transfer/${input.transferId}` },
    });
  }

  async physicalCoaRequested(input: { requestId: string; artistId: string; title: string; requestedByName: string }) {
    const artist = await this.user(input.artistId);
    if (!artist) return;
    await this.deliver(`coa-request/${input.requestId}`, artist.email, `Physical certificate requested for “${input.title}”`, {
      heading: "A collector wants the printed certificate",
      paragraphs: [`${esc(input.requestedByName)} has requested the physical Certificate of Authenticity for “${esc(input.title)}”. Print it from your dashboard, sign it, and mark it dispatched with the courier reference.`],
      cta: { label: "Open certificate requests", url: `${this.site}/dashboard/coa-nfc` },
    });
  }

  // ── Compliance ───────────────────────────────────────────────────────

  /**
   * GST and KYC decisions both gate something — KYC blocks payouts outright,
   * and an aggregator can't reserve a piece until their GSTIN is approved
   * (client, 30 Sep 2026). TDS does not depend on GST: it follows the artist's
   * financial-year sales. Deciding these silently left people guessing.
   */
  async complianceDecided(input: { userId: string; kind: "gst" | "kyc"; approved: boolean; reason?: string | undefined }) {
    const user = await this.user(input.userId);
    if (!user) return;
    const aggregator = user.role === "aggregator";
    const label = input.kind === "gst" ? "GSTIN" : "KYC";
    const approvedBody =
      input.kind === "gst"
        ? aggregator
          ? "Your GSTIN is verified. You can now reserve artwork."
          : "Your GSTIN is verified. Invoices now carry it."
        : "Your KYC is verified. Withdrawals from your wallet are now open.";
    const rejectedBody =
      input.kind === "gst"
        ? `We couldn't verify your GSTIN. Correct the details in your profile and resubmit${aggregator ? ". You can't reserve artwork until it is approved." : " — selling and settlements carry on in the meantime."}`
        : "We couldn't verify your KYC documents. Withdrawals stay on hold until this is resolved. Re-upload from your profile and we'll review again.";
    await this.deliver(`${input.kind}-${input.approved ? "approved" : "rejected"}/${input.userId}`, user.email, input.approved ? `${label} verified` : `${label} needs another look`, {
      heading: input.approved ? `Your ${label} is verified` : `We couldn't verify your ${label}`,
      paragraphs: [input.approved ? approvedBody : rejectedBody],
      ...(input.reason ? { footnote: `Reviewer's note: ${esc(input.reason)}` } : {}),
      cta: { label: "Open my profile", url: `${this.site}${aggregator ? "/aggregator/profile" : "/dashboard/profile"}` },
    });
  }

  async insuranceDecided(input: { artworkId: string; approved: boolean; reason?: string | undefined }) {
    const snap = await this.db.collection(Collections.artworks).doc(input.artworkId).get();
    const artwork = snap.data() as { title?: string; artistId?: string } | undefined;
    if (!artwork?.artistId) return;
    const artist = await this.user(artwork.artistId);
    if (!artist) return;
    const title = artwork.title ?? "your artwork";
    await this.deliver(`insurance-${input.approved ? "approved" : "rejected"}/${input.artworkId}`, artist.email, input.approved ? `Insurance approved — “${title}”` : `Insurance not approved — “${title}”`, {
      heading: input.approved ? "This piece is insured" : "We couldn't approve insurance on this piece",
      paragraphs: [
        input.approved
          ? `“${esc(title)}” is covered in transit and on display under the platform policy.`
          : `“${esc(title)}” isn't covered. It can still be listed and sold, but it travels uninsured — check the valuation and documents on the piece and resubmit if you'd like it reviewed again.`,
      ],
      ...(input.reason ? { footnote: `Reviewer's note: ${esc(input.reason)}` } : {}),
      cta: { label: "Open this artwork", url: `${this.site}/dashboard/artworks` },
    });
  }

  /** An admin pulling a live piece off the marketplace was entirely silent. */
  async artworkDelisted(input: { artworkId: string; artistId: string; title: string; reason?: string | undefined }) {
    const artist = await this.user(input.artistId);
    if (!artist) return;
    await this.deliver(`artwork-delisted/${input.artworkId}`, artist.email, `“${input.title}” has been delisted`, {
      heading: "Your artwork was removed from the marketplace",
      paragraphs: [`“${esc(input.title)}” is no longer visible to buyers. It stays in your dashboard, and nothing about your certificate or provenance record changes.`],
      ...(input.reason ? { footnote: `Reason given: ${esc(input.reason)}` } : {}),
      cta: { label: "Open my artworks", url: `${this.site}/dashboard/artworks` },
    });
  }

  // ── Aggregators ──────────────────────────────────────────────────────

  /**
   * A physical artwork leaves the artist's studio for a partner gallery.
   * Both sides need this in writing: the artist because their work is
   * moving, the aggregator because it is the record of the terms and the
   * advance they just committed to.
   */
  async aggregatorReserved(input: { holdingId: string; artworkId: string; aggregatorId: string; advanceAmountPaise: number; displayPricePaise: number; expiresAt: Date }) {
    const artworkSnap = await this.db.collection(Collections.artworks).doc(input.artworkId).get();
    const artwork = artworkSnap.data() as { title?: string; artistId?: string } | undefined;
    if (!artwork?.artistId) return;

    const [artist, aggregator] = await Promise.all([this.user(artwork.artistId), this.user(input.aggregatorId)]);
    const title = artwork.title ?? "your artwork";
    const until = input.expiresAt.toLocaleDateString("en-IN", { day: "numeric", month: "long", year: "numeric" });
    const gallery = aggregator?.name ?? "a partner gallery";

    if (artist) {
      await this.deliver(`holding-reserved-artist/${input.holdingId}`, artist.email, `“${title}” has been reserved by a gallery`, {
        preheader: `${gallery} will display it until ${until}.`,
        heading: "A gallery has reserved your artwork",
        paragraphs: [
          `<strong>${esc(gallery)}</strong> has reserved “${esc(title)}” for display until <strong>${esc(until)}</strong>.`,
          "Pack the piece to the standard in your agreement and wait for pickup instructions. If it doesn't sell within the placement window it comes back to you and returns to the marketplace automatically.",
        ],
        cta: { label: "See this piece", url: `${this.site}/dashboard/artworks` },
      });
    }

    if (aggregator) {
      await this.deliver(`holding-reserved-aggregator/${input.holdingId}`, aggregator.email, `Reserved: “${title}”`, {
        heading: "Your reservation is confirmed",
        paragraphs: [
          `“${esc(title)}” is reserved for you until <strong>${esc(until)}</strong>.`,
          `Advance committed: <strong>${inr(input.advanceAmountPaise)}</strong>. Display price: <strong>${inr(input.displayPricePaise)}</strong>.`,
          "Record the sale in your dashboard the moment it sells — a cash sale has to be remitted in full, never netted against your commission.",
        ],
        cta: { label: "Open my holdings", url: `${this.site}/aggregator/collection` },
      });
    }
  }

  /**
   * An aggregator priced a piece far above GalleryZone's offer. It is allowed
   * (client, 30 Sep 2026: no limit), but GalleryZone is told.
   */
  async holdingPriceWarning(input: { holdingId: string; artworkId: string; aggregatorId: string; sellingPricePaise: number; offerSellingPricePaise: number }) {
    const [artwork, aggregator, admins] = await Promise.all([this.artwork(input.artworkId), this.user(input.aggregatorId), this.admins()]);
    const title = artwork?.title ?? "an artwork";
    const over = Math.round((input.sellingPricePaise / input.offerSellingPricePaise - 1) * 100);
    await this.deliver(`holding-price-warning/${input.holdingId}`, admins, `Price warning: “${title}” priced ${over}% above the offer`, {
      heading: "A piece was priced far above your offer",
      paragraphs: [
        `<strong>${esc(aggregator?.name ?? "An aggregator")}</strong> reserved “${esc(title)}” at <strong>${inr(input.sellingPricePaise)}</strong> before GST, ${over}% above GalleryZone's price of ${inr(input.offerSellingPricePaise)}.`,
        "This is allowed and the reservation went through. It is a heads-up in case you want to look at it.",
      ],
      cta: { label: "Open this artwork", url: `${this.site}/admin/artworks/${input.artworkId}` },
    });
  }

  /** An aggregator wants to keep a piece past its window. GalleryZone decides each time. */
  async holdingExtensionRequested(input: { holdingId: string; artworkId: string; aggregatorId: string; assurance: string; expiresAt: Date }) {
    const [artwork, aggregator, admins] = await Promise.all([this.artwork(input.artworkId), this.user(input.aggregatorId), this.admins()]);
    const title = artwork?.title ?? "an artwork";
    const until = input.expiresAt.toLocaleDateString("en-IN", { day: "numeric", month: "long", year: "numeric" });
    await this.deliver(`holding-extension-requested/${input.holdingId}/${input.expiresAt.getTime()}`, admins, `Extension to decide: “${title}”`, {
      heading: "An aggregator wants to keep a piece longer",
      paragraphs: [
        `<strong>${esc(aggregator?.name ?? "An aggregator")}</strong> is asking to keep “${esc(title)}” past <strong>${esc(until)}</strong>.`,
        `Their assurance that it will sell: “${esc(input.assurance)}”`,
        "If nobody answers before the window ends, the piece goes back and the advance is released.",
      ],
      cta: { label: "Review the request", url: `${this.site}/admin/artworks/${input.artworkId}` },
    });
  }

  async holdingExtensionDecided(input: { holdingId: string; artworkId: string; aggregatorId: string; approved: boolean; newExpiresAt: Date | null; note: string | null }) {
    const [artwork, aggregator] = await Promise.all([this.artwork(input.artworkId), this.user(input.aggregatorId)]);
    if (!aggregator) return;
    const title = artwork?.title ?? "your piece";
    const until = input.newExpiresAt?.toLocaleDateString("en-IN", { day: "numeric", month: "long", year: "numeric" });
    await this.deliver(`holding-extension-decided/${input.holdingId}/${input.approved ? "yes" : "no"}`, aggregator.email, input.approved ? `You can keep “${title}” longer` : `Your request for “${title}” was not approved`, {
      heading: input.approved ? "Your request was approved" : "Your request was not approved",
      paragraphs: [
        input.approved
          ? `You can keep “${esc(title)}” until <strong>${esc(until ?? "")}</strong>. Your advance stays held until then.`
          : `“${esc(title)}” goes back at the end of its window, and your advance is released then.`,
      ],
      ...(input.note ? { footnote: `GalleryZone's note: ${esc(input.note)}` } : {}),
      cta: { label: "Open my inventory", url: `${this.site}/aggregator/collection` },
    });
  }

  /** The window ended and the piece moved on. The advance is released the same day. */
  async holdingPeriodEnded(input: { holdingId: string; artworkId: string; aggregatorId: string; advancePaise: number }) {
    const [artwork, aggregator] = await Promise.all([this.artwork(input.artworkId), this.user(input.aggregatorId)]);
    if (!aggregator) return;
    const title = artwork?.title ?? "your piece";
    await this.deliver(`holding-period-ended/${input.holdingId}`, aggregator.email, `Your period has ended: “${title}”`, {
      heading: "Your display period has ended",
      paragraphs: [
        `Your period for “${esc(title)}” has ended and it is now available to another aggregator.`,
        `Your advance of <strong>${inr(input.advancePaise)}</strong> has been released. The delivery deposit is not refunded on an unsold piece.`,
      ],
      cta: { label: "See my wallet", url: `${this.site}/aggregator/wallet` },
    });
  }

  private async artwork(artworkId: string): Promise<{ title?: string } | undefined> {
    return (await this.db.collection(Collections.artworks).doc(artworkId).get()).data() as { title?: string } | undefined;
  }

  // ── Money ────────────────────────────────────────────────────────────

  async withdrawalRequested(input: { withdrawalId: string; userId: string; amountPaise: number }) {
    const [user, admins] = await Promise.all([this.user(input.userId), this.admins()]);
    if (user) {
      await this.deliver(`withdrawal-requested/${input.withdrawalId}`, user.email, `Withdrawal request received — ${inr(input.amountPaise)}`, {
        heading: "We've received your withdrawal request",
        paragraphs: [`<strong>${inr(input.amountPaise)}</strong> is on its way to review. Payouts are processed within 2 working days and land in the bank account on your profile.`],
        cta: { label: "View my wallet", url: `${this.site}/dashboard/wallet` },
      });
    }
    await this.deliver(`withdrawal-requested-admin/${input.withdrawalId}`, admins, `Withdrawal to approve: ${inr(input.amountPaise)} for ${user?.name ?? input.userId}`, {
      heading: "Withdrawal awaiting approval",
      paragraphs: [`<strong>${esc(user?.name ?? input.userId)}</strong> requested <strong>${inr(input.amountPaise)}</strong>.`],
      cta: { label: "Open withdrawals", url: `${this.site}/admin/moderation/withdrawals` },
    });
  }

  async withdrawalDecided(input: { withdrawalId: string; userId: string; amountPaise: number; approved: boolean }) {
    const user = await this.user(input.userId);
    if (!user) return;
    await this.deliver(`withdrawal-${input.approved ? "approved" : "rejected"}/${input.withdrawalId}`, user.email, input.approved ? `Payout sent — ${inr(input.amountPaise)}` : `Withdrawal not approved — ${inr(input.amountPaise)}`, {
      heading: input.approved ? "Your payout has been sent" : "Your withdrawal wasn't approved",
      paragraphs: [
        input.approved
          ? `<strong>${inr(input.amountPaise)}</strong> has been transferred to the bank account on your profile. Allow 1–2 working days for it to appear.`
          : `Your request for <strong>${inr(input.amountPaise)}</strong> was not approved. The amount is back in your wallet. Reply to this email if you'd like to know why.`,
      ],
      cta: { label: "View my wallet", url: `${this.site}/dashboard/wallet` },
    });
  }

  /**
   * The artist asked to leave and then heard nothing either way. Admins
   * weren't told a request had been filed at all, so it could sit unseen.
   */
  async deactivationRequested(input: { userId: string; reason: string }) {
    const [user, admins] = await Promise.all([this.user(input.userId), this.admins()]);
    if (user) {
      await this.deliver(`deactivation-requested/${input.userId}`, user.email, "We've received your deactivation request", {
        heading: "Your request is with us",
        paragraphs: ["We'll review it and come back to you. Anything still in progress — a live listing, a piece with a gallery, an unpaid settlement — has to be closed out before an account can be deactivated."],
      });
    }
    await this.deliver(`deactivation-requested-admin/${input.userId}`, admins, `Deactivation requested by ${user?.name ?? input.userId}`, {
      heading: "Deactivation request",
      paragraphs: [`<strong>${esc(user?.name ?? input.userId)}</strong> asked to deactivate their account.`, `Reason given: ${esc(input.reason)}`],
    });
  }

  async deactivationDecided(input: { userId: string; approved: boolean; note?: string | undefined }) {
    const user = await this.user(input.userId);
    if (!user) return;
    await this.deliver(`deactivation-${input.approved ? "approved" : "rejected"}/${input.userId}`, user.email, input.approved ? "Your account has been deactivated" : "We couldn't deactivate your account yet", {
      heading: input.approved ? "Your account is deactivated" : "Your deactivation is on hold",
      paragraphs: [
        input.approved
          ? "Your account is closed. Your provenance records stay intact — every certificate you issued remains verifiable, because collectors rely on them."
          : "We can't close the account yet. Usually that means something is still open: a live listing, a piece out with a gallery, or an unsettled balance.",
      ],
      ...(input.note ? { footnote: `Note from the reviewer: ${esc(input.note)}` } : {}),
    });
  }

  /** The fee is raised automatically when an artist declares a sale elsewhere; the decision on it came silently. */
  async externalSaleFeeDecided(input: { penaltyId: string; artistId: string; title: string; amountPaise: number; waived: boolean; note?: string | undefined }) {
    const artist = await this.user(input.artistId);
    if (!artist) return;
    await this.deliver(`external-fee-${input.waived ? "waived" : "approved"}/${input.penaltyId}`, artist.email, input.waived ? `Fee waived — “${input.title}”` : `External-sale fee confirmed — “${input.title}”`, {
      heading: input.waived ? "We've waived this fee" : "Your external-sale fee is confirmed",
      paragraphs: [
        input.waived
          ? `The <strong>${inr(input.amountPaise)}</strong> fee on “${esc(input.title)}” has been waived. Nothing is owed.`
          : `The fee for selling “${esc(input.title)}” away from GalleryZone is <strong>${inr(input.amountPaise)}</strong>. It comes off your next settlement.`,
      ],
      ...(input.note ? { footnote: `Note from the reviewer: ${esc(input.note)}` } : {}),
      cta: { label: "View my wallet", url: `${this.site}/dashboard/wallet` },
    });
  }

  // ── Security ─────────────────────────────────────────────────────────

  /**
   * A changed payout destination is the classic account-takeover payload, so
   * it always gets mailed — the point is that the real owner hears about it
   * even when they were not the one who made the change.
   */
  async bankAccountChanged(input: { userId: string; maskedAccount: string | null }) {
    const user = await this.user(input.userId);
    if (!user) return;
    await this.deliver(`bank-changed/${input.userId}/${Date.now()}`, user.email, "Your payout account was changed", {
      preheader: "If this wasn't you, tell us straight away.",
      heading: "Your payout account was changed",
      paragraphs: [
        input.maskedAccount
          ? `Payouts will now go to the account ending <strong>${esc(input.maskedAccount.replace(/^•+\s*/, ""))}</strong>.`
          : "The bank account on your profile has been removed, so payouts are on hold until you add one.",
        "<strong>If you didn't do this, reply to this email immediately</strong> and we'll freeze payouts while we look into it.",
      ],
      cta: { label: "Check my profile", url: `${this.site}/dashboard/profile` },
    });
  }

  /** An admin suspending or restoring an account used to be entirely silent to the person it happened to. */
  async accountStatusChanged(input: { userId: string; status: string }) {
    const user = await this.user(input.userId);
    if (!user) return;
    const copy: Record<string, { subject: string; heading: string; body: string }> = {
      suspended: { subject: "Your account has been suspended", heading: "Your account is suspended", body: "You won't be able to sign in while this is in place. Reply to this email if you think it's a mistake and we'll take another look." },
      blocked: { subject: "Your account has been blocked", heading: "Your account is blocked", body: "Access has been withdrawn. Reply to this email if you believe this is an error." },
      active: { subject: "Your account is active again", heading: "Welcome back", body: "Your account has been restored and you can sign in as normal." },
    };
    const c = copy[input.status];
    if (!c) return;
    await this.deliver(`account-${input.status}/${input.userId}/${Date.now()}`, user.email, c.subject, {
      heading: c.heading,
      paragraphs: [c.body],
    });
  }

  /** The buyer got as far as the gateway and it didn't go through. Nothing was said, so the cart just died. */
  async paymentFailed(input: { orderId: string; customerId: string; title: string; totalPaise: number }) {
    const buyer = await this.user(input.customerId);
    if (!buyer) return;
    await this.deliver(`payment-failed/${input.orderId}`, buyer.email, `Your payment for “${input.title}” didn't go through`, {
      heading: "That payment didn't go through",
      paragraphs: [
        `Your payment of <strong>${inr(input.totalPaise)}</strong> for “${esc(input.title)}” was not completed, so the order hasn't been placed and you haven't been charged.`,
        "The piece is still available. It's an original, so it stays available only until someone else buys it.",
      ],
      cta: { label: "Try again", url: `${this.site}/account/orders/${input.orderId}` },
    });
  }

  // ── Support ──────────────────────────────────────────────────────────

  /**
   * A ticket used to vanish into a queue: the person who raised it got no
   * acknowledgement, and admins only saw it if they happened to open the
   * queue. Replies go to the requester's own address, so support can just
   * hit reply.
   */
  async supportTicketRaised(input: { ticketId: string; userId: string; subject: string; message: string }) {
    const [user, admins] = await Promise.all([this.user(input.userId), this.admins()]);
    if (user) {
      await this.deliver(`support-ack/${input.ticketId}`, user.email, `We've got your message — ${input.subject}`, {
        heading: "Thanks — we've got it",
        paragraphs: [
          `We've received your message about <strong>${esc(input.subject)}</strong> and someone will come back to you, usually within one working day.`,
          "You can reply to this email to add anything else.",
        ],
        cta: { label: "View my messages", url: `${this.site}${SUPPORT_PATH[user.role] ?? "/account/support"}` },
      });
    }
    await this.deliver(`support-new-admin/${input.ticketId}`, admins, `Support: ${input.subject}`, {
      heading: "New support ticket",
      paragraphs: [
        `<strong>${esc(user?.name ?? input.userId)}</strong>${user ? ` (${esc(user.email)}, ${esc(user.role)})` : ""} wrote:`,
        esc(input.message),
      ],
      footnote: "Reply to this email to answer them directly.",
    }, user?.email);
  }

  /** Any unexpected failure in a mail hook is logged here — never propagated. */
  swallow(label: string) {
    return (error: unknown) => this.logger.error(`${label}: ${String(error)}`);
  }
}
