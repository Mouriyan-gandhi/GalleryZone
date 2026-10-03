import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/data/models/aggregator.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/artwork.dart' show ReviewStatus;
import 'package:gallery_zone/data/models/customer.dart' show SupportTicket, SupportTicketStatus, WalletSummary;
import 'package:gallery_zone/data/repositories/aggregator_repository.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_account_screens.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_analytics_screen.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_dashboard_screen.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_profile_screen.dart';
import 'package:gallery_zone/features/shell/chart_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/aggregator_harness.dart';

// --- Fixtures --------------------------------------------------------------------

AggregatorProfile _profile({
  ReviewStatus gst = ReviewStatus.approved,
  bool signed = true,
  String phone = '+91 98450 12345',
  String designation = 'Gallery Manager',
  ReviewStatus aadhaar = ReviewStatus.notSubmitted,
  String? aadhaarMasked,
  String bank = '•••• •••• •••• 4821',
}) =>
    AggregatorProfile(
      companyName: 'Verandah Art House',
      contactPerson: 'Meher Chatterjee',
      avatar: '',
      gstNumber: '29ABCDE1234F1Z5',
      phone: phone,
      addressLine1: '14 Church Street',
      bankAccountMasked: bank,
      ifsc: 'HDFC0001234',
      securityDepositStatus: 'pending',
      gstStatus: gst,
      email: 'meher@example.com',
      addressCity: 'Bengaluru',
      addressState: 'Karnataka',
      addressPincode: '560001',
      aadhaarStatus: aadhaar,
      aadhaarMasked: aadhaarMasked,
      coordinatorDesignation: designation,
      coordinatorPhone: phone,
      coordinatorEmail: 'meher@example.com',
      mouAcceptance: signed
          ? const MouAcceptance(version: '2026.2', acceptedAt: '2026-09-01T00:00:00.000Z', signatureName: 'Meher Chatterjee')
          : null,
    );

const _space = GallerySpace(
  id: 'sp1',
  name: 'Verandah — Main Gallery',
  addressLine1: '14 Church Street',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560001',
  capacity: 12,
  coordinatorName: 'Meher Chatterjee',
);

MessageThread _message(String id, String subject, {bool unread = true}) => MessageThread(
      id: id,
      from: 'GalleryZone Audit Team',
      subject: subject,
      preview: 'A GalleryZone auditor will visit on 18 Aug 2026.',
      body: 'Please ensure all pieces are accessible at your premises.',
      unread: unread,
      receivedAt: '2026-09-20T00:00:00.000Z',
    );

/// An in-memory aggregator service for the account-side screens.
class _Acct implements AggregatorRepository {
  _Acct({
    AggregatorProfile? profile,
    this.summary = const AggregatorDashboardSummary(
      activeReservations: 2,
      commissionEarned: 12345,
      pendingSettlements: 1,
      conversionRate: 67,
    ),
    this.holdings = const [],
    this.sales = const [],
    this.spaces = const [],
    this.commissions = const {},
    this.messages = const [],
    this.categories = const [],
  }) : profile = profile ?? _profile();

  AggregatorProfile profile;
  AggregatorDashboardSummary summary;
  List<AggregatorHoldingView> holdings;
  List<AggregatorSale> sales;
  List<GallerySpace> spaces;
  Map<String, double> commissions;
  List<MessageThread> messages;
  List<SupportTicket> tickets = [];
  List<CategoryPerformance> categories;

  // 60,000 in the wallet, 9,000 of it held for reservations.
  final double balance = 60000;
  final double locked = 9000;
  AggregatorSettings settings = const AggregatorSettings(
    notifyNewAssignment: true,
    notifySaleRecorded: true,
    notifySettlementProcessed: false,
    notifyExpiryReminder: true,
  );
  AggregatorAnalyticsSummary analytics = const AggregatorAnalyticsSummary(
    salesCount: 4,
    totalRevenue: 500000,
    commissionPending: 0,
    commissionAvailable: 0,
    customerCount: 3,
    activeReservations: 1,
    averageSoldPrice: 125000,
    averageDisplayMarkup: 8000,
  );

