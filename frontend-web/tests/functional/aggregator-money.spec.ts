import { test, expect, type Page } from '@playwright/test';
import { signInAs } from '../support/auth';
import { dismissCookieConsent } from '../support/settle';

// The aggregator money flow as the client set it (30 Sep 2026): the aggregator
// prices a piece only when reserving in month 1, GST and a signed MOU are
// required before reserving, a piece can be kept past its 30 days only by
// asking GalleryZone, and returned pieces leave My Inventory. The API is
// stubbed, so this covers what the screens show and send; the arithmetic
// itself is covered by backend/packages/domain/src/pricing.check.ts.

const CORS = { 'access-control-allow-origin': '*' };
const AS_OF = '2026-09-30T06:00:00.000Z';

async function json(page: Page, pattern: string, body: unknown, method?: string) {
  await page.route(pattern, (route) => {
    if (method && route.request().method() !== method) return route.fallback();
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify(body) });
  });
}

const profile = (over: Record<string, unknown> = {}) => ({
  uid: 'u1', fullName: 'Anand Rao', email: 'anand@example.in', phone: '9876543210', role: 'aggregator', status: 'active',
  createdAt: '2026-01-10T00:00:00.000Z', bio: null, profileImageUrl: null, headline: 'Director', location: null, instagram: null,
  website: null, pan: null, gstin: '36ABCDE1234F1Z5', gstStatus: 'approved', aadhaarStatus: 'not_submitted', aadhaarMasked: null,
  bankAccountMasked: null, ifsc: null, pickupLine1: '12 Banjara Hills Road', pickupLine2: null, pickupCity: 'Hyderabad',
  pickupState: 'Telangana', pickupPincode: '500034', earningsAbove5L: false, socialProofVideoUrl: null, companyName: 'Rao Gallery', ...over,
});

const mou = (signed: boolean) => ({
  acceptance: signed
    ? { party: 'aggregator', version: '2026.2', signatureName: 'Anand Rao', signatureDataUrl: 'data:image/png;base64,AAAA', acceptedAt: AS_OF, parties: null }
    : null,
  draft: { version: '2026.2', parties: { party: {}, company: { name: null, designation: null } }, missing: [], asOf: AS_OF },
});

const artworkDto = (id: string, over: Record<string, unknown> = {}) => ({
  id, productCode: `GZ-${id}`, artistId: 'artist1', artistName: 'Meera Kulkarni', title: `Piece ${id}`, description: 'A piece.',
  category: 'Abstract', medium: 'Oil on canvas', dimensions: '24 x 36 in', yearCreated: 2024, images: [], displayPricePaise: 13_650_000,
  insured: true, status: 'marketplace', listingType: 'marketplace_and_aggregator', rarityType: null, coaCertificateNumber: null,
  coaIssuedAt: null, createdAt: '2026-09-01T00:00:00.000Z', artistLocation: 'Hyderabad', sizeBand: 'medium', ...over,
});

// ₹1,00,000 artist price. Month 1: GalleryZone's price ₹1,30,000 before GST,
// ₹1,36,500 with it, advance 5% of the price, delivery ₹2,500.
const monthOne = {
  month: 1, sellingPricePaise: 13_000_000, offerPricePaise: 13_650_000, standardPricePaise: 13_650_000, monthlyReductionPaise: 0,
  marketplacePricePaise: 13_650_000, canSetPrice: true, gstRate: 0.05, priceWarnFromPaise: 26_000_000, advancePaise: 650_000,
  advanceRate: 0.05, advanceBasePaise: 13_000_000, advanceBasis: 'selling_price', daysLeftInListing: 180, deliveryChargePaise: 250_000,
  payablePaise: 900_000,
};
// Month 2: GalleryZone's price steps down 2% of the artist price, and the
// advance is 5% of the artist price, whatever anyone charges.
const monthTwo = {
  ...monthOne, month: 2, sellingPricePaise: 12_800_000, offerPricePaise: 13_440_000, monthlyReductionPaise: 210_000,
  canSetPrice: false, priceWarnFromPaise: null, advancePaise: 500_000, advanceBasePaise: 10_000_000, advanceBasis: 'artist_price',
  payablePaise: 750_000,
};
const listed = (id: string, offer: object, over: Record<string, unknown> = {}) => ({ ...artworkDto(id, over), offer: { artworkId: id, ...offer } });

