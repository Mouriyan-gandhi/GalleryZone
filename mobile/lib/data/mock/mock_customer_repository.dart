import '../models/artwork.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../repositories/customer_repository.dart';
import '../storage/mock_db.dart';
import 'mock_artwork_repository.dart' show seedArtworksCollection;
import 'mock_utils.dart';
import 'seed/addresses_seed.dart';
import 'seed/customer_seed.dart';

const _profileKey = 'customerProfile';
const _addressesKey = 'addresses';
const _walletKey = 'customerWallet';
const _walletTransactionsKey = 'customerWalletTransactions';
const _resaleKey = 'customerResaleListings';
const _physicalCoaKey = 'physicalCoaRequests';
const _supportKey = 'customerSupportTickets';
const _ordersKey = 'orders';
const _artworksKey = 'artworks';

/// The active resale listing for an artwork, if it is being resold rather
/// than sold by its artist. The distinction decides who gets paid.
ResaleListing? activeResaleListing(String artworkId) => MockDb.getCollection(
  _resaleKey,
  () => const <ResaleListing>[],
  ResaleListing.fromJson,
  (l) => l.toJson(),
).where((l) => l.artworkId == artworkId && l.status == ResaleListingStatus.active).firstOrNull;

/// Credits the reseller's *pending* balance and closes their listing.
///
/// On a resale the money belongs to the collector who owned the piece, not to
/// the artist who made it — crediting the artist twice for one artwork would
/// be the easy bug here. Released on delivery, like every other credit in
/// this app.
void creditSellerForResale({required ResaleListing listing, required double amount}) {
  final listings = MockDb.getCollection(
    _resaleKey,
    () => const <ResaleListing>[],
    ResaleListing.fromJson,
    (l) => l.toJson(),
  );
  MockDb.setCollection(
    _resaleKey,
    [
      for (final l in listings)
        l.id == listing.id ? l.copyWith(status: ResaleListingStatus.sold) : l,
    ],
    (l) => l.toJson(),
  );

  final now = DateTime.now();
  final wallet = _readCustomerWallet();
  MockDb.setCollection(
    _walletKey,
    [wallet.copyWith(pendingBalance: wallet.pendingBalance + amount)],
    (w) => w.toJson(),
  );
  MockDb.setCollection(
    _walletTransactionsKey,
    [
      WalletTransaction(
        id: 'wt-${now.microsecondsSinceEpoch}',
        type: WalletTransactionType.settlement,
        label: 'Resale pending: listing ${listing.id}',
        amount: amount,
        date: now.toIso8601String().substring(0, 10),
        status: WalletTransactionStatus.pending,
      ),
      ..._readCustomerTransactions(),
    ],
    (t) => t.toJson(),
  );
}

/// Moves that pending resale credit into the withdrawable balance.
void settleSellerForResale({required String listingId, required double amount}) {
  final wallet = _readCustomerWallet();
  if (wallet.pendingBalance < amount) return;

  MockDb.setCollection(
    _walletKey,
    [
      wallet.copyWith(
        pendingBalance: wallet.pendingBalance - amount,
        balance: wallet.balance + amount,
      ),
    ],
    (w) => w.toJson(),
  );

  final transactions = _readCustomerTransactions();
  final index = transactions.indexWhere(
    (t) => t.status == WalletTransactionStatus.pending && t.label.contains(listingId),
  );
  if (index == -1) return;
  MockDb.setCollection(
    _walletTransactionsKey,
    [
      for (var i = 0; i < transactions.length; i++)
        if (i == index)
          transactions[i].copyWith(
            status: WalletTransactionStatus.completed,
            label: 'Resale settled: listing $listingId',
          )
        else
          transactions[i],
    ],
    (t) => t.toJson(),
  );
}

WalletSummary _readCustomerWallet() => MockDb.getCollection(
  _walletKey,
  () => [seedCustomerWallet()],
  WalletSummary.fromJson,
  (w) => w.toJson(),
).first;

List<WalletTransaction> _readCustomerTransactions() => MockDb.getCollection(
  _walletTransactionsKey,
  seedCustomerWalletTransactions,
  WalletTransaction.fromJson,
  (t) => t.toJson(),
);

class MockCustomerRepository implements CustomerRepository {
  /// `MockDb` stores collections, and the profile/wallet are single objects —
  /// they go in as one-element lists rather than growing the storage layer a
  /// second shape for two values.
  T _readSingle<T>(String key, T Function() seed, T Function(Map<String, dynamic>) fromJson,
          Map<String, dynamic> Function(T) toJson) =>
      MockDb.getCollection(key, () => [seed()], fromJson, toJson).first;

