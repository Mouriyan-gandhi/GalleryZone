// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_network.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ArtistReview _$ArtistReviewFromJson(Map<String, dynamic> json) =>
    _ArtistReview(
      id: json['id'] as String,
      artistId: json['artistId'] as String,
      reviewerName: json['reviewerName'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String,
      artworkTitle: json['artworkTitle'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$ArtistReviewToJson(_ArtistReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'artistId': instance.artistId,
      'reviewerName': instance.reviewerName,
      'rating': instance.rating,
      'comment': instance.comment,
      'artworkTitle': instance.artworkTitle,
      'createdAt': instance.createdAt,
    };

_ArtistConnection _$ArtistConnectionFromJson(Map<String, dynamic> json) =>
    _ArtistConnection(
      id: json['id'] as String,
      requesterId: json['requesterId'] as String,
      requesterName: json['requesterName'] as String,
      requesterAvatar: json['requesterAvatar'] as String,
      recipientId: json['recipientId'] as String,
      recipientName: json['recipientName'] as String,
      recipientAvatar: json['recipientAvatar'] as String,
      status: $enumDecode(_$ConnectionStatusEnumMap, json['status']),
      message: json['message'] as String,
      requestedAt: json['requestedAt'] as String,
      respondedAt: json['respondedAt'] as String?,
    );

Map<String, dynamic> _$ArtistConnectionToJson(_ArtistConnection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requesterId': instance.requesterId,
      'requesterName': instance.requesterName,
      'requesterAvatar': instance.requesterAvatar,
      'recipientId': instance.recipientId,
      'recipientName': instance.recipientName,
      'recipientAvatar': instance.recipientAvatar,
      'status': _$ConnectionStatusEnumMap[instance.status]!,
      'message': instance.message,
      'requestedAt': instance.requestedAt,
      'respondedAt': instance.respondedAt,
    };

const _$ConnectionStatusEnumMap = {
  ConnectionStatus.pending: 'pending',
  ConnectionStatus.accepted: 'accepted',
  ConnectionStatus.declined: 'declined',
};

_ArtistCollaboration _$ArtistCollaborationFromJson(Map<String, dynamic> json) =>
    _ArtistCollaboration(
      id: json['id'] as String,
      proposerId: json['proposerId'] as String,
      proposerName: json['proposerName'] as String,
      partnerId: json['partnerId'] as String,
      partnerName: json['partnerName'] as String,
      title: json['title'] as String,
      brief: json['brief'] as String,
      status: $enumDecode(_$CollaborationStatusEnumMap, json['status']),
      proposedAt: json['proposedAt'] as String,
      respondedAt: json['respondedAt'] as String?,
    );

Map<String, dynamic> _$ArtistCollaborationToJson(
  _ArtistCollaboration instance,
) => <String, dynamic>{
  'id': instance.id,
  'proposerId': instance.proposerId,
  'proposerName': instance.proposerName,
  'partnerId': instance.partnerId,
  'partnerName': instance.partnerName,
  'title': instance.title,
  'brief': instance.brief,
  'status': _$CollaborationStatusEnumMap[instance.status]!,
  'proposedAt': instance.proposedAt,
  'respondedAt': instance.respondedAt,
};

const _$CollaborationStatusEnumMap = {
  CollaborationStatus.proposed: 'proposed',
  CollaborationStatus.active: 'active',
  CollaborationStatus.completed: 'completed',
  CollaborationStatus.declined: 'declined',
};

_DeactivationRequest _$DeactivationRequestFromJson(Map<String, dynamic> json) =>
    _DeactivationRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      reason: json['reason'] as String,
      status: $enumDecode(_$DeactivationStatusEnumMap, json['status']),
      requestedAt: json['requestedAt'] as String,
      decidedAt: json['decidedAt'] as String?,
      decisionNote: json['decisionNote'] as String?,
    );

Map<String, dynamic> _$DeactivationRequestToJson(
  _DeactivationRequest instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'userName': instance.userName,
  'reason': instance.reason,
  'status': _$DeactivationStatusEnumMap[instance.status]!,
  'requestedAt': instance.requestedAt,
  'decidedAt': instance.decidedAt,
  'decisionNote': instance.decisionNote,
};

const _$DeactivationStatusEnumMap = {
  DeactivationStatus.pending: 'pending',
  DeactivationStatus.approved: 'approved',
  DeactivationStatus.rejected: 'rejected',
};