const DAY = 86_400_000;
const holdingDto = (id: string, artworkId: string, over: Record<string, unknown> = {}) => ({
  id, artworkId, artwork: artworkDto(artworkId), cycleMonth: 1, advancePercent: 5, advancePaise: 650_000, deliveryDepositPaise: 250_000,
  displayPricePaise: 13_650_000, assignmentSource: 'self_reserved', assignedAt: new Date(Date.now() - 20 * DAY).toISOString(),
  expiresAt: new Date(Date.now() + 10 * DAY).toISOString(), windowExtended: false, status: 'reserved', returnedAt: null,
  appreciated: false, priceWarning: false, extensionRequest: null, ...over,
});

interface Stub {
  gstStatus?: string;
  mouSigned?: boolean;
  inventory?: unknown[];
  holdings?: unknown[];
}

async function open(page: Page, baseURL: string, stub: Stub = {}) {
  // Anything not stubbed below fails fast instead of reaching a real API.
  await page.route('**/v1/**', (route) => route.abort());
  await dismissCookieConsent(page);
  await signInAs(page.context(), 'aggregator', baseURL);
  await json(page, '**/v1/auth/me', { uid: 'u1', role: 'aggregator', status: 'active', name: 'Anand Rao', email: 'anand@example.in', phone: '9876543210', roleGrants: [] });
  await json(page, '**/v1/me/profile', profile({ gstStatus: stub.gstStatus ?? 'approved' }));
  await json(page, '**/v1/aggregator/mou', mou(stub.mouSigned ?? true));
  await json(page, '**/v1/aggregator/inventory', { artworks: stub.inventory ?? [] });
  await json(page, '**/v1/aggregator/wallet', { accountType: 'aggregator_payable', balancePaise: 5_000_000, heldPaise: 0 });
  await json(page, '**/v1/aggregator/wallet/transactions', { transactions: [] });
  await json(page, '**/v1/aggregator/holdings', { holdings: stub.holdings ?? [] }, 'GET');
}

/** The breakdown row whose label reads `label`. */
const row = (page: Page, label: string | RegExp) =>
  page.getByText(label, { exact: typeof label === 'string' }).locator('xpath=ancestor::div[contains(@class,"justify-between")][1]');

test('month 1: the aggregator sets the price and every figure follows it', async ({ page, baseURL }, testInfo) => {
  await open(page, baseURL!, { inventory: [listed('a1', monthOne)] });
  const bodies: unknown[] = [];
  await page.route('**/v1/aggregator/holdings', (route) => {
    if (route.request().method() !== 'POST') return route.fallback();
    bodies.push(route.request().postDataJSON());
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify(holdingDto('h1', 'a1', { displayPricePaise: 15_750_000 })) });
  });
  await json(page, '**/v1/aggregator/holdings/h1', holdingDto('h1', 'a1', { displayPricePaise: 15_750_000 }));
  await page.goto('/aggregator/inventory/a1/reserve');

  // It starts at GalleryZone's price, with GalleryZone's own numbers.
  const price = page.getByLabel('Your selling price, before GST (₹)');
  await expect(price).toHaveValue('130000');
  await expect(row(page, 'What customers see')).toContainText('₹1,36,500');
  await expect(row(page, 'Advance (5%)')).toContainText('₹6,500');

  // The client's own example: sell at ₹1,50,000 before GST.
  await price.fill('150000');
  await expect(row(page, 'What customers see')).toContainText('₹1,57,500');
  await expect(row(page, /^GST \(5%\)$/)).toContainText('₹7,500');
  await expect(row(page, /^Artist.s price$/)).toContainText('₹1,00,000');
  await expect(row(page, /GalleryZone \(80% of the markup\)/)).toContainText('₹40,000');
  await expect(row(page, /Your commission if it sells here \(20%\)/)).toContainText('₹10,000');
  await expect(row(page, 'Advance (5%)')).toContainText('₹7,500');
  await expect(row(page, 'Held from your wallet')).toContainText('₹10,000');
  await expect(page.getByRole('status')).toHaveCount(0);

  // Below GalleryZone's price is refused before anything is sent.
  await price.fill('120000');
  await expect(page.getByText(/can.t be lower than GalleryZone.s price, ₹1,30,000/)).toBeVisible();
  await expect(page.getByRole('button', { name: 'Confirm reservation' })).toBeDisabled();

  // Double GalleryZone's price still goes through: GalleryZone is told, the aggregator is too.
  await price.fill('260000');
  await expect(page.getByRole('status')).toContainText(/at least double/);
  await expect(page.getByRole('button', { name: 'Confirm reservation' })).toBeEnabled();
  await page.screenshot({ path: testInfo.outputPath('reserve-month-1-warning.png'), fullPage: true });

  await price.fill('150000');
  await page.getByRole('button', { name: 'Confirm reservation' }).click();
  await page.waitForURL('**/aggregator/collection/h1');
  expect(bodies).toEqual([{ artworkId: 'a1', sellingPricePaise: 15_000_000 }]);
});

