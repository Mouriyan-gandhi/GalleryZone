// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ArtistVerificationState _$ArtistVerificationStateFromJson(
  Map<String, dynamic> json,
) => _ArtistVerificationState(
  tier1SocialMedia: json['tier1SocialMedia'] as bool,
  tier2ActivePlan: json['tier2ActivePlan'] as bool,
  tier3FirstSale: json['tier3FirstSale'] as bool,
);

Map<String, dynamic> _$ArtistVerificationStateToJson(
  _ArtistVerificationState instance,
) => <String, dynamic>{
  'tier1SocialMedia': instance.tier1SocialMedia,
  'tier2ActivePlan': instance.tier2ActivePlan,
  'tier3FirstSale': instance.tier3FirstSale,
};

_ArtistProfile _$ArtistProfileFromJson(Map<String, dynamic> json) =>
    _ArtistProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
      verification: ArtistVerificationState.fromJson(
        json['verification'] as Map<String, dynamic>,
      ),
      socialLinks: (json['socialLinks'] as List<dynamic>)
          .map((e) => SocialProofLink.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ArtistProfileToJson(_ArtistProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'bio': instance.bio,
      'profileImageUrl': instance.profileImageUrl,
      'verification': instance.verification,
      'socialLinks': instance.socialLinks,
    };