  final profileUpdates = <AggregatorProfile>[];
  final bankUpdates = <({String account, String ifsc})>[];
  final read = <String>[];
  final settingsWrites = <AggregatorSettings>[];
  final submitted = <({String subject, String message})>[];
  Completer<void>? holdSubmit;
  Object? failSummaryWith;
  Object? failProfileWith;
  Object? failBankWith;
  Object? failMessagesWith;
  Object? failSettingsWith;
  Object? failSpacesWith;
  Object? failAnalyticsWith;

  @override
  Future<AggregatorDashboardSummary> getDashboardSummary() async {
    if (failSummaryWith != null) {
      final error = failSummaryWith!;
      failSummaryWith = null;
      throw error;
    }
    return summary;
  }

  @override
  Future<List<AggregatorHoldingView>> listCollection() async => List.of(holdings);

  @override
  Future<List<AggregatorSale>> listSales() async => List.of(sales);

  @override
  Future<List<GallerySpace>> listGallerySpaces() async {
    if (failSpacesWith != null) {
      final error = failSpacesWith!;
      failSpacesWith = null;
      throw error;
    }
    return List.of(spaces);
  }

  @override
  Future<WalletSummary> getWallet() async => WalletSummary(balance: balance, pendingBalance: 0, lockedBalance: locked);

  @override
  Future<Map<String, double>> saleCommissions() async => Map.of(commissions);

  @override
  Future<AggregatorProfile> getProfile() async => profile;

  @override
  Future<AggregatorProfile> updateProfile(AggregatorProfile next) async {
    if (failProfileWith != null) throw failProfileWith!;
    profileUpdates.add(next);
    profile = next;
    return next;
  }

  @override
  Future<AggregatorProfile> updateBankDetails({required String accountNumber, required String ifsc}) async {
    if (failBankWith != null) throw failBankWith!;
    bankUpdates.add((account: accountNumber, ifsc: ifsc));
    profile = profile.copyWith(bankAccountMasked: '•••• •••• •••• ${accountNumber.substring(accountNumber.length - 4)}', ifsc: ifsc);
    return profile;
  }

  @override
  Future<AggregatorAnalyticsSummary> getAnalytics() async {
    if (failAnalyticsWith != null) {
      final error = failAnalyticsWith!;
      failAnalyticsWith = null;
      throw error;
    }
    return analytics;
  }

  @override
  Future<List<CategoryPerformance>> getCategoryPerformance() async => List.of(categories);

  @override
  Future<List<MessageThread>> listMessages() async {
    if (failMessagesWith != null) {
      final error = failMessagesWith!;
      failMessagesWith = null;
      throw error;
    }
    return List.of(messages);
  }

  @override
  Future<MessageThread> markMessageRead(String id) async {
    read.add(id);
    messages = [for (final m in messages) m.id == id ? m.copyWith(unread: false) : m];
    return messages.firstWhere((m) => m.id == id);
  }

  @override
  Future<AggregatorSettings> getSettings() async => settings;

  @override
  Future<AggregatorSettings> updateSettings(AggregatorSettings next) async {
    if (failSettingsWith != null) throw failSettingsWith!;
    settingsWrites.add(next);
    settings = next;
    return next;
  }

  @override
  Future<List<SupportTicket>> listSupportTickets() async => List.of(tickets);