test('later months: the price is GalleryZone’s and the advance is 5% of the artist price', async ({ page, baseURL }) => {
  await open(page, baseURL!, { inventory: [listed('a2', monthTwo)] });
  const bodies: unknown[] = [];
  await page.route('**/v1/aggregator/holdings', (route) => {
    if (route.request().method() !== 'POST') return route.fallback();
    bodies.push(route.request().postDataJSON());
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify(holdingDto('h2', 'a2', { cycleMonth: 2 })) });
  });
  await json(page, '**/v1/aggregator/holdings/h2', holdingDto('h2', 'a2', { cycleMonth: 2 }));
  await page.goto('/aggregator/inventory/a2/reserve');

  await expect(page.getByText('Price this month, before GST')).toBeVisible();
  await expect(page.getByLabel('Your selling price, before GST (₹)')).toHaveCount(0);
  await expect(row(page, 'Advance (5%)')).toContainText('₹5,000');
  await expect(page.getByText('of the artist price, ₹1,00,000')).toBeVisible();
  await expect(row(page, 'Held from your wallet')).toContainText('₹7,500');

  await page.getByRole('button', { name: 'Confirm reservation' }).click();
  await page.waitForURL('**/aggregator/collection/h2');
  // No price is sent for a month the aggregator doesn't price.
  expect(bodies).toEqual([{ artworkId: 'a2' }]);
});

const GATES = [
  { name: 'no GST number yet', stub: { gstStatus: 'not_submitted' }, notice: 'Add your GST number to reserve artwork.', profileLink: true },
  { name: 'GST number under review', stub: { gstStatus: 'submitted' }, notice: 'Your GST number is being reviewed.', profileLink: false },
  { name: 'GST number rejected', stub: { gstStatus: 'rejected' }, notice: "Your GST number wasn't approved.", profileLink: true },
  { name: 'MOU not signed', stub: { mouSigned: false }, notice: 'Sign your Aggregator MOU to reserve artwork.', profileLink: true },
];
for (const gate of GATES) {
  test(`nothing can be reserved: ${gate.name}`, async ({ page, baseURL }) => {
    await open(page, baseURL!, { ...gate.stub, inventory: [listed('a1', monthOne)] });

    await page.goto('/aggregator/inventory');
    await expect(page.getByText(gate.notice)).toBeVisible();
    await expect(page.getByRole('link', { name: 'Go to My Profile' })).toHaveCount(gate.profileLink ? 1 : 0);

    // Pressing Reserve explains why, in a popup, instead of doing nothing.
    await page.getByRole('button', { name: 'Reserve Artwork' }).click();
    const dialog = page.getByRole('dialog');
    await expect(dialog.getByText(gate.notice)).toBeVisible();
    await expect(dialog.getByRole('link', { name: 'Go to My Profile' })).toHaveCount(gate.profileLink ? 1 : 0);
    await expect(page).toHaveURL(/\/aggregator\/inventory$/);
    // The same wall stands on the reserve screen itself.
    await page.goto('/aggregator/inventory/a1/reserve');
    await expect(page.getByText(gate.notice)).toBeVisible();
    await expect(page.getByRole('button', { name: 'Confirm reservation' })).toBeDisabled();
  });
}

