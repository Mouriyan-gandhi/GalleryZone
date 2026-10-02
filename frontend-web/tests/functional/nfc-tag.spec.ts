import { test, expect, type Page } from '@playwright/test';
import { signInAs } from '../support/auth';
import { dismissCookieConsent } from '../support/settle';

// NFC tags (NFC_IMPLEMENTATION.md): what the artist's COA & NFC board shows for the three
// states, what the "Link NFC tag" dialog does with a real tag writer (a fake Web NFC reader is
// injected: Playwright's Chromium has none) and, above all, in what ORDER — the server is asked
// before the chip is touched — and what the public passport shows. The API is stubbed, so this
// covers the screens and the requests they make; the rules themselves are checked by
// backend/packages/db/src/nfc.check.ts.

const CORS = { 'access-control-allow-origin': '*' };
const UID_COLON = '04:A1:B2:C3:D4:E5:80';
const UID_PLAIN = '04a1b2c3d4e580';

async function json(page: Page, pattern: string, body: unknown, method?: string, status = 200) {
  await page.route(pattern, (route) => {
    if (method && route.request().method() !== method) return route.fallback();
    return route.fulfill({ status, contentType: 'application/json', headers: CORS, body: JSON.stringify(body) });
  });
}

const owned = (id: string, over: Record<string, unknown> = {}) => ({
  id, productCode: `GZ-${id}`, artistId: 'artist1', artistName: 'Meera Kulkarni', title: `Piece ${id}`, description: 'A piece.',
  category: 'Painting', medium: 'Oil on canvas', dimensions: '24 x 36 in', yearCreated: 2025,
  images: [{ id: 'i1', storagePath: 'x', url: '/artworks/framed-painting.png', thumbnailUrl: null, altText: null, sortOrder: 0 }],
  displayPricePaise: 13_650_000, insured: false, status: 'marketplace', listingType: 'marketplace_and_aggregator', rarityType: 'R',
  coaCertificateNumber: `GZ-COA-2026-000${id.replace(/\D/g, '') || 1}`, coaIssuedAt: '2026-03-14T00:00:00.000Z', createdAt: '2026-03-01T00:00:00.000Z',
  artistLocation: 'Pune, Maharashtra', sizeBand: 'medium', artistPricePaise: 10_000_000, artistNet: { marketplace: 9_900_000, aggregatorEstimate: 9_500_000 },
  statusHistory: [{ status: 'marketplace', changedAt: '2026-03-02T00:00:00.000Z', reason: null }], insuranceOpted: false, insuranceNumber: null,
  insuranceStatus: null, nfcTagUid: null, nfcLinkedAt: null, nfcLockedAt: null, artworkType: null, paintingStyle: null, physical: null,
  editableUntil: '2026-03-09T00:00:00.000Z', ...over,
});

const unlinked = owned('a1');
const linkedUnlocked = owned('a2', { nfcTagUid: UID_PLAIN, nfcLinkedAt: '2026-09-28T10:00:00.000Z' });
const locked = owned('a3', { nfcTagUid: '04ffeeddccbbaa', nfcLinkedAt: '2026-09-20T10:00:00.000Z', nfcLockedAt: '2026-09-20T10:05:00.000Z' });

async function openBoard(page: Page, baseURL: string, artworks: unknown[]) {
  // Anything not stubbed below fails fast instead of reaching a real API.
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await signInAs(page.context(), 'artist', baseURL);
  await json(page, '**/v1/auth/me', { uid: 'artist1', role: 'artist', status: 'active', name: 'Meera Kulkarni', email: 'meera@example.in', phone: null, roleGrants: [] });
  await json(page, '**/v1/artist/artworks', { artworks }, 'GET');
  await json(page, '**/v1/artist/coa/requests', []);
  await page.goto('/dashboard/coa-nfc');
}

