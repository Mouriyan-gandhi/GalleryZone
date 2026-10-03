import '../../models/artist.dart';
import '../../models/artwork.dart';
import 'artists_seed.dart';

/// Direct port of `frontend-web/lib/mock-data/artworks.ts` — same 26
/// artworks, same ids/prices/descriptions, same status/listing-type spread.
/// Kept in sync with the web fixture on purpose; don't hand-edit one
/// without the other. `_today` is the same fixed anchor the web source
/// uses, not a live clock — every `changedAt` must stay reproducible.
final _today = DateTime.utc(2026, 8, 11);

String _daysAgo(int days) => _today.subtract(Duration(days: days)).toIso8601String();

List<ArtworkStatusEvent> _history(List<(ArtworkStatus, int)> entries) => entries
    .map((e) => ArtworkStatusEvent(status: e.$1, changedAt: _daysAgo(e.$2)))
    .toList();

class _Img {
  static const bird = '/artworks/bird.png';
  static const busts = '/artworks/collage-busts.png';
  static const drape = '/artworks/draped-figure.png';
  static const pyramid = '/artworks/eye-pyramid.png';
  static const framed = '/artworks/framed-painting.png';
  static const landscape = '/artworks/landscape.png';
  static const portrait = '/artworks/portrait-woman.png';
  static const eco1 = '/ecosystem/artwork-1.png';
  static const eco2 = '/ecosystem/artwork-2.png';
  static const eco3 = '/ecosystem/artwork-3.png';
  static const journey = '/journey/artwork-preview.png';
  static const idPaint = '/identity/painting.png';
}

const _stageLabels = [
  'cover image',
  'detail of surface texture',
  'signature close-up',
  'scale reference against the gallery wall',
  'alternate angle',
  'studio lighting detail',
  'framing and edge detail',
  'full view in natural light',
];

List<ArtworkImage> _images(String title, List<String> files) => [
  for (var i = 0; i < files.length; i++)
    ArtworkImage(
      url: files[i],
      thumbnailUrl: files[i],
      sortOrder: i,
      altText: '$title, ${i < _stageLabels.length ? _stageLabels[i] : "detail view ${i + 1}"}',
    ),
];

({String artistName, bool verifiedArtist}) _artistMeta(String artistId) {
  final artist = seedArtists().firstWhere(
    (a) => a.id == artistId,
    orElse: () => throw StateError('mock-data/artworks: unknown artistId "$artistId"'),
  );
  return (artistName: artist.name, verifiedArtist: verifiedTierCount(artist.verification) > 0);
}