test('the grid says who sets the price, and suggests pieces like the ones already held', async ({ page, baseURL }) => {
  await open(page, baseURL!, {
    inventory: [
      listed('a1', monthOne, { title: 'Monsoon Study' }),
      listed('a2', monthTwo, { title: 'Tiny Harbour', category: 'Landscape', displayPricePaise: 1_000_000, sizeBand: 'small' }),
    ],
    holdings: [holdingDto('h1', 'held', { artwork: artworkDto('held', { title: 'Held Abstract' }) })],
  });
  await page.goto('/aggregator/inventory');

  await expect(page.getByText('Month 1 of 5 · you set the price')).toBeVisible();
  await expect(page.getByText('Month 2 of 5 · ₹2,100 off month 1')).toBeVisible();
  await expect(page.getByText('Fixed this month, incl. GST')).toBeVisible();

  // Same category, price and size as the held piece; the small landscape is none of those.
  const suggestions = page.locator('section').filter({ has: page.getByRole('heading', { name: 'Suggested for you' }) });
  await expect(suggestions.getByText('Monsoon Study')).toBeVisible();
  await expect(suggestions.getByText('Tiny Harbour')).toHaveCount(0);
});

test('a returned piece leaves My Inventory completely', async ({ page, baseURL }) => {
  await open(page, baseURL!, {
    holdings: [
      holdingDto('h1', 'kept', { artwork: artworkDto('kept', { title: 'Still Here' }) }),
      holdingDto('h2', 'gone', { artwork: artworkDto('gone', { title: 'Sent Back' }), status: 'returned', returnedAt: AS_OF }),
    ],
  });
  await page.goto('/aggregator/collection');

  await expect(page.getByText('Still Here').filter({ visible: true }).first()).toBeVisible();
  await expect(page.getByText('Sent Back')).toHaveCount(0);
  await expect(page.getByRole('button', { name: /^Returned/ })).toHaveCount(0);
  await expect(page.getByRole('button', { name: /^All 1$/ })).toBeVisible();
});

test('asking to keep a piece longer takes an assurance and shows GalleryZone’s answer', async ({ page, baseURL }, testInfo) => {
  await open(page, baseURL!, { inventory: [] });
  const base = holdingDto('h1', 'a1');
  let asked: { assurance: string } | null = null;
  const pending = () => ({
    ...base,
    extensionRequest: { status: 'pending', assurance: asked!.assurance, requestedAt: AS_OF, decidedAt: null, note: null, previousExpiresAt: base.expiresAt },
  });
  await page.route('**/v1/aggregator/holdings/h1', (route) => route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify(asked ? pending() : base) }));
  await page.route('**/v1/aggregator/holdings/h1/extension', (route) => {
    asked = route.request().postDataJSON();
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify(pending()) });
  });
  await page.goto('/aggregator/collection/h1');

  await page.getByRole('button', { name: 'Ask to keep it longer' }).click();
  const send = page.getByRole('button', { name: 'Send request' });
  await expect(send).toBeDisabled();
  await page.getByLabel('Your assurance that it will sell').fill('Too short');
  await expect(send).toBeDisabled();
  await page.getByLabel('Your assurance that it will sell').fill('A collector has viewed it twice and confirms this week.');
  await send.click();

  await expect(page.getByText('Waiting for GalleryZone')).toBeVisible();
  await expect(page.getByText(/A collector has viewed it twice/)).toBeVisible();
  await expect(page.getByRole('button', { name: 'Ask to keep it longer' })).toHaveCount(0);
  await page.screenshot({ path: testInfo.outputPath('extension-pending.png'), fullPage: true });
  expect(asked).toEqual({ assurance: 'A collector has viewed it twice and confirms this week.' });
});

test('a declined request stands for the window, and the piece cannot be asked about again', async ({ page, baseURL }) => {
  await open(page, baseURL!);
  const base = holdingDto('h1', 'a1');
  await json(page, '**/v1/aggregator/holdings/h1', {
    ...base,
    extensionRequest: { status: 'declined', assurance: 'It will sell.', requestedAt: AS_OF, decidedAt: AS_OF, note: 'Not this month.', previousExpiresAt: base.expiresAt },
  });
  await page.goto('/aggregator/collection/h1');

  await expect(page.getByText('GalleryZone said no')).toBeVisible();
  await expect(page.getByText(/Not this month\./)).toBeVisible();
  await expect(page.getByRole('button', { name: 'Ask to keep it longer' })).toHaveCount(0);
});

