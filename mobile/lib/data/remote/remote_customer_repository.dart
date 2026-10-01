import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/api/json_utils.dart';
import '../models/aggregator.dart' show DeliveryAddress;
import '../models/artwork.dart' show PhysicalCoaRequest;
import '../models/customer.dart';
import '../models/order.dart';
import '../repositories/customer_repository.dart';
import 'mappers/commerce_mappers.dart';
import 'mappers/portal_mappers.dart';

/// The collector's own data, from the real API: profile, address book,
/// wallet, collection, paper certificates, resale listings and support.
class RemoteCustomerRepository implements CustomerRepository {
  RemoteCustomerRepository(this.api);

  final ApiClient api;

  // --- Profile -----------------------------------------------------------------

  @override
  Future<CustomerProfile> getProfile() async =>
      customerProfileFromApi(await api.getMap('/v1/me/profile'));

  /// Sends only what changed. The bank account number is write-only — the API
  /// hands back a masked tail, so the masked value on [profile] means "the
  /// person did not touch it" and must never be sent back.
  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async {
    final current = await getProfile();
    final patch = <String, dynamic>{};
    if (profile.name.trim() != current.name) patch['fullName'] = profile.name.trim();
    if (profile.phone.trim() != current.phone) {
      patch['phone'] = profile.phone.trim().isEmpty ? null : profile.phone.trim();
    }
    if ((profile.gstin ?? '').trim().toUpperCase() != (current.gstin ?? '')) {
      final gstin = (profile.gstin ?? '').trim().toUpperCase();
      patch['gstin'] = gstin.isEmpty ? null : gstin;
    }
    if (profile.bankAccountNumber.trim() != current.bankAccountNumber) {
      final number = profile.bankAccountNumber.trim();
      patch['bankAccountNumber'] = number.isEmpty ? null : number;
    }
    if (profile.bankIfsc.trim().toUpperCase() != current.bankIfsc) {
      final ifsc = profile.bankIfsc.trim().toUpperCase();
      patch['ifsc'] = ifsc.isEmpty ? null : ifsc;
    }
    if (patch.isEmpty) return current;
    return customerProfileFromApi(asMap(await api.patch('/v1/me/profile', body: patch)));
  }

  // --- Address book --------------------------------------------------------------

  @override
  Future<List<Address>> listAddresses() async =>
      (await api.getList('/v1/account/addresses')).map(addressFromApi).toList();

  @override
  Future<Address> addAddress(Address address) async {
    final created = asMap(await api.post('/v1/account/addresses', body: addressToApi(address)));
    return address.copyWith(id: created['id'] as String? ?? address.id);
  }

  @override
  Future<Address> updateAddress(Address address) async {
    await api.patch('/v1/account/addresses/${Uri.encodeComponent(address.id)}', body: addressToApi(address));
    final updated = (await listAddresses()).where((a) => a.id == address.id).firstOrNull;
    if (updated == null) {
      throw const ApiError(status: 404, code: 'not_found', message: 'That address no longer exists.');
    }
    return updated;
  }

  @override
  Future<void> deleteAddress(String id) async {
    await api.delete('/v1/account/addresses/${Uri.encodeComponent(id)}');
  }

  // --- Wallet ----------------------------------------------------------------------

  @override
  Future<WalletSummary> getWallet() async {
    final json = await api.getMap('/v1/customer/wallet');
    return WalletSummary(balance: rupeesAt(json, 'balancePaise'), pendingBalance: 0, lockedBalance: 0);
  }

  /// The collector's wallet has no transaction feed on the API yet — an
  /// honest empty list, not a made-up one.
  @override
  Future<List<WalletTransaction>> listWalletTransactions() async => const [];

  /// Collector withdrawals aren't a server operation yet (only artists can
  /// request one). Refused plainly rather than faked.
  @override
  Future<WalletTransaction> requestWithdrawal(double amount) =>
      Future.error(Exception('Bank withdrawals for collectors are coming soon.'));

  // --- Collection -------------------------------------------------------------------

  @override
  Future<List<CollectionItem>> listCollection() async {
    final json = await api.getMap('/v1/account/collection');
    return asMapList(json['items']).map(collectionItemFromApi).toList();
  }

  // --- Paper certificates ---------------------------------------------------------------

  @override
  Future<PhysicalCoaRequest> requestPhysicalCoa({
    required String artworkId,
    required DeliveryAddress delivery,
  }) async {
    final json = await api.post(
      '/v1/coa/requests',
      body: {
        'artworkId': artworkId,
        'delivery': {
          'line1': delivery.line1,
          'city': delivery.city,
          'state': delivery.state,
          'pincode': delivery.pincode,
        },
      },
    );
    return coaRequestFromApi(asMap(json));
  }

  /// The API lists a collector's requests one piece at a time, so this reads
  /// the collection and asks about each piece — a few small calls, only when
  /// the collection screen is open.
  @override
  Future<List<PhysicalCoaRequest>> listPhysicalCoaRequests() async {
    final owned = (await listCollection()).map((item) => item.artwork.id).toSet().toList();
    final all = <PhysicalCoaRequest>[];
    for (var start = 0; start < owned.length; start += 4) {
      final batch = await Future.wait(
        owned.skip(start).take(4).map(
              (id) async => (await api.getList('/v1/coa/requests', query: {'artworkId': id}))
                  .map(coaRequestFromApi)
                  .toList(),
            ),
      );
      for (final requests in batch) {
        all.addAll(requests);
      }
    }
    all.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return all;
  }

  // --- Resale ----------------------------------------------------------------------------

  Future<List<ResaleListing>> _listings() async =>
      (await api.getList('/v1/account/resale')).map(resaleListingFromApi).toList();

  @override
  Future<List<ResaleListing>> listResaleListings() async {
    final listings = await _listings();
    listings.sort((a, b) => b.listedAt.compareTo(a.listedAt));
    return listings;
  }

  @override
  Future<ResaleListing> createResaleListing({
    required String artworkId,
    required double listedPrice,
  }) async {
    if (listedPrice <= 0) throw Exception('Enter a listing price');
    final created = asMap(
      await api.post(
        '/v1/account/resale',
        body: {'artworkId': artworkId, 'listedPricePaise': rupeesToPaise(listedPrice)},
      ),
    );
    return _find(created['id'] as String? ?? '');
  }

  @override
  Future<ResaleListing> withdrawResaleListing(String id) async {
    await api.post('/v1/account/resale/${Uri.encodeComponent(id)}/withdraw');
    return _find(id);
  }

  Future<ResaleListing> _find(String id) async {
    final found = (await _listings()).where((l) => l.id == id).firstOrNull;
    if (found == null) {
      throw const ApiError(status: 404, code: 'not_found', message: 'That listing could not be found.');
    }
    return found;
  }

  // --- Support ---------------------------------------------------------------------------------

  @override
  Future<List<SupportTicket>> listSupportTickets() async {
    final tickets = (await api.getList('/v1/support')).map(supportTicketFromApi).toList();
    tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tickets;
  }

  @override
  Future<SupportTicket> submitSupportTicket({required String subject, required String message}) async {
    if (subject.trim().isEmpty || message.trim().isEmpty) {
      throw Exception('Add a subject and a message');
    }
    final created = asMap(
      await api.post('/v1/support', body: {'subject': subject.trim(), 'message': message.trim()}),
    );
    return SupportTicket(
      id: created['id'] as String? ?? '',
      subject: subject.trim(),
      message: message.trim(),
      status: SupportTicketStatus.open,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }
}
