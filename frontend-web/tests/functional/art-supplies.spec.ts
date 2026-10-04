import { test, expect, type Page } from '@playwright/test';
import { signInAs } from '../support/auth';
import { dismissCookieConsent } from '../support/settle';

// The Art supplies shelf: Amazon products an admin keeps, earning GalleryZone a
// commission. The API and Amazon's image CDN are stubbed; nothing leaves the machine.

const PNG = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==', 'base64');
const CORS = { 'access-control-allow-origin': '*' };

const product = (n: number, over: Record<string, unknown> = {}) => ({
  id: `B00000000${n}`, asin: `B00000000${n}`, url: `https://link.amazon/B00000000${n}`,
  title: `Product ${n} for artists`, brand: `Brand${n}`, category: 'Easels',
  images: [1, 2].map((i) => `https://m.media-amazon.com/images/I/p${n}i${i}._SL1500_.jpg`),
  active: true, createdAt: '2026-10-02T00:00:00.000Z', updatedAt: '2026-10-02T00:00:00.000Z', ...over,
});
const SHELF = [
  product(1, { title: 'Brustro Tabletop Easel', brand: 'BRUSTRO' }),
  product(2, { title: 'Grandink H Frame Easel', brand: 'Grandink' }),
  product(3, { title: 'Mont Marte Acrylic Set 24 Colours', brand: 'Mont Marte', category: 'Paints' }),
  product(4, { title: 'ARTIOS Liner Brush Set', brand: 'ARTIOS', category: 'Brushes' }),
];

async function stubAmazonImages(page: Page) {
  await page.route('https://m.media-amazon.com/**', (route) => route.fulfill({ status: 200, contentType: 'image/png', body: PNG }));
}

async function openShelf(page: Page, products: unknown[] = SHELF) {
  await page.route('**/v1/**', (route) => route.abort());
  await stubAmazonImages(page);
  await page.route('**/v1/affiliate-products', (route) =>
    route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ products }) }),
  );
  await dismissCookieConsent(page);
  await page.goto('/art-supplies');
}

test('the shelf lists every product, with category pills that count and filter', async ({ page }) => {
  await openShelf(page);
  await expect(page.getByRole('heading', { name: 'Art supplies we recommend' })).toBeVisible();
  await expect(page.getByText('4 products')).toBeVisible();
  await expect(page.getByRole('button', { name: /^Easels\s*2$/ })).toBeVisible();

  await page.getByRole('button', { name: /^Paints\s*1$/ }).click();
  await expect(page.getByText('1 of 4 products')).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Mont Marte Acrylic Set 24 Colours' })).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Brustro Tabletop Easel' })).toHaveCount(0);

  await page.getByRole('button', { name: /^Paints/ }).click(); // pressing the active pill clears it
  await expect(page.getByText('4 products')).toBeVisible();
});

test('search matches title, brand and category, every word, and recovers from no match', async ({ page }) => {
  await openShelf(page);
  const search = page.getByRole('searchbox', { name: 'Search art supplies' });

  await search.fill('mont acrylic');
  await expect(page.getByText('1 of 4 products')).toBeVisible();
  await search.fill('grandink easel');
  await expect(page.getByRole('heading', { name: 'Grandink H Frame Easel' })).toBeVisible();
  await search.fill('brushes'); // matches the category, not the title
  await expect(page.getByRole('heading', { name: 'ARTIOS Liner Brush Set' })).toBeVisible();

  await search.fill('zzzz');
  await expect(page.getByText('Nothing matches that')).toBeVisible();
  await page.getByRole('button', { name: 'Show everything' }).click();
  await expect(page.getByText('4 products')).toBeVisible();
  await expect(search).toHaveValue('');
});

test('every Amazon link is the affiliate link, opens in a new tab, and is marked sponsored', async ({ page }) => {
  await openShelf(page);
  const links = page.getByRole('link', { name: 'View on Amazon' });
  await expect(links).toHaveCount(4);
  for (const [i, p] of SHELF.entries()) {
    const link = links.nth(i);
    await expect(link).toHaveAttribute('href', p.url);
    await expect(link).toHaveAttribute('target', '_blank');
    await expect(link).toHaveAttribute('rel', /sponsored/);
    await expect(link).toHaveAttribute('rel', /noopener/);
  }
  await expect(page.getByText(/As an Amazon Associate, GalleryZone earns from qualifying purchases/).first()).toBeVisible();
});

