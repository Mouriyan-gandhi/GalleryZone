import { test, expect } from '@playwright/test';
import { androidFingerprints, buildAppleAppSiteAssociation, buildAssetLinks } from '../../lib/app-links';

// The two files that let a phone open a scanned tag's URL in the GalleryZone app
// (NFC_IMPLEMENTATION.md §7.6, §9.5). They carry the app's identity and nothing is invented:
// with no fingerprint or team configured they are served EMPTY, never guessed.

const SHA = 'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99';

test('assetlinks.json is empty until a signing fingerprint is configured', () => {
  expect(buildAssetLinks({})).toEqual([]);
  expect(buildAssetLinks({ ANDROID_APP_PACKAGE: 'in.galleryzone.app' })).toEqual([]);
  expect(buildAssetLinks({ ANDROID_APP_SHA256_FINGERPRINTS: 'not-a-fingerprint' })).toEqual([]);
});

test('assetlinks.json names the app and its signing key', () => {
  expect(buildAssetLinks({ ANDROID_APP_SHA256_FINGERPRINTS: SHA })).toEqual([
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: { namespace: 'android_app', package_name: 'in.galleryzone.app', sha256_cert_fingerprints: [SHA] },
    },
  ]);
  const custom = buildAssetLinks({ ANDROID_APP_PACKAGE: ' in.example.app ', ANDROID_APP_SHA256_FINGERPRINTS: SHA }) as { target: { package_name: string } }[];
  expect(custom[0]!.target.package_name).toBe('in.example.app');
});

test('fingerprints are normalised, and anything malformed is dropped rather than served', () => {
  const lower = SHA.toLowerCase();
  expect(androidFingerprints(`${lower}, ${SHA} ,nonsense, AA:BB`)).toEqual([SHA, SHA]);
  expect(androidFingerprints(undefined)).toEqual([]);
  expect(androidFingerprints('')).toEqual([]);
});

test('the iOS association is empty until a team id is configured, and claims only /verify/*', () => {
  expect(buildAppleAppSiteAssociation({})).toEqual({ applinks: { details: [] } });
  expect(buildAppleAppSiteAssociation({ IOS_APP_ID: 'in.galleryzone.galleryZone' })).toEqual({ applinks: { details: [] } }); // no team id
  expect(buildAppleAppSiteAssociation({ IOS_APP_ID: 'ABCDE12345.in.galleryzone.galleryZone' })).toEqual({
    applinks: { details: [{ appIDs: ['ABCDE12345.in.galleryzone.galleryZone'], components: [{ '/': '/verify/*' }] }] },
  });
});

test('both files are served as JSON at their fixed paths, cacheable for an hour, with no redirect', async ({ request, baseURL }) => {
  for (const path of ['/.well-known/assetlinks.json', '/.well-known/apple-app-site-association']) {
    const response = await request.get(path, { maxRedirects: 0 });
    expect(response.status(), path).toBe(200);
    expect(response.headers()['content-type'], path).toContain('application/json');
    expect(response.headers()['cache-control'], path).toContain('max-age=3600');
    expect(new URL(response.url()).pathname, path).toBe(path);
    expect(response.url().startsWith(baseURL!), path).toBe(true);
    await response.json(); // parses
  }
  const assetlinks = await (await request.get('/.well-known/assetlinks.json')).json();
  expect(Array.isArray(assetlinks)).toBe(true);
  const aasa = await (await request.get('/.well-known/apple-app-site-association')).json();
  expect(Array.isArray(aasa.applinks.details)).toBe(true);
});
