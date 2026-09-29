import { test, expect, type Page } from '@playwright/test';
import { signInAs, type SessionRole } from '../support/auth';
import { assertNoHorizontalOverflow } from '../support/overflow';
import { dismissCookieConsent } from '../support/settle';

// /passport/<topic> shows the same explainer to everyone, but the slot under
// "what it includes" and the hero button depend on who is looking. The API is
// stubbed here so this covers the page's rendering, not the backend (the
// backend's own checks live in backend/packages/*/src/*.check.ts).

const piece = (n: number, over: Record<string, unknown> = {}) => ({
  relations: ['owner'],
  nfcLinked: null,
  holdingId: null,
  passport: {
    artworkId: `art${n}`,
    productCode: `AV00000${n}`,
    title: `Study in Ochre ${n}`,
    artistId: 'artist1',
    artistName: 'Meera Kulkarni',
    category: 'Painting',
    medium: 'Oil on canvas',
    dimensions: '24 x 36 in',
    yearCreated: 2025,
    images: [{ url: '/identity/painting.png', thumbnailUrl: null, altText: null, sortOrder: 0 }],
    status: 'sold',
    coaCertificateNumber: `GZ-COA-2026-000${n}`,
    coaIssuedAt: '2026-03-14T00:00:00.000Z',
    listedAt: '2026-02-01T00:00:00.000Z',
    owner: { kind: 'collector', displayName: 'Aarav Shah' },
    events: [
      {
        id: `art${n}.e1`,
        kind: 'ownership',
        status: 'accepted',
        fromName: 'Meera Kulkarni',
        toName: 'Aarav Shah',
        viaSale: true,
        initiatedAt: '2026-04-01T00:00:00.000Z',
        acceptedAt: '2026-04-01T00:00:00.000Z',
        cancelledAt: null,
        displayEndsAt: null,
        displayEndedAt: null,
      },
    ],
  },
  ...over,
});

async function stubMine(page: Page, status: number, body: unknown) {
  await page.route('**/v1/passport/mine', (route) =>
    route.fulfill({
      status,
      contentType: 'application/json',
      headers: { 'access-control-allow-origin': '*' },
      body: JSON.stringify(body),
    }),
  );
}

async function open(page: Page, role: SessionRole | null, topic: string, baseURL: string) {
  await dismissCookieConsent(page);
  if (role) await signInAs(page.context(), role, baseURL);
  await page.goto(`/passport/${topic}`);
}

