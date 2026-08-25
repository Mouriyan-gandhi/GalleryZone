// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_portal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityEntry _$ActivityEntryFromJson(Map<String, dynamic> json) =>
    _ActivityEntry(
      id: json['id'] as String,
      kind: $enumDecode(_$ActivityKindEnumMap, json['kind']),
      title: json['title'] as String,
      detail: json['detail'] as String,
      time: json['time'] as String,
    );

Map<String, dynamic> _$ActivityEntryToJson(_ActivityEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$ActivityKindEnumMap[instance.kind]!,
      'title': instance.title,
      'detail': instance.detail,
      'time': instance.time,
    };

const _$ActivityKindEnumMap = {
  ActivityKind.artworkApproved: 'artwork_approved',
  ActivityKind.artworkSubmitted: 'artwork_submitted',
  ActivityKind.settlement: 'settlement',
  ActivityKind.verification: 'verification',
  ActivityKind.withdrawal: 'withdrawal',
};

_ArtistProfileDetails _$ArtistProfileDetailsFromJson(
  Map<String, dynamic> json,
) => _ArtistProfileDetails(
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  bio: json['bio'] as String,
  instagram: json['instagram'] as String,
  website: json['website'] as String,
  bankAccountMasked: json['bankAccountMasked'] as String,
  ifsc: json['ifsc'] as String,
  aadhaarStatus: $enumDecode(_$AadhaarStatusEnumMap, json['aadhaarStatus']),
  aadhaarMasked: json['aadhaarMasked'] as String,
  gstin: json['gstin'] as String?,
  pickupLine1: json['pickupLine1'] as String? ?? '',
  pickupLine2: json['pickupLine2'] as String? ?? '',
  pickupCity: json['pickupCity'] as String? ?? '',
  pickupState: json['pickupState'] as String? ?? '',
  pickupPincode: json['pickupPincode'] as String? ?? '',
);

Map<String, dynamic> _$ArtistProfileDetailsToJson(
  _ArtistProfileDetails instance,
) => <String, dynamic>{
  'fullName': instance.fullName,
  'email': instance.email,
  'phone': instance.phone,
  'bio': instance.bio,
  'instagram': instance.instagram,
  'website': instance.website,
  'bankAccountMasked': instance.bankAccountMasked,
  'ifsc': instance.ifsc,
  'aadhaarStatus': _$AadhaarStatusEnumMap[instance.aadhaarStatus]!,
  'aadhaarMasked': instance.aadhaarMasked,
  'gstin': instance.gstin,
  'pickupLine1': instance.pickupLine1,
  'pickupLine2': instance.pickupLine2,
  'pickupCity': instance.pickupCity,
  'pickupState': instance.pickupState,
  'pickupPincode': instance.pickupPincode,
};

const _$AadhaarStatusEnumMap = {
  AadhaarStatus.verified: 'verified',
  AadhaarStatus.pending: 'pending',
  AadhaarStatus.unverified: 'unverified',
};

_ArtistSettings _$ArtistSettingsFromJson(Map<String, dynamic> json) =>
    _ArtistSettings(
      notifyArtworkApproved: json['notifyArtworkApproved'] as bool,
      notifyNewSale: json['notifyNewSale'] as bool,
      notifyWithdrawalProcessed: json['notifyWithdrawalProcessed'] as bool,
      notifyNewMessage: json['notifyNewMessage'] as bool,
    );

Map<String, dynamic> _$ArtistSettingsToJson(_ArtistSettings instance) =>
    <String, dynamic>{
      'notifyArtworkApproved': instance.notifyArtworkApproved,
      'notifyNewSale': instance.notifyNewSale,
      'notifyWithdrawalProcessed': instance.notifyWithdrawalProcessed,
      'notifyNewMessage': instance.notifyNewMessage,
    };

_MouAcceptance _$MouAcceptanceFromJson(Map<String, dynamic> json) =>
    _MouAcceptance(
      version: json['version'] as String,
      acceptedAt: json['acceptedAt'] as String,
      signatureName: json['signatureName'] as String? ?? '',
    );

Map<String, dynamic> _$MouAcceptanceToJson(_MouAcceptance instance) =>
    <String, dynamic>{
      'version': instance.version,
      'acceptedAt': instance.acceptedAt,
      'signatureName': instance.signatureName,
    };

