// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mou.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MouPartyDetails _$MouPartyDetailsFromJson(Map<String, dynamic> json) =>
    _MouPartyDetails(
      name: json['name'] as String?,
      businessName: json['businessName'] as String?,
      address: json['address'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
      governmentId: json['governmentId'] as String?,
      gstNo: json['gstNo'] as String?,
    );

Map<String, dynamic> _$MouPartyDetailsToJson(_MouPartyDetails instance) =>
    <String, dynamic>{
      'name': instance.name,
      'businessName': instance.businessName,
      'address': instance.address,
      'mobile': instance.mobile,
      'email': instance.email,
      'governmentId': instance.governmentId,
      'gstNo': instance.gstNo,
    };

_MouCompanyDetails _$MouCompanyDetailsFromJson(Map<String, dynamic> json) =>
    _MouCompanyDetails(
      name: json['name'] as String?,
      designation: json['designation'] as String?,
    );

Map<String, dynamic> _$MouCompanyDetailsToJson(_MouCompanyDetails instance) =>
    <String, dynamic>{
      'name': instance.name,
      'designation': instance.designation,
    };

_MouParties _$MouPartiesFromJson(Map<String, dynamic> json) => _MouParties(
  party: json['party'] == null
      ? const MouPartyDetails()
      : MouPartyDetails.fromJson(json['party'] as Map<String, dynamic>),
  company: json['company'] == null
      ? const MouCompanyDetails()
      : MouCompanyDetails.fromJson(json['company'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MouPartiesToJson(_MouParties instance) =>
    <String, dynamic>{'party': instance.party, 'company': instance.company};

_MouAcceptance _$MouAcceptanceFromJson(Map<String, dynamic> json) =>
    _MouAcceptance(
      version: json['version'] as String,
      acceptedAt: json['acceptedAt'] as String,
      signatureName: json['signatureName'] as String? ?? '',
      signatureDataUrl: json['signatureDataUrl'] as String? ?? '',
      parties: json['parties'] == null
          ? null
          : MouParties.fromJson(json['parties'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MouAcceptanceToJson(_MouAcceptance instance) =>
    <String, dynamic>{
      'version': instance.version,
      'acceptedAt': instance.acceptedAt,
      'signatureName': instance.signatureName,
      'signatureDataUrl': instance.signatureDataUrl,
      'parties': instance.parties,
    };