// ---- The wallet: money comes in through Razorpay ---------------------------------------------

const razorpaySession = (topupId: string, orderId: string) => ({
  mode: 'razorpay', topupId, keyId: 'rzp_test_key', razorpayOrderId: orderId, amountPaise: 2_500_000, currency: 'INR',
  name: 'GalleryZone', description: 'Add funds to your GalleryZone wallet', prefill: { name: 'Anand Rao', email: 'anand@example.in', contact: '9876543210' },
});

/** Stands in for Checkout.js: records what it was opened with, then pays or is closed. */
async function fakeRazorpay(page: Page, behaviour: 'pay' | 'close') {
  await page.addInitScript((mode) => {
    type Options = { order_id: string; handler: (r: object) => void; modal: { ondismiss: () => void } };
    (window as unknown as { Razorpay: unknown }).Razorpay = class {
      o: Options;
      constructor(o: Options) { this.o = o; (window as unknown as { __rzp: Options }).__rzp = o; }
      on() {}
      open() {
        setTimeout(() => (mode === 'pay'
          ? this.o.handler({ razorpay_order_id: this.o.order_id, razorpay_payment_id: 'pay_test_1', razorpay_signature: 'sig_test_1' })
          : this.o.modal.ondismiss()), 50);
      }
    };
  }, behaviour);
}

async function walletThatFollows(page: Page) {
  const state = { balancePaise: 0 };
  await page.route('**/v1/aggregator/wallet', (route) =>
    route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ accountType: 'aggregator_payable', balancePaise: state.balancePaise, heldPaise: 0 }) }),
  );
  return state;
}

const freeToUse = (page: Page) => page.getByText('Free to use').locator('xpath=ancestor::div[contains(@class,"rounded-lg")][1]');

test('topping up: Razorpay opens on our order, and the wallet is credited once the API has verified it', async ({ page, baseURL }, testInfo) => {
  await open(page, baseURL!);
  await fakeRazorpay(page, 'pay');
  const wallet = await walletThatFollows(page);
  const started: unknown[] = [];
  const verified: unknown[] = [];
  await page.route('**/v1/aggregator/wallet/topups', (route) => {
    started.push(route.request().postDataJSON());
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify(razorpaySession('t1', 'order_test_1')) });
  });
  await page.route('**/v1/aggregator/wallet/topups/t1/verify', (route) => {
    verified.push(route.request().postDataJSON());
    wallet.balancePaise = 2_500_000;
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ status: 'paid', amountPaise: 2_500_000 }) });
  });
  await page.goto('/aggregator/wallet');
  await expect(freeToUse(page)).toContainText('₹0');

  await page.getByLabel('Amount (₹)').first().fill('25000');
  await page.getByRole('button', { name: 'Add to wallet' }).click();

  // The amount goes to the API in paise; the API, not the browser, opens the gateway order.
  await expect(page.getByText('Added to your wallet')).toBeVisible();
  expect(started).toEqual([{ amountPaise: 2_500_000 }]);
  expect(await page.evaluate(() => (window as unknown as { __rzp: { order_id: string; key: string; amount: number } }).__rzp)).toMatchObject({ order_id: 'order_test_1', key: 'rzp_test_key', amount: 2_500_000 });
  // What Checkout.js returned is handed to the API to verify; nothing is credited by the browser.
  expect(verified).toEqual([{ razorpayOrderId: 'order_test_1', razorpayPaymentId: 'pay_test_1', signature: 'sig_test_1' }]);
  await expect(freeToUse(page)).toContainText('₹25,000');
  await page.screenshot({ path: testInfo.outputPath('wallet-topped-up.png'), fullPage: true });
});