_Settlement _$SettlementFromJson(Map<String, dynamic> json) => _Settlement(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  artworkTitle: json['artworkTitle'] as String,
  artistName: json['artistName'] as String,
  artistAmount: (json['artistAmount'] as num).toDouble(),
  aggregatorCommission: (json['aggregatorCommission'] as num).toDouble(),
  platformRevenue: (json['platformRevenue'] as num).toDouble(),
  status: $enumDecode(_$SettlementStatusEnumMap, json['status']),
  createdAt: json['createdAt'] as String,
  processedAt: json['processedAt'] as String?,
  releaseAfter: json['releaseAfter'] as String?,
);

Map<String, dynamic> _$SettlementToJson(_Settlement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'artworkTitle': instance.artworkTitle,
      'artistName': instance.artistName,
      'artistAmount': instance.artistAmount,
      'aggregatorCommission': instance.aggregatorCommission,
      'platformRevenue': instance.platformRevenue,
      'status': _$SettlementStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt,
      'processedAt': instance.processedAt,
      'releaseAfter': instance.releaseAfter,
    };

const _$SettlementStatusEnumMap = {
  SettlementStatus.pending: 'pending',
  SettlementStatus.processed: 'processed',
  SettlementStatus.failed: 'failed',
};

_MessageThread _$MessageThreadFromJson(Map<String, dynamic> json) =>
    _MessageThread(
      id: json['id'] as String,
      from: json['from'] as String,
      subject: json['subject'] as String,
      preview: json['preview'] as String,
      body: json['body'] as String,
      unread: json['unread'] as bool,
      receivedAt: json['receivedAt'] as String,
    );

Map<String, dynamic> _$MessageThreadToJson(_MessageThread instance) =>
    <String, dynamic>{
      'id': instance.id,
      'from': instance.from,
      'subject': instance.subject,
      'preview': instance.preview,
      'body': instance.body,
      'unread': instance.unread,
      'receivedAt': instance.receivedAt,
    };

_AggregatorHolding _$AggregatorHoldingFromJson(Map<String, dynamic> json) =>
    _AggregatorHolding(
      id: json['id'] as String,
      artworkId: json['artworkId'] as String,
      advancePercent: (json['advancePercent'] as num).toInt(),
      advanceAmount: (json['advanceAmount'] as num).toDouble(),
      displayPrice: (json['displayPrice'] as num).toDouble(),
      assignedAt: json['assignedAt'] as String,
      expiresAt: json['expiresAt'] as String,
      status: $enumDecode(_$HoldingStatusEnumMap, json['status']),
      assignmentSource: $enumDecode(
        _$AssignmentSourceEnumMap,
        json['assignmentSource'],
      ),
      deliveryDeposit: (json['deliveryDeposit'] as num?)?.toDouble() ?? 0.0,
      cycleMonth: (json['cycleMonth'] as num?)?.toInt() ?? 1,
      displayPriceSetAt: json['displayPriceSetAt'] as String?,
      returnedAt: json['returnedAt'] as String?,
      windowExtended: json['windowExtended'] as bool? ?? false,
    );

Map<String, dynamic> _$AggregatorHoldingToJson(_AggregatorHolding instance) =>
    <String, dynamic>{
      'id': instance.id,
      'artworkId': instance.artworkId,
      'advancePercent': instance.advancePercent,
      'advanceAmount': instance.advanceAmount,
      'displayPrice': instance.displayPrice,
      'assignedAt': instance.assignedAt,
      'expiresAt': instance.expiresAt,
      'status': _$HoldingStatusEnumMap[instance.status]!,
      'assignmentSource': _$AssignmentSourceEnumMap[instance.assignmentSource]!,
      'deliveryDeposit': instance.deliveryDeposit,
      'cycleMonth': instance.cycleMonth,
      'displayPriceSetAt': instance.displayPriceSetAt,
      'returnedAt': instance.returnedAt,
      'windowExtended': instance.windowExtended,
    };

const _$HoldingStatusEnumMap = {
  HoldingStatus.reserved: 'reserved',
  HoldingStatus.soldPendingSettlement: 'sold_pending_settlement',
  HoldingStatus.returned: 'returned',
};

const _$AssignmentSourceEnumMap = {
  AssignmentSource.selfReserved: 'self_reserved',
  AssignmentSource.gzAssigned: 'gz_assigned',
};

_RevenuePoint _$RevenuePointFromJson(Map<String, dynamic> json) =>
    _RevenuePoint(
      month: json['month'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$RevenuePointToJson(_RevenuePoint instance) =>
    <String, dynamic>{'month': instance.month, 'amount': instance.amount};