  void _writeSingle<T>(String key, T value, Map<String, dynamic> Function(T) toJson) =>
      MockDb.setCollection(key, [value], toJson);

  List<Address> _readAddresses() =>
      MockDb.getCollection(_addressesKey, seedAddresses, Address.fromJson, (a) => a.toJson());

  List<Order> _readOrders() =>
      MockDb.getCollection(_ordersKey, seedOrders, Order.fromJson, (o) => o.toJson());

  List<Artwork> _readArtworks() => MockDb.getCollection(
        _artworksKey,
        seedArtworksCollection,
        Artwork.fromJson,
        (a) => a.toJson(),
      );

  List<ResaleListing> _readResale() => MockDb.getCollection(
        _resaleKey,
        () => const <ResaleListing>[],
        ResaleListing.fromJson,
        (l) => l.toJson(),
      );

  List<SupportTicket> _readTickets() => MockDb.getCollection(
        _supportKey,
        seedCustomerSupportTickets,
        SupportTicket.fromJson,
        (t) => t.toJson(),
      );

  @override
  Future<CustomerProfile> getProfile() => mockDelay(
        () => _readSingle(
          _profileKey,
          seedCustomerProfile,
          CustomerProfile.fromJson,
          (p) => p.toJson(),
        ),
      );

  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) => mockDelay(() {
        // Unlike the web mock — which resolves an updated object without
        // persisting it, forcing every call site to patch its query cache by
        // hand — this writes through. A repository that silently discards a
        // successful write is a trap, not a simplification.
        _writeSingle(_profileKey, profile, (p) => p.toJson());
        return profile;
      });

  @override
  Future<List<Address>> listAddresses() => mockDelay(_readAddresses);

  @override
  Future<Address> addAddress(Address address) => mockDelay(() {
        final created = address.copyWith(id: 'addr-${DateTime.now().microsecondsSinceEpoch}');
        MockDb.setCollection(_addressesKey, [..._readAddresses(), created], (a) => a.toJson());
        return created;
      });

  @override
  Future<Address> updateAddress(Address address) {
    final addresses = _readAddresses();
    if (!addresses.any((a) => a.id == address.id)) {
      return mockError('Address "${address.id}" not found');
    }
    return mockDelay(() {
      MockDb.setCollection(
        _addressesKey,
        addresses.map((a) => a.id == address.id ? address : a).toList(),
        (a) => a.toJson(),
      );
      return address;
    });
  }

  @override
  Future<void> deleteAddress(String id) {
    final addresses = _readAddresses();
    if (!addresses.any((a) => a.id == id)) return mockError('Address "$id" not found');
    return mockDelay(() {
      MockDb.setCollection(
        _addressesKey,
        addresses.where((a) => a.id != id).toList(),
        (a) => a.toJson(),
      );
    });
  }

  @override
  Future<WalletSummary> getWallet() => mockDelay(
        () => _readSingle(
          _walletKey,
          seedCustomerWallet,
          WalletSummary.fromJson,
          (w) => w.toJson(),
        ),
      );

  @override
  Future<List<WalletTransaction>> listWalletTransactions() => mockDelay(
        () => MockDb.getCollection(
          _walletTransactionsKey,
          seedCustomerWalletTransactions,
          WalletTransaction.fromJson,
          (t) => t.toJson(),
        ),
      );

  @override
  Future<List<CollectionItem>> listCollection() => mockDelay(() {
        final artworks = {for (final artwork in _readArtworks()) artwork.id: artwork};
        return [
          for (final order in _readOrders())
            if (order.status == OrderStatus.delivered && artworks[order.artworkId] != null)
              CollectionItem(order: order, artwork: artworks[order.artworkId]!),
        ];
      });

  List<PhysicalCoaRequest> _readCoaRequests() => MockDb.getCollection(
        _physicalCoaKey,
        () => const <PhysicalCoaRequest>[],
        PhysicalCoaRequest.fromJson,
        (r) => r.toJson(),
      );

  @override
  Future<List<PhysicalCoaRequest>> listPhysicalCoaRequests() =>
      mockDelay(_readCoaRequests);

  @override
  Future<PhysicalCoaRequest> requestPhysicalCoa({
    required String artworkId,
    required String deliveryAddress,
  }) {
    final artwork = _readArtworks().where((a) => a.id == artworkId).firstOrNull;
    if (artwork == null) return mockError('Artwork not found');
    if (_readCoaRequests().any(
      (r) => r.artworkId == artworkId && r.status == PhysicalCoaStatus.requested,
    )) {
      return mockError('A certificate for this piece has already been requested');
    }

    return mockDelay(() {
      final profile = _readSingle(
        _profileKey,
        seedCustomerProfile,
        CustomerProfile.fromJson,
        (p) => p.toJson(),
      );
      final request = PhysicalCoaRequest(
        id: 'coa-${DateTime.now().microsecondsSinceEpoch}',
        artworkId: artworkId,
        artworkTitle: artwork.title,
        coaCertificateNumber: artwork.coaCertificateNumber,
        requestedByName: profile.name,
        requestedAt: DateTime.now().toIso8601String(),
        deliveryAddress: deliveryAddress,
        status: PhysicalCoaStatus.requested,
      );
      // One shared collection, written by the collector and read by the
      // artist — the same arrangement as `artworks` and `holdings`.
      MockDb.setCollection(
        _physicalCoaKey,
        [request, ..._readCoaRequests()],
        (r) => r.toJson(),
      );
      return request;
    });
  }

  @override
  Future<List<ResaleListing>> listResaleListings() => mockDelay(_readResale);

  @override
  Future<ResaleListing> createResaleListing({
    required String artworkId,
    required double listedPrice,
  }) {
    if (listedPrice <= 0) return mockError('Enter a listing price');
    if (_readResale().any(
      (l) => l.artworkId == artworkId && l.status == ResaleListingStatus.active,
    )) {
      return mockError('This piece is already listed for resale');
    }

    return mockDelay(() {
      final listing = ResaleListing(
        id: 'resale-${DateTime.now().microsecondsSinceEpoch}',
        artworkId: artworkId,
        listedPrice: listedPrice,
        status: ResaleListingStatus.active,
        listedAt: DateTime.now().toIso8601String(),
      );
      MockDb.setCollection(_resaleKey, [listing, ..._readResale()], (l) => l.toJson());
      // A listed piece goes back on the marketplace at the seller's asking
      // price. Without this the listing would be a private note to nobody —
      // there is no separate resale storefront, and building one to hold a
      // handful of rows would duplicate the marketplace it belongs in.
      _relistArtwork(artworkId, price: listedPrice);
      return listing;
    });
  }

  /// Puts a delivered piece back on the marketplace at [price], or takes it
  /// off again when the listing ends.
  void _relistArtwork(String artworkId, {double? price}) {
    final artworks = _readArtworks();
    final artwork = artworks.where((a) => a.id == artworkId).firstOrNull;
    if (artwork == null) return;
    final now = DateTime.now().toIso8601String();
    final status = price == null ? ArtworkStatus.delivered : ArtworkStatus.marketplace;
    MockDb.setCollection(
      _artworksKey,
      [
        for (final a in artworks)
          if (a.id != artworkId)
            a
          else
            a.copyWith(
              status: status,
              customerPrice: price ?? a.customerPrice,
              statusHistory: [
                ...a.statusHistory,
                ArtworkStatusEvent(status: status, changedAt: now),
              ],
            ),
      ],
      (a) => a.toJson(),
    );
  }

  @override
  Future<ResaleListing> withdrawResaleListing(String id) {
    final listings = _readResale();
    final existing = listings.where((l) => l.id == id).firstOrNull;
    if (existing == null) return mockError('Listing "$id" not found');
    if (existing.status != ResaleListingStatus.active) {
      return mockError('This listing is no longer active');
    }
    return mockDelay(() {
      _relistArtwork(existing.artworkId);
      final updated = existing.copyWith(status: ResaleListingStatus.withdrawn);
      MockDb.setCollection(
        _resaleKey,
        listings.map((l) => l.id == id ? updated : l).toList(),
        (l) => l.toJson(),
      );
      return updated;
    });
  }

  @override
  Future<List<SupportTicket>> listSupportTickets() => mockDelay(_readTickets);

  @override
  Future<SupportTicket> submitSupportTicket({
    required String subject,
    required String message,
  }) {
    if (subject.trim().isEmpty) return mockError('A subject is required');
    if (message.trim().isEmpty) return mockError('Enter a message');
    return mockDelay(() {
      final ticket = SupportTicket(
        id: 'cust-ticket-${DateTime.now().microsecondsSinceEpoch}',
        subject: subject.trim(),
        message: message.trim(),
        status: SupportTicketStatus.open,
        createdAt: DateTime.now().toIso8601String(),
      );
      MockDb.setCollection(_supportKey, [ticket, ..._readTickets()], (t) => t.toJson());
      return ticket;
    });
  }
}
