// Generated from `frontend-web/features/legal/data/cookies-sections.ts`, which is itself
// the port of production's copy. The wording is the company's: when it
// changes, re-port the web file rather than editing sentences here, or
// the two clients start quoting different terms.

import '../legal_section.dart';

const cookiesSections = <LegalSection>[
  LegalSection(
    id: 'overview',
    heading: 'Overview',
    body: [
      'GalleryZone uses a small number of cookies and browser storage entries to keep the site working and to remember your preferences. We do not run any analytics or advertising cookies today; the table below is a complete list, not a partial one.',
    ],
  ),
  LegalSection(
    id: 'cookie-categories',
    heading: 'Cookie Categories',
    body: [],
  ),
  LegalSection(
    id: 'managing-cookies',
    heading: 'Managing Cookies',
    body: [
      'Because the Essential category is required for sign-in and checkout security, it can\'t be turned off while still using GalleryZone. You can clear Functional data (theme preference and wishlist) at any time by clearing your browser\'s local storage for this site, or by asking us at galleryzone@zohomail.in.',
    ],
  ),
];

/// The `cookie-categories` section renders this table instead of body text.
const cookieCategories = <({String category, String examples, String purpose})>[
  (
    category: 'Essential',
    examples: 'Session cookie (httpOnly refresh token)',
    purpose: 'Keeps you signed in and secures your session. Required for the platform to function; it can\'t be disabled.',
  ),
  (
    category: 'Functional',
    examples: 'Theme preference, wishlist storage',
    purpose: 'Remembers your light/dark mode choice and the artworks you\'ve saved to your wishlist across visits.',
  ),
];
