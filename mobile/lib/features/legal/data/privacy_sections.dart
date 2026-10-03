// Generated from `frontend-web/features/legal/data/privacy-sections.ts`, which is itself
// the port of production's copy. The wording is the company's: when it
// changes, re-port the web file rather than editing sentences here, or
// the two clients start quoting different terms.

import '../legal_section.dart';

const privacySections = <LegalSection>[
  LegalSection(
    id: 'information-we-collect',
    heading: 'Information We Collect',
    body: [
      'Identity & KYC documents: for artists, this includes a government ID, a signature sample, and Aadhaar number submitted during onboarding. Your Aadhaar number is encrypted at rest and is never exposed through any API. Only your verification status (verified / not verified) is ever visible, including to GalleryZone staff.',
      'Artist profile & social accounts: your artist bio and portfolio details, and any social media profiles you choose to link (Instagram, Facebook, YouTube, X, TikTok) as part of artist verification.',
      'Bank account details: collected to pay out artist settlements and aggregator commissions. Your account number is stored masked (shown as, for example, XXXXXXXX1234) everywhere in the product; the full number is only used transiently at the moment a withdrawal is actually processed.',
      'Contact & address details: your name, email, phone number, and any delivery addresses you save for orders or shipments.',
      'Browsing and wishlist activity: which artworks and artists you view and save, used to keep your wishlist in sync and to show you more relevant work.',
    ],
  ),
  LegalSection(
    id: 'how-we-use-it',
    heading: 'How We Use It',
    body: [
      'To operate your account: authenticating you, verifying artist and aggregator eligibility, processing sales, settlements, and withdrawals, and fulfilling shipments.',
      'To communicate with you: order confirmations, settlement statements, verification status updates, and security notices.',
      'To improve the platform: understanding which artworks and categories collectors engage with, so search, recommendations, and curation get better over time.',
    ],
  ),
  LegalSection(
    id: 'who-we-share-it-with',
    heading: 'Who We Share It With',
    body: [
      'Payment gateway: to process payments, settlements, and refunds. GalleryZone does not store your full card or payment credentials.',
      'Resend: our transactional email provider, used to deliver account, order, and settlement emails.',
      'Sentry: our error-monitoring provider, used to detect and diagnose bugs. Sentry receives technical error data, not your KYC or payment details.',
      'HDFC ERGO: our transit-insurance partner, only for shipments where you\'ve opted into transit insurance.',
      'We do not sell your personal information to third parties.',
    ],
  ),
  LegalSection(
    id: 'data-retention',
    heading: 'Data Retention',
    body: [
      'We retain account, transaction, and settlement records for as long as your account is active and for a reasonable period after closure, as needed to meet legal, tax, and accounting obligations. Encrypted KYC data is retained only as long as required to maintain your verification status.',
    ],
  ),
  LegalSection(
    id: 'your-rights',
    heading: 'Your Rights',
    body: [
      'You can request access to the personal information we hold about you, ask us to correct inaccurate details, or request deletion of your account and associated data, subject to what we\'re legally required to retain (such as completed transaction records).',
      'To exercise any of these rights, contact us using the details below.',
    ],
  ),
  LegalSection(
    id: 'contact',
    heading: 'Contact',
    body: [
      'Questions about this Privacy Policy, or requests relating to your personal data, can be sent to galleryzone@zohomail.in.',
    ],
  ),
];
