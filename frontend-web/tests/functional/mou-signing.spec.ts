import { test, expect, type Page } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { signInAs } from '../support/auth';
import { dismissCookieConsent } from '../support/settle';

// The MOU on the profile page: the company's text word for word, its blanks
// filled from the signer's profile, signing refused until every required
// blank can be filled, and a signed copy that carries the same text. The API
// is stubbed, so this covers the page; backend/packages/db/src/mou.check.ts
// covers how the API fills the blanks.

const ARTIST_TEXT = readFileSync(join(process.cwd(), '../docs/legal/artist-mou-2026.3.txt'), 'utf8');
const AGGREGATOR_TEXT = readFileSync(join(process.cwd(), '../docs/legal/aggregator-mou-2026.2.txt'), 'utf8');
/** Every line of the source except the blanks, which the page fills in. */
const textLines = (src: string) =>
  src.split('\n').map((l) => l.trim()).filter((l) => l && !/:\s*_{3,}|_+\s*\/\s*_+/.test(l));

// 13:15 UTC is 18:45 IST on 29 September.
const AS_OF = '2026-09-29T13:15:00.000Z';

const profile = (over: Record<string, unknown> = {}) => ({
  uid: 'u1', fullName: 'Meera Kulkarni', email: 'meera@example.in', phone: '9876543210', role: 'artist', status: 'active',
  createdAt: '2026-01-10T00:00:00.000Z', bio: null, profileImageUrl: null, headline: null, location: null, instagram: null,
  website: null, pan: 'ABCDE1234F', gstin: null, gstStatus: 'not_submitted', aadhaarStatus: 'not_submitted', aadhaarMasked: null,
  bankAccountMasked: null, ifsc: null, pickupLine1: '12 Banjara Hills Road', pickupLine2: null, pickupCity: 'Hyderabad',
  pickupState: 'Telangana', pickupPincode: '500034', earningsAbove5L: false, socialProofVideoUrl: null, companyName: null, ...over,
});

const artistParty = {
  name: 'Meera Kulkarni', businessName: null, address: '12 Banjara Hills Road, Hyderabad, Telangana 500034',
  mobile: '+91 98765 43210', email: 'meera@example.in', governmentId: 'PAN ABCDE1234F', gstNo: null,
};
const company = { name: 'Anand Rao', designation: 'Director' };

async function json(page: Page, pattern: string, body: unknown, method?: string) {
  await page.route(pattern, (route) => {
    if (method && route.request().method() !== method) return route.fallback();
    return route.fulfill({ status: 200, contentType: 'application/json', headers: { 'access-control-allow-origin': '*' }, body: JSON.stringify(body) });
  });
}

async function open(page: Page, role: 'artist' | 'aggregator', baseURL: string, path: string) {
  // Anything not stubbed below fails fast instead of reaching a real API.
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await signInAs(page.context(), role, baseURL);
  await json(page, '**/v1/auth/me', { uid: 'u1', role, status: 'active', name: 'Meera Kulkarni', email: 'meera@example.in', phone: '9876543210', roleGrants: [] });
  return path;
}

test('the artist MOU shows the company text word for word, filled from the profile', async ({ page, baseURL }) => {
  const path = await open(page, 'artist', baseURL!, '/dashboard/profile');
  await json(page, '**/v1/me/profile', profile());
  await json(page, '**/v1/artist/mou', { acceptance: null, draft: { version: '2026.3', parties: { party: artistParty, company }, missing: [], asOf: AS_OF } });
  await page.goto(path);

  const doc = page.getByLabel('Artist Memorandum of Understanding, full text');
  await expect(doc).toBeVisible();
  const rendered = (await doc.innerText()).split('\n').map((l) => l.trim());
  const missingLines = textLines(ARTIST_TEXT).filter((line) => !rendered.includes(line));
  expect(missingLines, 'lines of docs/legal/artist-mou-2026.3.txt not rendered verbatim').toEqual([]);

  for (const value of ['Meera Kulkarni', '12 Banjara Hills Road, Hyderabad, Telangana 500034', '+91 98765 43210', 'meera@example.in', 'PAN ABCDE1234F', 'Anand Rao', 'Director']) {
    await expect(doc.getByText(value, { exact: true }).first()).toBeVisible();
  }
  // Before signing, the date is today's (IST) and marked as pending.
  await expect(doc.getByText('29/09/2026', { exact: true }).first()).toBeVisible();
  await expect(page.getByText('Dated 29/09/2026')).toBeVisible();
});

