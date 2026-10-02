import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/payments/payment_gateway.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/auth.dart';
import 'package:gallery_zone/data/models/order.dart';
import 'package:gallery_zone/data/repositories/checkout_repository.dart';
import 'package:gallery_zone/data/repositories/customer_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/account/providers/account_providers.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:gallery_zone/features/checkout/providers/checkout_providers.dart';
import 'package:gallery_zone/features/checkout/screens/checkout_screen.dart';
import 'package:gallery_zone/features/marketplace/providers/marketplace_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/catalog_fixtures.dart';
import 'support/fake_repositories.dart';

const _address = Address(
  id: 'ad-1',
  line1: '14 Marine Drive',
  city: 'Mumbai',
  state: 'Maharashtra',
  pincode: '400020',
  isDefault: true,
);

CheckoutQuote _quote({double convenienceFee = 0, double convenienceGst = 0}) => CheckoutQuote(
      artworkId: 'aw-1',
      displayPrice: 48000,
      gstIncluded: 2285.71,
      gstRate: 0.05,
      convenienceFee: convenienceFee,
      convenienceGst: convenienceGst,
      deliveryCharge: 2500,
      total: 48000 + 2500 + convenienceFee + convenienceGst,
    );

/// A checkout that records what it was asked and answers as scripted.
class _Checkout implements CheckoutRepository {
  _Checkout({CheckoutQuote? quote, this.failQuote = false, this.outcome}) : quote = quote ?? _quote();

  final CheckoutQuote quote;
  bool failQuote;

  /// What paying does: null places the order, otherwise it throws this.
  Object? outcome;
  final placed = <({String artworkId, String addressId})>[];

  @override
  Future<CheckoutQuote> getQuote(String artworkId) async {
    if (failQuote) {
      failQuote = false;
      throw Exception('offline');
    }
    return quote;
  }

  @override
  Future<Order> createOrder({
    required String artworkId,
    required String addressId,
    required PaymentMethod paymentMethod,
    bool simulateFailure = false,
  }) async {
    final failure = outcome;
    if (failure != null) {
      outcome = null;
      throw failure;
    }
    placed.add((artworkId: artworkId, addressId: addressId));
    return Order(
      id: 'order-0001',
      artworkId: artworkId,
      addressId: addressId,
      amount: quote.displayPrice,
      gstAmount: quote.gstIncluded,
      deliveryCharge: quote.deliveryCharge,
      convenienceFee: quote.convenienceFee,
      convenienceGst: quote.convenienceGst,
      status: OrderStatus.paid,
      createdAt: '2026-10-02T10:00:00.000Z',
      statusHistory: const [],
      payment: const OrderPayment(paymentId: 'pay_123', simulated: true),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Customer implements CustomerRepository {
  @override
  Future<List<Address>> listAddresses() async => const [_address];

  @override
  Future<Address> addAddress(Address address) async => address.copyWith(id: 'ad-2');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(_Checkout checkout, {bool remote = true, Role? role = Role.customer, Artwork? artwork}) {
  return ProviderScope(
    retry: (retryCount, error) => null,
    overrides: [
      remoteBackendProvider.overrideWithValue(remote),
      initialRoleProvider.overrideWithValue(role),
      checkoutRepositoryProvider.overrideWithValue(checkout),
      customerRepositoryProvider.overrideWithValue(_Customer()),
      artworkRepositoryProvider.overrideWithValue(FakeCatalog(artworks: [artwork ?? fixtureArtwork()])),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const CheckoutScreen(artworkId: 'aw-1')),
  );
}

void _phone(WidgetTester tester, {double width = 390}) {
  tester.view.physicalSize = Size(width * 3, 1200 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _toReview(WidgetTester tester) async {
  await tester.tap(find.text('14 Marine Drive'));
  await tester.pump();
  await tester.tap(find.text('Continue to review'));
  await tester.pumpAndSettle();
}

Future<void> _toConfirm(WidgetTester tester) async {
  await _toReview(tester);
  await tester.tap(find.text('Continue to confirm'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
  });

  testWidgets("the review shows the server's quote - fee, the GST on it, delivery and total", (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(_Checkout(quote: _quote(convenienceFee: 1000, convenienceGst: 180))));
    await tester.pumpAndSettle();
    await _toReview(tester);

    expect(find.text('Review your order'), findsOneWidget);
    expect(find.text('Includes GST (5%)'), findsOneWidget);
    expect(find.text('GST on convenience fee (18%)'), findsOneWidget);
    expect(find.text('₹1,000'), findsOneWidget, reason: 'the convenience fee');
    expect(find.text('₹51,680'), findsOneWidget, reason: 'price + delivery + fee + the GST on it');
  });

  testWidgets('a quote that will not load blocks the way forward and can be retried', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(_Checkout(failQuote: true)));
    await tester.pumpAndSettle();
    await _toReview(tester);

    expect(find.textContaining("couldn't price this order"), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue to confirm')).onPressed, isNull);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue to confirm')).onPressed, isNotNull);
  });

  testWidgets('with the real backend there are three steps and Pay shows the quoted total', (tester) async {
    _phone(tester, width: 500); // wide enough to label every step
    await tester.pumpWidget(_app(_Checkout()));
    await tester.pumpAndSettle();

    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Payment'), findsNothing, reason: 'the pretend payment sheet is offline-only');

    await _toConfirm(tester);
    expect(find.text('Ready to place your order'), findsOneWidget);
    expect(find.text('Pay ₹50,500'), findsOneWidget);
  });

  testWidgets('paying places the order and shows the receipt with the payment id', (tester) async {
    _phone(tester);
    final checkout = _Checkout();
    await tester.pumpWidget(_app(checkout));
    await tester.pumpAndSettle();
    await _toConfirm(tester);

    await tester.tap(find.text('Pay ₹50,500'));
    await tester.pumpAndSettle();

    expect(checkout.placed, [(artworkId: 'aw-1', addressId: 'ad-1')]);
    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('pay_123 · simulated payment'), findsOneWidget);
    expect(find.text('View order'), findsOneWidget);
    expect(find.text('Continue browsing'), findsOneWidget);
  });

