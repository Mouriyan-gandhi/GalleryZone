import { test, expect, type Page } from '@playwright/test';
import { signInAs } from '../support/auth';
import { dismissCookieConsent } from '../support/settle';

// The gallery's side of the lock-before-shipping rule (NFC_IMPLEMENTATION.md §4.7, §5.2): a held
// piece whose tag isn't locked says so, and so does an outbound sale that can't be dispatched yet.
// The gallery is never shown the chip's ID. The API is stubbed.

const CORS = { 'access-control-allow-origin': '*' };
const DAY = 86_400_000;

async function json(page: Page, pattern: string, body: unknown, method?: string, status = 200) {
  await page.route(pattern, (route) => {
    if (method && route.request().method() !== method) return route.fallback();
    return route.fulfill({ status, contentType: 'application/json', headers: CORS, body: JSON.stringify(body) });
  });
}

const artworkDto = (over: Record<string, unknown> = {}) => ({
  id: 'a1', productCode: 'GZ-a1', artistId: 'artist1', artistName: 'Meera Kulkarni', title: 'Study in Ochre', description: 'A piece.',
  category: 'Painting', medium: 'Oil on canvas', dimensions: '24 x 36 in', yearCreated: 2025, images: [], displayPricePaise: 13_650_000,
  insured: false, status: 'with_aggregator', listingType: 'marketplace_and_aggregator', rarityType: 'R', createdAt: '2026-09-01T00:00:00.000Z',
  artistLocation: 'Pune', sizeBand: 'medium', nfcLinkedAt: null, nfcLockedAt: null, ...over,
});

const holding = (artwork: Record<string, unknown>) => ({
  id: 'h1', artworkId: 'a1', artwork, cycleMonth: 1, advancePercent: 5, advancePaise: 650_000, deliveryDepositPaise: 250_000, displayPricePaise: 13_650_000,
  assignmentSource: 'self_reserved', assignedAt: new Date(Date.now() - 5 * DAY).toISOString(), expiresAt: new Date(Date.now() + 25 * DAY).toISOString(),
  windowExtended: false, status: 'reserved', returnedAt: null, appreciated: false, priceWarning: false, extensionRequest: null,
});

async function openAggregator(page: Page, baseURL: string) {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await signInAs(page.context(), 'aggregator', baseURL);
  await json(page, '**/v1/auth/me', { uid: 'agg1', role: 'aggregator', status: 'active', name: 'Anand Rao', email: 'anand@example.in', phone: null, roleGrants: [] });
  await json(page, '**/v1/aggregator/inventory', { artworks: [] });
}

test('a held piece with an unlocked tag carries a red banner, with no chip ID', async ({ page, baseURL }) => {
  await openAggregator(page, baseURL!);
  await json(page, '**/v1/aggregator/holdings/h1', holding(artworkDto({ nfcLinkedAt: '2026-09-28T10:00:00.000Z' })));
  await page.goto('/aggregator/collection/h1');

  const banner = page.locator('#holding-nfc-banner');
  await expect(banner).toContainText('This piece’s NFC tag is not locked');
  await expect(banner).toContainText('Lock it in the GalleryZone app before you put it on display or ship it');
  await expect(banner.getByRole('link', { name: 'Open in the app' })).toHaveAttribute('href', /\/verify\/a1$/);
  await expect(page.locator('body')).not.toContainText('04a1b2c3d4e580');
});

test('a piece with no tag at all is told to get one linked and locked', async ({ page, baseURL }) => {
  await openAggregator(page, baseURL!);
  await json(page, '**/v1/aggregator/holdings/h1', holding(artworkDto()));
  await page.goto('/aggregator/collection/h1');
  await expect(page.locator('#holding-nfc-banner')).toContainText('No tag is linked to it yet');
});

test('a locked piece has no banner', async ({ page, baseURL }) => {
  await openAggregator(page, baseURL!);
  await json(page, '**/v1/aggregator/holdings/h1', holding(artworkDto({ nfcLinkedAt: '2026-09-28T10:00:00.000Z', nfcLockedAt: '2026-09-28T10:05:00.000Z' })));
  await page.goto('/aggregator/collection/h1');
  await expect(page.getByText('Study in Ochre').first()).toBeVisible();
  await expect(page.locator('#holding-nfc-banner')).toHaveCount(0);
});

const sale = (id: string, over: Record<string, unknown> = {}) => ({
  id, holdingId: 'h1', artworkId: 'a1', soldPricePaise: 13_650_000, buyerName: `Buyer ${id}`, buyerEmail: 'b@example.in', buyerPhone: null,
  deliveryAddress: null, deliveryMode: 'courier', paymentRoute: 'direct_to_galleryzone', remittedAt: null, shipmentStatus: 'preparing',
  dispatchedAt: null, deliveredAt: null, courierRef: null, soldAt: '2026-09-29T10:00:00.000Z', nfcLocked: true, nfcGateOverridden: false, ...over,
});

test('an outbound sale whose tag is unlocked says so, and a refused dispatch explains itself', async ({ page, baseURL }) => {
  await openAggregator(page, baseURL!);
  await json(page, '**/v1/aggregator/holdings', { holdings: [] }, 'GET');
  let calls = 0;
  await page.route('**/v1/aggregator/sales', (route) => {
    calls += 1;
    return route.fulfill({
      status: 200, contentType: 'application/json', headers: CORS,
      body: JSON.stringify([sale('s1', { nfcLocked: false }), sale('s2'), sale('s3', { nfcLocked: false, nfcGateOverridden: true })]),
    });
  });
  let shipmentBody: unknown;
  await page.route('**/v1/aggregator/sales/s1/shipment', (route) => {
    shipmentBody = route.request().postDataJSON();
    return route.fulfill({
      status: 409, contentType: 'application/json', headers: CORS,
      body: JSON.stringify({ type: 'about:blank', title: "This artwork's NFC tag must be locked before it can be dispatched. Lock it in the GalleryZone app, then try again.", status: 409, code: 'nfc_lock_required' }),
    });
  });
  await page.goto('/aggregator/shipping');

  const table = page.getByRole('table');
  await expect(table.getByText('Buyer s1')).toBeVisible();
  // Only the sale that would be refused carries the chip: locked, and allowed-through, do not.
  await expect(table.getByText('Unlocked — lock the tag first')).toHaveCount(1);
  await expect(table.getByRole('row', { name: /Buyer s1/ }).getByText('Unlocked — lock the tag first')).toBeVisible();

  await table.getByRole('row', { name: /Buyer s1/ }).getByRole('button', { name: 'Mark dispatched' }).click();
  await expect(page.getByText('NFC tag must be locked before it can be dispatched')).toBeVisible();
  expect(calls).toBeGreaterThan(0);
  // Only what the API's strict schema takes: the sale id travels in the path, not the body.
  expect(shipmentBody).toEqual({ to: 'dispatched' });
});
