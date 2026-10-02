import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/api/json_utils.dart';
import '../../core/payments/payment_gateway.dart';
import '../models/aggregator.dart';
import '../models/artist_portal.dart';
import '../models/customer.dart';
import '../models/mou.dart';
import '../repositories/aggregator_repository.dart';
import '../storage/mock_db.dart';
import 'mappers/commerce_mappers.dart';
import 'mappers/portal_mappers.dart';

/// The aggregator (partner gallery) portal, from the real API.
///
/// The server owns the money: it works out each month's terms, holds the
/// advance and delivery deposit from the prepaid wallet in the same
/// transaction as the reservation, releases them on a sale or an unsold
/// return, and ends a placement by itself after thirty days. This class only
/// asks and shows — it computes no price, advance or commission of its own.
class RemoteAggregatorRepository implements AggregatorRepository {
  RemoteAggregatorRepository({required this.api, required this.gateway});

  final ApiClient api;
  final PaymentGateway gateway;

  /// The wallet top-up bounds (₹1,000 to ₹5,00,000). The API enforces them;
  /// checking here saves a round trip and words the refusal well.
  static const topupMin = aggregatorTopupMin;
  static const topupMax = aggregatorTopupMax;

  // --- Holdings -----------------------------------------------------------------

  Future<List<AggregatorHoldingView>> _holdings() async {
    final json = await api.getMap('/v1/aggregator/holdings');
    return asMapList(json['holdings']).map(holdingViewFromApi).toList();
  }

  @override
  Future<List<AggregatorHoldingView>> listCollection() => _holdings();

