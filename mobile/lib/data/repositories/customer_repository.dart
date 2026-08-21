import '../models/customer.dart';
import '../models/order.dart';

/// The collector's own data — profile, address book, wallet, collection,
/// resale listings and support tickets. Groups what the web splits across
/// `customerService`, `customerWalletService`, `customerCollectionService`,
/// `customerResaleService` and `customerSupportService`: five files of three
/// methods each is a TypeScript module-boundary habit, not a seam that means
/// anything here, and every one of them is the same actor's data behind the
/// same future `/customer/*` API surface.
///
/// The address book lives here (not on `CheckoutRepository`) so reads and
/// writes of the same records stay together — checkout is one caller of it,
/// not its owner.
abstract class CustomerRepository {
  Future<CustomerProfile> getProfile();
  Future<CustomerProfile> updateProfile(CustomerProfile profile);

  Future<List<Address>> listAddresses();
  Future<Address> addAddress(Address address);
  Future<Address> updateAddress(Address address);
  Future<void> deleteAddress(String id);

  Future<WalletSummary> getWallet();
  Future<List<WalletTransaction>> listWalletTransactions();

  /// Delivered orders joined to their artwork — see [CollectionItem].
  Future<List<CollectionItem>> listCollection();

  Future<List<ResaleListing>> listResaleListings();
  Future<ResaleListing> createResaleListing({
    required String artworkId,
    required double listedPrice,
  });
  Future<ResaleListing> withdrawResaleListing(String id);

  Future<List<SupportTicket>> listSupportTickets();
  Future<SupportTicket> submitSupportTicket({
    required String subject,
    required String message,
  });
}
