import 'dart:io';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/api/json_utils.dart';
import '../../core/format.dart';
import '../../core/pricing.dart' show artistPayoutDaysAfterDelivery;
import '../models/artist_portal.dart';
import '../models/artwork.dart';
import '../models/customer.dart';
import '../models/mou.dart';
import '../models/order.dart';
import '../models/pricing_rules.dart';
import '../repositories/artist_repository.dart';
import '../storage/mock_db.dart';
import 'mappers/catalog_mappers.dart';
import 'mappers/commerce_mappers.dart';
import 'mappers/portal_mappers.dart';

/// Reads a picked photo's bytes. A seam so the upload flow can be tested
/// without touching the file system.
typedef FileBytes = Future<List<int>> Function(String path);

/// The artist portal, from the real API: artworks (with the photo pipeline),
/// the wallet, orders and the settlements projected from them, penalties, the
/// profile and its payout account, paper certificates and the MOU.
class RemoteArtistRepository implements ArtistRepository {
  RemoteArtistRepository(this.api, {FileBytes? readFile})
      : _readFile = readFile ?? ((path) => File(path).readAsBytes());

  final ApiClient api;
  final FileBytes _readFile;

  static const maxImageBytes = 15 * 1024 * 1024;
  static const maxImages = 8;

  /// What the API accepts for a photo.
  static const imageTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  static const minimumWithdrawal = 1000.0;

  // --- Artworks ------------------------------------------------------------------

  @override
  Future<List<ArtistArtwork>> listArtworks() async {
    final json = await api.getMap('/v1/artist/artworks');
    return asMapList(json['artworks']).map(ownerArtworkFromApi).toList();
  }