test('signing is blocked until the profile can fill every required blank', async ({ page, baseURL }, testInfo) => {
  const path = await open(page, 'artist', baseURL!, '/dashboard/profile');
  await json(page, '**/v1/me/profile', profile({ phone: null }));
  await json(page, '**/v1/artist/mou', {
    acceptance: null,
    draft: { version: '2026.3', parties: { party: { ...artistParty, mobile: null }, company }, missing: ['mobile'], asOf: AS_OF },
  });
  await page.goto(path);

  await expect(page.getByText('Your profile is missing details this agreement needs')).toBeVisible();
  await expect(page.getByText('Mobile number.', { exact: false })).toBeVisible();
  const doc = page.getByLabel('Artist Memorandum of Understanding, full text');
  await expect(doc.getByText('Missing from your profile').first()).toBeVisible();
  await doc.evaluate((el) => el.scrollTo(0, el.scrollHeight));
  await expect(page.getByRole('checkbox')).toBeDisabled();
  await expect(page.getByRole('button', { name: 'Sign and accept' })).toBeDisabled();
  await page.locator('form').filter({ has: doc }).screenshot({ path: testInfo.outputPath('artist-mou-missing.png') });
});

test('an artist signs, and the signed copy downloads with the same text', async ({ page, baseURL }, testInfo) => {
  const path = await open(page, 'artist', baseURL!, '/dashboard/profile');
  await json(page, '**/v1/me/profile', profile());
  let signed: Record<string, unknown> | null = null;
  await page.route('**/v1/artist/mou/accept', async (route) => {
    const body = route.request().postDataJSON() as { version: string; signatureName: string; signatureDataUrl: string };
    signed = { party: 'artist', version: body.version, signatureName: body.signatureName, signatureDataUrl: body.signatureDataUrl, acceptedAt: AS_OF, parties: { party: artistParty, company } };
    await route.fulfill({ status: 200, contentType: 'application/json', headers: { 'access-control-allow-origin': '*' }, body: JSON.stringify(signed) });
  });
  await page.route('**/v1/artist/mou', (route) =>
    route.fulfill({
      status: 200, contentType: 'application/json', headers: { 'access-control-allow-origin': '*' },
      body: JSON.stringify({ acceptance: signed, draft: { version: '2026.3', parties: { party: artistParty, company }, missing: [], asOf: AS_OF } }),
    }),
  );
  await page.goto(path);

  const doc = page.getByLabel('Artist Memorandum of Understanding, full text');
  await doc.evaluate((el) => el.scrollTo(0, el.scrollHeight));
  await page.getByRole('checkbox').check();
  await page.getByLabel('Type your full name').fill('Meera Kulkarni');
  const pad = page.locator('canvas');
  const box = (await pad.boundingBox())!;
  await page.mouse.move(box.x + 30, box.y + 80);
  await page.mouse.down();
  await page.mouse.move(box.x + 120, box.y + 40, { steps: 8 });
  await page.mouse.move(box.x + 220, box.y + 90, { steps: 8 });
  await page.mouse.up();

  const request = page.waitForRequest('**/v1/artist/mou/accept');
  await page.getByRole('button', { name: 'Sign and accept' }).click();
  const body = (await request).postDataJSON();
  expect(body.version).toBe('2026.3');
  expect(body.signatureName).toBe('Meera Kulkarni');
  expect(body.signatureDataUrl).toMatch(/^data:image\/png;base64,/);

  await expect(page.getByText('Signed 29 September 2026 at 6:45 pm IST. Version 2026.3.')).toBeVisible();
  await page.getByText('Read the signed agreement').click();
  await page.getByText('Signed 29 September 2026 at 6:45 pm IST. Version 2026.3.').locator('xpath=ancestor::div[contains(@class,"rounded-lg")][1]').screenshot({ path: testInfo.outputPath('artist-mou-signed.png') });

  const download = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Download signed PDF' }).click();
  const file = testInfo.outputPath('artist-mou.pdf');
  await (await download).saveAs(file);

  // Every line of the source text is in the PDF, in order (wrapping aside).
  const lines = execFileSync('python', ['-c', 'import fitz,sys; print("".join(p.get_text() for p in fitz.open(sys.argv[1])))', file], {
    encoding: 'utf8', env: { ...process.env, PYTHONIOENCODING: 'utf-8' },
  }).split(/\r?\n/);
  // Each page carries the source's running footer and a page count.
  expect(lines).toContain('GalleryZone Private Limited — Artist MOU Revised Draft');
  expect(lines.some((l) => /^Page \d+ of \d+$/.test(l.trim()))).toBe(true);
  // The footer interrupts a paragraph that crosses a page; read past it.
  const pdfText = lines
    .filter((l) => l.trim() !== 'GalleryZone Private Limited — Artist MOU Revised Draft' && !/^Page \d+ of \d+$/.test(l.trim()))
    .join('\n');
  const squash = (s: string) => s.replace(/\s+/g, '');
  const pdf = squash(pdfText);
  let at = 0;
  for (const line of textLines(ARTIST_TEXT)) {
    const found = pdf.indexOf(squash(line), at);
    expect(found, `PDF is missing, or has out of order: ${line}`).toBeGreaterThanOrEqual(0);
    at = found;
  }
  for (const value of ['MeeraKulkarni', 'PANABCDE1234F', '+919876543210', '29/09/2026', 'AnandRao', 'Signedelectronically']) {
    expect(pdf).toContain(value);
  }
});

