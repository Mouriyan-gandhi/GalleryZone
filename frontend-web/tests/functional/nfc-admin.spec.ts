import { test, expect, type Page } from '@playwright/test';
import { signInAs } from '../support/auth';
import { dismissCookieConsent } from '../support/settle';

// The admin's side of NFC tags (NFC_IMPLEMENTATION.md §4.3, §4.4, §5.3, §13): one piece's tag
// pane (unlink before the lock, allow shipping unlocked, chase the artist), the red "Unlocked"
// chip in the orders queue, and the catalogue-wide overview. The API is stubbed.

const CORS = { 'access-control-allow-origin': '*' };

async function json(page: Page, pattern: string, body: unknown, method?: string, status = 200) {
  await page.route(pattern, (route) => {
    if (method && route.request().method() !== method) return route.fallback();
    return route.fulfill({ status, contentType: 'application/json', headers: CORS, body: JSON.stringify(body) });
  });
}

const adminArtwork = (over: Record<string, unknown> = {}) => ({
  id: 'a2', productCode: 'GZ-a2', artistId: 'artist1', artistName: 'Meera Kulkarni', title: 'Study in Ochre', description: 'A piece.',
  category: 'painting', medium: 'Oil on canvas', dimensions: '24 x 36 in', yearCreated: 2025,
  images: [{ id: 'i1', storagePath: 'x', url: '/artworks/framed-painting.png', thumbnailUrl: null, altText: null, sortOrder: 0 }],
  displayPricePaise: 13_650_000, insured: false, status: 'marketplace', listingType: 'marketplace_and_aggregator', rarityType: 'R',
  coaCertificateNumber: 'GZ-COA-2026-0002', coaIssuedAt: '2026-03-14T00:00:00.000Z', createdAt: '2026-03-01T00:00:00.000Z',
  artistLocation: 'Pune, Maharashtra', sizeBand: 'medium', artistPricePaise: 10_000_000, artistNet: { marketplace: 9_900_000, aggregatorEstimate: 9_500_000 },
  statusHistory: [{ status: 'marketplace', changedAt: '2026-03-02T00:00:00.000Z', reason: null }], insuranceOpted: false, insuranceNumber: null,
  insuranceStatus: null, nfcTagUid: '04a1b2c3d4e580', nfcLinkedAt: '2026-09-28T10:00:00.000Z', nfcLockedAt: null, artworkType: null, paintingStyle: null,
  physical: null, editableUntil: '2026-03-09T00:00:00.000Z', artistEmail: 'meera@example.in',
  nfcShipmentGateOverrideAt: null, nfcShipmentGateOverrideReason: null, nfcShipmentGateOverrideBy: null, ...over,
});

async function openAdmin(page: Page, baseURL: string) {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await signInAs(page.context(), 'admin', baseURL);
  await json(page, '**/v1/auth/me', { uid: 'admin1', role: 'admin', status: 'active', name: 'Admin', email: 'admin@example.in', phone: null, roleGrants: [] });
}

async function openArtwork(page: Page, baseURL: string, artwork: unknown) {
  await openAdmin(page, baseURL);
  await json(page, '**/v1/admin/artworks/a2', artwork);
  await json(page, '**/v1/admin/artworks/a2/holding', { holding: null });
  await page.goto('/admin/artworks/a2');
}

test('an unlocked tag shows its state, and an admin can unlink it with a reason', async ({ page, baseURL }) => {
  await openArtwork(page, baseURL!, adminArtwork());
  const panel = page.locator('#admin-nfc-panel');

  await expect(panel).toContainText('Unlocked');
  await expect(panel).toContainText('04a1b2c3d4e580'); // admins see the chip ID; the public never does
  await expect(panel.getByRole('button', { name: 'Unlink tag' })).toBeVisible();

  let sent: unknown;
  await page.route('**/v1/admin/artworks/a2/nfc/unlink', (route) => {
    sent = route.request().postDataJSON();
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ artworkId: 'a2', nfcTagUid: null, nfcLinkedAt: null, nfcLockedAt: null }) });
  });
  await panel.getByRole('button', { name: 'Unlink tag' }).click();
  const dialog = page.getByRole('dialog');
  // A reason is compulsory: an empty one is refused on the form, before any request.
  await dialog.getByRole('button', { name: 'Unlink tag' }).click();
  await expect(dialog.getByText('Give a reason the recipient can act on')).toBeVisible();
  expect(sent).toBeUndefined();

  await dialog.getByLabel('Why is it being unlinked?').fill('artist reported chip failed to lock');
  await dialog.getByRole('button', { name: 'Unlink tag' }).click();
  await expect.poll(() => sent).toEqual({ reason: 'artist reported chip failed to lock' });
});