  @override
  Future<ArtistArtwork?> getArtwork(String artworkId) async {
    try {
      return ownerArtworkFromApi(await api.getMap('/v1/artist/artworks/${Uri.encodeComponent(artworkId)}'));
    } on ApiError catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  Map<String, dynamic> _artworkBody(SubmitArtworkInput input, {String? mode}) => {
        'title': input.title.trim(),
        'description': input.description.trim(),
        'category': input.category,
        'medium': input.medium,
        'artistPricePaise': rupeesToPaise(input.artistPrice),
        'listingType': listingTypeToApi(input.listingType),
        if (input.dimensions != null && input.dimensions!.trim().isNotEmpty) 'dimensions': input.dimensions!.trim(),
        'yearCreated': ?input.yearCreated,
        'mode': ?mode,
        'artworkType': input.artworkType,
        'paintingStyle': input.paintingStyle,
        'insuranceOpted': input.insuranceOpted,
        'insuranceNumber': input.insuranceNumber,
        'nfcTagId': input.nfcTagId,
        if (input.physical != null) 'physical': physicalToApi(input.physical!),
      };

  /// Photos upload after the record exists. When the artist asked for review
  /// the piece is first saved as a draft and only moved to review once every
  /// photo is in — a failed upload leaves a draft they can fix, never a
  /// review request with missing pictures, and a retry never makes a
  /// duplicate.
  @override
  Future<Artwork> submitArtwork(SubmitArtworkInput input) async {
    if (input.title.trim().isEmpty) throw Exception('A title is required');
    if (input.artistPrice <= 0) throw Exception('Enter your price for this artwork');

    final hasUploads = input.images.any((image) => image.id == null);
    final created = ownerArtworkFromApi(
      asMap(
        await api.post(
          '/v1/artist/artworks',
          body: _artworkBody(input, mode: hasUploads || input.asDraft ? 'draft' : 'review'),
        ),
      ),
    );
    final id = created.artwork.id;

    try {
      await _syncImages(id, input.images, const []);
    } on Exception catch (error) {
      final reason = error.toString().replaceFirst('Exception: ', '');
      throw ArtworkSavedAsDraft(
        id,
        'Saved "${input.title.trim()}" as a draft, but $reason Open it from My Artworks to add the photo and submit.',
      );
    }
    if (hasUploads && !input.asDraft) {
      await api.patch('/v1/artist/artworks/${Uri.encodeComponent(id)}', body: {'mode': 'review'});
    }
    return (await _owned(id)).artwork;
  }

  @override
  Future<Artwork> updateArtwork({required String artworkId, required SubmitArtworkInput patch}) async {
    if (patch.title.trim().isEmpty) throw Exception('A title is required');
    if (patch.artistPrice <= 0) throw Exception('Enter your price for this artwork');

    final current = await _owned(artworkId);
    // `asDraft` is ignored on purpose: an edit never moves a piece between the
    // draft and review queues.
    await api.patch('/v1/artist/artworks/${Uri.encodeComponent(artworkId)}', body: _artworkBody(patch));
    await _syncImages(artworkId, patch.images, [
      for (final image in current.artwork.images)
        if (image.id != null) image.id!,
    ]);
    return (await _owned(artworkId)).artwork;
  }

  @override
  Future<Artwork> submitForReview(String artworkId) async {
    await api.patch('/v1/artist/artworks/${Uri.encodeComponent(artworkId)}', body: {'mode': 'review'});
    return (await _owned(artworkId)).artwork;
  }

  Future<ArtistArtwork> _owned(String artworkId) async {
    final artwork = await getArtwork(artworkId);
    if (artwork == null) {
      throw const ApiError(status: 404, code: 'not_found', message: 'That artwork could not be found.');
    }
    return artwork;
  }

  /// Brings the piece's photos in line with the form: delete the removed
  /// ones, upload the new ones, then apply the order.
  Future<void> _syncImages(String artworkId, List<ArtworkImage> images, List<String> existingIds) async {
    final base = '/v1/artist/artworks/${Uri.encodeComponent(artworkId)}/images';
    final keep = {for (final image in images) if (image.id != null) image.id!};
    for (final id in existingIds) {
      if (!keep.contains(id)) await api.delete('$base/${Uri.encodeComponent(id)}');
    }
    final finalIds = <String>[];
    for (final image in images) {
      finalIds.add(image.id ?? await _uploadOne(base, image));
    }
    final unchanged = finalIds.length == existingIds.length &&
        [for (var i = 0; i < finalIds.length; i++) finalIds[i] == existingIds[i]].every((same) => same);
    if (finalIds.length > 1 && !unchanged) {
      await api.put('$base/order', body: {'imageIds': finalIds});
    }
  }

  /// Primary path: a pre-signed PUT straight to the storage bucket (the bytes
  /// never touch the API). If the bucket can't be reached the bytes go
  /// through the API instead — slower, but a dead upload is never the
  /// artist's problem. Errors are worded for the artist.
  Future<String> _uploadOne(String base, ArtworkImage image) async {
    final path = image.url;
    final name = path.split(RegExp(r'[\\/]')).last;
    final extension = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final contentType = imageTypes[extension];
    if (contentType == null) throw Exception('"$name" isn\'t a JPEG, PNG or WebP image.');

    final bytes = await _readFile(path);
    if (bytes.length > maxImageBytes) {
      throw Exception('"$name" is larger than 15 MB. Please resize it and try again.');
    }

    try {
      final slot = asMap(
        await api.post('$base/upload-url', body: {'contentType': contentType, 'contentLength': bytes.length}),
      );
      final headers = <String, String>{
        for (final entry in asMap(slot['headers']).entries) entry.key: '${entry.value}',
      };
      await api.putToSignedUrl(slot['uploadUrl'] as String, bytes, headers: headers);
      final confirmed = asMap(
        await api.post('$base/confirm', body: {'key': slot['key'], 'altText': image.altText}),
      );
      return confirmed['id'] as String;
    } on ApiError catch (error) {
      // The API itself refusing (too many photos, not your piece…) is final;
      // only a failure to reach the bucket earns the fallback.
      if (error.status != 0) throw Exception('"$name": ${error.message}');
    }

    try {
      final uploaded = asMap(
        await api.postBytes(
          '$base/upload',
          bytes,
          headers: {'Content-Type': contentType, 'X-Alt-Text': Uri.encodeComponent(image.altText)},
        ),
      );
      return uploaded['id'] as String;
    } on ApiError catch (error) {
      if (error.status != 0) throw Exception('"$name": ${error.message}');
      throw Exception('"$name" couldn\'t be uploaded — check your connection and try again.');
    }
  }

  @override
  Future<Artwork> markSoldElsewhere(String artworkId) async {
    final json = asMap(await api.post('/v1/artist/artworks/${Uri.encodeComponent(artworkId)}/sold-elsewhere'));
    final artwork = json['artwork'];
    if (artwork is! Map) {
      throw const ApiError(status: 404, code: 'not_found', message: 'That artwork could not be found.');
    }
    return ownerArtworkFromApi(asMap(artwork)).artwork;
  }

  @override
  Future<List<ExternalSalePenalty>> listPenalties() async {
    final json = await api.getMap('/v1/artist/penalties');
    return asMapList(json['penalties']).map(penaltyFromApi).toList();
  }

  @override
  Future<Artwork> linkNfcTag(String artworkId, String nfcTagId) async {
    await api.patch('/v1/artist/artworks/${Uri.encodeComponent(artworkId)}', body: {'nfcTagId': nfcTagId});
    return (await _owned(artworkId)).artwork;
  }

  // --- Wallet ---------------------------------------------------------------------------

  /// `available` is what can be withdrawn; `locked` is requests awaiting
  /// approval. Sales still inside the 7-day clock are not in the ledger yet,
  /// so [WalletSummary.pendingBalance] is 0 — the Settlements view carries
  /// that wait.
  @override
  Future<WalletSummary> getWallet() async {
    final json = await api.getMap('/v1/artist/wallet');
    return WalletSummary(
      balance: rupeesAt(json, 'availablePaise'),
      pendingBalance: 0,
      lockedBalance: rupeesAt(json, 'lockedPaise'),
    );
  }

  @override
  Future<List<WalletTransaction>> listWalletTransactions() async {
    final json = await api.getMap('/v1/artist/wallet/transactions');
    return asMapList(json['transactions']).map(walletTransactionFromApi).toList();
  }

  @override
  Future<WalletTransaction> requestWithdrawal(double amount) async {
    if (amount < minimumWithdrawal) throw Exception('Minimum withdrawal is ₹1,000');
    final json = asMap(await api.post('/v1/artist/withdrawals', body: {'amountPaise': rupeesToPaise(amount)}));
    return WalletTransaction(
      id: json['withdrawalId'] as String? ?? '',
      type: WalletTransactionType.withdrawal,
      label: 'Withdrawal to bank',
      amount: -amount,
      date: DateTime.now().toUtc().toIso8601String(),
      status: WalletTransactionStatus.pending,
    );
  }

  // --- Profile ---------------------------------------------------------------------------

  @override
  Future<ArtistProfileDetails> getProfile() async =>
      artistProfileDetailsFromApi(await api.getMap('/v1/me/profile'));

  /// Sends only what changed. The bank account number is write-only and is not
  /// part of this — see [updateBankDetails]; the masked value on [profile]
  /// must never be sent back.
  @override
  Future<ArtistProfileDetails> updateProfile(ArtistProfileDetails profile) async {
    final current = await getProfile();
    final patch = <String, dynamic>{};

    void text(String key, String? next, String? now, {bool upper = false}) {
      var value = (next ?? '').trim();
      if (upper) value = value.toUpperCase();
      if (value == (now ?? '')) return;
      patch[key] = value.isEmpty ? null : value;
    }

    if (profile.fullName.trim() != current.fullName && profile.fullName.trim().length >= 2) {
      patch['fullName'] = profile.fullName.trim();
    }
    text('phone', profile.phone, current.phone);
    text('bio', profile.bio, current.bio);
    text('instagram', profile.instagram, current.instagram);
    text('website', profile.website, current.website);
    text('socialProofVideoUrl', profile.socialProofVideoUrl, current.socialProofVideoUrl);
    text('pan', profile.pan, current.pan, upper: true);
    text('gstin', profile.gstin, current.gstin, upper: true);
    text('headline', profile.headline, current.headline);
    text('location', profile.location, current.location);
    text('pickupLine1', profile.pickupLine1, current.pickupLine1);
    text('pickupLine2', profile.pickupLine2, current.pickupLine2);
    text('pickupCity', profile.pickupCity, current.pickupCity);
    text('pickupState', profile.pickupState, current.pickupState);
    text('pickupPincode', profile.pickupPincode, current.pickupPincode);

    if (patch.isEmpty) return current;
    return artistProfileDetailsFromApi(asMap(await api.patch('/v1/me/profile', body: patch)));
  }

  @override
  Future<ArtistProfileDetails> updateBankDetails({String accountNumber = '', required String ifsc}) async =>
      artistProfileDetailsFromApi(
        asMap(
          await api.patch(
            '/v1/me/profile',
            body: {
              if (accountNumber.trim().isNotEmpty) 'bankAccountNumber': accountNumber.trim(),
              'ifsc': ifsc.trim().toUpperCase(),
            },
          ),
        ),
      );

  // --- Orders and settlements -----------------------------------------------------------------

  @override
  Future<List<ArtistOrder>> listOrders() async {
    final json = await api.getMap('/v1/artist/orders');
    return [
      for (final row in asMapList(json['orders']))
        ArtistOrder(order: orderFromApi(row), artistPayout: rupeesAt(row, 'artistNetPaise')),
    ];
  }

  /// A projection of the artist's own orders: paid is pending until the piece
  /// is delivered and the payout window has passed, then processed. The
  /// amounts are the artist's net for that order.
  @override
  Future<List<Settlement>> listSettlements() async {
    final orders = await listOrders();
    final now = DateTime.now();
    return [
      for (final entry in orders)
        if (entry.order.status != OrderStatus.pending && entry.order.status != OrderStatus.cancelled)
          _settlementOf(entry, now),
    ];
  }

  Settlement _settlementOf(ArtistOrder entry, DateTime now) {
    final order = entry.order;
    final deliveredAt = order.statusHistory
        .where((event) => event.status == OrderStatus.delivered)
        .map((event) => event.changedAt)
        .lastOrNull;
    final releaseAfter = deliveredAt == null
        ? null
        : DateTime.parse(deliveredAt).add(const Duration(days: artistPayoutDaysAfterDelivery));
    final released = releaseAfter != null && !releaseAfter.isAfter(now);
    return Settlement(
      id: 'stl-${order.id}',
      orderId: order.id,
      artworkTitle: order.artwork?.title ?? order.artworkId,
      artistName: '',
      artistAmount: entry.artistPayout,
      aggregatorCommission: 0,
      platformRevenue: (order.amount - entry.artistPayout).clamp(0, double.infinity),
      status: released ? SettlementStatus.processed : SettlementStatus.pending,
      createdAt: order.createdAt,
      processedAt: released ? releaseAfter.toUtc().toIso8601String() : null,
      releaseAfter: releaseAfter?.toUtc().toIso8601String(),
    );
  }

  /// Which of this artist's pieces are on aggregators' walls isn't served to
  /// artists yet, so — like the website — this is honestly empty.
  @override
  Future<List<GallerySpacePlacement>> listGallerySpaces() async => const [];

  // --- Dashboard ----------------------------------------------------------------------------------

  @override
  Future<List<ArtistKpi>> getKpis() async {
    final results = await Future.wait([getWallet(), listArtworks(), listWalletTransactions()]);
    final wallet = results[0] as WalletSummary;
    final artworks = results[1] as List<ArtistArtwork>;
    final transactions = results[2] as List<WalletTransaction>;

    const soldStatuses = {
      ArtworkStatus.sold,
      ArtworkStatus.settlementComplete,
      ArtworkStatus.delivered,
      ArtworkStatus.completed,
    };
    final pending = artworks.where((a) => a.artwork.status == ArtworkStatus.pendingApproval).length;
    final soldCount = artworks.where((a) => soldStatuses.contains(a.artwork.status)).length;
    final revenue = transactions
        .where((t) => t.type == WalletTransactionType.settlement && t.status == WalletTransactionStatus.completed)
        .fold<double>(0, (sum, t) => sum + (t.amount > 0 ? t.amount : 0));
    return [
      ArtistKpi(
        label: 'Total revenue',
        value: formatInr(revenue),
        delta: soldCount > 0 ? '$soldCount ${soldCount == 1 ? 'sale' : 'sales'} settled' : 'No sales settled yet',
        positive: soldCount > 0,
      ),
      ArtistKpi(
        label: 'Wallet balance',
        value: formatInr(wallet.balance),
        delta: wallet.lockedBalance > 0
            ? '${formatInr(wallet.lockedBalance)} withdrawal pending'
            : 'Available to withdraw',
        positive: true,
      ),
      ArtistKpi(
        label: 'Pending approval',
        value: '$pending',
        delta: pending > 0 ? 'Awaiting admin review' : 'All caught up',
        positive: pending == 0,
      ),
    ];
  }

  /// Derived from real events — artwork status history and wallet
  /// transactions, newest first. No stored feed, so nothing to drift.
  @override
  Future<List<ActivityEntry>> listActivity() async {
    final results = await Future.wait([listArtworks(), listWalletTransactions()]);
    final artworks = results[0] as List<ArtistArtwork>;
    final transactions = results[1] as List<WalletTransaction>;
    final entries = <({String sortKey, ActivityEntry entry})>[];

    for (final owned in artworks) {
      final a = owned.artwork;
      for (final event in a.statusHistory) {
        final (kind, title, detail) = switch (event.status) {
          ArtworkStatus.pendingApproval => (
              ActivityKind.artworkSubmitted,
              'Submitted for review',
              '"${a.title}" is with the curation team',
            ),
          ArtworkStatus.marketplace => (
              ActivityKind.artworkApproved,
              'Artwork approved',
              '"${a.title}" is live on the marketplace',
            ),
          ArtworkStatus.returned => (
              ActivityKind.artworkSubmitted,
              'Artwork returned',
              '"${a.title}" needs changes before it can be listed',
            ),
          ArtworkStatus.sold => (ActivityKind.settlement, 'Artwork sold', '"${a.title}" has a buyer'),
          _ => (null, '', ''),
        };
        if (kind == null) continue;
        entries.add((
          sortKey: event.changedAt,
          entry: ActivityEntry(
            id: '${a.id}:${event.changedAt}:${event.status.name}',
            kind: kind,
            title: title,
            detail: detail,
            time: event.changedAt,
          ),
        ));
      }
    }
    for (final t in transactions) {
      if (t.type == WalletTransactionType.withdrawal) {
        entries.add((
          sortKey: t.date,
          entry: ActivityEntry(
            id: 'wt:${t.id}',
            kind: ActivityKind.withdrawal,
            title: t.status == WalletTransactionStatus.pending ? 'Withdrawal requested' : 'Withdrawal processed',
            detail: '${formatInr(t.amount.abs())} · ${t.label}',
            time: t.date,
          ),
        ));
      } else if (t.type == WalletTransactionType.settlement) {
        entries.add((
          sortKey: t.date,
          entry: ActivityEntry(
            id: 'wt:${t.id}',
            kind: ActivityKind.settlement,
            title: 'Settlement credited',
            detail: '${formatInr(t.amount)} · ${t.label}',
            time: t.date,
          ),
        ));
      }
    }
    entries.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return [for (final item in entries.take(30)) item.entry];
  }

  // --- Paper certificates --------------------------------------------------------------------------

  @override
  Future<List<PhysicalCoaRequest>> listPhysicalCoaRequests() async {
    final requests = (await api.getList('/v1/artist/coa/requests')).map(coaRequestFromApi).toList();
    requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return requests;
  }

  @override
  Future<PhysicalCoaRequest> dispatchPhysicalCoa(String requestId, String courierRef) async {
    if (courierRef.trim().isEmpty) throw Exception('Enter the courier or tracking reference');
    return coaRequestFromApi(
      asMap(
        await api.post(
          '/v1/artist/coa/requests/${Uri.encodeComponent(requestId)}/dispatch',
          body: {'courierRef': courierRef.trim()},
        ),
      ),
    );
  }

  // --- MOU -----------------------------------------------------------------------------------------------

  @override
  Future<MouState> getMouState() async => mouStateFromApi(await api.getMap('/v1/artist/mou'));

  @override
  Future<MouAcceptance?> getMouAcceptance() async => (await getMouState()).acceptance;

  @override
  Future<MouAcceptance> acceptMou({
    required String signatureName,
    required String version,
    String signatureDataUrl = '',
  }) async =>
      mouAcceptanceFromApi(
        asMap(
          await api.post(
            '/v1/artist/mou/accept',
            body: {'version': version, 'signatureName': signatureName.trim(), 'signatureDataUrl': signatureDataUrl},
          ),
        ),
      );

  // --- Rules ---------------------------------------------------------------------------------------------------

  @override
  Future<PricingRules?> getPricingRules() async {
    final json = await api.getMap('/v1/pricing-rules', auth: false);
    return pricingRulesFromApi(json['rates']);
  }

  // --- Preferences (this device only) ----------------------------------------------------------------------------

  static const _settingsKey = 'artistSettings';

  /// Notification preferences have no route yet, so — like the website — they
  /// are kept on the device. Defaults are all-on, which is what the emails do
  /// today.
  @override
  Future<ArtistSettings> getSettings() async => MockDb.getCollection(
        _settingsKey,
        () => [
          const ArtistSettings(
            notifyArtworkApproved: true,
            notifyNewSale: true,
            notifyWithdrawalProcessed: true,
            notifyNewMessage: true,
          ),
        ],
        ArtistSettings.fromJson,
        (s) => s.toJson(),
      ).first;

  @override
  Future<ArtistSettings> updateSettings(ArtistSettings settings) async {
    MockDb.setCollection(_settingsKey, [settings], (s) => s.toJson());
    return settings;
  }

  // --- Inbox and support -------------------------------------------------------------------------------------------

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
