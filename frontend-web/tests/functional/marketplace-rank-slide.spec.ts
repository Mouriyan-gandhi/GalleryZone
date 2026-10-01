import { test, expect, type Page } from '@playwright/test';
import { dismissCookieConsent } from '../support/settle';

// The "Every painting has a rank" slide in the marketplace slideshow. A rank
// with no works is still part of the guide: it stays at full strength and says
// "None yet" instead of being greyed out, and only a rank with works is a
// control that filters the grid. The API is stubbed.

const cors = { 'access-control-allow-origin': '*' };
const ok = (body: unknown) => ({ status: 200, contentType: 'application/json', headers: cors, body: JSON.stringify(body) });

const piece = {
  id: 'p1', productCode: 'GZ000001', artistId: 'a1', artistName: 'Devika Rao', title: 'Monsoon Light', description: '', category: 'painting',
  medium: 'oil', dimensions: null, yearCreated: 2025, images: [], displayPricePaise: 4_500_000, insured: false, status: 'marketplace',
  listingType: 'marketplace_only', rarityType: null, createdAt: '2026-01-01T00:00:00.000Z', artistLocation: 'Pune', sizeBand: 'medium',
};

async function openRanks(page: Page, rarityCounts: Record<string, number>, requests: string[] = []) {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await page.route(/\/v1\/artworks(\?|$)/, (route) => {
    requests.push(route.request().url());
    return route.fulfill(ok({
      artworks: [piece], total: 1, page: 1, pageSize: 20,
      facets: { categories: ['painting'], mediums: ['oil'], rarities: Object.keys(rarityCounts), rarityCounts, locations: ['Pune'], artists: [{ id: 'a1', name: 'Devika Rao' }], priceRangePaise: { min: 4_500_000, max: 4_500_000 } },
    }));
  });
  await page.goto('/marketplace');
  await page.getByRole('button', { name: /Ranks$/ }).click();
}

test('ranks with no works stay at full strength and say "None yet"', async ({ page }) => {
  await openRanks(page, {});
  const slide = page.getByRole('group', { name: /Ranks$/ });
  await expect(slide.getByText('None yet')).toHaveCount(4);
  await expect(slide.getByRole('button')).toHaveCount(0);
  for (const name of ['Rare', 'Unique', 'Original', 'Standard']) {
    const card = slide.getByText(name, { exact: true }).locator('xpath=ancestor::div[contains(@class,"rounded-xl")][1]');
    await expect(card).toBeVisible();
    expect(await card.evaluate((el) => getComputedStyle(el).opacity)).toBe('1');
  }
});

test('a rank with works is a control that filters the grid to that rank', async ({ page }) => {
  const requests: string[] = [];
  await openRanks(page, { R: 2, U: 1 }, requests);
  const slide = page.getByRole('group', { name: /Ranks$/ });
  await expect(slide.getByText('2 works')).toBeVisible();
  await expect(slide.getByText('1 work', { exact: true })).toBeVisible();
  await expect(slide.getByText('None yet')).toHaveCount(2);
  await expect(slide.getByRole('button')).toHaveCount(2);

  await slide.getByRole('button', { name: /Rare/ }).click();
  await expect.poll(() => requests.some((u) => new URL(u).searchParams.get('rarity') === 'R')).toBe(true);
});