test('a locked tag offers no unlink and no override', async ({ page, baseURL }) => {
  await openArtwork(page, baseURL!, adminArtwork({ nfcLockedAt: '2026-09-28T10:05:00.000Z' }));
  const panel = page.locator('#admin-nfc-panel');
  await expect(panel).toContainText('Tag locked');
  await expect(panel.getByRole('button', { name: 'Unlink tag' })).toHaveCount(0);
  await expect(panel.getByRole('button', { name: 'Allow shipping unlocked' })).toHaveCount(0);
  await expect(panel.getByRole('button', { name: 'Email the artist' })).toHaveCount(0);
});

test('allowing a piece to ship unlocked needs a reason, and is shown afterwards', async ({ page, baseURL }) => {
  await openArtwork(page, baseURL!, adminArtwork());
  const panel = page.locator('#admin-nfc-panel');
  let sent: unknown;
  await page.route('**/v1/admin/artworks/a2/nfc/skip-shipment-gate', (route) => {
    sent = route.request().postDataJSON();
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ artworkId: 'a2', nfcShipmentGateOverrideAt: '2026-10-02T10:00:00.000Z', nfcShipmentGateOverrideReason: 'x' }) });
  });
  await panel.getByRole('button', { name: 'Allow shipping unlocked' }).click();
  const dialog = page.getByRole('dialog');
  await dialog.getByLabel('Why may it ship unlocked?').fill('shipped before the lock requirement');
  await dialog.getByRole('button', { name: 'Allow shipping' }).click();
  await expect.poll(() => sent).toEqual({ reason: 'shipped before the lock requirement' });
});

test('an override already in place is shown with its reason', async ({ page, baseURL }) => {
  await openArtwork(page, baseURL!, adminArtwork({ nfcShipmentGateOverrideAt: '2026-10-01T10:00:00.000Z', nfcShipmentGateOverrideReason: 'shipped before the lock requirement' }));
  await expect(page.locator('#admin-nfc-override')).toContainText('shipped before the lock requirement');
  await expect(page.locator('#admin-nfc-panel').getByRole('button', { name: 'Allow shipping unlocked' })).toHaveCount(0);
});

test('the artist can be chased by email from the artwork', async ({ page, baseURL }) => {
  await openArtwork(page, baseURL!, adminArtwork());
  let asked = false;
  await page.route('**/v1/admin/artworks/a2/nfc/remind', (route) => {
    asked = true;
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ sent: true }) });
  });
  await page.locator('#admin-nfc-panel').getByRole('button', { name: 'Email the artist' }).click();
  await expect.poll(() => asked).toBe(true);
  await expect(page.getByText('The artist has been emailed')).toBeVisible();
});

// --- Orders queue ---------------------------------------------------------------------

const order = (id: string, status: string, nfc: unknown) => ({
  id, artworkId: id === 'o1' ? 'a1' : 'a2', customerId: 'c1', addressId: 'ad1', displayPricePaise: 13_650_000, gstPaise: 0, deliveryChargePaise: 250_000,
  convenienceFeePaise: 0, totalPaise: 13_900_000, status, rateConfigVersionId: 'v1', createdAt: '2026-09-20T10:00:00.000Z',
  payment: null, statusHistory: [], artwork: { title: `Piece for ${id}`, artistName: 'Meera Kulkarni', artistId: 'artist1', thumbnailUrl: null, productCode: 'GZ-1' }, nfc,
});

