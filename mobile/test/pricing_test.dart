import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/pricing.dart';

/// Port of `frontend-web/lib/pricing.check.ts`. Reproduces the client's own
/// worked example from the money-flow sheets. If any of these fail, the app is
/// quoting a different number than the business agreed to — and, just as bad,
/// a different number than the website.

const artistPrice = 100000.0;

/// The cycle's first placement, and a helper for "day N of the listing".
final cycleStart = DateTime.utc(2026, 1, 1);
DateTime day(int n) => cycleStart.add(Duration(days: n));

String ymd(DateTime value) =>
    value.toUtc().toIso8601String().substring(0, 10);

void main() {
  group('marketplace, exactly as the sheet works it', () {
    test('the price ladder', () {
      expect(basePriceOf(artistPrice), 130000, reason: '30% markup');
      expect(displayPriceOf(artistPrice), 136500,
          reason: 'GST inside the display price');
      expect(gstIncludedIn(136500), 6500);
      expect(exGst(136500), 130000,
          reason: 'stripping GST returns the base price');
    });

    test('the customer pays 1,39,000 and GST is never added on top', () {
      final marketplace = checkoutTotal(displayPriceOf(artistPrice));
      expect(marketplace.deliveryCharge, 2500);
      expect(marketplace.convenienceFee, 0);
      expect(marketplace.total, 139000);

      // The bug this file exists to prevent: GST is inside the price, so
      // adding it to the total charges the customer for it twice.
      expect(
        marketplace.total,
        marketplace.displayPrice +
            marketplace.deliveryCharge +
            marketplace.convenienceFee,
        reason: 'GST is never a line added to the total',
      );
    });

    test('the artist keeps the full asking price', () {
      final settlement =
          artistSettlementOf(artistPrice, SaleChannel.marketplace);
      expect(settlement.net, 100000);
      expect(settlement.deliveryDeduction, 0);
      expect(settlement.convenienceDeduction, 0);
    });

    test('GalleryZone keeps its 30% markup and nothing else', () {
      final marketplace = checkoutTotal(displayPriceOf(artistPrice));
      final settlement =
          artistSettlementOf(artistPrice, SaleChannel.marketplace);
      // What the customer paid, less GST (goes to the government), less
      // delivery (goes to the carrier), less the artist.
      expect(
        marketplace.total -
            marketplace.gstIncluded -
            marketplace.deliveryCharge -
            settlement.net,
        30000,
      );
    });
  });

  group('aggregator, exactly as the sheet works it', () {
    // The aggregator's one uplift: 1,30,000 -> 1,50,000 before tax.
    final aggregatorDisplay = withGst(150000);

    test('the customer pays 1,60,000', () {
      expect(aggregatorDisplay, 157500);
      final checkout = checkoutTotal(aggregatorDisplay);
      expect(checkout.total, 160000);
      expect(checkout.gstIncluded, 7500);
    });

    test('advance is 5% of the display price', () {
      expect(aggregatorAdvanceOf(aggregatorDisplay), 7875);
      expect(aggregatorAdvanceOf(150000), 7500,
          reason: "5% of the sheet's pre-tax figure");
    });

    test('commission is 20% of the markup over the artist price', () {
      expect(aggregatorCommissionOf(aggregatorDisplay, artistPrice), 10000);
      // An aggregator who never raises the price earns the markup share only.
      expect(
        aggregatorCommissionOf(displayPriceOf(artistPrice), artistPrice),
        6000,
      );
      expect(aggregatorCommissionOf(withGst(90000), artistPrice), 0,
          reason: 'no negative commission');
    });

    test('the artist receives 95,500', () {
      final settlement = artistSettlementOf(artistPrice, SaleChannel.aggregator);
      expect(settlement.deliveryDeduction, 2500);
      expect(settlement.convenienceDeduction, 2000, reason: '2% convenience');
      expect(settlement.net, 95500);
    });

    test('GalleryZone keeps 42,000 on an aggregator sale', () {
      final checkout = checkoutTotal(aggregatorDisplay);
      final settlement = artistSettlementOf(artistPrice, SaleChannel.aggregator);
      // Whole-flow balance: everything the customer and the aggregator put in
      // has to come back out as GST, delivery, and the three parties' shares.
      const aggregatorSettlement =
          7500 + deliveryCharge + 10000; // advance + delivery back + commission
      final moneyIn = checkout.total + 7500 + deliveryCharge;
      final moneyOut = checkout.gstIncluded +
          checkout.deliveryCharge +
          settlement.deliveryDeduction +
          aggregatorSettlement +
          settlement.net;
      expect(moneyIn - moneyOut, 42000);
    });
  });

  test('the ladder works backwards', () {
    expect(artistPriceFrom(136500), 100000);
    expect(artistPriceFrom(displayPriceOf(23400)), 23400, reason: 'round trips');
  });

  test('listing is free today', () {
    expect(listingFeeOf(artistPrice), 0);
  });

  group('payout timing', () {
    final delivered = DateTime.utc(2026, 8, 1);

    test('released 7 days after delivery', () {
      expect(ymd(payoutReleaseDate(delivered)), '2026-08-08');
    });

    test('not a day sooner', () {
      expect(
        isPayoutDue(delivered, now: DateTime.utc(2026, 8, 7, 23)),
        isFalse,
      );
      expect(
        isPayoutDue(delivered, now: DateTime.utc(2026, 8, 8, 1)),
        isTrue,
      );
    });
  });

  // Client, 25 Aug: "GST is always charged on total price of good and is not
  // charged anywhere else. So it will be on final customer price. That is as
  // per example 1,50,000."
  group('GST is charged on the goods and on nothing else', () {
    final aggregatorDisplay = withGst(150000);
    final checkout = checkoutTotal(aggregatorDisplay);

    test('the base is the artwork price, not the order total', () {
      // The tax is exactly 5% of 1,50,000 — the artwork — and not a rupee
      // more, even though the customer pays 1,60,000 in total.
      expect(checkout.gstIncluded, 7500);
      expect(checkout.gstIncluded, (150000 * 0.05).round());
      expect(
        checkout.gstIncluded < (checkout.total * 0.05).round(),
        isTrue,
        reason: 'taxing the whole order would be more than taxing the artwork',
      );
    });

    test('delivery is outside the GST base', () {
      // Adding delivery must not move the tax figure at all.
      expect(checkout.gstIncluded, gstIncludedIn(aggregatorDisplay));
    });

    test('commission carries no GST of its own', () {
      expect(
        aggregatorCommissionOf(aggregatorDisplay, artistPrice),
        (50000 * 0.2).round(),
      );
    });

    test("no GST anywhere in the artist's settlement", () {
      final settlement = artistSettlementOf(artistPrice, SaleChannel.aggregator);
      expect(
        settlement.net,
        artistPrice -
            settlement.deliveryDeduction -
            settlement.convenienceDeduction,
      );
    });
  });

  group('the five-month aggregator cycle', () {
    test('the offer price falls 2/4/6/8% of the artist price', () {
      expect(
        [1, 2, 3, 4, 5].map((m) => aggregatorOfferPriceOf(artistPrice, m)),
        [130000, 128000, 126000, 124000, 122000],
      );
    });

    test('month 6 is the transit buffer and holds at month 5', () {
      expect(aggregatorOfferPriceOf(artistPrice, 6), 122000);
      expect(aggregatorOfferPriceOf(artistPrice, 9), 122000);
    });

    test("the reduction comes out of GalleryZone's margin", () {
      // Never the artist's price, and never what the marketplace shows.
      expect(displayPriceOf(artistPrice), 136500,
          reason: 'marketplace price does not move');
      expect(aggregatorOfferPriceOf(artistPrice, 5) - artistPrice, 22000);
    });

    test('month 1 is 5% of the display price, plus delivery', () {
      final monthOne = aggregatorAdvanceForMonth(
        month: 1,
        displayPrice: 150000,
        artistPrice: artistPrice,
      );
      expect(monthOne.advance, 7500);
      expect(monthOne.basis, AdvanceBasis.displayPrice);
      expect(monthOne.payable, 7500 + deliveryCharge);
    });

    test('month 2 keeps 5% only after a price change', () {
      expect(
        aggregatorAdvanceForMonth(
          month: 2,
          displayPrice: 150000,
          artistPrice: artistPrice,
          previousAggregatorChangedPrice: true,
        ).advance,
        5000,
        reason: '5% of 1,00,000',
      );
      expect(
        aggregatorAdvanceForMonth(
          month: 2,
          displayPrice: 150000,
          artistPrice: artistPrice,
        ).basis,
        AdvanceBasis.artistPrice,
      );
      expect(
        aggregatorAdvanceForMonth(
          month: 2,
          displayPrice: 150000,
          artistPrice: artistPrice,
          previousAggregatorChangedPrice: false,
        ).advance,
        3000,
        reason: 'no price change: 3%',
      );
    });

    test('months 3-5 are always 3% of the artist price', () {
      for (final month in [3, 4, 5]) {
        for (final changed in [true, false]) {
          expect(
            aggregatorAdvanceForMonth(
              month: month,
              displayPrice: 150000,
              artistPrice: artistPrice,
              previousAggregatorChangedPrice: changed,
            ).advance,
            3000,
            reason: 'month $month, changed=$changed',
          );
        }
      }
    });
  });

  // Client, 25 Aug: "if 160 days went in 5 months with aggregator then for the
  // remaining 20 days it will not go for more aggregator — the art will extend
  // its time with the last aggregator itself. And then sent back to artist
  // upon its 180 days completion."
  group('the 180-day listing, and who keeps the leftover', () {
    test('the listing runs 180 days from the first placement', () {
      expect(ymd(listingEndsAt(cycleStart)), '2026-06-30');
    });

    test('a placement with room ends after its own thirty days', () {
      final early =
          placementWindow(cycleStartedAt: cycleStart, assignedAt: day(0));
      expect(ymd(early.expiresAt), '2026-01-31');
      expect(early.extended, isFalse);
    });

    test("the client's own case: the last aggregator absorbs the leftover", () {
      // A placement beginning on day 130 would naturally end on day 160,
      // leaving 20 days — too short for anyone else, so this aggregator keeps
      // the piece all the way to day 180 instead.
      final last =
          placementWindow(cycleStartedAt: cycleStart, assignedAt: day(130));
      expect(ymd(last.expiresAt), ymd(listingEndsAt(cycleStart)));
      expect(last.extended, isTrue);
    });

    test('exactly thirty days left is a real placement, not a stub', () {
      final exact =
          placementWindow(cycleStartedAt: cycleStart, assignedAt: day(120));
      expect(exact.extended, isFalse);
    });

    test('nobody new takes a piece with under thirty days on the clock', () {
      expect(
        canPlaceWithAnotherAggregator(
          cycleStartedAt: cycleStart,
          placementsSoFar: 3,
          now: day(160),
        ),
        isFalse,
        reason: '20 days left',
      );
      expect(
        canPlaceWithAnotherAggregator(
          cycleStartedAt: cycleStart,
          placementsSoFar: 3,
          now: day(100),
        ),
        isTrue,
      );
    });

    test('five aggregators maximum, even with time to spare', () {
      expect(
        canPlaceWithAnotherAggregator(
          cycleStartedAt: cycleStart,
          placementsSoFar: 5,
          now: day(10),
        ),
        isFalse,
      );
    });

    test('a piece nobody has taken yet has not started its clock', () {
      expect(
        canPlaceWithAnotherAggregator(
          cycleStartedAt: null,
          placementsSoFar: 0,
        ),
        isTrue,
      );
    });

    test('days left never goes negative', () {
      expect(daysLeftInListing(cycleStart, now: day(160)), 20);
      expect(daysLeftInListing(cycleStart, now: day(200)), 0);
    });
  });

  test('only the first aggregator prices the piece', () {
    expect(canSetDisplayPrice(1), isTrue);
    for (final month in [2, 3, 4, 5, 6]) {
      expect(canSetDisplayPrice(month), isFalse,
          reason: "month $month takes GalleryZone's calculated price");
    }
  });

  group('delivery', () {
    test('volumetric weight beats actual weight', () {
      // A 4kg framed canvas in a 100x70x12cm box.
      expect(
        billableWeightKg(
            actualKg: 4, lengthCm: 100, breadthCm: 70, heightCm: 12),
        16.8,
      );
    });

    test('a dense, small piece bills on its real weight', () {
      expect(
        billableWeightKg(
            actualKg: 16.5, lengthCm: 45, breadthCm: 30, heightCm: 25),
        16.5,
      );
    });

    test('no dimensions recorded falls back to the entered weight', () {
      expect(billableWeightKg(actualKg: 4), 4);
    });

    test('zones read off the postal numbering geography', () {
      expect(deliveryZoneBetween('560001', '560078'), DeliveryZone.local);
      expect(deliveryZoneBetween('560001', '562159'), DeliveryZone.regional);
      expect(deliveryZoneBetween('560001', '500001'), DeliveryZone.metro);
      expect(deliveryZoneBetween('560001', '110001'), DeliveryZone.national);
      expect(deliveryZoneBetween('560001', '190001'), DeliveryZone.remote);
    });

    test('distance matters as much as weight', () {
      final nearby = estimateDelivery(
          billableKg: 16.8, fromPincode: '560001', toPincode: '560078');
      final faraway = estimateDelivery(
          billableKg: 16.8, fromPincode: '560001', toPincode: '110001');
      expect(nearby.zone, DeliveryZone.local);
      expect(faraway.charge > nearby.charge, isTrue,
          reason: 'the same parcel costs more further away');
      expect(nearby.estimated && faraway.estimated, isTrue);

      final heavier = estimateDelivery(
          billableKg: 34.6, fromPincode: '560001', toPincode: '110001');
      expect(heavier.charge > faraway.charge, isTrue,
          reason: 'a bigger box costs more over the same distance');
    });

    test('not enough to go on falls back to the flat charge and says so', () {
      final unknown = estimateDelivery(
          billableKg: 16.8, fromPincode: '560001', toPincode: null);
      expect(unknown.charge, deliveryCharge);
      expect(unknown.estimated, isFalse);
    });
  });
}
