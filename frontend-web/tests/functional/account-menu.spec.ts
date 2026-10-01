import { test, expect, type Page } from '@playwright/test';
import { signInAs, type SessionRole } from '../support/auth';
import { dismissCookieConsent } from '../support/settle';

// Signing out is in one place in every portal: the avatar at the right end of
// the topbar. And a collapsed sidebar keeps the logo whole. The API is stubbed.

const PORTALS: Array<{ role: SessionRole; path: string }> = [
  { role: 'artist', path: '/dashboard' },
  { role: 'customer', path: '/account' },
  { role: 'aggregator', path: '/aggregator/dashboard' },
  { role: 'admin', path: '/admin' },
];

async function open(page: Page, baseURL: string, role: SessionRole, path: string) {
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await signInAs(page.context(), role, baseURL);
  await page.route('**/v1/auth/me', (route) =>
    route.fulfill({
      status: 200, contentType: 'application/json', headers: { 'access-control-allow-origin': '*' },
      body: JSON.stringify({ uid: 'u1', role, status: 'active', name: 'Yash Mehta', email: 'yash@example.in', phone: null, roleGrants: [] }),
    }),
  );
  await page.goto(path);
}

for (const { role, path } of PORTALS) {
  test(`${role}: the avatar menu is the one way to sign out, and it works`, async ({ page, baseURL }) => {
    await open(page, baseURL!, role, path);
    await page.getByRole('button', { name: 'Account menu' }).filter({ visible: true }).click();
    const menu = page.locator('[data-slot="popover-content"]');
    await expect(menu.getByText('yash@example.in')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Sign out' })).toHaveCount(1);

    await menu.getByRole('button', { name: 'Sign out' }).click();
    await page.waitForURL('**/login');
    const cookies = await page.context().cookies();
    expect(cookies.find((c) => c.name === 'gz_session')?.value ?? '').toBe('');
  });

  test(`${role}: the sidebar has no account card; the avatar menu carries the account`, async ({ page, baseURL }) => {
    await page.setViewportSize({ width: 1280, height: 720 });
    await open(page, baseURL!, role, path);
    await expect(page.getByRole('button', { name: 'Account menu' }).filter({ visible: true })).toBeVisible();
    await expect(page.locator('aside').getByText('yash@example.in')).toHaveCount(0);
    await expect(page.locator('aside').getByText('Yash Mehta')).toHaveCount(0);
  });

  test(`${role}: a collapsed sidebar keeps the logo whole, with the toggle under it`, async ({ page, baseURL }) => {
    await page.setViewportSize({ width: 1280, height: 720 });
    await open(page, baseURL!, role, path);
    await page.getByRole('button', { name: 'Collapse sidebar' }).click();
    const logo = page.locator('aside').getByRole('img', { name: 'GalleryZone' });
    const toggle = page.getByRole('button', { name: 'Expand sidebar' });
    await expect(toggle).toBeVisible();
    // Natural size at h-8 is 47x32. Squashed, it used to be about 16px wide.
    await expect.poll(async () => (await logo.boundingBox())?.width ?? 0).toBeGreaterThan(40);
    const [l, t] = [await logo.boundingBox(), await toggle.boundingBox()];
    expect(t!.y).toBeGreaterThan(l!.y + l!.height - 1);
    const rail = await page.locator('aside').first().boundingBox();
    expect(l!.x).toBeGreaterThanOrEqual(rail!.x);
    expect(l!.x + l!.width).toBeLessThanOrEqual(rail!.x + rail!.width);
  });
}

test('artist sidebar order: View site, Profile, My Artworks, Add Artwork, Dashboard', async ({ page, baseURL }) => {
  await page.setViewportSize({ width: 1280, height: 720 });
  await open(page, baseURL!, 'artist', '/dashboard');
  const labels = (await page.locator('aside').first().getByRole('link').allInnerTexts()).map((t) => t.trim()).filter(Boolean);
  // The first link is the brand wordmark.
  expect(labels.slice(1, 6)).toEqual(['View site', 'My Profile', 'My Artworks', 'Add Artwork', 'Dashboard']);
});

for (const { role, path } of PORTALS.filter((p) => p.role === 'customer' || p.role === 'aggregator')) {
  test(`${role}: on a phone the same avatar menu signs out, and the More sheet has no second sign-out`, async ({ page, baseURL }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await open(page, baseURL!, role, path);
    await page.getByRole('button', { name: 'Account menu' }).filter({ visible: true }).click();
    await expect(page.getByRole('button', { name: 'Sign out' })).toHaveCount(1);
    await page.keyboard.press('Escape');
    await page.getByRole('button', { name: /^More/ }).click();
    await expect(page.getByRole('button', { name: 'Sign out' })).toHaveCount(0);
  });
}
