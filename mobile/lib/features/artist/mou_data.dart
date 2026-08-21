// GENERATED-BY-TRANSCRIPTION — do not hand-edit the wording.
//
// The artist's Memorandum of Understanding with GalleryZone, transcribed
// clause for clause from the signed PDF ("MOU of Artist.pdf") by way of
// `frontend-web/features/dashboard/mou-data.ts`, so the app, the website and
// the paper version cannot say different things. The wording is the
// company's: correct the source document and re-transcribe rather than
// editing here.
//
// Distinct from the per-artwork listing terms — this is the artist's overall
// agreement with the platform.

/// Bumped whenever the wording changes, so an acceptance can be tied to what
/// was actually on screen.
const mouVersion = '2026.1';

class MouClause {
  const MouClause({
    required this.number,
    required this.title,
    required this.paragraphs,
    this.points,
    this.closing,
  });

  final int number;
  final String title;
  final List<String> paragraphs;
  final List<String>? points;
  final List<String>? closing;
}

const mouPreamble = [
  'This Memorandum of Understanding (“MOU”) is executed between '
      'GalleryZone Private Limited and the Artist for the listing, '
      'promotion, exhibition, marketing, and sale of artworks through the'
      ' GalleryZone platform.',
  'Both parties agree to the following terms and conditions.',
];

