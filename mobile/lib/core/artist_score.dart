import '../data/models/artist_portal.dart';

/// The artist's single 0-10 score: customer ratings, profile completion and
/// artwork count combined. Port of `types/artist-rating.ts` - "port to lib/core
/// the same way pricing is ported, rather than duplicating the formula" - so
/// the card here, the website's card and the admin table cannot disagree about
/// what "6.8" means.
///
/// PLACEHOLDER weights pending client sign-off (the "Ten-Point Score" note,
/// client meeting Aug 2026): customer-dominant, no on-time-delivery factor yet,
/// a linear artwork-count curve. When the client answers, this is the one place
/// that changes on each side.
const ratingScoreWeights = (customerRating: 0.65, profileCompletion: 0.25, artworkCount: 0.1);

/// 0-10. Linear to 10 - 0 artworks = 0, 10 or more = full marks.
double artworkCountScore(int artworkCount) => artworkCount.clamp(0, 10).toDouble();

/// 0-10: the share of a fixed set of profile fields the artist has filled in,
/// equal weight each (the client hasn't said which should count more).
///
/// The website checks the Aadhaar field against the word `verified`, which the
/// API never sends (it says `approved`), so on the website that tenth of the
/// score can never be earned. This matches the website exactly, so the number
/// is the same everywhere; it moves when the website's check does.
double profileCompletionScore(ArtistProfileDetails profile) {
  bool filled(String? value) => (value ?? '').trim().isNotEmpty;
  final checks = [
    filled(profile.bio),
    filled(profile.instagram),
    filled(profile.website),
    filled(profile.bankAccountMasked),
    filled(profile.ifsc),
    filled(profile.pan),
    filled(profile.gstin),
    false, // Aadhaar "verified" - see above
    filled(profile.pickupLine1),
    filled(profile.pickupPincode),
  ];
  return checks.where((ok) => ok).length / checks.length * 10;
}

/// The one place that turns the factors into the card's single number, to one
/// decimal.
double scoreArtist({
  required double customerRating,
  required double profileCompletion,
  required double artworkCount,
}) {
  final raw = customerRating * ratingScoreWeights.customerRating +
      profileCompletion * ratingScoreWeights.profileCompletion +
      artworkCount * ratingScoreWeights.artworkCount;
  return (raw * 10).round() / 10;
}