test('the board shows three states, and flags what cannot ship', async ({ page, baseURL }) => {
  await openBoard(page, baseURL!, [unlinked, linkedUnlocked, locked]);

  await expect(page.getByText('Not yet tagged', { exact: true })).toBeVisible();
  await expect(page.getByText('Tag linked · unlocked', { exact: true })).toBeVisible();
  await expect(page.getByText('Tag locked', { exact: true })).toBeVisible();

  // Red "must lock" only on the linked-but-unlocked piece, and a banner that counts them.
  await expect(page.getByText('Must lock before shipping')).toHaveCount(1);
  await expect(page.locator('#nfc-must-lock-a2')).toBeVisible();
  await expect(page.locator('#nfc-lock-warning')).toContainText("1 piece has a tag that isn't locked");

  // Link on the untagged piece, replace on the unlocked one, nothing once it is locked for good.
  await expect(page.locator('#link-nfc-a1')).toHaveText(/Link Tag/);
  await expect(page.locator('#link-nfc-a2')).toHaveText(/Replace tag/);
  await expect(page.locator('#link-nfc-a3')).toHaveCount(0);
});

test('no warning when every linked tag is locked', async ({ page, baseURL }) => {
  await openBoard(page, baseURL!, [unlinked, locked]);
  await expect(page.getByText('Tag locked', { exact: true })).toBeVisible();
  await expect(page.locator('#nfc-lock-warning')).toHaveCount(0);
  await expect(page.getByText('Must lock before shipping')).toHaveCount(0);
});

test('a browser that cannot write tags is sent to the app, with no fake write', async ({ page, baseURL }) => {
  await openBoard(page, baseURL!, [unlinked]);
  await page.locator('#link-nfc-a1').click();
  await expect(page.locator('#nfc-dialog-use-app')).toBeVisible();
  await expect(page.locator('#nfc-dialog-write-btn')).toHaveCount(0);
  await expect(page.getByText('Simulate', { exact: false })).toHaveCount(0);
});

// A stand-in for Chrome's NDEFReader: scan() reports a tap, write() records what it was given.
async function fakeWebNfc(page: Page, serialNumber: string, events: string[]) {
  await page.exposeFunction('__record', (entry: string) => events.push(entry));
  await page.addInitScript((serial) => {
    class FakeNdefReader extends EventTarget {
      async scan() {
        setTimeout(() => {
          const reading = new Event('reading');
          Object.assign(reading, { serialNumber: serial });
          this.dispatchEvent(reading);
        }, 30);
      }
      async write(message: { records: { data: string }[] }) {
        await (window as unknown as { __record: (e: string) => Promise<void> }).__record(`write:${message.records[0]!.data}`);
      }
    }
    (window as unknown as { NDEFReader: unknown }).NDEFReader = FakeNdefReader;
  }, serialNumber);
}

test('Web NFC: the server is asked before the chip is written, and the link is recorded after', async ({ page, baseURL }) => {
  const events: string[] = [];
  const bodies: Record<string, unknown> = {};
  await fakeWebNfc(page, UID_COLON, events);
  await openBoard(page, baseURL!, [unlinked]);
  await page.route('**/v1/artist/artworks/a1/nfc/check', (route) => {
    events.push('check');
    bodies.check = route.request().postDataJSON();
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ artworkId: 'a1', intent: 'link', action: 'link' }) });
  });
  await page.route('**/v1/artist/artworks/a1/nfc/link', (route) => {
    if (route.request().method() !== 'POST') return route.fallback();
    events.push('link');
    bodies.link = route.request().postDataJSON();
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ artworkId: 'a1', nfcTagUid: UID_PLAIN, nfcLinkedAt: '2026-10-02T12:00:00.000Z', nfcLockedAt: null }) });
  });

  await page.locator('#link-nfc-a1').click();
  await expect(page.locator('#nfc-dialog-write-btn')).toBeVisible();
  await page.locator('#nfc-dialog-write-btn').click();

  // Success is the lock prompt, not "done".
  await expect(page.getByText('Not locked yet — must lock before shipping')).toBeVisible();
  await expect(page.locator('#nfc-dialog-open-app')).toBeVisible();

  // The order is the point: ask, then write, then record.
  expect(events[0]).toBe('check');
  expect(events[1]).toMatch(/^write:https?:\/\/.+\/verify\/a1$/);
  expect(events[2]).toBe('link');
  expect(events).toHaveLength(3);
  // The server normalises the UID, so the chip's own spelling is sent as it was read.
  expect(bodies.check).toEqual({ tagUid: UID_COLON, intent: 'link' });
  expect(bodies.link).toEqual({ tagUid: UID_COLON });
});