  @override
  Future<SupportTicket> submitSupportTicket({required String subject, required String message}) async {
    submitted.add((subject: subject, message: message));
    await holdSubmit?.future;
    final ticket = SupportTicket(
      id: 't${submitted.length}',
      subject: subject.trim(),
      message: message.trim(),
      status: SupportTicketStatus.open,
      createdAt: '2026-10-02T00:00:00.000Z',
    );
    tickets = [ticket, ...tickets];
    return ticket;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  group('the dashboard', () {
    testWidgets('three figures, the website\'s worked example, and the conversion rate', (tester) async {
      await pumpAggregator(tester, _Acct(), AggregatorDashboardScreen.path);
      expect(find.text('Active reservations'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Commission earned'), findsOneWidget);
      expect(find.text('₹12,345'), findsOneWidget);
      expect(find.text('Pending settlements'), findsOneWidget);

      expect(find.text('You earn 20% of the 30% markup'), findsOneWidget);
      expect(find.text('₹1,00,000'), findsOneWidget, reason: 'listed price');
      expect(find.text('₹30,000'), findsOneWidget, reason: 'the 30% platform markup');
      expect(find.text('₹6,000'), findsOneWidget, reason: '20% of that markup');

      expect(find.text('Sales conversion'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
    });

    testWidgets('a rate over nothing is a dash, not 0%', (tester) async {
      final acct = _Acct(
        summary: const AggregatorDashboardSummary(activeReservations: 1, commissionEarned: 0, pendingSettlements: 0),
      );
      await pumpAggregator(tester, acct, AggregatorDashboardScreen.path);
      expect(find.text('Sales conversion'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('when the figures fail the cards stay, with dashes and a way to try again', (tester) async {
      final acct = _Acct()..failSummaryWith = Exception('Too many requests. Wait a moment and try again.');
      await pumpAggregator(tester, acct, AggregatorDashboardScreen.path);
      expect(find.text('Active reservations'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
      expect(find.text("Couldn't load your figures. Try again"), findsOneWidget);

      await tapVisible(tester, find.text("Couldn't load your figures. Try again"));
      expect(find.text('₹12,345'), findsOneWidget);
      expect(find.text("Couldn't load your figures. Try again"), findsNothing);
    });

    testWidgets('recent activity is the newest five, counted from today, and a returned piece says so', (tester) async {
      final acct = _Acct(
        holdings: [
          testHolding('a', 'Monsoon', assignedAt: daysAgo(0)),
          testHolding('b', 'Bronze Dancer', status: HoldingStatus.soldPendingSettlement, assignedAt: daysAgo(1)),
          testHolding('c', 'Late Light', status: HoldingStatus.returned, assignedAt: daysAgo(3)),
          testHolding('d', 'Fourth', assignedAt: daysAgo(5)),
          testHolding('e', 'Fifth', assignedAt: daysAgo(6)),
          testHolding('f', 'Sixth', assignedAt: daysAgo(9)),
        ],
      );
      await pumpAggregator(tester, acct, AggregatorDashboardScreen.path);
      await tester.scrollUntilVisible(find.text('Recent activity'), 300, scrollable: find.byType(Scrollable).first);

      expect(find.text('Reserved: "Monsoon"'), findsOneWidget);
      expect(find.text('Sale recorded: "Bronze Dancer"'), findsOneWidget);
      expect(find.text('Returned: "Late Light"'), findsOneWidget, reason: 'the website files it under Reserved');
      expect(find.text('Reserved: "Fifth"'), findsOneWidget);
      expect(find.text('Reserved: "Sixth"'), findsNothing, reason: 'five at most');

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('3 days ago'), findsOneWidget);
      expect(find.text('Display price ₹1,36,500 · 5% advance'), findsWidgets);
    });

    testWidgets('no activity points at Browse', (tester) async {
      await pumpAggregator(tester, _Acct(), AggregatorDashboardScreen.path);
      await tester.scrollUntilVisible(find.text('Browse Inventory'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('No activity yet. Reserve an artwork from Inventory to get started.'), findsOneWidget);
      await tapVisible(tester, find.text('Browse Inventory'));
      expect(find.text('BROWSE PAGE'), findsOneWidget);
    });
  });

  group('analytics', () {
    testWidgets('four figures, and the categories that moved - biggest first', (tester) async {
      final acct = _Acct(
        categories: const [
          CategoryPerformance(category: 'sculpture', revenue: 90000, orders: 1),
          CategoryPerformance(category: 'mixed-media', revenue: 410000, orders: 3),
        ],
      );
      await pumpAggregator(tester, acct, AggregatorAnalyticsScreen.path);
      expect(find.text('SALES RECORDED'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('₹5,00,000'), findsOneWidget);
      expect(find.text('₹1,25,000'), findsOneWidget);
      expect(find.text('AVG. DISPLAY MARKUP'), findsOneWidget);
      expect(find.text('₹8,000'), findsOneWidget);

      expect(find.text('Top categories moved'), findsOneWidget);
      expect(find.text('Revenue from your recorded sales, by artwork category.'), findsOneWidget);
      expect(find.byType(BarList), findsOneWidget);
      expect(find.text('₹4.1L'), findsOneWidget);
      expect(find.text('₹90k'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Mixed media')).dy,
        lessThan(tester.getTopLeft(find.text('Sculpture')).dy),
        reason: 'the bigger earner leads',
      );
    });

    testWidgets('no sales yet says so rather than drawing nothing', (tester) async {
      await pumpAggregator(tester, _Acct(), AggregatorAnalyticsScreen.path);
      expect(find.text('No category revenue yet'), findsOneWidget);
    });

    testWidgets('a failed load can be retried', (tester) async {
      final acct = _Acct()..failAnalyticsWith = Exception('Offline');
      await pumpAggregator(tester, acct, AggregatorAnalyticsScreen.path);
      expect(find.text("Couldn't load your analytics"), findsOneWidget);
      await tapVisible(tester, find.text('Try again'));
      expect(find.text('SALES RECORDED'), findsOneWidget);
    });
  });

  group('display spaces', () {
    testWidgets('a space shows where it is, who coordinates it and how full it is', (tester) async {
      final acct = _Acct(spaces: const [_space], holdings: [testHolding('a', 'One'), testHolding('b', 'Two'), testHolding('c', 'Gone', status: HoldingStatus.returned)]);
      await pumpAggregator(tester, acct, AggregatorGallerySpacesScreen.path);
      expect(find.text('Verandah — Main Gallery'), findsOneWidget);
      expect(find.text('14 Church Street, Bengaluru, Karnataka 560001'), findsOneWidget);
      expect(find.text('Meher Chatterjee'), findsOneWidget);
      expect(find.text('2 / 12'), findsOneWidget, reason: 'only reserved pieces occupy it');
    });

    testWidgets('a space with no capacity set does not draw a bar that reads as full', (tester) async {
      final acct = _Acct(
        spaces: [
          const GallerySpace(
            id: 'sp2',
            name: 'Annexe',
            addressLine1: '2 Lane',
            city: 'Pune',
            state: 'Maharashtra',
            pincode: '411001',
            capacity: 0,
            coordinatorName: '',
          ),
        ],
        holdings: [testHolding('a', 'One')],
      );
      await pumpAggregator(tester, acct, AggregatorGallerySpacesScreen.path);
      expect(find.text('1 · capacity not set'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('none on file, and a failed load that can be retried', (tester) async {
      await pumpAggregator(tester, _Acct(), AggregatorGallerySpacesScreen.path);
      expect(find.text('No display spaces on file'), findsOneWidget);

      final failing = _Acct(spaces: const [_space])..failSpacesWith = Exception('Offline');
      await pumpAggregator(tester, failing, AggregatorGallerySpacesScreen.path);
      expect(find.text("Couldn't load your display spaces"), findsOneWidget);
      await tapVisible(tester, find.text('Try again'));
      expect(find.text('Verandah — Main Gallery'), findsOneWidget);
    });
  });

  group('messages', () {
    testWidgets('the sender and a line of the message show before opening; opening marks it read once', (tester) async {
      final acct = _Acct(messages: [_message('m1', 'Scheduled inventory audit'), _message('m2', 'Already seen', unread: false)]);
      await pumpAggregator(tester, acct, AggregatorMessagesScreen.path);
      expect(find.text('GalleryZone Audit Team · A GalleryZone auditor will visit on 18 Aug 2026.'), findsNWidgets(2));
      expect(find.text('20 Sep'), findsNWidgets(2));
      expect(find.text('Please ensure all pieces are accessible at your premises.'), findsNothing);

      await tapVisible(tester, find.text('Scheduled inventory audit'));
      expect(find.text('Please ensure all pieces are accessible at your premises.'), findsOneWidget);
      expect(acct.read, ['m1']);

      // Closing and reopening does not ask again; a message already read never does.
      await tapVisible(tester, find.text('Scheduled inventory audit'));
      await tapVisible(tester, find.text('Scheduled inventory audit'));
      await tapVisible(tester, find.text('Already seen'));
      expect(acct.read, ['m1']);
    });

    testWidgets('none, and a failed load', (tester) async {
      await pumpAggregator(tester, _Acct(), AggregatorMessagesScreen.path);
      expect(find.text('No messages'), findsOneWidget);

      final failing = _Acct(messages: [_message('m1', 'Hello')])..failMessagesWith = Exception('Offline');
      await pumpAggregator(tester, failing, AggregatorMessagesScreen.path);
      expect(find.text("Couldn't load your messages"), findsOneWidget);
      await tapVisible(tester, find.text('Try again'));
      expect(find.text('Hello'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('each switch writes its own preference', (tester) async {
      final acct = _Acct();
      await pumpAggregator(tester, acct, AggregatorSettingsScreen.path);
      await tapVisible(tester, find.widgetWithText(SwitchListTile, 'Settlement processed'));
      expect(acct.settingsWrites.single.notifySettlementProcessed, isTrue);
      expect(acct.settingsWrites.single.notifySaleRecorded, isTrue, reason: 'the others are left alone');
      expect(acct.settings.notifySettlementProcessed, isTrue);

      await tapVisible(tester, find.widgetWithText(SwitchListTile, 'Sale recorded'));
      expect(acct.settings.notifySaleRecorded, isFalse);
      expect(acct.settings.notifySettlementProcessed, isTrue, reason: 'and the first stays on');
    });

    testWidgets('a write that fails says why', (tester) async {
      final acct = _Acct()..failSettingsWith = Exception('Could not save your settings.');
      await pumpAggregator(tester, acct, AggregatorSettingsScreen.path);
      await tapVisible(tester, find.widgetWithText(SwitchListTile, 'Sale recorded'));
      expect(find.text('Could not save your settings.'), findsOneWidget);
    });
  });

  group('support', () {
    testWidgets('ways to reach GalleryZone, the FAQ, and no hand-written advance rule that has gone stale', (tester) async {
      await pumpAggregator(tester, _Acct(), AggregatorSupportScreen.path);
      expect(find.text('Contact GalleryZone'), findsOneWidget);
      expect(find.text('+91 94929 53627'), findsOneWidget);
      expect(find.text('Raise a ticket'), findsOneWidget);
      expect(find.textContaining("5% or 3% of the artwork's value"), findsNothing);
      expect(find.textContaining('Frequently asked'), findsNothing);
      expect(find.textContaining("doesn't send to a live inbox"), findsNothing, reason: 'tickets reach the API');
    });

    testWidgets('a ticket needs both a subject and a message', (tester) async {
      final acct = _Acct();
      await pumpAggregator(tester, acct, AggregatorSupportScreen.path);
      await tapVisible(tester, find.text('Submit ticket'));
      expect(find.text('A subject is required'), findsOneWidget);
      expect(find.text('Enter a message'), findsOneWidget);
      expect(acct.submitted, isEmpty);
    });

    testWidgets('sending shows it is sending, can\'t be sent twice, then clears the form and lists the ticket', (tester) async {
      final acct = _Acct()..holdSubmit = Completer<void>();
      await pumpAggregator(tester, acct, AggregatorSupportScreen.path);
      await tester.enterText(_field('Subject'), 'Question about my advance');
      await tester.enterText(_field('Message'), 'How is it held?');
      await tester.ensureVisible(find.text('Submit ticket'));
      await tester.pump();
      await tester.tap(find.text('Submit ticket'));
      await tester.pump();

      expect(find.text('Sending…'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Sending…')).onPressed, isNull);

      acct.holdSubmit!.complete();
      await tester.pumpAndSettle();
      expect(acct.submitted, hasLength(1));
      expect(find.text('Ticket submitted.'), findsOneWidget);
      expect(tester.widget<TextFormField>(_field('Subject')).controller!.text, isEmpty);
      await tester.scrollUntilVisible(find.text('Your tickets'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('profile', () {
    testWidgets('the summary: held, sold, owed, where, and whether the MOU is signed', (tester) async {
      final acct = _Acct(
        spaces: const [_space],
        holdings: [testHolding('a', 'One'), testHolding('b', 'Two', status: HoldingStatus.soldPendingSettlement), testHolding('c', 'Gone', status: HoldingStatus.returned)],
        sales: [
          testSale(id: 's1', price: 90000, route: PaymentRoute.cashAtPremises),
          testSale(id: 's2', price: 40000, route: PaymentRoute.cashAtPremises, remittedAt: '2026-09-30T00:00:00.000Z', buyerEmail: 'ravi@example.com'),
        ],
        commissions: {'s1': 6000, 's2': 4000},
      );
      await pumpAggregator(tester, acct, AggregatorProfileScreen.path);
      expect(find.text('Bengaluru · 1 space'), findsOneWidget);
      expect(find.text('MOU signed 1 Sep 2026'), findsOneWidget);
      // Cash taken and not yet paid in is an obligation, set apart from the figures.
      expect(find.textContaining('₹90,000 collected in cash is owed to GalleryZone'), findsOneWidget);
      expect(find.text('On display now'), findsOneWidget);
      expect(find.text('1 / 12'), findsOneWidget, reason: 'display capacity');
      expect(find.text('Buyers'), findsOneWidget);
      expect(find.text('₹10,000'), findsOneWidget, reason: 'commission earned: what the ledger credited');
      expect(find.text('₹9,000'), findsOneWidget, reason: 'held against reservations');
      expect(find.text('1 piece has gone back to GalleryZone unsold.'), findsOneWidget);
    });

    testWidgets('unsigned, the agreement leads the page; signed, it is a receipt at the foot', (tester) async {
      await pumpAggregator(tester, _Acct(profile: _profile(signed: false)), AggregatorProfileScreen.path);
      expect(find.text('MOU not signed'), findsOneWidget);
      expect(find.text('Sign your Aggregator MOU'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Sign your Aggregator MOU')).dy,
        lessThan(tester.getTopLeft(find.text('Company profile').first).dy),
        reason: 'above the form',
      );
      await tapVisible(tester, find.text('Read and sign'));
      expect(find.text('MOU PAGE'), findsOneWidget);

      await pumpAggregator(tester, _Acct(), AggregatorProfileScreen.path);
      expect(find.text('Sign your Aggregator MOU'), findsNothing);
      await tester.scrollUntilVisible(find.text('Read the signed copy'), 400, scrollable: find.byType(Scrollable).first);
      expect(find.text('Signed by'), findsOneWidget);
      expect(find.text('Meher Chatterjee'), findsWidgets);
      expect(find.text('2026.2'), findsOneWidget);
    });

    testWidgets('the form opens filled from the profile, with the phone split into dial code and number', (tester) async {
      await pumpAggregator(tester, _Acct(), AggregatorProfileScreen.path);
      expect(tester.widget<TextFormField>(_field('Company name')).controller!.text, 'Verandah Art House');
      expect(tester.widget<TextFormField>(_field('Contact person')).controller!.text, 'Meher Chatterjee');
      expect(tester.widget<TextFormField>(_field('Phone')).controller!.text, '98450 12345');
      expect(find.text('+91'), findsWidgets);
      expect(tester.widget<TextFormField>(_field('PIN code')).controller!.text, '560001');
      expect(find.text('Approved'), findsOneWidget, reason: 'the GST verdict');
      expect(find.textContaining('(required to reserve)', findRichText: true), findsOneWidget, reason: 'inside the label');
      expect(find.text('GalleryZone reviews it before you can reserve artwork.'), findsOneWidget);
    });

    testWidgets('nothing is saved until every required field is right', (tester) async {
      final acct = _Acct();
      await pumpAggregator(tester, acct, AggregatorProfileScreen.path);
      await tester.enterText(_field('Company name'), 'V');
      await tester.enterText(_field('Phone'), '12345');
      await tester.enterText(_field('Business address'), '14');
      await tester.enterText(_field('City'), '');
      await tester.enterText(_field('PIN code'), '012345');
      await tester.enterText(find.byType(TextFormField).at(2), 'NOT-A-GSTIN');
      await tapVisible(tester, find.text('Save profile'));

      expect(find.text('Enter your company name'), findsOneWidget);
      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(find.text('Enter your business address'), findsOneWidget);
      expect(find.text('Enter the city'), findsOneWidget);
      expect(find.text('Enter the 6-digit PIN code'), findsOneWidget, reason: 'a PIN does not start with 0');
      expect(acct.profileUpdates, isEmpty);
    });

    testWidgets('a blank GST number still saves - the rest of the profile can be filled in first', (tester) async {
      final acct = _Acct();
      await pumpAggregator(tester, acct, AggregatorProfileScreen.path);
      final gst = find.byType(TextFormField).at(2);
      await tester.enterText(gst, '');
      await tapVisible(tester, find.text('Save profile'));
      expect(acct.profileUpdates.single.gstNumber, isEmpty);
    });

    testWidgets('saving sends what was typed - capitals for the GSTIN, the dial code in front of the phone', (tester) async {
      final acct = _Acct();
      await pumpAggregator(tester, acct, AggregatorProfileScreen.path);
      await tester.enterText(_field('Company name'), 'Verandah Art Co');
      await tester.enterText(find.byType(TextFormField).at(2), '29abcde1234f1z6');
      await tester.enterText(_field('Phone'), '98450 99999');
      await tester.enterText(_field('City'), 'Mysuru');
      await tapVisible(tester, find.text('Save profile'));

      final saved = acct.profileUpdates.single;
      expect(saved.companyName, 'Verandah Art Co');
      expect(saved.gstNumber, '29ABCDE1234F1Z6');
      expect(saved.phone, '+91 98450 99999');
      expect(saved.addressCity, 'Mysuru');
      expect(saved.coordinatorDesignation, 'Gallery Manager');
      expect(find.text('Profile saved'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('the dial code comes from a list', (tester) async {
      final acct = _Acct();
      await pumpAggregator(tester, acct, AggregatorProfileScreen.path);
      await tapVisible(tester, find.widgetWithText(InkWell, '+91').first);
      expect(find.text('Select dial code'), findsOneWidget);
      await tester.tap(find.text('United Kingdom'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save profile'));
      expect(acct.profileUpdates.single.phone, '+44 98450 12345');
    });

    testWidgets('the coordinator\'s designation is a list with "Other"; Other asks for one', (tester) async {
      final acct = _Acct(profile: _profile(designation: 'Head of Display'));
      await pumpAggregator(tester, acct, AggregatorProfileScreen.path);
      // A designation that isn't a preset opens on Other, with the text filled in.
      expect(tester.widget<TextFormField>(_field('Their designation')).controller!.text, 'Head of Display');

      await tester.enterText(_field('Their designation'), '');
      await tapVisible(tester, find.text('Save profile'));
      expect(find.text('Enter their role, e.g. Gallery Manager'), findsOneWidget);
      expect(acct.profileUpdates, isEmpty);

      await tester.enterText(_field('Their designation'), 'Curator');
      await tapVisible(tester, find.text('Save profile'));
      expect(acct.profileUpdates.single.coordinatorDesignation, 'Curator');
    });

    testWidgets('against the API the coordinator\'s phone and email are the company\'s - read-only, and not pretended otherwise', (tester) async {
      final acct = _Acct();
      await pumpAggregator(tester, acct, AggregatorProfileScreen.path);
      expect(find.text('Uses your company phone above.'), findsOneWidget);
      expect(find.text('Uses your account email.'), findsOneWidget);
      expect(find.text('Taken from the contact person above — change it there.'), findsOneWidget);
      expect(_field('Direct phone'), findsNothing);

      await tapVisible(tester, find.text('Save profile'));
      expect(acct.profileUpdates.single.coordinatorPhone, '+91 98450 12345', reason: 'unchanged: there is nothing to edit');
    });

    testWidgets('in the offline demo they are fields of their own, and are kept', (tester) async {
      final acct = _Acct();
      await pumpAggregator(tester, acct, AggregatorProfileScreen.path, remote: false);
      expect(find.text('Uses your company phone above.'), findsNothing);

      await tester.enterText(_field('Direct phone'), '99999 11111');
      await tester.enterText(_field('Email'), 'floor@example.com');
      await tapVisible(tester, find.text('Save profile'));
      expect(acct.profileUpdates.single.coordinatorPhone, '+91 99999 11111');
      expect(acct.profileUpdates.single.coordinatorEmail, 'floor@example.com');

      await tester.enterText(_field('Email'), 'not-an-email');
      await tapVisible(tester, find.text('Save profile'));
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('a refusal from the service is shown and nothing claims to be saved', (tester) async {
      final acct = _Acct()..failProfileWith = Exception('GSTIN must be the 15-character registration number');
      await pumpAggregator(tester, acct, AggregatorProfileScreen.path);
      await tapVisible(tester, find.text('Save profile'));
      expect(find.text('GSTIN must be the 15-character registration number'), findsOneWidget);
      expect(find.text('Profile saved'), findsNothing);
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('the website\'s photo, country and Aadhaar-number fields are not offered - the API keeps none of them', (tester) async {
      await pumpAggregator(tester, _Acct(), AggregatorProfileScreen.path);
      expect(find.text('Country'), findsNothing);
      expect(find.byTooltip('Change photo'), findsNothing);
      expect(_field('Aadhaar number'), findsNothing);
      expect(find.text('Submit for review'), findsNothing);
    });

    testWidgets('the deposit is marked active, as on the website', (tester) async {
      await pumpAggregator(tester, _Acct(), AggregatorProfileScreen.path);
      await tester.scrollUntilVisible(find.text('Security deposit'), 400, scrollable: find.byType(Scrollable).first);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('bank details: the masked account on file, checks, and only the last four kept', (tester) async {
      final acct = _Acct();
      await pumpAggregator(tester, acct, AggregatorProfileScreen.path);
      await tester.scrollUntilVisible(find.text('Bank account'), 400, scrollable: find.byType(Scrollable).first);
      expect(find.text('•••• •••• •••• 4821'), findsOneWidget);
      expect(find.text('Currently on file'), findsOneWidget);

      await tester.enterText(_field('New account number'), '123');
      await tester.enterText(_field('IFSC code'), 'BAD');
      await tapVisible(tester, find.text('Update bank details'));
      expect(find.text('Enter your account number'), findsOneWidget);
      expect(find.text('Enter a valid IFSC code'), findsOneWidget);
      expect(acct.bankUpdates, isEmpty);

      await tester.enterText(_field('New account number'), '000123456789');
      await tester.enterText(_field('IFSC code'), 'icic0004321');
      await tapVisible(tester, find.text('Update bank details'));
      expect(acct.bankUpdates.single, (account: '000123456789', ifsc: 'ICIC0004321'));
      expect(find.text('Bank details updated'), findsOneWidget);
      expect(find.text('•••• •••• •••• 6789'), findsOneWidget);
      expect(tester.widget<TextFormField>(_field('New account number')).controller!.text, isEmpty, reason: 'never left on screen');
    });

    testWidgets('identity is on file read-only, with support for changing it', (tester) async {
      await pumpAggregator(tester, _Acct(), AggregatorProfileScreen.path);
      await tester.scrollUntilVisible(find.text('Identity verification'), 500, scrollable: find.byType(Scrollable).first);
      expect(find.text('Not on file'), findsOneWidget);
      expect(find.text('Not submitted'), findsOneWidget);

      await pumpAggregator(
        tester,
        _Acct(profile: _profile(aadhaar: ReviewStatus.approved, aadhaarMasked: 'XXXX XXXX 4821')),
        AggregatorProfileScreen.path,
      );
      await tester.scrollUntilVisible(find.text('Identity verification'), 500, scrollable: find.byType(Scrollable).first);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('XXXX XXXX 4821'), findsOneWidget);
      expect(find.text('Aadhaar currently on file'), findsOneWidget);
      expect(find.byIcon(LucideIcons.fingerprint), findsOneWidget);

      await tapVisible(tester, find.text('Contact support'));
      expect(find.text('Raise a ticket'), findsOneWidget);
    });
  });
}