const mouClauses = <MouClause>[
  MouClause(
    number: 1,
    title: 'Purpose',
    paragraphs: [
      'GalleryZone is a digital art marketplace and art management '
          'platform connecting artists, aggregators, collectors, investors, '
          'institutions, and art enthusiasts.',
      'GalleryZone aims to:',
    ],
    points: [
      'Build a permanent digital footprint for every artwork.',
      'Increase artist recognition and credibility.',
      'Create a verified digital portfolio.',
      'Enable artworks to become collectible investment assets.',
      'Maintain secure ownership and provenance records.',
      'Promote artworks through online and offline sales channels.',
      'Resale of the artwork.',
    ],
    closing: ['GalleryZone promotes artworks but does not guarantee a sale.'],
  ),
  MouClause(
    number: 2,
    title: 'Artwork Eligibility',
    paragraphs: ['The Artist confirms that:'],
    points: [
      'Every artwork submitted is 100% handmade and created by the '
          'Artist.',
      'Once created, the Artist shall not replicate the same artwork '
          'again; doing so degrades the artwork\'s value and may lead to '
          'termination or delisting of the artwork.',
      'No AI-generated artwork, AI-assisted artwork, digital artwork, '
          'digital print, machine-generated reproduction, NFT artwork, or '
          'copied artwork shall be accepted unless expressly approved in '
          'writing by GalleryZone.',
      'The Artist is the sole owner of the artwork.',
      'The artwork does not infringe any copyright, trademark, or '
          'intellectual property rights.',
      'GalleryZone reserves the right to reject any artwork without '
          'assigning any reason.',
    ],
  ),
  MouClause(
    number: 3,
    title: 'Artwork Submission Requirements',
    paragraphs: ['Before shipment, the Artist shall provide:'],
    points: [
      'Completed artwork details.',
      'Name of artwork.',
      'Dimensions.',
      'Medium used.',
      'Subject.',
      'Type of artwork.',
      'Year of creation.',
      'Description.',
      'High-quality photographs.',
      'Artist profile.',
      'Certificate of Authenticity (COA).',
      'Government ID.',
      'Signature.',
      'Any additional information requested by GalleryZone.',
    ],
  ),
  MouClause(
    number: 4,
    title: 'Digital Footprint & Portfolio',
    paragraphs: ['Upon approval:'],
    points: [
      'Every artwork shall receive a unique GalleryZone Digital Identity.',
      'GalleryZone may create digital certificates, ownership records, QR'
          ' records, NFC records and provenance history.',
      'Artwork images may be used for marketing, exhibitions, '
          'publications, social media, and promotional activities.',
    ],
  ),
  MouClause(
    number: 5,
    title: 'Artist Verification',
    paragraphs: [
      'Artists are encouraged to provide social media profiles including '
          'Instagram, Facebook, YouTube, X (Twitter) and TikTok, showing '
          'studio work, artwork creation, and work-in-progress to improve '
          'buyer confidence.',
    ],
  ),
  MouClause(
    number: 6,
    title: 'Confidential Pricing',
    paragraphs: [
      'The Artist\'s quoted price shall remain confidential.',
      'The Artist shall not publicly disclose artwork pricing through '
          'social media, websites, videos, interviews, exhibitions, '
          'promotional materials, or comments.',
      'Violation may result in removal of the artwork and termination of '
          'this agreement.',
    ],
  ),
  MouClause(
    number: 7,
    title: 'Artwork Listing',
    paragraphs: [
      'Listing artwork on GalleryZone is completely free. No confirmation'
          ' fee shall be payable.',
      'Artwork shall include the mandatory basic material with the '
          'artwork at the time of shipment, as advised by GalleryZone. The '
          'Artist shall ensure all documentation, packaging, labeling, and '
          'shipment requirements prescribed by GalleryZone are completed '
          'before dispatch.',
      'Shipment cost, GST, taxes, convenience charges, insurance charges '
          '(if applicable), and any other agreed charges shall be deducted '
          'from the Artist\'s final settlement.',
    ],
  ),
  MouClause(
    number: 8,
    title: 'Selling Channels',
    paragraphs: ['GalleryZone may sell or promote artwork through:'],
    points: [
      'Online Marketplace (B2C).',
      'Authorized GalleryZone Aggregators.',
      'Art exhibitions.',
      'Corporate sales.',
      'Institutional sales.',
      'Private collectors.',
      'International buyers.',
      'Any other sales channel developed by GalleryZone.',
    ],
    closing: [
      'The Artist may promote the artwork independently. However, every '
          'promotion shall include the GalleryZone artwork link, and buyers '
          'shall complete purchases only through GalleryZone.',
      'Once an artwork is selected by an authorized Aggregator for '
          'display, it shall not be removed from the GalleryZone marketplace '
          'until approved by GalleryZone or the listing period expires.',
    ],
  ),
  MouClause(
    number: 9,
    title: 'Shipping & Insurance',
    paragraphs: [
      'Transit insurance is mandatory.',
      'If the Artist voluntarily declines insurance, the Artist shall '
          'bear sole responsibility for:',
    ],
    points: [
      'Theft.',
      'Fire.',
      'Transit damage.',
      'Loss.',
      'Wear and tear.',
      'Natural disasters.',
      'Any unforeseen incidents.',
    ],
    closing: [
      'GalleryZone, its employees, aggregators, logistics partners, and '
          'affiliates shall not be liable where insurance has been declined. '
          'Insurance charges shall be borne by the Artist.',
    ],
  ),
  MouClause(
    number: 10,
    title: 'Delivery Charges',
    paragraphs: [
      'One-time transportation charges for delivery of the artwork to the'
          ' assigned Aggregator shall be deducted from the Artist\'s final '
          'settlement after successful sale.',
      'Customer delivery charges shall be separately payable by the buyer'
          ' wherever applicable.',
    ],
  ),
  MouClause(
    number: 11,
    title: 'Certificate of Authenticity',
    paragraphs: [
      'The Artist shall complete the Certificate of Authenticity (COA) '
          'through the official GalleryZone website before shipment.',
      'GalleryZone may retain digital copies permanently.',
    ],
  ),
  MouClause(
    number: 12,
    title: 'Packaging Requirements',
    paragraphs: ['For display through GalleryZone Aggregators:'],
    points: [
      'Artwork shall be supplied either professionally stretched on '
          'canvas or properly framed.',
      'Packaging shall comply with GalleryZone shipping standards.',
      'GalleryZone may reject improperly packed artworks.',
      'Hangers shall be provided with the artwork.',
      'Upon sale, if the customer requires a physical COA, the Artist '
          'shall print the COA, sign it, and dispatch it through the '
          'GalleryZone portal.',
    ],
  ),
  MouClause(
    number: 13,
    title: 'Ownership Before Sale',
    paragraphs: [
      'Ownership of the artwork remains with the Artist until successful '
          'sale.',
      'GalleryZone shall retain possession for display, marketing, and '
          'sale purposes where applicable.',
    ],
  ),
  MouClause(
    number: 14,
    title: 'Rights Before Sale',
    paragraphs: [
      'The Artist grants GalleryZone a non-exclusive worldwide licence to'
          ' photograph, publish, advertise, exhibit, and promote the artwork.',
      'The Artist shall not sell or list the same artwork elsewhere '
          'during the active GalleryZone listing period.',
    ],
  ),
  MouClause(
    number: 15,
    title: 'Rights After Sale',
    paragraphs: [
      'Upon successful payment and delivery, ownership transfers to the '
          'buyer.',
      'The Artist retains only moral rights as the original creator '
          'unless otherwise agreed.',
    ],
  ),
  MouClause(
    number: 16,
    title: 'Authenticity Records',
    paragraphs: ['GalleryZone may maintain:'],
    points: [
      'Digital Certificate of Authenticity.',
      'Ownership history.',
      'QR verification.',
      'Artwork provenance.',
      'Transaction history.',
    ],
  ),
  MouClause(
    number: 17,
    title: 'Aggregator Display Period',
    paragraphs: [
      'Each artwork may remain with an authorized Aggregator for an '
          'initial period of thirty (30) days.',
      'If unsold, GalleryZone may relocate the artwork to another '
          'Aggregator, exhibition, or sales channel and revise the marketing '
          'strategy.',
    ],
  ),
  MouClause(
    number: 18,
    title: 'Listing Period',
    paragraphs: [
      'Artwork shall remain listed for up to six (6) months.',
      'If unsold, GalleryZone shall coordinate its return. Any agreed '
          'return shipment charges shall be communicated in advance.',
    ],
  ),
  MouClause(
    number: 19,
    title: 'Responsibilities of the Artist',
    paragraphs: ['The Artist shall:'],
    points: [
      'Provide genuine artwork.',
      'Provide accurate information.',
      'Cooperate during verification.',
      'Complete the COA.',
      'Respond promptly to GalleryZone communications.',
      'Maintain professional conduct.',
      'Ensure artwork quality matches submitted photographs.',
    ],
  ),
  MouClause(
    number: 20,
    title: 'Responsibilities of GalleryZone',
    paragraphs: ['GalleryZone shall:'],
    points: [
      'Promote the artwork.',
      'Maintain digital records.',
      'Connect artists with buyers.',
      'Facilitate settlements.',
      'Generate authenticity records.',
      'Coordinate logistics.',
      'Return unsold artworks where applicable.',
    ],
    closing: ['GalleryZone does not guarantee sales.'],
  ),
  MouClause(
    number: 21,
    title: 'Settlement',
    paragraphs: [
      'After a successful sale, the Artist shall receive the confidential'
          ' Artist Price, with applicable deductions including:',
    ],
    points: [
      'GST.',
      'Taxes.',
      'Shipment charges.',
      'Delivery charges.',
      'Insurance charges.',
      'Convenience charges.',
      'Any other applicable deductions.',
    ],
    closing: [
      'Settlement shall normally be processed after successful delivery '
          'and receipt of payment from the buyer.',
    ],
  ),
  MouClause(
    number: 22,
    title: 'Termination',
    paragraphs: ['GalleryZone may terminate this MOU if:'],
    points: [
      'Artwork is counterfeit.',
      'False information is provided.',
      'Pricing confidentiality is breached.',
      'Intellectual property rights are violated.',
      'Fraudulent activity is detected.',
      'The Artist breaches this agreement.',
    ],
  ),
  MouClause(
    number: 23,
    title: 'Limitation of Liability',
    paragraphs: ['GalleryZone shall not be liable for:'],
    points: [
      'Failure to sell artwork.',
      'Market fluctuations.',
      'Loss where insurance has been declined by the Artist.',
      'Indirect or consequential damages.',
    ],
  ),
  MouClause(
    number: 24,
    title: 'Governing Law',
    paragraphs: [
      'This MOU shall be governed by the laws of India.',
      'Courts at Hyderabad, Telangana shall have exclusive jurisdiction.',
    ],
  ),
  MouClause(
    number: 25,
    title: 'Entire Agreement',
    paragraphs: [
      'This document constitutes the complete agreement between '
          'GalleryZone and the Artist.',
      'Any amendment shall be valid only if made in writing and signed by'
          ' both parties.',
    ],
  ),
];