test('a visitor gets the marketplace button and a way to sign up, not a pieces list', async ({ page, baseURL }) => {
  await open(page, null, 'identity', baseURL!);
  await expect(page.getByRole('link', { name: 'Browse artworks' })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Create an account' })).toHaveAttribute('href', '/register');
  await expect(page.getByRole('heading', { name: 'Your pieces' })).toHaveCount(0);
});

test('a collector sees their own certificates, three at a time', async ({ page, baseURL }) => {
  await stubMine(page, 200, { total: 4, items: [1, 2, 3, 4].map((n) => piece(n)) });
  await open(page, 'customer', 'certificate', baseURL!);

  await expect(page.getByRole('heading', { name: 'Your pieces' })).toBeVisible();
  await expect(page.getByText('4 pieces', { exact: true })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Open my collection' })).toHaveAttribute('href', '/account/collection');
  await expect(page.getByRole('link', { name: 'Ask for a signed copy' })).toHaveAttribute('href', '/account/collection');
  await expect(page.getByText('GZ-COA-2026-0001')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Download certificate (PDF)' })).toHaveCount(3);

  await page.getByRole('button', { name: 'Show all 4 pieces' }).click();
  await expect(page.getByRole('button', { name: 'Download certificate (PDF)' })).toHaveCount(4);
  await expect(page.getByRole('button', { name: 'Show fewer' })).toHaveAttribute('aria-expanded', 'true');

  await page.screenshot({ path: 'test-results/passport-collector-certificate.png', fullPage: true });
});

test('an artist sees product IDs and which works still need a tag', async ({ page, baseURL }) => {
  await stubMine(page, 200, {
    total: 2,
    items: [
      piece(1, { relations: ['artist'], nfcLinked: true }),
      piece(2, { relations: ['artist', 'owner'], nfcLinked: false }),
    ],
  });
  await open(page, 'artist', 'identity', baseURL!);

  await expect(page.getByRole('heading', { name: 'Your works' })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Open my dashboard' })).toHaveAttribute('href', '/dashboard');
  await expect(page.getByRole('link', { name: 'Link a tag' })).toHaveAttribute('href', '/dashboard/coa-nfc');
  await expect(page.getByText('AV000001')).toBeVisible();
  await expect(page.getByText('Linked', { exact: true })).toBeVisible();
  await expect(page.getByText('Not linked yet')).toBeVisible();
  await expect(page.getByText('You made this and still own it')).toBeVisible();
});

test('an aggregator sees their held pieces on Provenance, and the public view on Legacy', async ({ page, baseURL }) => {
  await stubMine(page, 200, { total: 1, items: [piece(1, { relations: ['holder'], holdingId: 'h1' })] });
  await open(page, 'aggregator', 'provenance', baseURL!);

  await expect(page.getByRole('heading', { name: 'Pieces you hold' })).toBeVisible();
  await expect(page.getByText('On display with you.')).toBeVisible();
  await expect(page.getByRole('link', { name: 'Open holding' })).toHaveAttribute('href', '/aggregator/collection/h1');

  await page.goto('/passport/legacy');
  await expect(page.getByRole('heading', { name: 'Pieces you hold' })).toHaveCount(0);
});

test('a signed-in cookie the API rejects falls back to the visitor view', async ({ page, baseURL }) => {
  await stubMine(page, 401, { type: 'about:blank', title: 'Invalid or expired ID token', status: 401, code: 'unauthorized' });
  await open(page, 'customer', 'identity', baseURL!);
  await expect(page.getByRole('heading', { name: 'What the passport shows' })).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Your pieces' })).toHaveCount(0);
  await expect(page.getByText("We couldn't load your pieces.")).toHaveCount(0);
});

test('empty and failed lists say what to do next', async ({ page, baseURL }) => {
  await stubMine(page, 200, { total: 0, items: [] });
  await open(page, 'customer', 'provenance', baseURL!);
  await expect(page.getByText("You don't own a piece yet.")).toBeVisible();
  await expect(page.getByRole('link', { name: 'Browse artworks' }).last()).toHaveAttribute('href', '/marketplace');

  await page.unroute('**/v1/passport/mine');
  await stubMine(page, 500, { type: 'about:blank', title: 'Server error', status: 500, code: 'internal' });
  await page.reload();
  await expect(page.getByRole('alert').filter({ hasText: "We couldn't load your pieces." })).toBeVisible({ timeout: 10_000 });
  await expect(page.getByRole('button', { name: 'Try again' })).toBeVisible();
});

test('the pieces list fits a phone screen for each topic', async ({ page, baseURL }) => {
  await page.setViewportSize({ width: 360, height: 800 });
  await stubMine(page, 200, { total: 4, items: [1, 2, 3, 4].map((n) => piece(n, { relations: ['artist', 'owner'], nfcLinked: false })) });
  await dismissCookieConsent(page);
  await signInAs(page.context(), 'artist', baseURL!);
  for (const topic of ['identity', 'certificate', 'provenance', 'legacy']) {
    await page.goto(`/passport/${topic}`);
    await expect(page.getByRole('heading', { name: 'Your works' })).toBeVisible();
    await assertNoHorizontalOverflow(page, `/passport/${topic} at 360px`);
  }
  await page.goto('/passport/certificate');
  await page.getByRole('heading', { name: 'Your works' }).scrollIntoViewIfNeeded();
  await page.screenshot({ path: 'test-results/passport-artist-mobile.png' });
});
