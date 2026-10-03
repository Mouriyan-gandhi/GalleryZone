import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/data/models/aggregator.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/customer.dart' show WalletSummary;
import 'package:gallery_zone/features/aggregator/aggregator_stats.dart';
import 'package:gallery_zone/features/aggregator/country_codes.dart';

import 'support/aggregator_harness.dart';

AggregatorProfile _profile({MouAcceptance? mou}) => AggregatorProfile(
      companyName: 'Verandah',
      contactPerson: 'Meher',
      avatar: '',
      gstNumber: '',
      phone: '',
      addressLine1: '',
      bankAccountMasked: '',
      ifsc: '',
      securityDepositStatus: 'pending',
      mouAcceptance: mou,
    );

GallerySpace _space(String city, int capacity) => GallerySpace(
      id: city,
      name: city,
      addressLine1: 'x',
      city: city,
      state: 's',
      pincode: '1',
      capacity: capacity,
      coordinatorName: 'c',
    );

void main() {
  group('byFrequency', () {
    test('the commonest first, ties alphabetical, blanks and padding dropped', () {
      expect(byFrequency(['Pune', 'Goa', 'Pune', ' Goa ', 'Delhi', '', '  ']), ['Goa', 'Pune', 'Delhi']);
      expect(byFrequency(['b', 'A', 'a']), ['A', 'a', 'b'], reason: 'ties ignore case');
      expect(byFrequency(const []), isEmpty);
    });
  });

  group('aggregatorStatsOf', () {
    final stats = aggregatorStatsOf(
      holdings: [
        testHolding('a', 'One'),
        testHolding('b', 'Two'),
        testHolding('c', 'Three', status: HoldingStatus.soldPendingSettlement),
        testHolding('d', 'Four', status: HoldingStatus.returned),
      ],
      sales: [
        testSale(id: 's1', price: 90000, route: PaymentRoute.cashAtPremises),
        testSale(id: 's2', price: 40000, route: PaymentRoute.cashAtPremises, remittedAt: '2026-09-30T00:00:00.000Z'),
        testSale(id: 's3', price: 136500, buyerEmail: 'ravi@example.com'),
        testSale(id: 's4', price: 10000, buyerEmail: 'ravi@example.com'),
      ],
      spaces: [_space('Pune', 8), _space('Goa', 4), _space('Pune', 6)],
      wallet: const WalletSummary(balance: 80000, pendingBalance: 0, lockedBalance: 13000),
      profile: _profile(mou: const MouAcceptance(version: '2026.2', acceptedAt: '2026-09-01T00:00:00.000Z')),
      commissions: {'s1': 6000, 's2': 4000, 's3': 6000, 's4': 0},
    );

    test('counts pieces by what became of them', () {
      expect(stats.onDisplay, 2);
      expect(stats.piecesSold, 1);
      expect(stats.returned, 1);
    });

    test('what is owed is cash taken and not yet paid in - nothing else', () {
      expect(stats.owedToGalleryZone, 90000, reason: 's2 was paid in, s3/s4 reached GalleryZone directly');
    });

    test('earnings are the ledger credits; what is held is the wallet\'s locked part', () {
      expect(stats.commissionEarned, 16000);
      expect(stats.heldAgainstReservations, 13000);
    });

    test('spaces, capacity, where they are, and who has bought', () {
      expect(stats.gallerySpaces, 3);
      expect(stats.displayCapacity, 18);
      expect(stats.cities, ['Pune', 'Goa']);
      expect(stats.distinctBuyers, 2, reason: 'by email: anita and ravi');
      expect(stats.mouSignedAt, '2026-09-01T00:00:00.000Z');
    });

    test('nothing yet is zeroes and an unsigned agreement', () {
      final empty = aggregatorStatsOf(
        holdings: const [],
        sales: const [],
        spaces: const [],
        wallet: const WalletSummary(balance: 0, pendingBalance: 0, lockedBalance: 0),
        profile: _profile(),
        commissions: const {},
      );
      expect(empty.onDisplay, 0);
      expect(empty.owedToGalleryZone, 0);
      expect(empty.commissionEarned, 0);
      expect(empty.cities, isEmpty);
      expect(empty.mouSignedAt, isNull);
    });
  });

  group('phone numbers', () {
    test('a stored number splits at a known dial code that is followed by a space', () {
      expect(splitPhone('+91 98450 33127'), (dial: '+91', number: '98450 33127'));
      expect(splitPhone('+44 7700 900123'), (dial: '+44', number: '7700 900123'));
      expect(splitPhone('+971 50 123 4567'), (dial: '+971', number: '50 123 4567'));
    });

    test('anything else keeps India\'s code and the whole value as the number', () {
      expect(splitPhone('98450 33127'), (dial: '+91', number: '98450 33127'));
      expect(splitPhone(null), (dial: '+91', number: ''));
      expect(splitPhone('   '), (dial: '+91', number: ''));
      expect(splitPhone('+999 123456'), (dial: '+91', number: '+999 123456'), reason: 'not a code on the list');
    });

    test('joining puts the code back in front, and a number alone stays empty', () {
      expect(joinPhone('+91', ' 98450 33127 '), '+91 98450 33127');
      expect(joinPhone('+44', ''), '+44');
      expect(splitPhone(joinPhone('+65', '9123 4567')), (dial: '+65', number: '9123 4567'));
    });

    test('a number is 6 to 14 digits whatever the country, spaces aside', () {
      expect(isValidPhoneNumber('98450 12345'), isTrue);
      expect(isValidPhoneNumber('123456'), isTrue);
      expect(isValidPhoneNumber('12345'), isFalse);
      expect(isValidPhoneNumber('123456789012345'), isFalse);
      expect(isValidPhoneNumber('98450-12345'), isFalse);
      expect(isValidPhoneNumber('+91 98450 12345'), isFalse, reason: 'the dial code is not part of it');
      expect(isValidPhoneNumber(''), isFalse);
    });
  });
}
