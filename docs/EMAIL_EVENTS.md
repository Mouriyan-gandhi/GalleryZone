# Email events

Every moment GalleryZone should send mail, who receives it, and what is
built today. Written 19 Sep 2026, revised 22 Sep 2026 against
`backend/apps/api/src/mail/`.

**Status key**

- **Live** — template written and wired to the event; it sends today.
- **Template only** — the template exists but nothing calls it; no mail goes out.
- **Not built** — neither template nor trigger.

**How sending works.** `Mailer.send()` (`mail/mailer.ts`) is fire-and-forget
and never throws — a failed send is logged, never a failed request. Every
send carries an idempotency key (e.g. `order-paid-buyer/<orderId>`), so a
retried request cannot send the same mail twice. With no `RESEND_API_KEY`
the mailer dry-runs and logs instead of sending.

**What gates real delivery**

1. `galleryzone.art` is **verified in Resend** as of 22 Sep 2026, so mail
   leaves from the real domain rather than the sandbox sender. That has not
   yet been confirmed by actually receiving one — send yourself a password
   reset.
2. Admin-recipient mails resolve to every user with `role == "admin"`. If no
   admin account exists, those sends are silently skipped.

**Every CTA link is checked against `frontend-web/app`.** Three were wrong
and shipping in live mail until 22 Sep (`/admin/withdrawals`,
`/aggregator/holdings`, `/dashboard/coa`). There is no shared `/support`
page either — it resolves per role.

---

## 1. Account

| Event | To | Status | Notes |
|---|---|---|---|
| Registered (email/password) | the new user | **Live** | Carries the "confirm my email" link. |
| Registered via Google (first sign-in bootstrap) | the new user | **Live** | No verify link — Google already verified the address. |
| Password reset requested | the account | **Live** | One-use link, one hour. Sent even when the address has no account? No — silently skipped, so the form can't be used to discover who has an account. |
| Email verification re-sent | the account | **Live** | `POST /v1/auth/resend-verification`. |
| Email address changed | old **and** new address | **Not built** | Security-relevant: the old address must be told. |
| Password changed | the account | **Not built** | Same reason. |
| Account suspended / reactivated by an admin | the user | **Live** | Suspended, blocked and restored. |
| Deactivation requested by the artist | the artist + admins | **Live** | |
| Deactivation approved / rejected | the artist | **Live** | Carries the reviewer’s note. |

## 2. Artist — listings

| Event | To | Status | Notes |
|---|---|---|---|
| Artwork submitted for review | the artist | **Live** | "It's in review." |
| Artwork submitted for review | admins | **Live** | The review queue prompt. |
| Artwork approved and listed | the artist | **Live** | Includes the CoA certificate number. |
| Artwork rejected | the artist | **Live** | Carries the admin's reason. |
| Artwork delisted by an admin | the artist | **Live** | |
| Free edit window about to close | the artist | **Not built** | Needs a scheduled job. |
| Listing expiring (end of the 180-day window) | the artist | **Not built** | Needs a scheduled job. |
| "Sold elsewhere" declared → external-sale fee raised | the artist | **Not built** | The artist triggers this themselves and the response carries the amount, so it is the weakest gap here. |
| External-sale fee decided by an admin | the artist | **Live** | Approved or waived, with the amount and the reviewer’s note. |

## 3. Artist — compliance

| Event | To | Status | Notes |
|---|---|---|---|
| GSTIN approved / rejected | the artist or aggregator | **Live** | An aggregator can't reserve until it is approved. It no longer decides TDS, which follows the artist's financial-year sales. |
| KYC approved / rejected | the artist | **Live** | Blocks payouts while unresolved. |
| Insurance approved / rejected on a piece | the artist | **Live** | |
| Artist MOU version bumped → re-signature required | all artists | **Not built** | Today they only find out on next sign-in. |
| Sales crossed ₹5,00,000 in the financial year (TDS starts) | the artist | **Not built** | TDS is now withheld from the sale that crosses the line. The artist should know why a payout came in lower. |

## 4. Orders and payment

| Event | To | Status | Notes |
|---|---|---|---|
| Payment captured — order confirmed | the buyer | **Live** | Receipt with the total paid. |
| Payment captured — piece sold | the artist | **Live** | Shows their net settlement. |
| Payment captured | admins | **Not built** | No ops notification on a sale. |
| Payment failed or abandoned | the buyer | **Live** | On Razorpay's `payment.failed` webhook. Says they were not charged and the piece is still available. |
| Order confirmed → packed → transit → delivered → cancelled | the buyer | **Live** | Wired into `PATCH /v1/admin/orders/:id/status`. The copy had been keyed to `shipped`/`refunded`, which are not order statuses, so nothing would have matched even once it was called. |
| Order status changed | the artist | **Live** | On the stages that are theirs: confirmed, transit, delivered, cancelled. |
| Order cancelled / refunded | the buyer + the artist | **Not built** | There is no refund flow yet at all. |
| GST invoice issued | the buyer | **Not built** | Needs the invoice PDF first. |
| Settlement released (7 days after delivery) | the artist | **Not built** | Needs the payout job. |