  @override
  Future<AggregatorHoldingView?> getHolding(String holdingId) async {
    try {
      final json = await api.getMap('/v1/aggregator/holdings/${Uri.encodeComponent(holdingId)}');
      return holdingViewFromApi(json);
    } on ApiError catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<AggregatorDashboardSummary> getDashboardSummary() async {
    final holdings = (await _holdings()).map((view) => view.holding).toList();
    final active = holdings.where((h) => h.status == HoldingStatus.reserved).length;
    final sold = holdings.where((h) => h.status == HoldingStatus.soldPendingSettlement).length;
    final returned = holdings.where((h) => h.status == HoldingStatus.returned).length;
    final finished = sold + returned;
    return AggregatorDashboardSummary(
      activeReservations: active,
      // Commission is settled by GalleryZone after the sale; the wallet shows
      // what has actually been credited.
      commissionEarned: 0,
      pendingSettlements: sold,
      conversionRate: finished == 0 ? null : (sold / finished * 100).round(),
    );
  }

  @override
  Future<List<ReservableArtwork>> listReservableInventory() async {
    final json = await api.getMap('/v1/aggregator/inventory');
    return asMapList(json['artworks']).map(reservableFromApi).toList();
  }

  /// Reserving needs a signed MOU and an approved GST number; the server
  /// refuses otherwise with a sentence that says which. [sellingPrice] is the
  /// price before GST, month 1 only, never below GalleryZone's offer.
  @override
  Future<AggregatorHolding> reserve(
    String artworkId, {
    double? sellingPrice,
    bool simulateConflict = false,
  }) async {
    final json = await api.post(
      '/v1/aggregator/holdings',
      body: {'artworkId': artworkId, 'sellingPricePaise': ?(sellingPrice == null ? null : rupeesToPaise(sellingPrice))},
    );
    return holdingFromApi(asMap(json));
  }

  @override
  Future<AggregatorHolding> requestExtension(String holdingId, String assurance) async {
    final text = assurance.trim();
    if (text.length < 10) throw Exception('Tell GalleryZone why this piece will sell');
    final json = await api.post(
      '/v1/aggregator/holdings/${Uri.encodeComponent(holdingId)}/extension',
      body: {'assurance': text},
    );
    return holdingFromApi(asMap(json));
  }

  /// The advance comes back; the delivery deposit does not — the money-flow
  /// sheet settles delivery only on a sale.
  @override
  Future<HoldingRelease> releaseHolding(String holdingId) async {
    final json = await api.post('/v1/aggregator/holdings/${Uri.encodeComponent(holdingId)}/return');
    final holding = holdingFromApi(asMap(json));
    return HoldingRelease(refunded: holding.advanceAmount, deliveryLost: holding.deliveryDeposit);
  }

  // --- Sales --------------------------------------------------------------------------

  Future<List<AggregatorSale>> _sales() async {
    final sales = (await api.getList('/v1/aggregator/sales')).map(saleFromApi).toList();
    sales.sort((a, b) => b.soldAt.compareTo(a.soldAt));
    return sales;
  }

  @override
  Future<List<AggregatorSale>> listSales() => _sales();

  /// Posts to the holding that is live for the piece. The body carries the
  /// holding id as well as the URL does — the API's schema requires it — and
  /// the sale must be at the holding's own price, so [RecordSaleInput.soldPrice]
  /// is the price the screen showed, unedited.
  @override
  Future<AggregatorSale> recordSale(RecordSaleInput input) async {
    final live = (await _holdings())
        .map((view) => view.holding)
        .where((h) => h.artworkId == input.artworkId && h.status == HoldingStatus.reserved)
        .firstOrNull;
    if (live == null) throw Exception('No active reservation found for this artwork');

    await api.post(
      '/v1/aggregator/holdings/${Uri.encodeComponent(live.id)}/sale',
      body: {
        'holdingId': live.id,
        'soldPricePaise': rupeesToPaise(input.soldPrice),
        'buyerName': input.buyerName.trim(),
        'buyerEmail': input.buyerEmail.trim(),
        if (input.buyerPhone.trim().isNotEmpty) 'buyerPhone': input.buyerPhone.trim(),
        'deliveryMode': input.deliveryMode == DeliveryMode.selfPickup ? 'self_pickup' : 'courier',
        'paymentRoute': input.paymentRoute == PaymentRoute.cashAtPremises
            ? 'cash_at_premises'
            : 'direct_to_galleryzone',
        'deliveryAddress': ?joinDeliveryAddress(input.deliveryAddress),
      },
    );
    final sale = (await _sales()).where((s) => s.holdingId == live.id).firstOrNull;
    if (sale == null) {
      throw const ApiError(status: 0, code: 'bad_response', message: 'The sale was recorded but could not be read back.');
    }
    return sale;
  }

  @override
  Future<List<AggregatorCustomer>> listCustomers() async {
    final byEmail = <String, AggregatorCustomer>{};
    for (final sale in await _sales()) {
      final existing = byEmail[sale.buyerEmail];
      byEmail[sale.buyerEmail] = AggregatorCustomer(
        buyerName: existing?.buyerName ?? sale.buyerName,
        buyerEmail: sale.buyerEmail,
        buyerPhone: existing?.buyerPhone ?? sale.buyerPhone,
        orderCount: (existing?.orderCount ?? 0) + 1,
        totalSpend: (existing?.totalSpend ?? 0) + sale.soldPrice,
      );
    }
    final customers = byEmail.values.toList()..sort((a, b) => b.totalSpend.compareTo(a.totalSpend));
    return customers;
  }

  /// preparing → dispatched → delivered. The body is exactly `{to, courierRef?}`
  /// — the API's schema is strict and refuses anything else.
  @override
  Future<AggregatorSale> advanceShipment(String saleId, {String? courierRef}) async {
    final current = (await _sales()).where((s) => s.id == saleId).firstOrNull;
    if (current == null) throw Exception('Sale not found');
    final to = switch (current.shipmentStatus) {
      ShipmentStatus.preparing => 'dispatched',
      ShipmentStatus.dispatched => 'delivered',
      ShipmentStatus.delivered => null,
    };
    if (to == null) throw Exception('Shipment is already delivered');
    final ref = courierRef?.trim() ?? '';
    await api.patch(
      '/v1/aggregator/sales/${Uri.encodeComponent(saleId)}/shipment',
      body: {'to': to, if (ref.isNotEmpty) 'courierRef': ref},
    );
    return _saleById(saleId);
  }

  Future<AggregatorSale> _saleById(String saleId) async {
    final sale = (await _sales()).where((s) => s.id == saleId).firstOrNull;
    if (sale == null) throw const ApiError(status: 404, code: 'not_found', message: 'Sale not found');
    return sale;
  }

  // --- Premises -------------------------------------------------------------------------

  @override
  Future<List<GallerySpace>> listGallerySpaces() async =>
      (await api.getList('/v1/aggregator/gallery-spaces')).map(gallerySpaceFromApi).toList();

  @override
  Future<GallerySpace> addGallerySpace(GallerySpace space) async {
    final json = asMap(
      await api.post(
        '/v1/aggregator/gallery-spaces',
        body: {
          'name': space.name.trim(),
          'addressLine1': space.addressLine1.trim(),
          'city': space.city.trim(),
          'state': space.state.trim(),
          'pincode': space.pincode.trim(),
          if (space.capacity > 0) 'capacity': space.capacity,
          if (space.coordinatorName.trim().isNotEmpty) 'coordinatorName': space.coordinatorName.trim(),
        },
      ),
    );
    return space.copyWith(id: json['id'] as String? ?? space.id);
  }

  // --- Wallet ----------------------------------------------------------------------------------

  /// The API sends the spendable part and the held part separately. The wallet
  /// screens want a total and a locked part (free = total − locked), so it is
  /// put back together here.
  @override
  Future<WalletSummary> getWallet() async {
    final json = await api.getMap('/v1/aggregator/wallet');
    final free = rupeesAt(json, 'balancePaise');
    final held = rupeesAt(json, 'heldPaise');
    return WalletSummary(balance: free + held, pendingBalance: 0, lockedBalance: held);
  }

  @override
  Future<List<WalletTransaction>> listWalletTransactions() async {
    final results = await Future.wait([api.getMap('/v1/aggregator/wallet/transactions'), _holdings()]);
    final feed = results[0] as Map<String, dynamic>;
    final holdings = results[1] as List<AggregatorHoldingView>;
    final titleOf = {for (final view in holdings) view.holding.id: view.artwork.title};
    final transactions = [
      for (final row in asMapList(feed['transactions'])) walletTransactionFromApi(row, titleOfHolding: titleOf),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// Money comes in from the aggregator's own bank through the payment sheet
  /// (client, 30 Sep 2026). The API opens the gateway order; the app only ever
  /// holds the public key and that order id. The wallet is credited once the
  /// API has verified the signed result. With the gateway off, there is no
  /// payment: the API's own simulate call credits the amount.
  @override
  Future<WalletTransaction> addFunds(double amount) async {
    if (amount < topupMin || amount > topupMax) {
      throw Exception('Add between ₹1,000 and ₹5,00,000 at a time.');
    }
    final session = asMap(await api.post('/v1/aggregator/wallet/topups', body: {'amountPaise': rupeesToPaise(amount)}));
    final topupId = session['topupId'] as String? ?? '';
    final base = '/v1/aggregator/wallet/topups/${Uri.encodeComponent(topupId)}';
    if (session['mode'] == 'razorpay') {
      final paid = await gateway.pay(GatewaySession.fromApi(session));
      await api.post(
        '$base/verify',
        body: {
          'razorpayOrderId': paid.orderId,
          'razorpayPaymentId': paid.paymentId,
          'signature': paid.signature,
        },
      );
    } else {
      await api.post('$base/simulate');
    }
    return WalletTransaction(
      id: 'topup-$topupId',
      type: WalletTransactionType.adjustment,
      label: 'Added to wallet',
      amount: amount,
      date: DateTime.now().toUtc().toIso8601String(),
      status: WalletTransactionStatus.completed,
    );
  }

  /// Aggregators are agents, not principals: no withdrawal route, by design.
  @override
  Future<WalletTransaction> requestWithdrawal(double amount) => Future.error(
        Exception(
          "Withdrawals from the wallet aren't open yet. Contact GalleryZone to have unused money returned to your bank account.",
        ),
      );

  // --- Settlements ------------------------------------------------------------------------------

  /// Settlements are run by GalleryZone; this view derives them from the
  /// aggregator's sales so they can see what is owed.
  @override
  Future<List<Settlement>> listSettlements() async {
    final results = await Future.wait([_sales(), _holdings()]);
    final sales = results[0] as List<AggregatorSale>;
    final holdings = results[1] as List<AggregatorHoldingView>;
    return [
      for (final sale in sales)
        () {
          final view = holdings.where((h) => h.holding.id == sale.holdingId).firstOrNull;
          final settled = sale.remittedAt != null || sale.paymentRoute == PaymentRoute.directToGalleryZone;
          return Settlement(
            id: 'stl-${sale.id}',
            orderId: sale.id,
            artworkTitle: view?.artwork.title ?? sale.artworkId,
            artistName: view?.artwork.artistName ?? '',
            artistAmount: 0,
            aggregatorCommission:
                (sale.soldPrice - (view?.holding.displayPrice ?? sale.soldPrice)).clamp(0, double.infinity),
            platformRevenue: 0,
            status: settled ? SettlementStatus.processed : SettlementStatus.pending,
            createdAt: sale.soldAt,
            processedAt: sale.remittedAt,
          );
        }(),
    ];
  }

  @override
  Future<List<AggregatorSale>> listRemittancesDue() async =>
      (await api.getList('/v1/aggregator/sales/remittances-due')).map(saleFromApi).toList();

  /// Cash is GalleryZone's money, due in full within two days (client,
  /// 30 Sep 2026): `wallet` takes it from the free balance, `bank` is the
  /// aggregator saying they transferred it to GalleryZone's account.
  @override
  Future<AggregatorSale> markRemitted(String saleId, {RemitVia via = RemitVia.wallet}) async {
    await api.post(
      '/v1/aggregator/sales/${Uri.encodeComponent(saleId)}/remit',
      body: {'via': via == RemitVia.bank ? 'bank' : 'wallet'},
    );
    return _saleById(saleId);
  }

  @override
  Future<Settlement> processSettlement(String saleId) =>
      Future.error(Exception('Settlements are processed by GalleryZone after delivery.'));

  // --- Analytics ----------------------------------------------------------------------------------

  @override
  Future<AggregatorAnalyticsSummary> getAnalytics() async {
    final results = await Future.wait([_sales(), _holdings()]);
    final sales = results[0] as List<AggregatorSale>;
    final holdings = results[1] as List<AggregatorHoldingView>;
    final revenue = sales.fold<double>(0, (sum, sale) => sum + sale.soldPrice);
    final markups = [
      for (final sale in sales)
        () {
          final view = holdings.where((h) => h.holding.id == sale.holdingId).firstOrNull;
          final base = view?.holding.displayPrice ?? 0;
          return base > 0 ? (sale.soldPrice - base) / base : 0.0;
        }(),
    ];
    return AggregatorAnalyticsSummary(
      salesCount: sales.length,
      totalRevenue: revenue,
      commissionPending: 0,
      commissionAvailable: 0,
      customerCount: sales.map((s) => s.buyerEmail).toSet().length,
      activeReservations: holdings.where((h) => h.holding.status == HoldingStatus.reserved).length,
      averageSoldPrice: sales.isEmpty ? 0 : (revenue / sales.length).roundToDouble(),
      averageDisplayMarkup: markups.isEmpty ? 0 : markups.reduce((a, b) => a + b) / markups.length,
    );
  }

  @override
  Future<List<CategoryPerformance>> getCategoryPerformance() async {
    final results = await Future.wait([_sales(), _holdings()]);
    final sales = results[0] as List<AggregatorSale>;
    final holdings = results[1] as List<AggregatorHoldingView>;
    final byCategory = <String, ({double revenue, int orders})>{};
    for (final sale in sales) {
      final category =
          holdings.where((h) => h.holding.id == sale.holdingId).firstOrNull?.artwork.category ?? 'other';
      final key = category.isEmpty ? 'other' : category;
      final previous = byCategory[key];
      byCategory[key] = (revenue: (previous?.revenue ?? 0) + sale.soldPrice, orders: (previous?.orders ?? 0) + 1);
    }
    return [
      for (final entry in byCategory.entries)
        CategoryPerformance(category: entry.key, revenue: entry.value.revenue, orders: entry.value.orders),
    ]..sort((a, b) => b.revenue.compareTo(a.revenue));
  }

  // --- Profile and agreement --------------------------------------------------------------------------

  @override
  Future<AggregatorProfile> getProfile() async {
    final results = await Future.wait([api.getMap('/v1/me/profile'), getMouState()]);
    return aggregatorProfileFromApi(
      results[0] as Map<String, dynamic>,
      mouAcceptance: (results[1] as MouState).acceptance,
    );
  }

  /// Sends only what changed. The bank account number is write-only and goes
  /// through [updateBankDetails]; the masked value on [profile] is never sent.
  @override
  Future<AggregatorProfile> updateProfile(AggregatorProfile profile) async {
    final current = await getProfile();
    final patch = <String, dynamic>{};
    void text(String key, String next, String now, {bool upper = false}) {
      var value = next.trim();
      if (upper) value = value.toUpperCase();
      if (value == now) return;
      patch[key] = value.isEmpty ? null : value;
    }

    if (profile.contactPerson.trim() != current.contactPerson && profile.contactPerson.trim().length >= 2) {
      patch['fullName'] = profile.contactPerson.trim();
    }
    text('companyName', profile.companyName, current.companyName);
    text('phone', profile.phone, current.phone);
    text('gstin', profile.gstNumber, current.gstNumber, upper: true);
    text('pickupLine1', profile.addressLine1, current.addressLine1);
    text('pickupCity', profile.addressCity, current.addressCity);
    text('pickupState', profile.addressState, current.addressState);
    text('pickupPincode', profile.addressPincode, current.addressPincode);
    text('headline', profile.coordinatorDesignation, current.coordinatorDesignation);

    if (patch.isEmpty) return current;
    await api.patch('/v1/me/profile', body: patch);
    return getProfile();
  }

  @override
  Future<AggregatorProfile> updateBankDetails({required String accountNumber, required String ifsc}) async {
    await api.patch(
      '/v1/me/profile',
      body: {'bankAccountNumber': accountNumber.trim(), 'ifsc': ifsc.trim().toUpperCase()},
    );
    return getProfile();
  }

  @override
  Future<MouState> getMouState() async => mouStateFromApi(await api.getMap('/v1/aggregator/mou'));

  @override
  Future<AggregatorProfile> acceptMou({
    required String signatureName,
    required String version,
    String signatureDataUrl = '',
  }) async {
    await api.post(
      '/v1/aggregator/mou/accept',
      body: {'version': version, 'signatureName': signatureName.trim(), 'signatureDataUrl': signatureDataUrl},
    );
    return getProfile();
  }

  // --- Preferences (this device only) -----------------------------------------------------------------------

  static const _settingsKey = 'aggregatorSettings';

  /// Notification preferences have no route yet, so — like the website — they
  /// are kept on the device, all on by default.
  @override
  Future<AggregatorSettings> getSettings() async => MockDb.getCollection(
        _settingsKey,
        () => [
          const AggregatorSettings(
            notifyNewAssignment: true,
            notifySaleRecorded: true,
            notifySettlementProcessed: true,
            notifyExpiryReminder: true,
          ),
        ],
        AggregatorSettings.fromJson,
        (s) => s.toJson(),
      ).first;

  @override
  Future<AggregatorSettings> updateSettings(AggregatorSettings settings) async {
    MockDb.setCollection(_settingsKey, [settings], (s) => s.toJson());
    return settings;
  }

  // --- Inbox and support ----------------------------------------------------------------------------------------

  @override
  Future<List<MessageThread>> listMessages() async {
    final messages = (await api.getList('/v1/messages')).map(messageThreadFromApi).toList();
    messages.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return messages;
  }

  @override
  Future<MessageThread> markMessageRead(String id) async {
    await api.post('/v1/messages/${Uri.encodeComponent(id)}/read');
    final updated = (await listMessages()).where((m) => m.id == id).firstOrNull;
    if (updated == null) {
      throw const ApiError(status: 404, code: 'not_found', message: 'That message could not be found.');
    }
    return updated;
  }

  @override
  Future<List<SupportTicket>> listSupportTickets() async {
    final tickets = (await api.getList('/v1/support')).map(supportTicketFromApi).toList();
    tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tickets;
  }

  @override
  Future<SupportTicket> submitSupportTicket({required String subject, required String message}) async {
    if (subject.trim().isEmpty || message.trim().isEmpty) throw Exception('Add a subject and a message');
    final created = asMap(await api.post('/v1/support', body: {'subject': subject.trim(), 'message': message.trim()}));
    return SupportTicket(
      id: created['id'] as String? ?? '',
      subject: subject.trim(),
      message: message.trim(),
      status: SupportTicketStatus.open,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }
}
