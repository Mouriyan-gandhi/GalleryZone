import '../../../core/api/json_utils.dart';
import '../../models/artwork.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import 'catalog_mappers.dart';

/// Wire JSON -> models for buying: orders, quotes, addresses, the collection,
/// paper certificates, resale, wallets, tickets and messages.

String _s(Object? value, [String fallback = '']) => value is String ? value : fallback;
String? _sn(Object? value) => value is String && value.isNotEmpty ? value : null;

OrderStatus orderStatusFromApi(Object? code) => switch (code) {
  'paid' => OrderStatus.paid,
  'confirmed' => OrderStatus.confirmed,
  'packed' => OrderStatus.packed,
  'transit' => OrderStatus.transit,
  'delivered' => OrderStatus.delivered,
  'cancelled' => OrderStatus.cancelled,
  _ => OrderStatus.pending,
};

Order orderFromApi(Map<String, dynamic> json) {
  final status = orderStatusFromApi(json['status']);
  final createdAt = isoOf(json['createdAt']);
  final history = asMapList(json['statusHistory']);
  final snapshot = json['artwork'];
  final payment = asMap(json['payment']);
  return Order(
    id: _s(json['id']),
    artworkId: _s(json['artworkId']),
    addressId: _s(json['addressId']),
    amount: rupeesAt(json, 'displayPricePaise'),
    gstAmount: rupeesAt(json, 'gstPaise'),
    deliveryCharge: rupeesAt(json, 'deliveryChargePaise'),
    convenienceFee: rupeesAt(json, 'convenienceFeePaise'),
    convenienceGst: rupeesAt(json, 'convenienceGstPaise'),
    status: status,
    createdAt: createdAt,
    statusHistory: history.isNotEmpty
        ? [
            for (final event in history)
              OrderStatusEvent(
                status: orderStatusFromApi(event['status']),
                changedAt: isoOf(event['changedAt']),
              ),
          ]
        : [OrderStatusEvent(status: status, changedAt: createdAt)],
    artwork: snapshot is Map
        ? OrderArtwork(
            title: _s(snapshot['title'], 'Artwork'),
            artistName: _s(snapshot['artistName']),
            artistId: _s(snapshot['artistId']),
            thumbnailUrl: _s(snapshot['thumbnailUrl']),
            productCode: _s(snapshot['productCode']),
          )
        : null,
    // Only a captured payment is shown; a pending or failed attempt is not
    // a receipt.
    payment: payment['status'] == 'captured'
        ? OrderPayment(
            paymentId: _s(payment['providerPaymentId']),
            method: _s(payment['method'], 'razorpay'),
            simulated: payment['method'] == 'simulated',
          )
        : null,
  );
}

CheckoutQuote quoteFromApi(Map<String, dynamic> json) => CheckoutQuote(
  artworkId: _s(json['artworkId']),
  displayPrice: rupeesAt(json, 'displayPricePaise'),
  gstIncluded: rupeesAt(json, 'gstPaise'),
  gstRate: (json['gstRate'] as num?)?.toDouble() ?? 0.05,
  convenienceFee: rupeesAt(json, 'convenienceFeePaise'),
  convenienceGst: rupeesAt(json, 'convenienceGstPaise'),
  deliveryCharge: rupeesAt(json, 'deliveryChargePaise'),
  total: rupeesAt(json, 'totalPaise'),
);

Address addressFromApi(Map<String, dynamic> json) => Address(
  id: _s(json['id']),
  line1: _s(json['line1']),
  line2: _sn(json['line2']),
  city: _s(json['city']),
  state: _s(json['state']),
  pincode: _s(json['pincode']),
  isDefault: json['isDefault'] == true,
);

/// The address body for create/update. Only keys that are present are sent,
/// so a PATCH changes only what the person edited.
Map<String, dynamic> addressToApi(Address address) => {
  'line1': address.line1,
  if (address.line2 != null && address.line2!.trim().isNotEmpty) 'line2': address.line2,
  'city': address.city,
  'state': address.state,
  'pincode': address.pincode,
  'isDefault': address.isDefault,
};

CollectionItem collectionItemFromApi(Map<String, dynamic> json) {
  final order = json['order'];
  return CollectionItem(
    artwork: artworkFromApi(asMap(json['artwork'])),
    order: order is Map ? orderFromApi(asMap(order)) : null,
    source: json['source'] == 'marketplace_order'
        ? CollectionSource.marketplaceOrder
        : CollectionSource.transfer,
    acquiredAt: isoOrNull(json['acquiredAt']),
    fromName: _s(json['fromName']),
  );
}

