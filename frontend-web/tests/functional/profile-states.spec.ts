import { test, expect, type Page } from '@playwright/test';
import { signInAs } from '../support/auth';
import { dismissCookieConsent } from '../support/settle';

// The artist profile page used to sit on a blank skeleton whenever a request
// behind it failed (the account lookup, or the profile itself). It must say so
// and offer a retry. Also covers the real logo on the auth screens and the
// YouTube link in the footer. The API is stubbed.

const ME = { uid: 'u1', role: 'artist', status: 'active', name: 'Meera Kulkarni', email: 'meera@example.in', phone: '9876543210', roleGrants: [] };
const PROFILE = {
  uid: 'u1', fullName: 'Meera Kulkarni', email: 'meera@example.in', phone: '9876543210', role: 'artist', status: 'active',
  createdAt: '2026-01-10T00:00:00.000Z', bio: null, profileImageUrl: null, headline: null, location: null, instagram: null,
  website: null, pan: 'ABCDE1234F', gstin: null, gstStatus: 'not_submitted', aadhaarStatus: 'not_submitted', aadhaarMasked: null,
  bankAccountMasked: null, ifsc: null, pickupLine1: null, pickupLine2: null, pickupCity: null, pickupState: null, pickupPincode: null,
  earningsAbove5L: false, socialProofVideoUrl: null, companyName: null,
};
const MOU = { acceptance: null, draft: { version: '2026.3', parties: { party: { name: 'Meera Kulkarni', businessName: null, address: null, mobile: null, email: 'meera@example.in', governmentId: null, gstNo: null }, company: { name: 'Anand Rao', designation: 'Director' } }, missing: [], asOf: '2026-09-29T13:15:00.000Z' } };

const cors = { 'access-control-allow-origin': '*' };
const ok = (body: unknown) => ({ status: 200, contentType: 'application/json', headers: cors, body: JSON.stringify(body) });
const fail = { status: 500, contentType: 'application/problem+json', headers: cors, body: JSON.stringify({ type: 'about:blank', title: 'Server error', status: 500, code: 'internal' }) };

async function openProfile(page: Page, baseURL: string, routes: Record<string, () => object>) {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await signInAs(page.context(), 'artist', baseURL);
  for (const [pattern, reply] of Object.entries(routes)) await page.route(pattern, (route) => route.fulfill(reply()));
  await page.goto('/dashboard/profile');
}

// TanStack retries a failed query three times (1s, 2s, 4s) before it reports
// the error, so the message takes about seven seconds to appear.
const SLOW = { timeout: 20_000 };

test('the profile figures say when they cannot load, instead of a blank card', async ({ page, baseURL }) => {
  await openProfile(page, baseURL!, {
    '**/v1/auth/me': () => fail,
    '**/v1/me/profile': () => ok(PROFILE),
    '**/v1/artist/mou': () => ok(MOU),
  });
  await expect(page.getByText('Your profile figures couldn’t be loaded just now.')).toBeVisible(SLOW);
  await expect(page.getByRole('button', { name: 'Try again' })).toBeVisible();
  await expect(page.locator('.animate-pulse')).toHaveCount(0);
});

test('the profile page says when the profile itself cannot load, and recovers on retry', async ({ page, baseURL }) => {
  let healthy = false;
  await openProfile(page, baseURL!, {
    '**/v1/auth/me': () => ok(ME),
    '**/v1/me/profile': () => (healthy ? ok(PROFILE) : fail),
    '**/v1/artist/mou': () => ok(MOU),
  });
  await expect(page.getByRole('heading', { name: "Couldn't load your profile" })).toBeVisible(SLOW);

  healthy = true;
  await page.getByRole('button', { name: 'Try again' }).click();
  await expect(page.getByRole('heading', { name: 'Public profile' })).toBeVisible(SLOW);
});

test('login and register show the GalleryZone logo, not a text stand-in', async ({ page }) => {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  for (const path of ['/login', '/register']) {
    await page.goto(path);
    const logos = page.getByRole('img', { name: 'GalleryZone' });
    await expect(logos.first()).toBeVisible();
    // The side panel shows one too on a wide screen; the form crest always does.
    expect(await logos.count()).toBeGreaterThanOrEqual(1);
    const loaded = await logos.first().evaluate((img: HTMLImageElement) => img.complete && img.naturalWidth > 0);
    expect(loaded, `${path} logo image loaded`).toBe(true);
  }
});

test('the footer links to YouTube', async ({ page }) => {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await page.goto('/about');
  await expect(page.getByRole('link', { name: 'YouTube' })).toBeVisible();
});