List<Artwork> seedArtworks() {
  final meeraNair = _artistMeta('meera-nair');
  final arjunMehta = _artistMeta('arjun-mehta');
  final kavyaIyer = _artistMeta('kavya-iyer');
  final rohanBhattacharya = _artistMeta('rohan-bhattacharya');
  final ananyaDeshmukh = _artistMeta('ananya-deshmukh');
  final ishaanKapoor = _artistMeta('ishaan-kapoor');
  final priyaSubramaniam = _artistMeta('priya-subramaniam');

  return [
    // --- Meera Nair (Gold, painting) ------------------------------------
    Artwork(
      id: 'monsoon-over-madurai',
      title: 'Monsoon Over Madurai',
      artistId: 'meera-nair',
      artistName: meeraNair.artistName,
      verifiedArtist: meeraNair.verifiedArtist,
      category: 'painting',
      medium: 'Oil on Canvas',
      customerPrice: 23400,
      thumbnailUrl: _Img.landscape,
      insured: true,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceOnly,
      description:
          'Painted over three sittings during the 2025 monsoon, this canvas builds the Madurai coastline in layered oil washes, working wet-into-wet to catch the exact grey-gold light that appears just as the rain breaks. The palette-knife work in the foreground surf is left deliberately raw against the smoother sky. Ships with a signed Certificate of Authenticity and a linked studio video of the final varnishing pass.',
      dimensions: '24x36 in',
      yearCreated: 2025,
      images: _images('Monsoon Over Madurai', [_Img.landscape, _Img.framed, _Img.journey, _Img.idPaint]),
      coaCertificateNumber: 'GZ-COA-2026-0001',
      coaIssueDate: _daysAgo(199),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-monsoon-madurai/'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 210),
        (ArtworkStatus.pendingApproval, 204),
        (ArtworkStatus.marketplace, 196),
      ]),
    ),
    Artwork(
      id: 'backwater-light-early-hours',
      title: 'Backwater Light, Early Hours',
      artistId: 'meera-nair',
      artistName: meeraNair.artistName,
      verifiedArtist: meeraNair.verifiedArtist,
      category: 'painting',
      medium: 'Oil on Canvas',
      customerPrice: 19500,
      thumbnailUrl: _Img.framed,
      insured: false,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceOnly,
      description:
          "A quieter companion to Meera's coastal series, painted at first light on the Kerala backwaters before the water traffic begins. Built in thin, transparent oil glazes over a warm underpainting so the canvas grain shows through in the shadow passages. Unframed and ready to hang, signed and dated on the reverse.",
      dimensions: '20x30 in',
      yearCreated: 2026,
      images: _images('Backwater Light, Early Hours', [_Img.framed, _Img.landscape, _Img.eco1]),
      coaCertificateNumber: 'GZ-COA-2026-0002',
      coaIssueDate: _daysAgo(141),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-backwater-light'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 150),
        (ArtworkStatus.pendingApproval, 145),
        (ArtworkStatus.marketplace, 138),
      ]),
    ),
    Artwork(
      id: 'tide-line-dusk',
      title: 'Tide Line, Dusk',
      artistId: 'meera-nair',
      artistName: meeraNair.artistName,
      verifiedArtist: meeraNair.verifiedArtist,
      category: 'painting',
      medium: 'Oil on Canvas',
      customerPrice: 27800,
      thumbnailUrl: _Img.idPaint,
      insured: true,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          "One of the earliest paintings in Meera's current coastal body of work, revisiting a stretch of shoreline she has returned to for three years running. The tideline itself is built up in a heavier impasto than the rest of the canvas, marking where land and water meet. Eligible for gallery display through GalleryZone's aggregator network as well as direct marketplace sale.",
      dimensions: '18x24 in',
      yearCreated: 2024,
      images: _images('Tide Line, Dusk', [_Img.idPaint, _Img.landscape, _Img.framed, _Img.eco2, _Img.journey]),
      coaCertificateNumber: 'GZ-COA-2026-0003',
      coaIssueDate: _daysAgo(85),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-tide-line-dusk/'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 95),
        (ArtworkStatus.pendingApproval, 90),
        (ArtworkStatus.marketplace, 82),
      ]),
    ),

    // --- Arjun Mehta (Gold, sculpture) -----------------------------------
    Artwork(
      id: 'ancestral-bronze-study',
      title: 'Ancestral Bronze Study',
      artistId: 'arjun-mehta',
      artistName: arjunMehta.artistName,
      verifiedArtist: arjunMehta.verifiedArtist,
      category: 'sculpture',
      medium: 'Cast Bronze',
      customerPrice: 128000,
      thumbnailUrl: _Img.busts,
      insured: true,
      status: ArtworkStatus.reserved,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          "Cast using the lost-wax method in Arjun's family workshop, this study reworks a seated-figure motif that recurs across four generations of his family's carving practice. The bronze is left in its natural patina rather than polished, so the surface will keep shifting tone over years of handling. Currently reserved through a partner aggregator ahead of gallery display.",
      dimensions: '18 in H x 9 in W x 7 in D',
      yearCreated: 2025,
      images: _images('Ancestral Bronze Study', [_Img.busts, _Img.drape, _Img.pyramid, _Img.eco3, _Img.bird, _Img.portrait]),
      coaCertificateNumber: 'GZ-COA-2026-0004',
      coaIssueDate: _daysAgo(128),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-ancestral-bronze'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 140),
        (ArtworkStatus.pendingApproval, 133),
        (ArtworkStatus.marketplace, 125),
        (ArtworkStatus.reserved, 5),
      ]),
    ),
    Artwork(
      id: 'carved-marble-torso',
      title: 'Carved Marble Torso',
      artistId: 'arjun-mehta',
      artistName: arjunMehta.artistName,
      verifiedArtist: arjunMehta.verifiedArtist,
      category: 'sculpture',
      medium: 'Carved Marble',
      customerPrice: 149000,
      thumbnailUrl: _Img.drape,
      insured: true,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceOnly,
      description:
          'A single block of Makrana marble, carved entirely by hand over four months with no mechanical finishing on the final surface passes. The torso form continues a study Arjun has returned to several times, each version testing a different balance of rough-cut and polished stone. Base included.',
      dimensions: '22 in H x 10 in W x 8 in D',
      yearCreated: 2023,
      images: _images('Carved Marble Torso', [_Img.drape, _Img.busts, _Img.pyramid, _Img.eco1]),
      coaCertificateNumber: 'GZ-COA-2026-0005',
      coaIssueDate: _daysAgo(284),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-marble-torso/'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 300),
        (ArtworkStatus.pendingApproval, 292),
        (ArtworkStatus.marketplace, 280),
      ]),
    ),
    Artwork(
      id: 'reclaimed-stone-vessel',
      title: 'Reclaimed Stone Vessel',
      artistId: 'arjun-mehta',
      artistName: arjunMehta.artistName,
      verifiedArtist: arjunMehta.verifiedArtist,
      category: 'sculpture',
      medium: 'Reclaimed Sandstone',
      customerPrice: 68500,
      thumbnailUrl: _Img.busts,
      insured: true,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceOnly,
      description:
          'Carved from a single salvaged sandstone block sourced from a demolished haveli near Jaipur, this vessel form keeps the weathering and tool marks of the original stone visible along its base. Arjun finishes each vessel with a hand-rubbed wax seal rather than a synthetic coating, so the surface will darken naturally with handling.',
      dimensions: '14 in H x 12 in diameter',
      yearCreated: 2025,
      images: _images('Reclaimed Stone Vessel', [_Img.busts, _Img.drape, _Img.eco2]),
      coaCertificateNumber: 'GZ-COA-2026-0006',
      coaIssueDate: _daysAgo(50),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-stone-vessel'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 60),
        (ArtworkStatus.pendingApproval, 55),
        (ArtworkStatus.marketplace, 47),
      ]),
    ),

    // --- Kavya Iyer (tier1 only, photography) ----------------------------
    Artwork(
      id: 'last-show-at-metro-talkies',
      title: 'Last Show at Metro Talkies',
      artistId: 'kavya-iyer',
      artistName: kavyaIyer.artistName,
      verifiedArtist: kavyaIyer.verifiedArtist,
      category: 'photography',
      medium: 'Archival Pigment Print',
      customerPrice: 12800,
      thumbnailUrl: _Img.portrait,
      insured: false,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceOnly,
      description:
          'Shot on medium-format film on the final night Metro Talkies screened a film before closing for good, printed as edition 2 of 9 on archival cotton rag paper. Kavya hand-processes every negative herself and scans at high resolution before printing, so grain and tonal range stay true to the original film stock. Signed and numbered on the reverse.',
      dimensions: '16x20 in',
      yearCreated: 2026,
      images: _images('Last Show at Metro Talkies', [_Img.portrait, _Img.bird, _Img.eco3, _Img.journey]),
      coaCertificateNumber: 'GZ-COA-2026-0007',
      coaIssueDate: _daysAgo(33),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-metro-talkies/'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 40),
        (ArtworkStatus.pendingApproval, 36),
        (ArtworkStatus.marketplace, 30),
      ]),
    ),
    Artwork(
      id: 'balcony-seats-empty-reel',
      title: 'Balcony Seats, Empty Reel',
      artistId: 'kavya-iyer',
      artistName: kavyaIyer.artistName,
      verifiedArtist: kavyaIyer.verifiedArtist,
      category: 'photography',
      medium: 'Archival Pigment Print',
      customerPrice: 16400,
      thumbnailUrl: _Img.bird,
      insured: true,
      status: ArtworkStatus.reserved,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          "Part of Kavya's ongoing series on Bengaluru's disappearing single-screen cinemas, this print looks down from an empty balcony section onto a projector booth mid reel-change. Edition of 9, printed on archival cotton rag paper from a hand-processed medium-format negative. Currently on reserve for gallery display.",
      dimensions: '20x24 in',
      yearCreated: 2026,
      images: _images('Balcony Seats, Empty Reel', [_Img.bird, _Img.portrait, _Img.eco1]),
      coaCertificateNumber: 'GZ-COA-2026-0008',
      coaIssueDate: _daysAgo(23),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-balcony-seats/'),
        SocialProofLink(platform: SocialProofPlatform.x, url: 'https://x.com/kavyaiyerphoto/status/1234567890123456789'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 30),
        (ArtworkStatus.pendingApproval, 25),
        (ArtworkStatus.marketplace, 20),
        (ArtworkStatus.reserved, 18),
      ]),
    ),

    // --- Rohan Bhattacharya (tier1+tier2, printmaking) -------------------
    Artwork(
      id: 'howrah-line-evening',
      title: 'Howrah Line, Evening',
      artistId: 'rohan-bhattacharya',
      artistName: rohanBhattacharya.artistName,
      verifiedArtist: rohanBhattacharya.verifiedArtist,
      category: 'printmaking',
      medium: 'Linocut on Paper',
      customerPrice: 8400,
      thumbnailUrl: _Img.pyramid,
      insured: false,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceOnly,
      description:
          'A hand-pulled linocut of the evening commuter rush along the Howrah line, cut and printed in a single run of eighteen. Rohan carves each block himself and prints on a hand-cranked proofing press using water-based ink, which keeps the line work crisp without the sheen of oil-based printing. Numbered 6/18.',
      dimensions: '12x16 in',
      yearCreated: 2026,
      images: _images('Howrah Line, Evening', [_Img.pyramid, _Img.busts, _Img.eco2]),
      coaCertificateNumber: 'GZ-COA-2026-0009',
      coaIssueDate: _daysAgo(63),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-howrah-line/'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 70),
        (ArtworkStatus.pendingApproval, 66),
        (ArtworkStatus.marketplace, 60),
      ]),
    ),
    Artwork(
      id: 'ghat-steps-no-7',
      title: 'Ghat Steps No. 7',
      artistId: 'rohan-bhattacharya',
      artistName: rohanBhattacharya.artistName,
      verifiedArtist: rohanBhattacharya.verifiedArtist,
      category: 'printmaking',
      medium: 'Etching on Paper',
      customerPrice: 11600,
      thumbnailUrl: _Img.pyramid,
      insured: false,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          'The seventh in an ongoing series studying the ferry ghats of the Hooghly at different times of day, etched on a copper plate and hand-inked for each pull. This impression uses a heavier plate tone than earlier editions in the series, pushing the steps further into shadow. Eligible for aggregator display alongside its marketplace listing.',
      dimensions: '14x18 in',
      yearCreated: 2025,
      images: _images('Ghat Steps No. 7', [_Img.pyramid, _Img.eco3, _Img.busts, _Img.journey]),
      coaCertificateNumber: 'GZ-COA-2026-0010',
      coaIssueDate: _daysAgo(89),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-ghat-steps'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 100),
        (ArtworkStatus.pendingApproval, 94),
        (ArtworkStatus.marketplace, 86),
      ]),
    ),
    Artwork(
      id: 'college-street-folio',
      title: 'College Street Folio',
      artistId: 'rohan-bhattacharya',
      artistName: rohanBhattacharya.artistName,
      verifiedArtist: rohanBhattacharya.verifiedArtist,
      category: 'printmaking',
      medium: 'Linocut on Paper',
      customerPrice: 14200,
      thumbnailUrl: _Img.busts,
      insured: true,
      status: ArtworkStatus.reserved,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          "A four-colour linocut built from Rohan's sketches of the second-hand book stalls along College Street, printed in four separate registered passes. Each colour block was hand-cut and aligned individually, so slight registration variation between prints in the edition is expected and part of the process. Currently on reserve for gallery display.",
      dimensions: '16x20 in',
      yearCreated: 2026,
      images: _images('College Street Folio', [_Img.busts, _Img.pyramid, _Img.eco1]),
      coaCertificateNumber: 'GZ-COA-2026-0011',
      coaIssueDate: _daysAgo(41),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-college-street/'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 50),
        (ArtworkStatus.pendingApproval, 45),
        (ArtworkStatus.marketplace, 38),
        (ArtworkStatus.reserved, 24),
      ]),
    ),

    // --- Ananya Deshmukh (zero tiers, textile art) ------------------------
    Artwork(
      id: 'field-of-kusum-dye',
      title: 'Field of Kusum Dye',
      artistId: 'ananya-deshmukh',
      artistName: ananyaDeshmukh.artistName,
      verifiedArtist: ananyaDeshmukh.verifiedArtist,
      category: 'textile art',
      medium: 'Hand Embroidery on Cotton, Natural Dye',
      customerPrice: 10400,
      thumbnailUrl: _Img.drape,
      insured: false,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceOnly,
      description:
          'A wall-hung textile piece hand-embroidered on handwoven cotton, dyed using kusum flower and iron-mordant baths mixed in small batches. Ananya draws the design directly onto the cloth freehand before stitching, so no two pieces in this series share an identical layout. Comes with a fabric-care card and a wooden hanging dowel.',
      dimensions: '22x30 in',
      yearCreated: 2026,
      images: _images('Field of Kusum Dye', [_Img.drape, _Img.eco2, _Img.journey]),
      coaCertificateNumber: 'GZ-COA-2026-0012',
      coaIssueDate: _daysAgo(13),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-kusum-dye/'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 20),
        (ArtworkStatus.pendingApproval, 16),
        (ArtworkStatus.marketplace, 10),
      ]),
    ),
    Artwork(
      id: 'grandmothers-stitch-revisited',
      title: "Grandmother's Stitch, Revisited",
      artistId: 'ananya-deshmukh',
      artistName: ananyaDeshmukh.artistName,
      verifiedArtist: ananyaDeshmukh.verifiedArtist,
      category: 'textile art',
      medium: 'Hand Embroidery on Cotton, Natural Dye',
      customerPrice: 13900,
      thumbnailUrl: _Img.drape,
      insured: false,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceOnly,
      description:
          "Ananya's largest piece to date, reworking a border-stitch pattern her grandmother taught her as a continuous field across the full canvas rather than a framing edge. Every dye bath in this piece was mixed from marigold and pomegranate rind sourced from her family's own kitchen garden. Her first major listing on GalleryZone.",
      dimensions: '24x36 in',
      yearCreated: 2026,
      images: _images("Grandmother's Stitch, Revisited", [_Img.drape, _Img.journey, _Img.eco3, _Img.idPaint]),
      coaCertificateNumber: 'GZ-COA-2026-0013',
      coaIssueDate: _daysAgo(9),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-grandmothers-stitch'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 15),
        (ArtworkStatus.pendingApproval, 12),
        (ArtworkStatus.marketplace, 6),
      ]),
    ),

    // --- Ishaan Kapoor (tier1+tier3, painting) ----------------------------
    Artwork(
      id: 'concrete-bloom',
      title: 'Concrete Bloom',
      artistId: 'ishaan-kapoor',
      artistName: ishaanKapoor.artistName,
      verifiedArtist: ishaanKapoor.verifiedArtist,
      category: 'painting',
      medium: 'Acrylic on Canvas',
      customerPrice: 21600,
      thumbnailUrl: _Img.framed,
      insured: true,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceOnly,
      description:
          "Built up in thin acrylic layers over several weeks, this canvas fractures a stairwell in Ishaan's own apartment block into overlapping planes of colour until the architecture starts to read as botanical. He works without preparatory sketches, building the composition directly on the canvas and painting out sections that don't hold. Full studio session filmed start to finish.",
      dimensions: '30x30 in',
      yearCreated: 2026,
      images: _images('Concrete Bloom', [_Img.framed, _Img.landscape, _Img.eco1, _Img.journey, _Img.bird]),
      coaCertificateNumber: 'GZ-COA-2026-0014',
      coaIssueDate: _daysAgo(69),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-concrete-bloom'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 80),
        (ArtworkStatus.pendingApproval, 74),
        (ArtworkStatus.marketplace, 66),
      ]),
    ),
    Artwork(
      id: 'fractured-skyline',
      title: 'Fractured Skyline',
      artistId: 'ishaan-kapoor',
      artistName: ishaanKapoor.artistName,
      verifiedArtist: ishaanKapoor.verifiedArtist,
      category: 'painting',
      medium: 'Acrylic on Canvas',
      customerPrice: 34500,
      thumbnailUrl: _Img.landscape,
      insured: true,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceOnly,
      description:
          "Ishaan's largest canvas to date, breaking the Delhi skyline seen from his studio window into a grid of overlapping vantage points painted in separate sessions and reassembled as one composition. The underlying pencil grid is still faintly visible beneath the paint in several passages, left intentionally. Ships stretched and ready to hang.",
      dimensions: '36x48 in',
      yearCreated: 2025,
      images: _images('Fractured Skyline', [_Img.landscape, _Img.framed, _Img.eco2, _Img.journey, _Img.idPaint, _Img.bird]),
      coaCertificateNumber: 'GZ-COA-2026-0015',
      coaIssueDate: _daysAgo(109),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-fractured-skyline'),
        SocialProofLink(platform: SocialProofPlatform.tiktok, url: 'https://www.tiktok.com/@ishaankapoorstudio/video/7345678901234567890'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 120),
        (ArtworkStatus.pendingApproval, 114),
        (ArtworkStatus.marketplace, 105),
      ]),
    ),
    Artwork(
      id: 'density-study-karol-bagh',
      title: 'Density Study, Karol Bagh',
      artistId: 'ishaan-kapoor',
      artistName: ishaanKapoor.artistName,
      verifiedArtist: ishaanKapoor.verifiedArtist,
      category: 'painting',
      medium: 'Acrylic on Canvas',
      customerPrice: 26200,
      thumbnailUrl: _Img.framed,
      insured: true,
      status: ArtworkStatus.reserved,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          'A study of the wholesale market lanes in Karol Bagh at closing time, built from overlapping fractured planes in a tighter, more restrained palette than Ishaan\'s larger canvases. Painted directly from memory the same evening rather than from photographs. Currently on reserve for gallery display.',
      dimensions: '24x30 in',
      yearCreated: 2026,
      images: _images('Density Study, Karol Bagh', [_Img.framed, _Img.eco3, _Img.landscape]),
      coaCertificateNumber: 'GZ-COA-2026-0016',
      coaIssueDate: _daysAgo(41),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-density-study/'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 52),
        (ArtworkStatus.pendingApproval, 46),
        (ArtworkStatus.marketplace, 38),
        (ArtworkStatus.reserved, 28),
      ]),
    ),

    // --- Priya Subramaniam (tier2+tier3, mixed media) ---------------------
    Artwork(
      id: 'rust-and-ochre-wall-piece',
      title: 'Rust and Ochre Wall Piece',
      artistId: 'priya-subramaniam',
      artistName: priyaSubramaniam.artistName,
      verifiedArtist: priyaSubramaniam.verifiedArtist,
      category: 'mixed media',
      medium: 'Repurposed Metal and Pigment on Panel',
      customerPrice: 58000,
      thumbnailUrl: _Img.busts,
      insured: true,
      status: ArtworkStatus.reserved,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          "Built from sheet-metal offcuts sourced from a scrapyard near her studio collective, welded to a plywood panel and finished with layered pigment and controlled oxidation. Priya lets the metal rust naturally over several weeks under wet cloths before sealing the surface, so the final colour is never fully predictable. Currently on reserve for gallery display.",
      dimensions: '30 in H x 40 in W x 4 in D',
      yearCreated: 2025,
      images: _images('Rust and Ochre Wall Piece', [_Img.busts, _Img.pyramid, _Img.eco1, _Img.drape]),
      coaCertificateNumber: 'GZ-COA-2026-0017',
      coaIssueDate: _daysAgo(35),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-rust-ochre'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 45),
        (ArtworkStatus.pendingApproval, 40),
        (ArtworkStatus.marketplace, 32),
        (ArtworkStatus.reserved, 12),
      ]),
    ),
    Artwork(
      id: 'salvaged-frequencies',
      title: 'Salvaged Frequencies',
      artistId: 'priya-subramaniam',
      artistName: priyaSubramaniam.artistName,
      verifiedArtist: priyaSubramaniam.verifiedArtist,
      category: 'mixed media',
      medium: 'Repurposed Metal and Pigment on Panel',
      customerPrice: 44500,
      thumbnailUrl: _Img.busts,
      insured: true,
      status: ArtworkStatus.sold,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          "An earlier, smaller panel in Priya's welded-metal series, built around a cut radio dial salvaged from a decommissioned workshop. The pigment layer was applied in three separate sessions to let each coat oxidize the metal differently before the next. Sold through a partner aggregator; settlement in progress.",
      dimensions: '24 in H x 32 in W x 3 in D',
      yearCreated: 2024,
      images: _images('Salvaged Frequencies', [
        _Img.busts,
        _Img.pyramid,
        _Img.drape,
        _Img.eco2,
        _Img.eco3,
        _Img.journey,
        _Img.bird,
        _Img.portrait,
      ]),
      coaCertificateNumber: 'GZ-COA-2026-0018',
      coaIssueDate: _daysAgo(150),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-salvaged-frequencies/'),
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-salvaged-frequencies'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 160),
        (ArtworkStatus.pendingApproval, 154),
        (ArtworkStatus.marketplace, 146),
        (ArtworkStatus.reserved, 37),
        (ArtworkStatus.sold, 10),
      ]),
    ),

    // --- Reservable aggregator stock -------------------------------------
    // Eight pieces that exist purely so the Aggregator Portal's Inventory page
    // has something left to reserve. Everything above is either claimed by a
    // holding in aggregator_seed.dart or marketplace-only, which left the grid
    // with two cards and an empty state one tap later.
    //
    // All eight are aggregator-eligible, `marketplace` status and referenced by
    // no holding, so listReservableInventory() picks them up. They carry a real
    // `physical` block because MOU §12 governs anything sent for aggregator
    // display — framed or stretched, hangers included, packed to standard.
    Artwork(
      id: 'terrace-garden-after-rain',
      title: 'Terrace Garden, After Rain',
      artistId: 'meera-nair',
      artistName: meeraNair.artistName,
      verifiedArtist: meeraNair.verifiedArtist,
      category: 'painting',
      medium: 'Oil on Canvas',
      customerPrice: 26600,
      thumbnailUrl: _Img.landscape,
      insured: true,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          'A rooftop in Fort Kochi an hour after the rain stops, when the water still standing in the planters throws the sky back up at the wall. Built in thin oil glazes so the white of the ground keeps coming through the greens, with the puddles scraped back rather than painted in.',
      dimensions: '30x40 in',
      yearCreated: 2026,
      images: _images('Terrace Garden, After Rain', [_Img.landscape, _Img.framed, _Img.journey]),
      coaCertificateNumber: 'GZ-COA-2026-0019',
      coaIssueDate: _daysAgo(41),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-terrace-garden/'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 52),
        (ArtworkStatus.pendingApproval, 47),
        (ArtworkStatus.marketplace, 41),
      ]),
      physical: const ArtworkPhysical(
        weightKg: 4.2,
        framing: FramingState.framed,
        format: 'Canvas on stretcher, teak frame',
        hangingHardwareIncluded: true,
        packagingConfirmed: true,
      ),
    ),
    Artwork(
      id: 'weight-of-a-quiet-room',
      title: 'Weight of a Quiet Room',
      artistId: 'arjun-mehta',
      artistName: arjunMehta.artistName,
      verifiedArtist: arjunMehta.verifiedArtist,
      category: 'sculpture',
      medium: 'Cast Bronze',
      customerPrice: 84500,
      thumbnailUrl: _Img.busts,
      insured: true,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          'A seated figure reduced to the three planes that still read as a person from across a room. Sand-cast in a single pour, then worked back by hand at the shoulders so the tool marks stay visible under the patina. Supplied on a machined steel base.',
      dimensions: '18x11x14 in',
      yearCreated: 2025,
      images: _images('Weight of a Quiet Room', [_Img.busts, _Img.drape, _Img.eco1, _Img.portrait]),
      coaCertificateNumber: 'GZ-COA-2026-0020',
      coaIssueDate: _daysAgo(63),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-quiet-room/'),
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-quiet-room-pour'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 78),
        (ArtworkStatus.pendingApproval, 71),
        (ArtworkStatus.marketplace, 63),
      ]),
      physical: const ArtworkPhysical(
        weightKg: 16.5,
        framing: FramingState.freestanding,
        format: 'Bronze on steel base',
        hangingHardwareIncluded: false,
        packagingConfirmed: true,
      ),
    ),
    Artwork(
      id: 'platform-nine-first-light',
      title: 'Platform Nine, First Light',
      artistId: 'kavya-iyer',
      artistName: kavyaIyer.artistName,
      verifiedArtist: kavyaIyer.verifiedArtist,
      category: 'photography',
      medium: 'Archival Pigment Print',
      customerPrice: 18200,
      thumbnailUrl: _Img.framed,
      insured: false,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          'Shot at 5.40am from the far end of Platform Nine, waiting for the one minute when the station lights and the daylight are the same temperature and the whole shed goes flat. Printed on cotton rag in an edition of twelve, each one numbered on the reverse.',
      dimensions: '16x24 in',
      yearCreated: 2026,
      images: _images('Platform Nine, First Light', [_Img.framed, _Img.eco2, _Img.landscape]),
      coaCertificateNumber: 'GZ-COA-2026-0021',
      coaIssueDate: _daysAgo(29),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-platform-nine/'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 38),
        (ArtworkStatus.pendingApproval, 34),
        (ArtworkStatus.marketplace, 29),
      ]),
      physical: const ArtworkPhysical(
        weightKg: 2.1,
        framing: FramingState.framed,
        format: 'Cotton rag print, museum glass',
        hangingHardwareIncluded: true,
        packagingConfirmed: true,
      ),
    ),
    Artwork(
      id: 'letterpress-for-a-lost-street',
      title: 'Letterpress for a Lost Street',
      artistId: 'rohan-bhattacharya',
      artistName: rohanBhattacharya.artistName,
      verifiedArtist: rohanBhattacharya.verifiedArtist,
      category: 'printmaking',
      medium: 'Linocut on Paper',
      customerPrice: 15600,
      thumbnailUrl: _Img.pyramid,
      insured: false,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          "Cut from a single block after the shopfronts on the artist's own street were painted over in one weekend. The signage lettering is set from wood type salvaged from the press that used to print those shutters, so the piece is partly made of the thing it records.",
      dimensions: '14x20 in',
      yearCreated: 2025,
      images: _images('Letterpress for a Lost Street', [_Img.pyramid, _Img.eco3, _Img.framed]),
      coaCertificateNumber: 'GZ-COA-2026-0022',
      coaIssueDate: _daysAgo(55),
      socialProofLinks: const [],
      statusHistory: _history([
        (ArtworkStatus.draft, 66),
        (ArtworkStatus.pendingApproval, 61),
        (ArtworkStatus.marketplace, 55),
      ]),
      physical: const ArtworkPhysical(
        weightKg: 1.6,
        framing: FramingState.framed,
        format: 'Handmade paper, ash frame',
        hangingHardwareIncluded: true,
        packagingConfirmed: true,
      ),
    ),
    Artwork(
      id: 'kantha-in-three-registers',
      title: 'Kantha in Three Registers',
      artistId: 'ananya-deshmukh',
      artistName: ananyaDeshmukh.artistName,
      verifiedArtist: ananyaDeshmukh.verifiedArtist,
      category: 'textile art',
      medium: 'Hand Embroidery on Cotton, Natural Dye',
      customerPrice: 32400,
      thumbnailUrl: _Img.drape,
      insured: true,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.aggregatorOnly,
      description:
          'Three bands of running stitch worked at three different densities across a single dyed field, so the cloth reads as one surface from a distance and as three separate weathers up close. Roughly four months of stitching, in madder, indigo and pomegranate rind.',
      dimensions: '36x48 in',
      yearCreated: 2025,
      images: _images('Kantha in Three Registers', [_Img.drape, _Img.eco1, _Img.portrait]),
      coaCertificateNumber: 'GZ-COA-2026-0023',
      coaIssueDate: _daysAgo(35),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-kantha-registers/'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 45),
        (ArtworkStatus.pendingApproval, 40),
        (ArtworkStatus.marketplace, 35),
      ]),
      physical: const ArtworkPhysical(
        weightKg: 3.4,
        framing: FramingState.stretchedCanvas,
        format: 'Cotton stretched on a hardwood frame',
        hangingHardwareIncluded: true,
        packagingConfirmed: true,
      ),
    ),
    Artwork(
      id: 'signal-loss-diptych',
      title: 'Signal Loss (Diptych)',
      artistId: 'priya-subramaniam',
      artistName: priyaSubramaniam.artistName,
      verifiedArtist: priyaSubramaniam.verifiedArtist,
      category: 'mixed media',
      medium: 'Repurposed Metal and Pigment on Panel',
      customerPrice: 47800,
      thumbnailUrl: _Img.eco2,
      insured: true,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          'Two panels built from the housings of dead television sets, flattened, primed and worked over in dry pigment until the seams of the original casing come back through. Hung as a pair with a fixed four-inch gap, which is part of the work rather than a display note.',
      dimensions: '24x36 in (each panel)',
      yearCreated: 2026,
      images: _images('Signal Loss (Diptych)', [_Img.eco2, _Img.eco3, _Img.pyramid, _Img.busts]),
      coaCertificateNumber: 'GZ-COA-2026-0024',
      coaIssueDate: _daysAgo(22),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-signal-loss-build'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 31),
        (ArtworkStatus.pendingApproval, 27),
        (ArtworkStatus.marketplace, 22),
      ]),
      physical: const ArtworkPhysical(
        weightKg: 11.8,
        framing: FramingState.mountedBoard,
        format: 'Metal and pigment on birch panel',
        hangingHardwareIncluded: true,
        packagingConfirmed: true,
      ),
    ),
    Artwork(
      id: 'noon-heat-chettinad',
      title: 'Noon Heat, Chettinad',
      artistId: 'ishaan-kapoor',
      artistName: ishaanKapoor.artistName,
      verifiedArtist: ishaanKapoor.verifiedArtist,
      category: 'painting',
      medium: 'Acrylic on Canvas',
      customerPrice: 96200,
      thumbnailUrl: _Img.idPaint,
      insured: true,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.marketplaceAndAggregator,
      description:
          'The largest canvas in this series, and the one that gave up its horizon: a courtyard at the hour when the light is so flat that the walls, the floor and the sky all resolve to the same value. Painted in acrylic for the speed, then knocked back with a dry brush over four weeks.',
      dimensions: '48x60 in',
      yearCreated: 2026,
      images: _images('Noon Heat, Chettinad', [_Img.idPaint, _Img.landscape, _Img.framed, _Img.journey]),
      coaCertificateNumber: 'GZ-COA-2026-0025',
      coaIssueDate: _daysAgo(17),
      socialProofLinks: const [
        SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://www.instagram.com/reel/gz-noon-heat-chettinad/'),
        SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://www.youtube.com/watch?v=gz-noon-heat-process'),
      ],
      statusHistory: _history([
        (ArtworkStatus.draft, 27),
        (ArtworkStatus.pendingApproval, 22),
        (ArtworkStatus.marketplace, 17),
      ]),
      physical: const ArtworkPhysical(
        weightKg: 7.9,
        framing: FramingState.stretchedCanvas,
        format: 'Canvas on deep stretcher, unframed edges',
        hangingHardwareIncluded: true,
        packagingConfirmed: true,
      ),
    ),
    Artwork(
      id: 'verdigris-study-no-4',
      title: 'Verdigris Study No. 4',
      artistId: 'arjun-mehta',
      artistName: arjunMehta.artistName,
      verifiedArtist: arjunMehta.verifiedArtist,
      category: 'sculpture',
      medium: 'Cast Bronze',
      customerPrice: 21900,
      thumbnailUrl: _Img.eco3,
      insured: false,
      status: ArtworkStatus.marketplace,
      listingType: ListingType.aggregatorOnly,
      description:
          'A wall-mounted bronze the size of an open hand, patinated in stages over six weeks and stopped at the point where the green had taken but the metal underneath still showed at the edges. Fourth in a run of nine, each one halted at a different week.',
      dimensions: '9x7x2 in',
      yearCreated: 2025,
      images: _images('Verdigris Study No. 4', [_Img.eco3, _Img.busts, _Img.eco1]),
      coaCertificateNumber: 'GZ-COA-2026-0026',
      coaIssueDate: _daysAgo(48),
      socialProofLinks: const [],
      statusHistory: _history([
        (ArtworkStatus.draft, 58),
        (ArtworkStatus.pendingApproval, 54),
        (ArtworkStatus.marketplace, 48),
      ]),
      physical: const ArtworkPhysical(
        weightKg: 2.8,
        framing: FramingState.framed,
        format: 'Bronze on a mounted backing plate',
        hangingHardwareIncluded: true,
        packagingConfirmed: true,
      ),
    ),
  ];
}
