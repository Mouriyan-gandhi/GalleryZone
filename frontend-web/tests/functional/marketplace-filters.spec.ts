import { test, expect, type Page } from '@playwright/test';
import { dismissCookieConsent } from '../support/settle';

// The marketplace filter sidebar and search. Filtering, search and paging all
// happen on the API (GET /v1/artworks), so the API is stubbed here with the same
// contract: `category` (comma-separated) and `q` narrow the list. What this
// pins is the page's side of it: choosing a filter or typing a search sends the
// right request and the grid shows the answer, and Reset Filters brings the full
// list back. There is no demo catalogue to lean on any more.

const cors = { 'access-control-allow-origin': '*' };
const ok = (body: unknown) => ({ status: 200, contentType: 'application/json', headers: cors, body: JSON.stringify(body) });

const piece = (id: string, title: string, artistName: string, category: string) => ({
  id, productCode: `GZ${id}`, artistId: `art-${id}`, artistName, title, description: '', category, medium: 'Mixed', dimensions: null,
  yearCreated: 2025, images: [], displayPricePaise: 2_500_000, insured: false, status: 'marketplace', listingType: 'marketplace_only',
  rarityType: null, createdAt: '2026-01-01T00:00:00.000Z', artistLocation: 'Pune', sizeBand: 'medium',
});
const PIECES = [
  piece('001', 'Monsoon Light', 'Devika Rao', 'painting'),
  piece('002', 'Bronze Bull', 'Ravi Menon', 'sculpture'),
  piece('003', 'Monsoon Study', 'Meera Rathore', 'painting'),
];

async function stubListing(page: Page) {
  await page.route('**/v1/**', (route) => route.abort());
  await page.route(/\/v1\/artworks(\?|$)/, (route) => {
    const params = new URL(route.request().url()).searchParams;
    const categories = params.get('category')?.split(',');
    const q = params.get('q')?.toLowerCase();
    const artworks = PIECES.filter(
      (a) => (!categories || categories.includes(a.category)) && (!q || `${a.title} ${a.artistName}`.toLowerCase().includes(q)),
    );
    return route.fulfill(ok({
      artworks, total: artworks.length, page: 1, pageSize: 20,
      facets: {
        categories: ['painting', 'sculpture'], mediums: ['Mixed'], rarities: [], rarityCounts: {}, locations: ['Pune'],
        artists: PIECES.map((a) => ({ id: a.artistId, name: a.artistName })), priceRangePaise: { min: 2_500_000, max: 2_500_000 },
      },
    }));
  });
}

/** The distinct artwork pages the grid links to. */
async function listed(page: Page): Promise<string[]> {
  const hrefs = await page.locator('a[href^="/marketplace/"]').evaluateAll((els) => els.map((el) => el.getAttribute('href') ?? ''));
  return [...new Set(hrefs.filter((h) => h !== '/marketplace/' && h !== '/marketplace'))].sort();
}

test('the Category filter narrows the grid, and clearing it restores the full list', async ({ page }) => {
  await stubListing(page);
  await dismissCookieConsent(page);
  await page.goto('/marketplace');

  await expect.poll(async () => (await listed(page)).length).toBe(3);

  const sculpture = page.getByRole('region', { name: 'Category' }).getByText('Sculpture', { exact: true });
  await sculpture.click();
  await expect.poll(() => listed(page)).toEqual(['/marketplace/002']);

  await sculpture.click();
  await expect.poll(async () => (await listed(page)).length).toBe(3);
});

test('search narrows results to actual title/artist matches', async ({ page }) => {
  await stubListing(page);
  await dismissCookieConsent(page);
  await page.goto('/marketplace');

  const search = page.getByPlaceholder(/Search artworks/);

  await search.fill('Monsoon');
  await expect.poll(() => listed(page)).toEqual(['/marketplace/001', '/marketplace/003']);
  await expect(page.getByText('Monsoon Light').first()).toBeVisible();
  await expect(page.getByText('Monsoon Study').first()).toBeVisible();

  await search.fill('zzz-no-such-artwork-zzz');
  await expect.poll(() => listed(page)).toEqual([]);
});