test('closing the Razorpay window charges nothing and credits nothing', async ({ page, baseURL }) => {
  await open(page, baseURL!);
  await fakeRazorpay(page, 'close');
  const wallet = await walletThatFollows(page);
  const verified: unknown[] = [];
  await json(page, '**/v1/aggregator/wallet/topups', razorpaySession('t2', 'order_test_2'), 'POST');
  await page.route('**/v1/aggregator/wallet/topups/t2/verify', (route) => {
    verified.push(route.request().postDataJSON());
    return route.abort();
  });
  await page.goto('/aggregator/wallet');

  await page.getByLabel('Amount (₹)').first().fill('25000');
  await page.getByRole('button', { name: 'Add to wallet' }).click();

  await expect(page.getByText('Payment cancelled — nothing was charged.')).toBeVisible();
  expect(verified).toEqual([]);
  expect(wallet.balancePaise).toBe(0);
  await expect(freeToUse(page)).toContainText('₹0');
});

test('with no gateway configured the top-up is simulated, not silently credited by the page', async ({ page, baseURL }) => {
  await open(page, baseURL!);
  const wallet = await walletThatFollows(page);
  const calls: string[] = [];
  await json(page, '**/v1/aggregator/wallet/topups', { mode: 'simulated', topupId: 't3', amountPaise: 1_000_000 }, 'POST');
  await page.route('**/v1/aggregator/wallet/topups/t3/simulate', (route) => {
    calls.push(route.request().url());
    wallet.balancePaise = 1_000_000;
    return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify({ status: 'paid', amountPaise: 1_000_000 }) });
  });
  await page.goto('/aggregator/wallet');

  await page.getByLabel('Amount (₹)').first().fill('10000');
  await page.getByRole('button', { name: 'Add to wallet' }).click();
  await expect(freeToUse(page)).toContainText('₹10,000');
  expect(calls).toHaveLength(1);
});

test('a top-up outside ₹1,000 to ₹5,00,000 can’t be started', async ({ page, baseURL }) => {
  await open(page, baseURL!);
  await page.goto('/aggregator/wallet');
  const amount = page.getByLabel('Amount (₹)').first();
  const add = page.getByRole('button', { name: 'Add to wallet' });

  for (const [value, ok] of [['500', false], ['600000', false], ['1000.5', false], ['1000', true], ['500000', true]] as const) {
    await amount.fill(value);
    if (ok) await expect(add).toBeEnabled(); else await expect(add).toBeDisabled();
  }
});

test('the wallet history says what each entry was, and which piece it was for', async ({ page, baseURL }) => {
  await open(page, baseURL!, { holdings: [holdingDto('h1', 'held', { artwork: artworkDto('held', { title: 'Held Abstract' }) })] });
  await json(page, '**/v1/aggregator/wallet/transactions', {
    transactions: [
      { id: 'e1', amountPaise: 2_500_000, reason: 'wallet_topup', holdingId: null, at: '2026-09-29T10:00:00.000Z' },
      { id: 'e2', amountPaise: -1_000_000, reason: 'reservation_hold', holdingId: 'h1', at: '2026-09-30T10:00:00.000Z' },
      { id: 'e3', amountPaise: 750_000, reason: 'advance_returned_to_wallet', holdingId: 'h1', at: '2026-10-30T10:00:00.000Z' },
    ],
  });
  await page.goto('/aggregator/wallet');

  await expect(page.getByText('Added to wallet', { exact: true })).toBeVisible();
  await expect(page.getByText('Held for reservation · Held Abstract')).toBeVisible();
  await expect(page.getByText('Advance returned · Held Abstract')).toBeVisible();
});

test('a reservation the wallet can’t cover is refused with the reason', async ({ page, baseURL }) => {
  await open(page, baseURL!, { inventory: [listed('a1', monthOne)] });
  await page.route('**/v1/aggregator/holdings', (route) => {
    if (route.request().method() !== 'POST') return route.fallback();
    return route.fulfill({
      status: 409, contentType: 'application/json', headers: CORS,
      body: JSON.stringify({ type: 'about:blank', title: 'Your wallet needs ₹9,000 free to reserve this piece and has ₹0. Add funds in Earnings & Wallet.', status: 409, code: 'conflict' }),
    });
  });
  await page.goto('/aggregator/inventory/a1/reserve');
  await page.getByRole('button', { name: 'Confirm reservation' }).click();
  await expect(page.getByText(/Your wallet needs ₹9,000 free/)).toBeVisible();
  await expect(page).toHaveURL(/\/reserve$/);
});

