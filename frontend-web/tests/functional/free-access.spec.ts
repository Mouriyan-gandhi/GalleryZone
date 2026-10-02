import { test, expect, type Page } from '@playwright/test';
import { signInAs } from '../support/auth';
import { dismissCookieConsent } from '../support/settle';

// The Early Artist Program: six months free, a year for artists who filled in
// the survey. The landing page says so, and the artist's dashboard shows how
// long their own free access runs. The API is stubbed.

const cors = { 'access-control-allow-origin': '*' };
const ok = (body: unknown) => ({ status: 200, contentType: 'application/json', headers: cors, body: JSON.stringify(body) });

const ME = { uid: 'u1', role: 'artist', status: 'active', name: 'Meera Kulkarni', email: 'meera@example.in', phone: null, roleGrants: [] };
const profile = (freeAccess: unknown) => ({
  uid: 'u1', fullName: 'Meera Kulkarni', email: 'meera@example.in', phone: '9876543210', role: 'artist', status: 'active',
  createdAt: '2026-10-01T06:00:00.000Z', bio: null, profileImageUrl: null, headline: null, location: null, instagram: null,
  website: null, pan: null, gstin: null, gstStatus: 'not_submitted', aadhaarStatus: 'not_submitted', aadhaarMasked: null,
  bankAccountMasked: null, ifsc: null, pickupLine1: null, pickupLine2: null, pickupCity: null, pickupState: null, pickupPincode: null,
  earningsAbove5L: false, socialProofVideoUrl: null, companyName: null, freeAccess,
});

async function openDashboard(page: Page, baseURL: string, freeAccess: unknown) {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await signInAs(page.context(), 'artist', baseURL);
  await page.route('**/v1/auth/me', (route) => route.fulfill(ok(ME)));
  await page.route('**/v1/me/profile', (route) => route.fulfill(ok(profile(freeAccess))));
  // The artist profile loads the MOU alongside it.
  await page.route('**/v1/artist/mou', (route) => route.fulfill(ok({ acceptance: null, draft: null })));
  await page.goto('/dashboard');
}

test('the early artist offer says six months, and a year for survey respondents', async ({ page }) => {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await page.goto('/');
  await expect(page.getByText('6 Months Free Access').first()).toBeVisible();
  await expect(page.getByText(/Artists who filled in our survey get a full year/)).toBeVisible();
  await expect(page.getByText(/1 Year Free Access|one year of free access/i)).toHaveCount(0);
});

test('an artist sees six months of free access, and when it ends', async ({ page, baseURL }) => {
  await openDashboard(page, baseURL!, { until: '2027-04-01T06:00:00.000Z', months: 6, surveyRespondent: false, active: true });
  const note = page.getByText('Free access to every premium feature, for your first six months.').filter({ visible: true });
  await expect(note).toBeVisible();
  await expect(page.getByText('It runs until 1 April 2027.').filter({ visible: true })).toBeVisible();
});

test('a survey respondent sees a full year', async ({ page, baseURL }) => {
  await openDashboard(page, baseURL!, { until: '2027-10-01T06:00:00.000Z', months: 12, surveyRespondent: true, active: true });
  await expect(page.getByText('A full year of free access to every premium feature, because you filled in our survey.').filter({ visible: true })).toBeVisible();
  await expect(page.getByText('It runs until 1 October 2027.').filter({ visible: true })).toBeVisible();
});

test('once free access has ended the dashboard says nothing about it', async ({ page, baseURL }) => {
  await openDashboard(page, baseURL!, { until: '2026-12-01T06:00:00.000Z', months: 6, surveyRespondent: false, active: false });
  await expect(page.getByRole('heading', { name: /Welcome|Dashboard/ }).first()).toBeVisible();
  await expect(page.getByText(/free access/i)).toHaveCount(0);
});

test('the Settings plan card shows the same free period, not a hard-coded year', async ({ page, baseURL }) => {
  await openDashboard(page, baseURL!, { until: '2027-04-01T06:00:00.000Z', months: 6, surveyRespondent: false, active: true });
  await page.goto('/dashboard/settings');
  await expect(page.getByText('Free for your first six months')).toBeVisible();
  await expect(page.getByText(/Free until 1 April 2027, then ₹1,200\/year/)).toBeVisible();
  await expect(page.getByText(/first year/i)).toHaveCount(0);
});

test('a survey respondent’s Settings plan card says a year, and an ended period says so', async ({ page, baseURL }) => {
  await openDashboard(page, baseURL!, { until: '2027-10-01T06:00:00.000Z', months: 12, surveyRespondent: true, active: true });
  await page.goto('/dashboard/settings');
  await expect(page.getByText('Free for your first year')).toBeVisible();
  await expect(page.getByText(/Free until 1 October 2027/)).toBeVisible();

  await page.route('**/v1/me/profile', (route) => route.fulfill(ok(profile({ until: '2026-12-01T06:00:00.000Z', months: 6, surveyRespondent: false, active: false }))));
  await page.reload();
  await expect(page.getByText('Ended', { exact: true })).toBeVisible();
  await expect(page.getByText(/Your free period ended on 1 December 2026/)).toBeVisible();
});
