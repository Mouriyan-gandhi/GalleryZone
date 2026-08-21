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
const _supportKey = 'customerSupportTickets';
const _ordersKey = 'orders';
const _artworksKey = 'artworks';

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

  @override
  Future<List<ResaleListing>> listResaleListings() => mockDelay(_readResale);

  @override
  Future<ResaleListing> createResaleListing({
    required String artworkId,
    required double listedPrice,
  }) {
    if (listedPrice <= 0) return mockError('Enter a listing price');
    return mockDelay(() {
      final listing = ResaleListing(
        id: 'resale-${DateTime.now().microsecondsSinceEpoch}',
        artworkId: artworkId,
        listedPrice: listedPrice,
        status: ResaleListingStatus.active,
        listedAt: DateTime.now().toIso8601String(),
      );
      MockDb.setCollection(_resaleKey, [listing, ..._readResale()], (l) => l.toJson());
      return listing;
    });
  }

  @override
  Future<ResaleListing> withdrawResaleListing(String id) {
    final listings = _readResale();
    final existing = listings.where((l) => l.id == id).firstOrNull;
    if (existing == null) return mockError('Listing "$id" not found');
    return mockDelay(() {
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