// ---- Cash sales: the full price is due at GalleryZone within 2 days ----------------------------

const cashSale = (id: string, soldDaysAgo: number, over: Record<string, unknown> = {}) => ({
  id, holdingId: `h-${id}`, artworkId: 'a1', soldPricePaise: 15_750_000, buyerName: `Buyer ${id}`, buyerEmail: 'b@example.in', buyerPhone: '9000000000',
  deliveryAddress: '1 Road, Hyderabad, Telangana, 500034', deliveryMode: 'courier', paymentRoute: 'cash_at_premises', remittedAt: null,
  remitDueAt: new Date(Date.now() + (2 - soldDaysAgo) * DAY).toISOString(), remittedVia: null, shipmentStatus: 'preparing', dispatchedAt: null, deliveredAt: null,
  courierRef: null, soldAt: new Date(Date.now() - soldDaysAgo * DAY).toISOString(), ...over,
});

async function openSettlements(page: Page, baseURL: string, walletPaise: number) {
  await open(page, baseURL);
  const sales = [cashSale('s1', 1), cashSale('s2', 4)];
  const remaining = [...sales];
  await json(page, '**/v1/aggregator/wallet', { accountType: 'aggregator_payable', balancePaise: walletPaise, heldPaise: 0 });
  await page.route('**/v1/aggregator/sales', (route) => route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify(sales) }));
  await page.route('**/v1/aggregator/sales/remittances-due', (route) => route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: JSON.stringify(remaining) }));
  return { sales, remaining };
}

test('a cash sale shows when it is due, and an overdue one says so', async ({ page, baseURL }) => {
  await openSettlements(page, baseURL!, 20_000_000);
  await page.goto('/aggregator/settlements');

  await expect(page.getByRole('heading', { name: 'Owed to GalleryZone' })).toBeVisible();
  await expect(page.getByText(/Pay in the full amount within 2 days/)).toBeVisible();
  const due = new Date(Date.now() + 1 * DAY).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
  await expect(page.locator('li').filter({ hasText: 'Buyer s1' })).toContainText(`due ${due}`);
  await expect(page.locator('li').filter({ hasText: 'Buyer s2' })).toContainText('Overdue by 2 days');
});

test('paying in a cash sale from the wallet, and by bank transfer, each say which they are', async ({ page, baseURL }) => {
  const { remaining } = await openSettlements(page, baseURL!, 20_000_000);
  const bodies: Record<string, unknown> = {};
  for (const id of ['s1', 's2']) {
    await page.route(`**/v1/aggregator/sales/${id}/remit`, (route) => {
      bodies[id] = route.request().postDataJSON();
      const at = remaining.findIndex((s) => s.id === id);
      if (at >= 0) remaining.splice(at, 1);
      return route.fulfill({ status: 200, contentType: 'application/json', headers: CORS, body: '{}' });
    });
  }
  await page.goto('/aggregator/settlements');

  await page.locator('li').filter({ hasText: 'Buyer s1' }).getByRole('button', { name: 'Pay from wallet' }).click();
  await expect(page.getByText('Paid from your wallet')).toBeVisible();
  await page.locator('li').filter({ hasText: 'Buyer s2' }).getByRole('button', { name: 'Mark transferred' }).click();
  await expect(page.getByText('Marked as transferred')).toBeVisible();
  expect(bodies).toEqual({ s1: { via: 'wallet' }, s2: { via: 'bank' } });
});

test('with too little in the wallet the wallet route is off and says how much to add', async ({ page, baseURL }) => {
  await openSettlements(page, baseURL!, 5_000_000);
  await page.goto('/aggregator/settlements');

  const pay = page.locator('li').filter({ hasText: 'Buyer s1' }).getByRole('button', { name: 'Pay from wallet' });
  await expect(pay).toBeDisabled();
  await expect(pay).toHaveAttribute('title', 'Add ₹1,07,500 to your wallet first');
  // The bank route is still open.
  await expect(page.locator('li').filter({ hasText: 'Buyer s1' }).getByRole('button', { name: 'Mark transferred' })).toBeEnabled();
});