test('a chip that belongs to another piece is refused before anything is written', async ({ page, baseURL }) => {
  const events: string[] = [];
  await fakeWebNfc(page, UID_COLON, events);
  await openBoard(page, baseURL!, [unlinked]);
  await page.route('**/v1/artist/artworks/a1/nfc/check', (route) => {
    events.push('check');
    return route.fulfill({
      status: 409, contentType: 'application/json', headers: CORS,
      body: JSON.stringify({ type: 'about:blank', title: 'This chip is already linked to another artwork.', status: 409, code: 'tag_already_bound' }),
    });
  });
  await page.route('**/v1/artist/artworks/a1/nfc/link', (route) => {
    events.push('link');
    return route.fulfill({ status: 500, headers: CORS });
  });
  await page.route('**/v1/artist/artworks/a1/nfc/failure', (route) => {
    events.push('failure');
    return route.fulfill({ status: 204, headers: CORS });
  });

  await page.locator('#link-nfc-a1').click();
  await page.locator('#nfc-dialog-write-btn').click();

  await expect(page.getByText('This chip is already linked to another artwork.')).toBeVisible();
  // The chip was never touched and no link was recorded; the failure went to Sentry via the API.
  await expect.poll(() => events.includes('failure')).toBe(true);
  expect(events.filter((e) => e.startsWith('write'))).toEqual([]);
  expect(events).not.toContain('link');
  await expect(page.locator('#nfc-dialog-write-btn')).toBeEnabled();
});

test('a chip that is not an NTAG213 is refused without asking the server or writing', async ({ page, baseURL }) => {
  const events: string[] = [];
  await fakeWebNfc(page, '04:A1:B2:C3', events); // a 4-byte UID: some other kind of card
  await openBoard(page, baseURL!, [unlinked]);
  await page.route('**/v1/artist/artworks/a1/nfc/**', (route) => {
    events.push(`request:${new URL(route.request().url()).pathname.split('/').pop()}`);
    return route.fulfill({ status: 204, headers: CORS });
  });

  await page.locator('#link-nfc-a1').click();
  await page.locator('#nfc-dialog-write-btn').click();

  await expect(page.getByText("This isn't an NTAG213 chip. Please use a GalleryZone-supplied tag.")).toBeVisible();
  expect(events.filter((e) => e.startsWith('write') || e === 'request:check' || e === 'request:link')).toEqual([]);
});

// --- The public passport ----------------------------------------------------------------

const passport = (over: Record<string, unknown> = {}) => ({
  artworkId: 'p1', productCode: 'GZ000001', title: 'Study in Ochre', artistId: 'artist1', artistName: 'Meera Kulkarni', category: 'Painting',
  medium: 'Oil on canvas', dimensions: '24 x 36 in', yearCreated: 2025, images: [{ url: '/artworks/framed-painting.png', thumbnailUrl: null, altText: null, sortOrder: 0 }],
  status: 'sold', coaCertificateNumber: 'GZ-COA-2026-0001', coaIssuedAt: '2026-03-14T00:00:00.000Z', listedAt: '2026-03-02T00:00:00.000Z',
  owner: { kind: 'collector', displayName: 'Ravi K' }, events: [],
  nfcLinked: true, nfcLocked: true,
  lifecycle: [
    { id: 'created', kind: 'created', at: '2026-03-01T10:00:00.000Z', actor: { kind: 'artist', displayName: 'Meera Kulkarni' }, location: { city: 'Pune', state: 'Maharashtra', country: 'India' }, note: null },
    { id: 'approved', kind: 'approved', at: '2026-03-02T10:00:00.000Z', actor: { kind: 'platform', displayName: 'GalleryZone' }, location: null, note: null },
    { id: 'placed:h1', kind: 'placed_with_gallery', at: '2026-04-01T10:00:00.000Z', actor: { kind: 'gallery', displayName: 'Studio Eight' }, location: { city: 'Delhi', state: 'Delhi', country: 'India' }, note: 'Month 1 of the gallery cycle' },
    { id: 'sale:o1', kind: 'sold_marketplace', at: '2026-06-10T10:00:00.000Z', actor: { kind: 'collector', displayName: 'Ravi K' }, location: null, note: null },
    { id: 'delivered:ord1', kind: 'delivered', at: '2026-06-14T10:00:00.000Z', actor: { kind: 'platform', displayName: 'GalleryZone' }, location: null, note: null },
  ],
  ...over,
});