  testWidgets('closing the payment sheet leaves the buyer here, with nothing charged', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(_Checkout(outcome: const PaymentDismissedException())));
    await tester.pumpAndSettle();
    await _toConfirm(tester);

    await tester.tap(find.text('Pay ₹50,500'));
    await tester.pumpAndSettle();

    expect(find.text('Payment cancelled — nothing was charged.'), findsOneWidget);
    expect(find.text('Ready to place your order'), findsOneWidget);
    expect(find.text('Order placed'), findsNothing);
  });

  testWidgets('a declined payment says why and leaves Pay available', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(_Checkout(outcome: const PaymentFailedException('Your bank declined the payment.'))));
    await tester.pumpAndSettle();
    await _toConfirm(tester);

    await tester.tap(find.text('Pay ₹50,500'));
    await tester.pumpAndSettle();

    expect(find.text('Your bank declined the payment.'), findsOneWidget);
    expect(find.text('Pay ₹50,500'), findsOneWidget);
  });

  testWidgets('a piece that is no longer on sale is nothing to check out', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(_Checkout(), artwork: fixtureArtwork(status: ArtworkStatus.sold)));
    await tester.pumpAndSettle();
    expect(find.text('Nothing to check out.'), findsOneWidget);
  });

  testWidgets('an artist or aggregator is told buying needs a collector account', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(_Checkout(), role: Role.artist));
    await tester.pumpAndSettle();
    expect(find.text('Buying needs a collector account'), findsOneWidget);
    expect(find.text('Sign in as a collector'), findsOneWidget);
  });

  testWidgets('the offline demo keeps its pretend payment step and says so', (tester) async {
    _phone(tester, width: 500);
    await tester.pumpWidget(_app(_Checkout(), remote: false));
    await tester.pumpAndSettle();
    expect(find.text('Payment'), findsOneWidget);

    await _toConfirm(tester);
    expect(find.textContaining('Demo payment'), findsOneWidget);
  });
}
