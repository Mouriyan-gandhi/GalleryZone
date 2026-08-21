import '../../models/customer.dart';
import '../../models/order.dart';

/// Ported from `frontend-web/lib/mock-data/customer.ts` and the collector
/// block of `lib/mock-collections.ts`. Same fixed "today" anchor
/// (2026-08-11) every other mock-data file uses — real `DateTime.now()` is
/// deliberately avoided so seeded relative dates stay stable.
final _today = DateTime.utc(2026, 8, 11);

String _daysAgo(int days) => _today.subtract(Duration(days: days)).toIso8601String();

List<OrderStatusEvent> _history(List<(OrderStatus, int)> entries) => [
      for (final (status, days) in entries)
        OrderStatusEvent(status: status, changedAt: _daysAgo(days)),
    ];

/// The single "signed in as" collector fixture — there is no real customer
/// session in this mock phase, same as the web.
CustomerProfile seedCustomerProfile() => const CustomerProfile(
      name: 'Aarav Shah',
      email: 'aarav.shah@example.com',
      phone: '+919812345678',
    );

/// `artworkId` values reference real entries in `artworks_seed.dart`, and
/// amount/GST/delivery follow `createOrder`'s exact math (5% GST, flat ₹250)
/// so seeded and freshly-created orders look internally consistent.
List<Order> seedOrders() => [
      Order(
        id: 'order-monsoon-madurai',
        artworkId: 'monsoon-over-madurai',
        addressId: 'addr-home-pune',
        amount: 23400,
        gstAmount: 1170,
        deliveryCharge: 250,
        status: OrderStatus.delivered,
        createdAt: _daysAgo(21),
        statusHistory: _history(const [
          (OrderStatus.pending, 21),
          (OrderStatus.paid, 21),
          (OrderStatus.confirmed, 20),
          (OrderStatus.packed, 17),
          (OrderStatus.transit, 15),
          (OrderStatus.delivered, 11),
        ]),
      ),
      Order(
        id: 'order-backwater-light',
        artworkId: 'backwater-light-early-hours',
        addressId: 'addr-home-pune',
        amount: 31200,
        gstAmount: 1560,
        deliveryCharge: 250,
        status: OrderStatus.transit,
        createdAt: _daysAgo(6),
        statusHistory: _history(const [
          (OrderStatus.pending, 6),
          (OrderStatus.paid, 6),
          (OrderStatus.confirmed, 5),
          (OrderStatus.packed, 3),
          (OrderStatus.transit, 1),
        ]),
      ),
      Order(
        id: 'order-tide-line-dusk',
        artworkId: 'tide-line-dusk',
        addressId: 'addr-office-mumbai',
        amount: 18700,
        gstAmount: 935,
        deliveryCharge: 250,
        status: OrderStatus.confirmed,
        createdAt: _daysAgo(2),
        statusHistory: _history(const [
          (OrderStatus.pending, 2),
          (OrderStatus.paid, 2),
          (OrderStatus.confirmed, 1),
        ]),
      ),
      Order(
        id: 'order-ancestral-bronze',
        artworkId: 'ancestral-bronze-study',
        addressId: 'addr-family-bengaluru',
        amount: 47450,
        gstAmount: 2372.5,
        deliveryCharge: 250,
        status: OrderStatus.paid,
        createdAt: _daysAgo(1),
        statusHistory: _history(const [(OrderStatus.pending, 1), (OrderStatus.paid, 1)]),
      ),
      Order(
        id: 'order-carved-marble-torso',
        artworkId: 'carved-marble-torso',
        addressId: 'addr-home-pune',
        amount: 62400,
        gstAmount: 3120,
        deliveryCharge: 250,
        status: OrderStatus.pending,
        createdAt: _daysAgo(0),
        statusHistory: _history(const [(OrderStatus.pending, 0)]),
      ),
      Order(
        id: 'order-reclaimed-stone-vessel',
        artworkId: 'reclaimed-stone-vessel',
        addressId: 'addr-office-mumbai',
        amount: 15600,
        gstAmount: 780,
        deliveryCharge: 250,
        status: OrderStatus.cancelled,
        createdAt: _daysAgo(14),
        statusHistory: _history(const [(OrderStatus.pending, 14), (OrderStatus.cancelled, 13)]),
      ),
    ];

/// Seeded around the one cancelled order above, so the wallet isn't empty on
/// first load. This balance is refund/store credit, never earnings — there
/// is no withdrawal path on the collector side.
WalletSummary seedCustomerWallet() =>
    const WalletSummary(balance: 16630, pendingBalance: 0, lockedBalance: 0);

List<WalletTransaction> seedCustomerWalletTransactions() => const [
      WalletTransaction(
        id: 'cwt-1',
        type: WalletTransactionType.refund,
        label: 'Refund: "Reclaimed Stone Vessel" (order cancelled)',
        amount: 16630,
        date: '2026-07-29',
        status: WalletTransactionStatus.completed,
      ),
    ];

List<SupportTicket> seedCustomerSupportTickets() => const [
      SupportTicket(
        id: 'cust-ticket-1',
        subject: 'Question about certificate of authenticity',
        message:
            'Where can I view the digital certificate of authenticity for my '
            'delivered artwork?',
        status: SupportTicketStatus.answered,
        createdAt: '2026-08-01T10:00:00.000Z',
      ),
    ];
