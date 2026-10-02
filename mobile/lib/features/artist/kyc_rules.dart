import '../../data/models/artwork.dart';
import '../../data/models/customer.dart';

/// The rules behind the artist's profile and payout forms. Port of the
/// constants and checks at the top of `profile-kyc-form.tsx`, kept apart from
/// the screen so they can be tested without building one.

/// Standard PAN shape: 5 letters, 4 digits, 1 letter.
final panPattern = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

/// Four letters, a zero, then six letters or digits.
final ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

/// Six digits, and the first can't be 0 - no Indian pincode starts with one.
final pincodePattern = RegExp(r'^[1-9][0-9]{5}$');

/// Income above which the GST field suggests registering - not enforced, just
/// a hint beside the field.
const gstSuggestedIncomeThreshold = 2000000;

/// Whether [number] is not an account number a payout should ever be sent to.
/// Account numbers are typed twice and 9-18 digits long; one that is all the
/// same digit, or a straight run (1234567890...), is what a test entry looks
/// like, so it is refused rather than paid to.
bool bankAccountNumberInvalid(String number) {
  if (number.isEmpty) return false;
  if (!RegExp(r'^\d{9,18}$').hasMatch(number)) return true;
  if (RegExp(r'^(\d)\1+$').hasMatch(number)) return true;
  return '01234567890123456789'.contains(number) || '98765432109876543210'.contains(number);
}

/// The artist's own figures, shown only to them. Derived on read from what
/// already holds the truth, never stored, so a figure cannot drift from the
/// thing it counts. Port of `profileStatsService.artistPrivate`.
typedef ArtistPrivateStats = ({double earned, double pending, double averageSale, int drafts});

ArtistPrivateStats artistPrivateStatsFor({
  required List<WalletTransaction> transactions,
  required WalletSummary wallet,
  required List<ArtistArtwork> artworks,
}) {
  final settled = [
    for (final transaction in transactions)
      if (transaction.type == WalletTransactionType.settlement &&
          transaction.status == WalletTransactionStatus.completed)
        transaction.amount,
  ];
  final earned = settled.fold<double>(0, (sum, amount) => sum + amount);
  return (
    earned: earned,
    pending: wallet.lockedBalance,
    averageSale: settled.isEmpty ? 0 : (earned / settled.length).roundToDouble(),
    drafts: artworks
        .where(
          (entry) =>
              entry.artwork.status == ArtworkStatus.draft || entry.artwork.status == ArtworkStatus.pendingApproval,
        )
        .length,
  );
}

/// What any visitor to the artist's public page can see of their work.
typedef ArtistPublicStats = ({int listed, int sold, int atGalleries});

ArtistPublicStats artistPublicStatsFor(List<ArtistArtwork> artworks) {
  const sold = {
    ArtworkStatus.sold,
    ArtworkStatus.settlementComplete,
    ArtworkStatus.delivered,
    ArtworkStatus.completed,
  };
  int count(bool Function(ArtworkStatus) test) => artworks.where((entry) => test(entry.artwork.status)).length;
  return (
    listed: count((status) => status == ArtworkStatus.marketplace),
    sold: count(sold.contains),
    atGalleries: count((status) => status == ArtworkStatus.withAggregator),
  );
}

/// `Since March 2026`, from the join date; a dash when there isn't one.
String joinedLabelFor(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return '—';
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.toLocal().month - 1]} ${date.toLocal().year}';
}