test('the aggregator MOU fills business name, GST and the effective date in IST', async ({ page, baseURL }, testInfo) => {
  const path = await open(page, 'aggregator', baseURL!, '/aggregator/profile');
  await json(page, '**/v1/me/profile', profile({ role: 'aggregator', companyName: 'Kulkarni Fine Art', gstin: '36ABCDE1234F1Z5' }));
  // 19:00 UTC on the 29th is already 30 September in India.
  await json(page, '**/v1/aggregator/mou', {
    acceptance: null,
    draft: {
      version: '2026.2',
      parties: { party: { ...artistParty, governmentId: null, businessName: 'Kulkarni Fine Art', gstNo: '36ABCDE1234F1Z5' }, company: { name: null, designation: null } },
      missing: [],
      asOf: '2026-09-29T19:00:00.000Z',
    },
  });
  await page.goto(path);

  const doc = page.getByLabel('Aggregator Memorandum of Understanding, full text');
  await expect(doc).toBeVisible();
  const rendered = (await doc.innerText()).split('\n').map((l) => l.trim());
  expect(textLines(AGGREGATOR_TEXT).filter((line) => !rendered.includes(line))).toEqual([]);

  await expect(doc.getByText('Kulkarni Fine Art', { exact: true }).first()).toBeVisible();
  await expect(doc.getByText('36ABCDE1234F1Z5', { exact: true })).toBeVisible();
  await expect(doc.getByText('30 / 09 / 2026', { exact: true })).toBeVisible();
  // No configured Galleryzone signatory: its lines stay blank, nothing invented.
  await expect(doc.getByLabel('Blank')).toHaveCount(4);

  // The profile form now asks for the address in the parts the MOU needs.
  await expect(page.getByLabel('City')).toHaveValue('Hyderabad');
  await expect(page.getByLabel('PIN code')).toHaveValue('500034');
  await doc.screenshot({ path: testInfo.outputPath('aggregator-mou.png') });
});