async function openPassport(page: Page, body: unknown) {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await json(page, '**/v1/verify/p1', body);
  await json(page, '**/v1/artworks/p1', {
    id: 'p1', productCode: 'GZ000001', artistId: 'artist1', artistName: 'Meera Kulkarni', title: 'Study in Ochre', description: 'A piece.', category: 'Painting',
    medium: 'Oil on canvas', dimensions: '24 x 36 in', yearCreated: 2025, images: [{ url: '/artworks/framed-painting.png', thumbnailUrl: null, altText: null, sortOrder: 0 }],
    displayPricePaise: 13_650_000, insured: false, status: 'sold', listingType: 'marketplace_and_aggregator', rarityType: 'R', createdAt: '2026-03-01T00:00:00.000Z',
    artistLocation: 'Pune, Maharashtra', sizeBand: 'medium',
  });
  await json(page, '**/v1/artists/artist1', { id: 'artist1', name: 'Meera Kulkarni', headline: null, bio: null, location: 'Pune, Maharashtra', profileImageUrl: null });
  await page.goto('/verify/p1');
}

test('a locked tag reads "Verified via NFC + locked", and the lifecycle shows places only for the artist and galleries', async ({ page }) => {
  await openPassport(page, passport());

  await expect(page.locator('#passport-nfc-chip')).toHaveText(/Verified via NFC \+ locked/);
  await expect(page.getByRole('status')).toContainText('Verified via NFC + locked');

  const timeline = page.getByRole('region', { name: 'Lifecycle' });
  await expect(timeline.getByText('Made by Meera Kulkarni')).toBeVisible();
  await expect(timeline.getByText('Pune, Maharashtra, India')).toBeVisible();
  await expect(timeline.getByText('On display at Studio Eight')).toBeVisible();
  await expect(timeline.getByText('Delhi, Delhi, India')).toBeVisible();
  await expect(timeline.getByText('Month 1 of the gallery cycle')).toBeVisible();
  await expect(timeline.getByText('Sold to Ravi K')).toBeVisible();
  await expect(timeline.getByText('Delivered to the new owner')).toBeVisible();

  // The collector's entries carry no place at all: two places in the whole timeline, both venues.
  await expect(timeline.locator('svg.lucide-map-pin')).toHaveCount(2);
  // The chip's own ID is nowhere on the page.
  await expect(page.locator('body')).not.toContainText(UID_PLAIN);
  await expect(page.locator('body')).not.toContainText(UID_COLON);
});

test('a linked but unlocked tag is not presented as sealed', async ({ page }) => {
  await openPassport(page, passport({ nfcLocked: false }));
  await expect(page.locator('#passport-nfc-chip')).toHaveText(/NFC tag linked · not yet locked/);
  await expect(page.getByRole('status')).toContainText('NFC tag linked — not yet locked');
  await expect(page.getByText('Verified via NFC + locked')).toHaveCount(0);
});

test('a piece with no tag shows no NFC badge', async ({ page }) => {
  await openPassport(page, passport({ nfcLinked: false, nfcLocked: false }));
  await expect(page.getByText('Artwork Passport', { exact: true })).toBeVisible();
  await expect(page.locator('#passport-nfc-chip')).toHaveCount(0);
  await expect(page.getByRole('status')).toHaveCount(0);
});
