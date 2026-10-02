import '../../data/models/artwork.dart';
import 'painting_styles.dart';

/// What the artwork form offers, and the small pure rules around it. Port of
/// `features/dashboard/artwork-submit-data.ts` plus the helpers at the top of
/// `artwork-submit-form.tsx`, kept out of the screen so they can be tested
/// without building one.

/// One choice in a dropdown: the value the API stores and the label the artist
/// reads.
class FormOption {
  const FormOption(this.value, this.label);

  final String value;
  final String label;
}

const artworkCategories = [
  FormOption('painting', 'Painting'),
  FormOption('sculpture', 'Sculpture'),
  FormOption('printmaking', 'Printmaking'),
  FormOption('mixed-media', 'Mixed Media'),
  FormOption('textile', 'Textile Art'),
  FormOption('ceramics', 'Ceramics'),
];

/// A different axis from category (painting, sculpture...): what kind of piece
/// this instance of the work is. "Other" asks for a few words rather than
/// forcing a guess into one of the fixed options.
const artworkTypes = [
  FormOption('original', 'Original'),
  FormOption('limited_edition_print', 'Limited Edition Print'),
  FormOption('open_edition_print', 'Open Edition Print'),
  FormOption('study_sketch', 'Study / Sketch'),
  FormOption('commission_piece', 'Commission Piece'),
  FormOption('other', 'Other'),
];

/// The API stores the slug; the card and detail page humanize it back.
const artworkMediums = [
  FormOption('oil-on-canvas', 'Oil on Canvas'),
  FormOption('acrylic-on-canvas', 'Acrylic on Canvas'),
  FormOption('watercolor', 'Watercolor'),
  FormOption('charcoal', 'Charcoal'),
  FormOption('ink', 'Ink'),
  FormOption('bronze', 'Bronze'),
  FormOption('ceramic-mixed-media', 'Ceramic & Mixed Media'),
  FormOption('other', 'Other'),
];

/// The surface the work is made on. An aggregator needs to know what they are
/// hanging, not a taxonomy.
const artworkFormats = [
  FormOption('canvas', 'Canvas'),
  FormOption('paper', 'Paper'),
  FormOption('board', 'Board / panel'),
  FormOption('wood', 'Wood'),
  FormOption('metal', 'Metal'),
  FormOption('stone', 'Stone'),
  FormOption('textile', 'Textile'),
  FormOption('other', 'Other'),
];

const dimensionUnits = ['in', 'cm'];

class ListingChoice {
  const ListingChoice(this.type, this.label, this.description);

  final ListingType type;
  final String label;
  final String description;
}

const listingChoices = [
  ListingChoice(
    ListingType.marketplaceOnly,
    'Marketplace',
    "Sell online through GalleryZone's own marketplace.",
  ),
  ListingChoice(
    ListingType.aggregatorOnly,
    'Aggregator',
    'Send the physical piece to a verified aggregator to display and sell in person.',
  ),
  ListingChoice(
    ListingType.marketplaceAndAggregator,
    'Both',
    'List online and make the piece available for aggregator display at the same time.',
  ),
];

const maxArtworkImages = 8;

/// What the API takes for a photo; the repository enforces the same limits when
/// it uploads, this is so the artist hears about a bad file when they pick it.
const maxImageBytes = 15 * 1024 * 1024;

/// Fallback for the "strongly recommended" nudge before the published rules
/// have loaded.
const insuranceRecommendedThreshold = 20000.0;

/// Named in the Artist Onboarding Guide.
const insurancePartner = 'HDFC ERGO';
const insurancePartnerUrl = 'https://www.hdfcergo.com/';

/// Why [name] can't be uploaded, or null when it can.
String? imageProblem(String name, int bytes) {
  final extension = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
    return '"$name" isn\'t a JPEG, PNG or WebP image.';
  }
  if (bytes > maxImageBytes) {
    return '"$name" is larger than 15 MB. Please resize it and try again.';
  }
  return null;
}

// --- Dimensions --------------------------------------------------------------

typedef Dimensions = ({String length, String width, String height, String unit});

/// The API derives the size band from `L x W [x H] unit`, and this form is the
/// only thing that ever writes it, so splitting it back round-trips an edit
/// losslessly. Anything of another shape is older data the form never made -
/// it comes back empty and the caller keeps the original string untouched.
Dimensions parseDimensions(String? raw) {
  const empty = (length: '', width: '', height: '', unit: 'in');
  final match = raw == null ? null : _dimensionsShape.firstMatch(raw.trim());
  if (match == null) return empty;
  return (
    length: match[1]!,
    width: match[2]!,
    height: match[3] ?? '',
    unit: match[4]!.toLowerCase(),
  );
}

final _dimensionsShape = RegExp(
  r'^([\d.]+)\s*x\s*([\d.]+)(?:\s*x\s*([\d.]+))?\s*(in|cm)$',
  caseSensitive: false,
);

/// `24 x 36 in` / `24 x 36 x 2 in`, or empty when there is no length and width.
String composeDimensions(Dimensions dimensions) {
  if (dimensions.length.isEmpty || dimensions.width.isEmpty) return '';
  final parts = [dimensions.length, dimensions.width, dimensions.height]
      .where((part) => part.isNotEmpty)
      .join(' x ');
  return '$parts ${dimensions.unit}';
}

