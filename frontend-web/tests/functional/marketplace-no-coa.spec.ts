import { test, expect, type Page } from '@playwright/test';
import { dismissCookieConsent } from '../support/settle';

// The marketplace doesn't show or send the COA. The public passport page is
// where the certificate lives, so it must still show it, now read from the
// passport instead of the marketplace listing. The API is stubbed.

const cors = { 'access-control-allow-origin': '*' };
const ok = (body: unknown) => ({ status: 200, contentType: 'application/json', headers: cors, body: JSON.stringify(body) });

// A marketplace listing as the API now sends it: no certificate fields.
const listing = {
  id: 'a1', productCode: 'GZ000001', artistId: 'art1', artistName: 'Devika Rao', title: 'Monsoon Light', description: 'Oil on canvas.',
  category: 'Painting', medium: 'Oil', dimensions: '24x36 in', yearCreated: 2025, images: [], displayPricePaise: 4_500_000,
  insured: true, status: 'marketplace', listingType: 'marketplace_only', rarityType: null, createdAt: '2026-01-01T00:00:00.000Z',
  artistLocation: 'Hyderabad', sizeBand: 'medium',
};
const passport = {
  artworkId: 'a1', productCode: 'GZ000001', title: 'Monsoon Light', artistId: 'art1', artistName: 'Devika Rao', category: 'Painting',
  medium: 'Oil', dimensions: '24x36 in', yearCreated: 2025, images: [], status: 'marketplace',
  coaCertificateNumber: 'GZ-COA-2026-0001', coaIssuedAt: '2026-02-01T00:00:00.000Z', listedAt: '2026-01-05T00:00:00.000Z',
  owner: { kind: 'artist', displayName: 'Devika Rao' }, events: [],
};

// `listed` is what the list route returns. The second test passes an older API's
// listing, which still carries the certificate: the page must ignore it.
async function stub(page: Page, listed: object = listing) {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await page.route(/\/v1\/artworks(\?|$)/, (route) =>
    route.fulfill(ok({
      artworks: [listed], total: 1, page: 1, pageSize: 20,
      facets: { categories: ['Painting'], mediums: ['Oil'], rarities: [], rarityCounts: {}, locations: ['Hyderabad'], artists: [{ id: 'art1', name: 'Devika Rao' }], priceRangePaise: { min: 4_500_000, max: 4_500_000 } },
    })),
  );
  await page.route(/\/v1\/artworks\/a1$/, (route) => route.fulfill(ok(listing)));
  await page.route(/\/v1\/verify\/a1$/, (route) => route.fulfill(ok(passport)));
}

test('marketplace cards and the passport band show no COA, even if the API sends one', async ({ page }) => {
  await stub(page, { ...listing, coaCertificateNumber: 'GZ-COA-2026-0001', coaIssuedAt: '2026-02-01T00:00:00.000Z' });
  await page.goto('/marketplace');
  await expect(page.getByRole('heading', { name: 'Monsoon Light' }).first()).toBeVisible();
  await expect(page.getByText('Digital Passport').first()).toBeVisible();
  await expect(page.getByText('COA', { exact: true })).toHaveCount(0);
  await expect(page.getByText(/certificate/i)).toHaveCount(0);
});

test('the public passport still shows the certificate, read from the passport', async ({ page }) => {
  await stub(page);
  await page.goto('/verify/a1');
  await expect(page.getByText('GZ-COA-2026-0001')).toBeVisible();
  await expect(page.getByText('COA issued 1 February 2026')).toBeVisible();
  await expect(page.getByText('Pending issuance')).toHaveCount(0);
});
