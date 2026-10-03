import '../../models/artist.dart';
import '../../models/artwork.dart' show SocialProofLink, SocialProofPlatform;

/// Direct port of `frontend-web/lib/mock-data/artists.ts` — same 7 artists,
/// same ids, same bios, same verification-tier spread (kept in sync with
/// the web fixture on purpose; don't hand-edit one without the other).
List<ArtistProfile> seedArtists() => [
  const ArtistProfile(
    id: 'meera-nair',
    name: 'Meera Nair',
    bio:
        '<p>Meera paints the Tamil Nadu coastline in the hours just before and after monsoon rain, working almost entirely in oil on canvas. Her practice began after a decade in textile design, and it shows in the way she builds colour in layered washes rather than single strokes.</p><p>Every canvas ships with a signed Certificate of Authenticity and a linked process video, and she has been part of GalleryZone\'s verified artist community since its earliest cohort.</p>',
    profileImageUrl: '/early-program/avatar-1.png',
    verification: ArtistVerificationState(
      tier1SocialMedia: true,
      tier2ActivePlan: true,
      tier3FirstSale: true,
    ),
    socialLinks: [
      SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/meera.paints/'),
      SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/@meeranairart'),
    ],
  ),
  const ArtistProfile(
    id: 'arjun-mehta',
    name: 'Arjun Mehta',
    bio:
        '<p>Arjun works in reclaimed marble and cast bronze, drawing on four generations of stone-carving tradition in his family\'s workshop outside Jaipur. Each piece is hand-finished over several weeks, with no two ever repeated.</p><p>He documents the full process on video, from raw block to final polish, giving collectors a rare look at how the work is actually made. Fully verified on GalleryZone, with confirmed sales through both the open marketplace and partner aggregators.</p>',
    profileImageUrl: '/early-program/avatar-2.png',
    verification: ArtistVerificationState(
      tier1SocialMedia: true,
      tier2ActivePlan: true,
      tier3FirstSale: true,
    ),
    socialLinks: [
      SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/arjunmehta.sculpture/'),
      SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/@arjunmehtastudio'),
    ],
  ),
  const ArtistProfile(
    id: 'kavya-iyer',
    name: 'Kavya Iyer',
    bio:
        '<p>Kavya is a fine-art photographer working in limited-edition archival prints, documenting the single-screen cinemas of Bengaluru before they disappear. She shoots exclusively on film and hand-prints every edition in a small darkroom studio.</p><p>Newly listed on GalleryZone, with her Instagram linked for collectors who want to see new work as it\'s shot.</p>',
    profileImageUrl: '/early-program/avatar-4.png',
    verification: ArtistVerificationState(
      tier1SocialMedia: true,
      tier2ActivePlan: false,
      tier3FirstSale: false,
    ),
    socialLinks: [
      SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/kavya.frames/'),
    ],
  ),
  const ArtistProfile(
    id: 'rohan-bhattacharya',
    name: 'Rohan Bhattacharya',
    bio:
        '<p>Rohan is a printmaker working in linocut and etching, trained at the Government College of Art &amp; Craft in Kolkata. His editions draw on the city\'s tram lines, ferry ghats, and old-book markets, and are kept deliberately small.</p><p>He keeps an active GalleryZone plan and shares his studio process on social media, and is currently working toward his first confirmed sale on the platform.</p>',
    profileImageUrl: '/early-program/avatar-5.png',
    verification: ArtistVerificationState(
      tier1SocialMedia: true,
      tier2ActivePlan: true,
      tier3FirstSale: false,
    ),
    socialLinks: [
      SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/rohan.prints/'),
    ],
  ),
  const ArtistProfile(
    id: 'ananya-deshmukh',
    name: 'Ananya Deshmukh',
    bio:
        '<p>Ananya is a textile artist working in hand embroidery and natural-dye techniques she learned from her grandmother in rural Maharashtra, reinterpreted through contemporary wall-hung forms.</p><p>She joined GalleryZone this month and is completing her profile verification alongside her very first listings.</p>',
    profileImageUrl: '/ecosystem/avatar.png',
    verification: ArtistVerificationState(
      tier1SocialMedia: false,
      tier2ActivePlan: false,
      tier3FirstSale: false,
    ),
    socialLinks: [],
  ),
  const ArtistProfile(
    id: 'ishaan-kapoor',
    name: 'Ishaan Kapoor',
    bio:
        '<p>Ishaan is a self-taught painter working in acrylic and found pigment, exploring the density of Delhi\'s built environment through fractured, layered compositions.</p><p>He sold his first piece directly through the GalleryZone marketplace and has linked his YouTube channel, where he posts full studio sessions from blank canvas to finished work.</p>',
    profileImageUrl: '/early-program/avatar-3.png',
    verification: ArtistVerificationState(
      tier1SocialMedia: true,
      tier2ActivePlan: false,
      tier3FirstSale: true,
    ),
    socialLinks: [
      SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/@ishaankapoorstudio'),
    ],
  ),
  const ArtistProfile(
    id: 'priya-subramaniam',
    name: 'Priya Subramaniam',
    bio:
        '<p>Priya builds mixed-media wall sculptures from repurposed metal and pigment, working out of a studio collective in Hyderabad.</p><p>She keeps an active GalleryZone plan and has completed her first confirmed sale through a partner aggregator, and prefers to let the work speak for itself rather than maintain a public social presence.</p>',
    profileImageUrl: '/early-program/avatar-1.png',
    verification: ArtistVerificationState(
      tier1SocialMedia: false,
      tier2ActivePlan: true,
      tier3FirstSale: true,
    ),
    socialLinks: [],
  ),
];