PhysicalCoaRequest coaRequestFromApi(Map<String, dynamic> json) {
  final delivery = asMap(json['delivery']);
  final lines = [
    _s(delivery['line1']),
    _s(delivery['city']),
    '${_s(delivery['state'])} ${_s(delivery['pincode'])}'.trim(),
  ].where((part) => part.isNotEmpty);
  return PhysicalCoaRequest(
    id: _s(json['id']),
    artworkId: _s(json['artworkId']),
    artworkTitle: _s(json['artworkTitle'], 'Artwork'),
    coaCertificateNumber: _s(json['coaCertificateNumber']),
    requestedByName: _s(json['requestedByName']),
    requestedAt: isoOf(json['requestedAt']),
    deliveryAddress: lines.join(', '),
    status: json['status'] == 'dispatched' ? PhysicalCoaStatus.dispatched : PhysicalCoaStatus.requested,
    dispatchedAt: isoOrNull(json['dispatchedAt']),
    courierRef: _sn(json['courierRef']),
  );
}

ResaleListing resaleListingFromApi(Map<String, dynamic> json) => ResaleListing(
  id: _s(json['id']),
  artworkId: _s(json['artworkId']),
  listedPrice: rupeesAt(json, 'listedPricePaise'),
  status: switch (json['status']) {
    'sold' => ResaleListingStatus.sold,
    'withdrawn' => ResaleListingStatus.withdrawn,
    _ => ResaleListingStatus.active,
  },
  listedAt: isoOf(json['listedAt']),
);

SupportTicket supportTicketFromApi(Map<String, dynamic> json) => SupportTicket(
  id: _s(json['id']),
  subject: _s(json['subject']),
  message: _s(json['message']),
  status: switch (json['status']) {
    'answered' => SupportTicketStatus.answered,
    'closed' => SupportTicketStatus.closed,
    _ => SupportTicketStatus.open,
  },
  createdAt: isoOf(json['createdAt']),
);

// --- Wallets -----------------------------------------------------------------

/// What each ledger reason is called. The server sends the reason; the screen
/// shows the label.
({WalletTransactionType type, String label}) describeLedgerReason(String reason) {
  const known = <String, ({WalletTransactionType type, String label})>{
    // Artist
    'marketplace_settlement': (type: WalletTransactionType.settlement, label: 'Marketplace sale settled'),
    'aggregator_settlement': (type: WalletTransactionType.settlement, label: 'Gallery sale settled'),
    'withdrawal': (type: WalletTransactionType.withdrawal, label: 'Withdrawal to bank'),
    'withdrawal_payout': (type: WalletTransactionType.withdrawal, label: 'Withdrawal to bank'),
    'external_sale_penalty': (type: WalletTransactionType.adjustment, label: 'Off-platform sale fee'),
    'refund': (type: WalletTransactionType.refund, label: 'Refund'),
    // Aggregator
    'wallet_topup': (type: WalletTransactionType.adjustment, label: 'Added to wallet'),
    'reservation_hold': (type: WalletTransactionType.adjustment, label: 'Held for reservation'),
    'advance_returned_to_wallet': (type: WalletTransactionType.refund, label: 'Advance returned'),
    'hold_returned_to_wallet': (type: WalletTransactionType.refund, label: 'Held amount returned after sale'),
    'aggregator_commission': (type: WalletTransactionType.commission, label: 'Commission on sale'),
  };
  final hit = known[reason];
  if (hit != null) return hit;
  if (reason.startsWith('order:')) {
    return (type: WalletTransactionType.settlement, label: 'Order ${reason.substring(6)}');
  }
  return (type: WalletTransactionType.adjustment, label: reason.replaceAll(RegExp(r'[_:]'), ' '));
}

WalletTransactionStatus _walletStatus(Object? code) => switch (code) {
  'pending' => WalletTransactionStatus.pending,
  'failed' => WalletTransactionStatus.failed,
  _ => WalletTransactionStatus.completed,
};

/// One row of an artist's or aggregator's ledger feed. [titleOfHolding] puts
/// the piece's name on rows that belong to a reservation.
WalletTransaction walletTransactionFromApi(
  Map<String, dynamic> json, {
  Map<String, String> titleOfHolding = const {},
}) {
  final reason = _s(json['reason']);
  final described = describeLedgerReason(reason);
  final holdingId = _sn(json['holdingId']);
  final title = holdingId == null ? null : titleOfHolding[holdingId];
  return WalletTransaction(
    id: _s(json['id']),
    type: described.type,
    label: title == null ? described.label : '${described.label} · $title',
    amount: rupeesAt(json, 'amountPaise'),
    date: isoOf(json['at'] ?? json['createdAt']),
    status: _walletStatus(json['status']),
  );
}