/// A typed measurement, tidied the way a number input would hand it over:
/// `60`, not `60.0` or ` 60 `. Null when it is not a positive number.
String? tidyMeasurement(String raw) {
  final value = double.tryParse(raw.trim());
  if (value == null || value <= 0) return null;
  return value == value.roundToDouble() ? value.round().toString() : value.toString();
}

// --- Stored values back into the form ----------------------------------------

/// Older records can carry the display name ("Oil on Canvas") where the API
/// now stores the slug ("oil-on-canvas"). Finds the option [stored] means, or
/// returns it as it came so the form can keep it rather than rewrite it.
String normalizeOption(String stored, List<FormOption> options) {
  final lowered = stored.trim().toLowerCase();
  final slug = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  for (final option in options) {
    if (option.value == stored) return option.value;
  }
  for (final option in options) {
    if (option.label.toLowerCase() == lowered || option.value == slug) return option.value;
  }
  return stored;
}

/// The "Type of artwork" picker's value and its free text, from what is stored
/// (a label such as "Limited Edition Print", or the artist's own words).
({String type, String other}) artworkTypeFields(String? stored) {
  if ((stored ?? '').isEmpty) return (type: '', other: '');
  for (final option in artworkTypes) {
    if (option.value != 'other' && option.label == stored) return (type: option.value, other: '');
  }
  return (type: 'other', other: stored!);
}

/// What goes to the API for the picker: the label, or the artist's own words
/// for "Other".
String? artworkTypeToStore(String type, String other) {
  if (type == 'other') return other.trim().isEmpty ? null : other.trim();
  for (final option in artworkTypes) {
    if (option.value == type) return option.label;
  }
  return null;
}

/// The painting-style picker's value (a style name, `Other` or empty) and its
/// free text, from what is stored.
({String style, String other}) paintingStyleFields(String? stored) {
  if ((stored ?? '').isEmpty) return (style: '', other: '');
  if (paintingStyles.any((style) => style.name == stored)) return (style: stored!, other: '');
  return (style: 'Other', other: stored!);
}

/// Only paintings carry a style.
String? paintingStyleToStore(String category, String style, String other) {
  if (category != 'painting') return null;
  if (style == 'Other') return other.trim().isEmpty ? null : other.trim();
  return style.isEmpty ? null : style;
}

// --- Price ladder ------------------------------------------------------------

typedef PriceLadder = ({double base, double customer, double gstIncluded});

/// Where every rupee between the artist's rate and the listed price goes: the
/// markup first, then GST on top. Quoted from the rules GalleryZone published,
/// so a rate change reaches the form with no release.
PriceLadder priceLadderFor(double artistPrice, {required double markup, required double gstRate}) {
  final base = (artistPrice * (1 + markup)).roundToDouble();
  final customer = (base * (1 + gstRate)).roundToDouble();
  return (base: base, customer: customer, gstIncluded: customer - base);
}

/// `5` for 0.05, `12.5` for 0.125.
String percentLabel(double rate) {
  final percent = double.parse((rate * 100).toStringAsFixed(2));
  return percent == percent.roundToDouble() ? percent.round().toString() : percent.toString();
}

// --- Aggregator readiness ----------------------------------------------------

/// What is still missing before this can go for review on the aggregator
/// channel: the physical facts (MOU §12) and the artist's acceptance of the
/// display terms. Empty means ready.
List<String> missingForAggregatorListing(ArtworkPhysical physical, {required bool termsAccepted}) => [
      ...missingForAggregator(physical),
      if (!termsAccepted) 'aggregator terms accepted',
    ];

/// The label for an insurance verdict, as the artist is shown it.
const insuranceStatusLabel = {
  ReviewStatus.notSubmitted: 'Not submitted',
  ReviewStatus.submitted: 'Pending review',
  ReviewStatus.approved: 'Verified',
  ReviewStatus.rejected: 'Rejected — resubmit',
};

/// The questions an artist asks about cover, answered once. Port of
/// `insurance-faq-chat.tsx`; not a chatbot - there is nothing to answer a free
/// question, so it is a fixed set.
const insuranceFaqs = [
  (
    question: 'What does the insurance actually cover?',
    answer: 'Theft, fire, transit damage and loss while the piece is out of your hands — in transit or on display '
        'with an aggregator. It does not cover normal wear and tear.',
  ),
  (
    question: 'What happens if I decline it?',
    answer: 'You can still list your work, but GalleryZone, its aggregators and logistics partners carry no '
        'liability for the piece in transit. Declining is only allowed for marketplace-only listings — aggregator '
        'display requires cover.',
  ),
  (
    question: 'Who pays for the policy?',
    answer: "You buy it directly through the insurer. The premium isn't collected by GalleryZone — it's a separate "
        'charge from them, not deducted from your settlement.',
  ),
  (
    question: 'Where do I get my policy/certificate number?',
    answer: 'After you complete the application on the $insurancePartner site, they issue a policy or certificate '
        'number by email. Paste that into the field above once you have it.',
  ),
  (
    question: 'How long until GalleryZone verifies it?',
    answer: "Admin review usually clears within a couple of business days. You'll see the status change here from "
        '"Pending review" to "Verified".',
  ),
];
