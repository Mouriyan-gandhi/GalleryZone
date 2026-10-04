// Run: node --experimental-strip-types apps/api/src/amazon-product.check.ts
//
// The fixture copies the two shapes on a real amazon.in page that a naive
// parser gets wrong: data-csa-c-content-id="bylineInfo" appears before the
// real byline link, and the gallery is a JSON string inside A.$.parseJSON('...').

import assert from "node:assert/strict";
import { isAmazonUrl, parseAmazonProductPage } from "./amazon-product.ts";

const page = `
<div data-csa-c-content-id="bylineInfo"
     data-csa-c-slot-id="bylineInfo_feature_div">
  <a id="bylineInfo" class="a-link-normal" href="/s?k=ECLET">Brand: ECLET</a>
</div>
<div id="wayfinding-breadcrumbs_feature_div"><ul>
  <li><span><a class="a-link-normal" href="/b?node=1">Home &amp; Kitchen</a></span></li>
  <li><span>›</span></li>
  <li><span><a class="a-link-normal" href="/b?node=2">
     Paintbrush Sets
  </a></span></li>
</ul></div>
<span id="productTitle" class="a-size-large">   ECLET Set of 12 Brushes &amp; Palette   </span>
<input type="hidden" name="ASIN" value="B0CKW9P9Z7">
<script>
  'colorImages': { 'initial': A.$.parseJSON('[{"hiRes":"https://m.media-amazon.com/images/I/A1._SL1500_.jpg","large":"https://m.media-amazon.com/images/I/a1.jpg"},{"hiRes":"https://m.media-amazon.com/images/I/A2._SL1500_.jpg"},{"hiRes":"https://m.media-amazon.com/images/I/A1._SL1500_.jpg"}]')},
  'colorToAsin': {'initial': {}},
</script>
<script>var other = {"hiRes":"https://m.media-amazon.com/images/I/NOT-THIS-PRODUCT.jpg"};</script>
`;

const product = parseAmazonProductPage(page, "https://www.amazon.in/dp/B0CKW9P9Z7/ref=x?tag=galleryzone27-21");
assert.ok(product);
assert.equal(product.title, "ECLET Set of 12 Brushes & Palette");
assert.equal(product.brand, "ECLET");
assert.equal(product.asin, "B0CKW9P9Z7");
assert.deepEqual(product.categoryPath, ["Home & Kitchen", "Paintbrush Sets"]);
assert.deepEqual(product.images, [
  "https://m.media-amazon.com/images/I/A1._SL1500_.jpg",
  "https://m.media-amazon.com/images/I/A2._SL1500_.jpg",
]);

// At most two photos, cover first, even when the page has many.
const many = [1, 2, 3, 4, 5].map((i) => `{"hiRes":"https://m.media-amazon.com/images/I/P${i}._SL1500_.jpg"}`).join(",");
const capped = parseAmazonProductPage(`<span id="productTitle">T</span>'colorImages': { 'initial': A.$.parseJSON('[${many}]')}, 'colorToAsin': {}`, "https://www.amazon.in/dp/B000000001");
assert.deepEqual(capped?.images, ["https://m.media-amazon.com/images/I/P1._SL1500_.jpg", "https://m.media-amazon.com/images/I/P2._SL1500_.jpg"]);

// ASIN falls back to the hidden input when the final URL has no /dp/ segment.
assert.equal(parseAmazonProductPage(page, "https://www.amazon.in/gp/product")?.asin, "B0CKW9P9Z7");
// Numeric entities, as in a real title: Easel Size - 12&#34 (no semicolon).
assert.equal(
  parseAmazonProductPage(`<span id="productTitle">Easel Size - 12&#34 x 9&#x22;, Art &amp;lt;3</span>`, "https://www.amazon.in/dp/B000000001")?.title,
  'Easel Size - 12" x 9", Art &lt;3',
);
// A captcha page has no title: no product, not a half-filled one.
assert.equal(parseAmazonProductPage("<form action='/errors/validateCaptcha'>", "https://www.amazon.in/"), null);

// The lookup fetches only Amazon's own hosts, over https.
for (const ok of ["https://link.amazon/B011xih2K", "https://www.amazon.in/dp/B0CKW9P9Z7", "https://amzn.to/3abc", "https://amazon.com/dp/X"]) {
  assert.ok(isAmazonUrl(ok), ok);
}
for (const bad of ["http://www.amazon.in/dp/X", "https://amazon.in.evil.com/", "https://evilamazon.in/", "https://169.254.169.254/", "not a url"]) {
  assert.ok(!isAmazonUrl(bad), bad);
}

console.log("apps/api/amazon-product: parser and host allow-list hold");