test('the orders queue flags a dispatch the tag would stop', async ({ page, baseURL }) => {
  await openAdmin(page, baseURL!);
  await json(page, '**/v1/admin/orders', [
    order('o1', 'packed', { linked: true, locked: false, gateOverridden: false }), // blocked
    order('o2', 'packed', { linked: true, locked: true, gateOverridden: false }), // fine
    order('o3', 'packed', { linked: true, locked: false, gateOverridden: true }), // allowed through
    order('o4', 'delivered', { linked: false, locked: false, gateOverridden: false }), // already shipped
  ]);
  await page.goto('/admin/orders');
  // The table also renders as a list on small screens; the table is the one under test.
  const table = page.getByRole('table');
  await expect(table.getByText('Piece for o1')).toBeVisible();
  await expect(table.getByText('Unlocked', { exact: true })).toHaveCount(1);
  await expect(table.getByRole('row', { name: /Piece for o1/ }).getByText('Unlocked')).toBeVisible();
  await expect(table.getByRole('row', { name: /Piece for o2/ }).getByText('Unlocked')).toHaveCount(0);
  await expect(table.getByRole('row', { name: /Piece for o3/ }).getByText('Unlocked')).toHaveCount(0);
  await expect(table.getByRole('row', { name: /Piece for o4/ }).getByText('Unlocked')).toHaveCount(0);
});

// --- Overview -------------------------------------------------------------------------

test('the NFC overview counts the catalogue and lists what still needs locking', async ({ page, baseURL }) => {
  await openAdmin(page, baseURL!);
  await json(page, '**/v1/admin/nfc/overview', {
    gateEnforced: false,
    counts: { total: 40, unlinked: 25, linkedUnlocked: 4, locked: 11, gateOverridden: 2 },
    awaitingLock: [{ artworkId: 'a2', title: 'Study in Ochre', artistId: 'artist1', linkedAt: '2026-09-28T10:00:00.000Z' }],
    recent: [
      { id: 'e1', action: 'nfc.tag_replaced', artworkId: 'a2', title: 'Study in Ochre', actorId: 'artist1', at: '2026-09-29T10:00:00.000Z', detail: {} },
      { id: 'e2', action: 'nfc.shipment_gate_overridden', artworkId: 'a9', title: 'Dusk', actorId: 'admin1', at: '2026-09-30T10:00:00.000Z', detail: {} },
    ],
  });
  await page.goto('/admin/nfc');

  await expect(page.locator('#nfc-gate-state')).toContainText('warn-only');
  await expect(page.getByText('Linked, unlocked', { exact: true })).toBeVisible();
  await expect(page.getByRole('link', { name: /Study in Ochre.*linked/ })).toHaveAttribute('href', '/admin/artworks/a2');
  await expect(page.getByText('Tag replaced')).toBeVisible();
  await expect(page.getByText('Shipping allowed unlocked')).toBeVisible();
});

test('the pricing rules editor can turn the dispatch gate on', async ({ page, baseURL }) => {
  await openAdmin(page, baseURL!);
  await json(page, '**/v1/auth/me', { uid: 'admin1', role: 'admin', status: 'active', name: 'Admin', email: 'admin@example.in', phone: null, roleGrants: ['platform_admin'] });
  const rates = { nfcShipmentGateEnforced: false, platformMarkup: 0.3 };
  await json(page, '**/v1/admin/rate-config', { rates });
  await json(page, '**/v1/admin/rate-config/versions', { versions: [] });
  await json(page, '**/v1/admin/rate-config/defaults', { rates });
  let proposed: { rates: Record<string, unknown>; reason: string } | undefined;
  await page.route('**/v1/admin/rate-config/propose', (route) => {
    proposed = route.request().postDataJSON();
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ versionId: 'v2', status: 'pending_approval' }) });
  });
  await page.goto('/admin/settings');

  await page.getByRole('button', { name: /Propose a change/ }).click();
  // A real toggle in its own group, not a read-only line under "Other".
  await expect(page.getByText('Require a locked NFC tag to dispatch')).toBeVisible();
  const toggle = page.getByRole('checkbox');
  await expect(toggle).not.toBeChecked();
  await toggle.check();
  await expect(page.getByText('Enforced — an unlocked dispatch is refused')).toBeVisible();

  await page.getByLabel(/Why this change/).fill('every linked tag is locked or allowed');
  await page.getByRole('button', { name: /Propose 1 change/ }).click();
  await expect.poll(() => proposed?.rates.nfcShipmentGateEnforced).toBe(true);
  expect(proposed?.rates.platformMarkup).toBe(0.3);
});