## 5. Money — wallet and payouts

| Event | To | Status | Notes |
|---|---|---|---|
| Withdrawal requested | the requester | **Live** | Artist, aggregator or collector. |
| Withdrawal requested | admins | **Live** | The approval prompt. |
| Withdrawal approved | the requester | **Live** | |
| Withdrawal rejected | the requester | **Live** | |
| Payout actually paid out (NEFT/RazorpayX reference) | the requester | **Not built** | Approval and payment are separate events; only approval is mailed. |
| Bank account changed on a profile | the account | **Live** | Always sent, with a “wasn’t you?” line — the point is the real owner hears about it. |

## 6. Certificates, ownership and the passport

| Event | To | Status | Notes |
|---|---|---|---|
| Physical CoA requested by an owner | the artist | **Live** | They hand-sign and dispatch it. |
| Physical CoA dispatched | the requester | **Not built** | The person waiting for it is never told it shipped. |
| Ownership transfer invited | the recipient | **Live** | Works for an unregistered recipient — the link is the whole flow. |
| Transfer accepted | the sender | **Not built** | |
| Transfer cancelled or expired | both parties | **Not built** | |
| Display period ended | both parties | **Not built** | |
| NFC tag linked to a piece | the artist | **Not built** | Low priority; the UI confirms it. |

## 7. Aggregators

| Event | To | Status | Notes |
|---|---|---|---|
| Aggregator reserved a piece | the aggregator | **Live** | Their confirmation of the advance and the placement window. |
| Aggregator reserved a piece | the artist | **Live** | Names the gallery and the date the placement window closes. |
| Reserved piece — shipping instructions | the artist | **Not built** | |
| Placement window closing (7 days out) | the aggregator | **Not built** | The expiry sweep exists now (below), so this is a small addition to it. |
| Placement window ended, piece moved on, advance released | the aggregator | **Live** | Sent by the sweep in `holding-expiry.ts`, which runs at boot and every 15 minutes. Not sent to the artist yet. |
| Aggregator priced a piece at least double GalleryZone's offer | admins | **Live** | A warning, never a block (`aggregatorPriceWarnRate`). |
| Aggregator asked to keep a piece past its window | admins | **Live** | Carries their assurance. |
| Extension request approved / declined | the aggregator | **Live** | Carries GalleryZone's note. |
| Piece returned unsold | the artist + admins | **Not built** | |
| Sale recorded at a partner gallery | the artist + admins | **Not built** | |
| Cash-at-premises sale due, or overdue | the aggregator | **Not built** | The full price is due 2 days after the sale (client, 30 Sep 2026). The due date and an overdue flag show on the Settlements page; no mail is sent yet. |
| Admin pulled a piece back | the aggregator + the artist | **Not built** | |
| Aggregator MOU re-signature required | all aggregators | **Not built** | |

## 8. Support and admin

| Event | To | Status | Notes |
|---|---|---|---|
| Support ticket raised | the person who raised it | **Live** | |
| Support ticket raised | admins | **Live** | Carries the message body with `replyTo` set to the requester, because there is still no admin support queue page. |
| Support ticket replied to | the requester | **Not built** | |
| Pricing-rule change proposed | the other platform admins | **Not built** | The two-admin approval needs a nudge to reach the second admin. |
| Pricing-rule change approved | both admins | **Not built** | Every price on the site just moved — worth a record. |

---

## Recommended order of work

Items 1–3 and 5 of the original list were done on 22 Sep 2026: order status
to the buyer and the artist, aggregator reservation to both sides, the
compliance decisions, delisting, deactivation, the external-sale fee
decision, and support acknowledgement in both directions. What is left:

1. **Password changed / email address changed** → the account. The last two
   security mails. Both happen inside Firebase Auth rather than in our own
   handlers, so they need a Firebase Function on the auth events, not a
   controller call — which is why they are still open while the other
   security mails are done.
2. **Payout actually paid out** → the requester. Approval and the bank
   transfer are separate events; only approval is mailed. Needs the RazorpayX
   payout integration to have something to report.
3. **GST invoice issued** → the buyer. Needs the invoice PDF first.
4. **Scheduled mails** — listing expiry, free-edit window closing,
   settlement released, and a 7-day warning before a placement window ends.
   Placement expiry itself now runs (`holding-expiry.ts`); the rest all need
   the cron work already on the launch list, so they come last.
5. **Support ticket replied to.** There is no admin reply flow, or an admin
   support queue page, to hang it on yet.

## Adding one

Add a method to `Emails` (`apps/api/src/mail/emails.ts`) following the shape
of the existing ones — resolve the recipient from Firestore, build a
`Layout`, and pass a stable idempotency key. Then call it from the
controller that owns the event with
`void this.emails.yourEvent(...).catch(this.emails.swallow("label"))`, so a
mail failure can never fail the request that triggered it.
