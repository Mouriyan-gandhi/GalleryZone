import 'package:freezed_annotation/freezed_annotation.dart';

import 'artwork.dart' show SocialProofLink;

part 'artist.freezed.dart';
part 'artist.g.dart';

/// Mirrors `types/artist.ts`. Reuses [SocialProofLink] from the artwork
/// model rather than duplicating an identical `{platform, url}` shape under
/// a second name (the TS source itself has two structurally-identical types,
/// `ArtistSocialLink` and `SocialProofLink` — not worth the same split here).
@freezed
abstract class ArtistVerificationState with _$ArtistVerificationState {
  const factory ArtistVerificationState({
    required bool tier1SocialMedia,
    required bool tier2ActivePlan,
    required bool tier3FirstSale,
  }) = _ArtistVerificationState;

  factory ArtistVerificationState.fromJson(Map<String, dynamic> json) =>
      _$ArtistVerificationStateFromJson(json);
}

/// Port of `verifiedTierCount()` in `types/artist.ts`.
int verifiedTierCount(ArtistVerificationState v) {
  var count = 0;
  if (v.tier1SocialMedia) count++;
  if (v.tier2ActivePlan) count++;
  if (v.tier3FirstSale) count++;
  return count;
}

@freezed
abstract class ArtistProfile with _$ArtistProfile {
  const factory ArtistProfile({
    required String id,
    required String name,
    required String bio, // sanitized-at-display simple <p> markup, same as web
    required String profileImageUrl,
    required ArtistVerificationState verification,
    required List<SocialProofLink> socialLinks,
  }) = _ArtistProfile;

  factory ArtistProfile.fromJson(Map<String, dynamic> json) => _$ArtistProfileFromJson(json);
}
