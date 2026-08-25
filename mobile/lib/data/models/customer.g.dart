// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CustomerProfile _$CustomerProfileFromJson(Map<String, dynamic> json) =>
    _CustomerProfile(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      gstin: json['gstin'] as String?,
      bankAccountName: json['bankAccountName'] as String? ?? '',
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '',
      bankIfsc: json['bankIfsc'] as String? ?? '',
    );

Map<String, dynamic> _$CustomerProfileToJson(_CustomerProfile instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'gstin': instance.gstin,
      'bankAccountName': instance.bankAccountName,
      'bankAccountNumber': instance.bankAccountNumber,
      'bankIfsc': instance.bankIfsc,
    };

_WalletSummary _$WalletSummaryFromJson(Map<String, dynamic> json) =>
    _WalletSummary(
      balance: (json['balance'] as num).toDouble(),
      pendingBalance: (json['pendingBalance'] as num).toDouble(),
      lockedBalance: (json['lockedBalance'] as num).toDouble(),
    );

Map<String, dynamic> _$WalletSummaryToJson(_WalletSummary instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'pendingBalance': instance.pendingBalance,
      'lockedBalance': instance.lockedBalance,
    };

_WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) =>
    _WalletTransaction(
      id: json['id'] as String,
      type: $enumDecode(_$WalletTransactionTypeEnumMap, json['type']),
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] as String,
      status: $enumDecode(_$WalletTransactionStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$WalletTransactionToJson(_WalletTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$WalletTransactionTypeEnumMap[instance.type]!,
      'label': instance.label,
      'amount': instance.amount,
      'date': instance.date,
      'status': _$WalletTransactionStatusEnumMap[instance.status]!,
    };

const _$WalletTransactionTypeEnumMap = {
  WalletTransactionType.settlement: 'settlement',
  WalletTransactionType.withdrawal: 'withdrawal',
  WalletTransactionType.commission: 'commission',
  WalletTransactionType.refund: 'refund',
  WalletTransactionType.adjustment: 'adjustment',
};

const _$WalletTransactionStatusEnumMap = {
  WalletTransactionStatus.completed: 'completed',
  WalletTransactionStatus.pending: 'pending',
  WalletTransactionStatus.failed: 'failed',
};

_ResaleListing _$ResaleListingFromJson(Map<String, dynamic> json) =>
    _ResaleListing(
      id: json['id'] as String,
      artworkId: json['artworkId'] as String,
      listedPrice: (json['listedPrice'] as num).toDouble(),
      status: $enumDecode(_$ResaleListingStatusEnumMap, json['status']),
      listedAt: json['listedAt'] as String,
    );

Map<String, dynamic> _$ResaleListingToJson(_ResaleListing instance) =>
    <String, dynamic>{
      'id': instance.id,
      'artworkId': instance.artworkId,
      'listedPrice': instance.listedPrice,
      'status': _$ResaleListingStatusEnumMap[instance.status]!,
      'listedAt': instance.listedAt,
    };

const _$ResaleListingStatusEnumMap = {
  ResaleListingStatus.active: 'active',
  ResaleListingStatus.sold: 'sold',
  ResaleListingStatus.withdrawn: 'withdrawn',
};

_SupportTicket _$SupportTicketFromJson(Map<String, dynamic> json) =>
    _SupportTicket(
      id: json['id'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: $enumDecode(_$SupportTicketStatusEnumMap, json['status']),
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$SupportTicketToJson(_SupportTicket instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subject': instance.subject,
      'message': instance.message,
      'status': _$SupportTicketStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt,
    };

const _$SupportTicketStatusEnumMap = {
  SupportTicketStatus.open: 'open',
  SupportTicketStatus.answered: 'answered',
  SupportTicketStatus.closed: 'closed',
};