test('quick view shows the photos, switches between them, and buys on Amazon', async ({ page }) => {
  await openShelf(page);
  await page.getByRole('button', { name: 'Quick view: Brustro Tabletop Easel' }).click();
  const dialog = page.getByRole('dialog');
  await expect(dialog.getByRole('heading', { name: 'Brustro Tabletop Easel' })).toBeVisible();
  await expect(dialog.getByText('BRUSTRO', { exact: true })).toBeVisible();

  const main = dialog.locator('img[alt="Brustro Tabletop Easel"]');
  await expect(main).toHaveAttribute('src', /p1i1\._AC_SL800_\.jpg/);
  await dialog.getByRole('button', { name: 'Photo 2 of 2' }).click();
  await expect(dialog.getByRole('button', { name: 'Photo 2 of 2' })).toHaveAttribute('aria-pressed', 'true');
  await expect(main).toHaveAttribute('src', /p1i2\._AC_SL800_\.jpg/);

  const buy = dialog.getByRole('link', { name: /Buy on Amazon/ });
  await expect(buy).toHaveAttribute('href', SHELF[0]!.url);
  await expect(buy).toHaveAttribute('rel', /sponsored/);

  await page.keyboard.press('Escape');
  await expect(dialog).toHaveCount(0);
  // A different product opens on its own cover, not the previous photo index.
  await page.getByRole('button', { name: 'Quick view: Grandink H Frame Easel' }).click();
  await expect(page.getByRole('dialog').locator('img[alt="Grandink H Frame Easel"]')).toHaveAttribute('src', /p2i1\._AC_SL800_\.jpg/);
});

test('cards ask Amazon for a small image, not the 1500px original', async ({ page }) => {
  const requested: string[] = [];
  await page.route('https://m.media-amazon.com/**', (route) => {
    requested.push(route.request().url());
    return route.fulfill({ status: 200, contentType: 'image/png', body: PNG });
  });
  await page.route('**/v1/**', (route) => route.abort());
  await page.route('**/v1/affiliate-products', (route) =>
    route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ products: SHELF }) }),
  );
  await dismissCookieConsent(page);
  await page.goto('/art-supplies');
  await expect(page.getByText('4 products')).toBeVisible();
  await expect.poll(() => requested.length).toBeGreaterThan(0);
  expect(requested.filter((u) => u.includes('_SL1500_'))).toEqual([]);
});

test('an empty shelf, and an API that is down, each say so and the second can retry', async ({ page }) => {
  await openShelf(page, []);
  await expect(page.getByText('The shelf is being stocked')).toBeVisible();

  let up = false;
  const p2 = await page.context().newPage();
  await p2.route('**/v1/**', (route) => route.abort());
  await p2.route('**/v1/affiliate-products', (route) =>
    up
      ? route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ products: SHELF }) })
      : route.abort(),
  );
  await stubAmazonImages(p2);
  await dismissCookieConsent(p2);
  await p2.goto('/art-supplies');
  // react-query retries a failed read three times (about 7s) before giving up.
  await expect(p2.getByText("The shelf didn't load")).toBeVisible({ timeout: 20_000 });
  up = true;
  await p2.getByRole('button', { name: 'Try again' }).click();
  await expect(p2.getByText('4 products')).toBeVisible();
});

test('the header and footer lead to the shelf', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await openShelf(page);
  await page.goto('/about');
  await expect(page.getByRole('link', { name: 'Art Supplies' }).first()).toHaveAttribute('href', '/art-supplies');
  await expect(page.locator('footer').getByRole('link', { name: 'Art Supplies' })).toHaveAttribute('href', '/art-supplies');
});

// --- Admin ------------------------------------------------------------------

async function openAdmin(page: Page, baseURL: string, products: unknown[]) {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.route('**/v1/**', (route) => route.abort());
  await stubAmazonImages(page);
  await dismissCookieConsent(page);
  await signInAs(page.context(), 'admin', baseURL);
  await page.route('**/v1/auth/me', (route) =>
    route.fulfill({
      status: 200, contentType: 'application/json', headers: CORS,
      body: JSON.stringify({ uid: 'a1', role: 'admin', status: 'active', name: 'Admin', email: 'admin@example.in', phone: null, roleGrants: [] }),
    }),
  );
  await page.route('**/v1/admin/affiliate-products', (route) => {
    if (route.request().method() !== 'GET') return route.fallback();
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ products }) });
  });
  await page.goto('/admin/art-supplies');
}

