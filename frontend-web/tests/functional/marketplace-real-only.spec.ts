import { test, expect } from '@playwright/test';
import { dismissCookieConsent } from '../support/settle';

// The marketplace shows only what the API returns. There used to be a local
// preview switch (NEXT_PUBLIC_DEMO_ARTWORKS=true) that mixed invented paintings
// and artists into the grid; it is gone, so the switch being set changes nothing.
// The API is stubbed.

const cors = { 'access-control-allow-origin': '*' };
const ok = (body: unknown) => ({ status: 200, contentType: 'application/json', headers: cors, body: JSON.stringify(body) });

const listing = {
  id: 'real-1', productCode: 'GZ000001', artistId: 'art1', artistName: 'Devika Rao', title: 'Monsoon Light', description: 'Oil on canvas.',
  category: 'Painting', medium: 'Oil', dimensions: '24x36 in', yearCreated: 2025, images: [], displayPricePaise: 4_500_000,
  insured: false, status: 'marketplace', listingType: 'marketplace_only', rarityType: null, createdAt: '2026-01-01T00:00:00.000Z',
  artistLocation: 'Hyderabad', sizeBand: 'medium',
};

test('the marketplace grid holds only the listings the API sent', async ({ page }) => {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await page.route(/\/v1\/artworks(\?|$)/, (route) =>
    route.fulfill(ok({
      artworks: [listing], total: 1, page: 1, pageSize: 20,
      facets: { categories: ['Painting'], mediums: ['Oil'], rarities: [], rarityCounts: {}, locations: ['Hyderabad'], artists: [{ id: 'art1', name: 'Devika Rao' }], priceRangePaise: { min: 4_500_000, max: 4_500_000 } },
    })),
  );
  await page.goto('/marketplace');
  await expect(page.getByRole('heading', { name: 'Monsoon Light' }).first()).toBeVisible();

  const hrefs = await page.locator('a[href^="/marketplace/"]').evaluateAll((els) => els.map((el) => el.getAttribute('href')));
  expect(hrefs.length).toBeGreaterThan(0);
  expect(hrefs.filter((h) => h && h.startsWith('/marketplace/demo-'))).toEqual([]);
  expect(new Set(hrefs.filter((h) => h && h !== '/marketplace/')).size).toBeLessThanOrEqual(1);

  const text = await page.locator('body').innerText();
  for (const invented of ['Kabir Shekhawat', 'Rohan Bhatt', 'Sanjukta Mohapatra', 'Anaya Iyer']) {
    expect(text).not.toContain(invented);
  }
});

test('the aggregator analytics page draws no invented trend', async ({ page, baseURL }) => {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await page.context().addCookies([{ name: 'gz_session', value: 'aggregator', domain: new URL(baseURL!).hostname, path: '/' }]);
  await page.route('**/v1/auth/me', (route) =>
    route.fulfill(ok({ uid: 'u2', role: 'aggregator', status: 'active', name: 'Anand Rao', email: 'a@example.in', phone: null, roleGrants: [] })),
  );
  await page.goto('/aggregator/analytics');
  await expect(page.getByText('Sales recorded')).toBeVisible();
  await expect(page.getByText('Sell-through rate')).toHaveCount(0);
  await expect(page.getByText(/Demonstration trend/)).toHaveCount(0);
});