test('admin: fill from Amazon, then add, posts exactly the fields on the form', async ({ page, baseURL }) => {
  await openAdmin(page, baseURL!, SHELF);
  // The admin table renders a desktop table and a phone list; scope to the table.
  await expect(page.getByRole('table').getByText('Brustro Tabletop Easel')).toBeVisible();

  await page.route('**/v1/admin/affiliate-products/lookup', (route) =>
    route.fulfill({
      status: 200, contentType: 'application/json', headers: CORS,
      body: JSON.stringify({
        asin: 'B0CKW9P9Z7', title: 'ECLET Set of 12 Brushes', brand: 'ECLET',
        categoryPath: ['Home & Kitchen', 'Craft Materials', 'Paintbrush Sets'],
        images: ['https://m.media-amazon.com/images/I/aaa._SL1500_.jpg', 'https://m.media-amazon.com/images/I/bbb._SL1500_.jpg'],
      }),
    }),
  );
  let posted: Record<string, unknown> | null = null;
  await page.route('**/v1/admin/affiliate-products', (route) => {
    if (route.request().method() !== 'POST') return route.fallback();
    posted = route.request().postDataJSON();
    return route.fulfill({ status: 201, contentType: 'application/json', headers: CORS, body: JSON.stringify(product(9, posted!)) });
  });

  await page.getByRole('button', { name: 'Add product' }).click();
  const dialog = page.getByRole('dialog');
  await dialog.getByLabel('Amazon link').fill('https://link.amazon/B011xih2K');
  await dialog.getByRole('button', { name: 'Fill from Amazon' }).click();
  await expect(dialog.getByLabel('Title')).toHaveValue('ECLET Set of 12 Brushes');
  await expect(dialog.getByLabel('Brand')).toHaveValue('ECLET');
  await expect(dialog.getByLabel('Category')).toHaveValue('Paintbrush Sets');
  await expect(dialog.getByText('ASIN B0CKW9P9Z7')).toBeVisible();

  await dialog.getByLabel('Category').fill('Brushes'); // the admin corrects Amazon's wording
  await dialog.getByRole('button', { name: 'Add product', exact: true }).click();

  await expect.poll(() => posted).not.toBeNull();
  expect(posted).toEqual({
    url: 'https://link.amazon/B011xih2K', title: 'ECLET Set of 12 Brushes', brand: 'ECLET', category: 'Brushes', active: true,
    images: ['https://m.media-amazon.com/images/I/aaa._SL1500_.jpg', 'https://m.media-amazon.com/images/I/bbb._SL1500_.jpg'],
    asin: 'B0CKW9P9Z7',
  });
  await expect(dialog).toHaveCount(0);
});

test('admin: a failed Amazon lookup says so and leaves the form for typing by hand', async ({ page, baseURL }) => {
  await openAdmin(page, baseURL!, []);
  await page.route('**/v1/admin/affiliate-products/lookup', (route) =>
    route.fulfill({
      status: 422, contentType: 'application/json', headers: CORS,
      body: JSON.stringify({ type: 'about:blank', title: "Amazon didn't return the product page. Fill in the title and image by hand.", status: 422, code: 'amazon_lookup_failed' }),
    }),
  );
  await page.getByRole('button', { name: 'Add product' }).click();
  const dialog = page.getByRole('dialog');
  await dialog.getByLabel('Amazon link').fill('https://link.amazon/B011xih2K');
  await dialog.getByRole('button', { name: 'Fill from Amazon' }).click();
  await expect(dialog.getByText(/Fill in the title and image by hand/)).toBeVisible();
  await dialog.getByLabel('Title').fill('Typed by hand');
  await expect(dialog.getByLabel('Title')).toHaveValue('Typed by hand');
});

test('admin: hiding a product sends only active:false, and removing asks first', async ({ page, baseURL }) => {
  await openAdmin(page, baseURL!, SHELF);
  const patches: Array<{ url: string; body: unknown }> = [];
  await page.route('**/v1/admin/affiliate-products/*', (route) => {
    const req = route.request();
    if (req.method() === 'PATCH') {
      patches.push({ url: req.url(), body: req.postDataJSON() });
      return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify(product(1, { active: false })) });
    }
    if (req.method() === 'DELETE') return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ id: 'B000000002' }) });
    return route.fallback();
  });

  await page.getByRole('switch', { name: 'Hide Brustro Tabletop Easel' }).click();
  await expect.poll(() => patches.length).toBe(1);
  expect(patches[0]!.url).toMatch(/\/v1\/admin\/affiliate-products\/B000000001$/);
  expect(patches[0]!.body).toEqual({ active: false });

  let deleted = false;
  await page.route('**/v1/admin/affiliate-products/B000000002', (route) => {
    if (route.request().method() === 'DELETE') deleted = true;
    return route.fallback();
  });
  await page.getByRole('button', { name: 'Remove Grandink H Frame Easel' }).click();
  await expect(page.getByRole('alertdialog').or(page.getByRole('dialog'))).toContainText('Remove this product?');
  expect(deleted, 'nothing is deleted until the admin confirms').toBe(false);
  await page.getByRole('button', { name: 'Remove', exact: true }).click();
  await expect.poll(() => deleted).toBe(true);
});
