import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/artwork.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';
import '../widgets/list_tools.dart';
import 'aggregator_inventory_screen.dart';

/// A sale with the piece it was of and what it earned. Joined once here so the
/// list, its filters and its detail sheet all read the same row.
class _SaleRow {
  const _SaleRow({required this.sale, required this.commission, this.artwork});

  final AggregatorSale sale;
  final Artwork? artwork;

  /// What the ledger credited for this sale - the same figure Settlements shows.
  final double commission;

  String get title => artwork?.title ?? sale.artworkId;
}

/// Sales joined to their artwork and commission. The three loads start together,
/// so a sale recorded a second ago is here without waiting on a chain of requests.
final _saleRowsProvider = FutureProvider.autoDispose<List<_SaleRow>>((ref) async {
  final loaded = await Future.wait<Object>([
    ref.watch(aggregatorSalesProvider.future),
    ref.watch(aggregatorCollectionProvider.future),
    ref.watch(aggregatorSaleCommissionsProvider.future),
  ]);
  final sales = loaded[0] as List<AggregatorSale>;
  final byHoldingId = {for (final view in loaded[1] as List<AggregatorHoldingView>) view.holding.id: view};
  final commissions = loaded[2] as Map<String, double>;
  return [
    for (final sale in sales)
      _SaleRow(
        sale: sale,
        artwork: byHoldingId[sale.holdingId]?.artwork,
        commission: commissions[sale.id] ?? 0,
      ),
  ];
});

/// Loads the sales again from the start. The joined rows only watch the three
/// lists beneath them, so invalidating just the rows would re-read whichever of
/// those had failed straight out of its cache.
void _reloadSales(WidgetRef ref) {
  ref
    ..invalidate(aggregatorSalesProvider)
    ..invalidate(aggregatorCollectionProvider)
    ..invalidate(aggregatorSaleCommissionsProvider)
    ..invalidate(_saleRowsProvider);
}

/// `14 Church Street, Bengaluru, Karnataka 560001` - whichever parts there are.
String _address(DeliveryAddress address) {
  final regionLine = '${address.state} ${address.pincode}'.trim();
  return [address.line1, address.city, regionLine].where((part) => part.trim().isNotEmpty).join(', ');
}

// --- Orders & sales -------------------------------------------------------------------

enum _DatePreset {
  week('Last 7 days', 7),
  month('Last 30 days', 30),
  year('This year', 365);

  const _DatePreset(this.label, this.days);
  final String label;
  final int days;
}

/// "Owed to GalleryZone" is the same vocabulary Settlements uses for cash the
/// aggregator has not paid in yet - not a new status.
enum _PaymentStatus {
  owed('Owed to GalleryZone'),
  settled('Settled');

  const _PaymentStatus(this.label);
  final String label;
}

_PaymentStatus _paymentStatusOf(AggregatorSale sale) =>
    sale.paymentRoute == PaymentRoute.cashAtPremises && sale.remittedAt == null
        ? _PaymentStatus.owed
        : _PaymentStatus.settled;

const _shipmentLabel = {
  ShipmentStatus.preparing: 'Preparing',
  ShipmentStatus.dispatched: 'Dispatched',
  ShipmentStatus.delivered: 'Delivered',
};

/// Port of `features/aggregator/sales-table.tsx`. The website's seven-column
/// table becomes the card list its own phone layout uses; the filters are the
/// same four (search, shipment, date, payment status). Its "All / Reservations /
/// Sold / Returned" tabs filter nothing there, so they are not drawn here.
class AggregatorOrdersScreen extends ConsumerStatefulWidget {
  const AggregatorOrdersScreen({super.key});

  static const path = '/aggregator/dashboard/orders';

  @override
  ConsumerState<AggregatorOrdersScreen> createState() => _AggregatorOrdersScreenState();
}

class _AggregatorOrdersScreenState extends ConsumerState<AggregatorOrdersScreen> {
  final _search = TextEditingController();
  ShipmentStatus? _shipment;
  _DatePreset? _date;
  _PaymentStatus? _payment;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _filtering => _search.text.trim().isNotEmpty || _shipment != null || _date != null || _payment != null;

  void _clear() => setState(() {
        _search.clear();
        _shipment = null;
        _date = null;
        _payment = null;
      });

  List<_SaleRow> _visible(List<_SaleRow> rows) {
    final needle = _search.text.trim().toLowerCase();
    final cutoff = _date == null ? null : DateTime.now().toUtc().subtract(Duration(days: _date!.days));
    return [
      for (final row in rows)
        if ((needle.isEmpty ||
                '${row.sale.buyerName} ${row.sale.buyerEmail} ${row.artwork?.title ?? ''}'
                    .toLowerCase()
                    .contains(needle)) &&
            (_shipment == null || row.sale.shipmentStatus == _shipment) &&
            (_payment == null || _paymentStatusOf(row.sale) == _payment) &&
            (cutoff == null || !DateTime.parse(row.sale.soldAt).isBefore(cutoff)))
          row,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = ref.watch(_saleRowsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders & sales')),
      body: rows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your sales",
          description: authErrorMessage(error),
          action: OutlinedButton(
            onPressed: () => _reloadSales(ref),
            child: const Text('Try again'),
          ),
        ),
        data: (all) {
          if (all.isEmpty) {
            return EmptyState(
              icon: LucideIcons.shoppingBag,
              title: 'No sales yet',
              description: 'Recorded sales from your holdings will show up here. When a customer purchases or a '
                  'reservation is converted to a sale, it will appear in this list.',
              action: FilledButton(
                onPressed: () => context.go(AggregatorBrowseScreen.path),
                child: const Text('Browse GalleryZone'),
              ),
            );
          }
          final shown = _visible(all);

          return RefreshIndicator(
            onRefresh: () async {
              _reloadSales(ref);
              await ref.read(_saleRowsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              // Header, the cards, and the note under them.
              itemCount: shown.length + 2,
              itemBuilder: (context, index) {
                final Widget child;
                if (index == 0) {
                  child = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Track sales, reservations and returns for the artworks in your collection.',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ListSearchField(
                              controller: _search,
                              hint: 'Search by buyer or artwork...',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            tooltip: 'Clear search and filters',
                            onPressed: _filtering ? _clear : null,
                            icon: const Icon(LucideIcons.slidersHorizontal, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            PillFilter<ShipmentStatus>(
                              label: 'All Shipment',
                              value: _shipment,
                              options: [for (final s in ShipmentStatus.values) (s, _shipmentLabel[s]!)],
                              onChanged: (value) => setState(() => _shipment = value),
                            ),
                            const SizedBox(width: 8),
                            PillFilter<_DatePreset>(
                              label: 'All Dates',
                              value: _date,
                              options: [for (final d in _DatePreset.values) (d, d.label)],
                              onChanged: (value) => setState(() => _date = value),
                            ),
                            const SizedBox(width: 8),
                            PillFilter<_PaymentStatus>(
                              label: 'All Status',
                              value: _payment,
                              options: [for (final p in _PaymentStatus.values) (p, p.label)],
                              onChanged: (value) => setState(() => _payment = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (shown.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Column(
                            children: [
                              Text('No sales match these filters.', style: theme.textTheme.bodyMedium),
                              TextButton(onPressed: _clear, child: const Text('Clear filters')),
                            ],
                          ),
                        ),
                    ],
                  );
                } else if (index == shown.length + 1) {
                  child = const Padding(padding: EdgeInsets.only(top: 6), child: WalletMechanicsNotice());
                } else {
                  child = Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SaleCard(row: shown[index - 1]),
                  );
                }
                return ContentWidth(child: child);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.row});

  final _SaleRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sale = row.sale;
    return PortalCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _openDetail(context, row),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (row.artwork != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(width: 56, height: 56, child: ArtworkImageView(url: row.artwork!.thumbnailUrl)),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(sale.buyerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PriceTag(amount: sale.soldPrice, style: theme.textTheme.bodyMedium),
                        ShipmentStatusPill(status: sale.shipmentStatus),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(formatDay(sale.soldAt), style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

void _openDetail(BuildContext context, _SaleRow row) {
  final theme = Theme.of(context);
  final sale = row.sale;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(row.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Sold to ${sale.buyerName} for ${formatInr(sale.soldPrice)}', style: theme.textTheme.bodySmall),
          const Divider(height: 28),
          PortalDetailRow(label: 'Buyer email', value: sale.buyerEmail),
          PortalDetailRow(label: 'Buyer phone', value: sale.buyerPhone),
          PortalDetailRow(
            label: 'Delivery mode',
            value: sale.deliveryMode == DeliveryMode.courier ? 'Courier' : 'Self pickup',
          ),
          PortalDetailRow(label: 'Commission', value: formatInr(row.commission), gold: true),
          PortalDetailRow(label: 'Payment', value: _paymentStatusOf(sale).label),
          PortalDetailRow(label: 'Sold on', value: formatShortDate(sale.soldAt)),
          PortalDetailRow(label: 'Delivery address', value: _address(sale.deliveryAddress)),
          if (sale.courierRef != null && sale.courierRef!.isNotEmpty)
            PortalDetailRow(label: 'Courier reference', value: sale.courierRef!),
        ],
      ),
    ),
  );
}

// --- Customers --------------------------------------------------------------------------

enum _CustomerSort {
  name('Name'),
  email('Email'),
  orders('Orders'),
  spend('Total spend');

  const _CustomerSort(this.label);
  final String label;
}

/// Port of `features/aggregator/customers-table.tsx`: one row per buyer, searchable
/// by name or email, sortable by name, email, orders or spend. As the table does,
/// picking a sort ascends, picking it again descends, a third time clears it.
class AggregatorCustomersScreen extends ConsumerStatefulWidget {
  const AggregatorCustomersScreen({super.key});

  static const path = '/aggregator/dashboard/customers';

  @override
  ConsumerState<AggregatorCustomersScreen> createState() => _AggregatorCustomersScreenState();
}

class _AggregatorCustomersScreenState extends ConsumerState<AggregatorCustomersScreen> {
  final _search = TextEditingController();
  _CustomerSort? _sort;
  bool _descending = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _pick(_CustomerSort sort) => setState(() {
        if (_sort != sort) {
          _sort = sort;
          _descending = false;
        } else if (!_descending) {
          _descending = true;
        } else {
          _sort = null;
          _descending = false;
        }
      });

  List<AggregatorCustomer> _visible(List<AggregatorCustomer> all) {
    final needle = _search.text.trim().toLowerCase();
    final shown = [
      for (final customer in all)
        if (needle.isEmpty || '${customer.buyerName} ${customer.buyerEmail}'.toLowerCase().contains(needle)) customer,
    ];
    final sort = _sort;
    if (sort == null) return shown; // the service's order: biggest spender first
    int compare(AggregatorCustomer a, AggregatorCustomer b) => switch (sort) {
          _CustomerSort.name => a.buyerName.toLowerCase().compareTo(b.buyerName.toLowerCase()),
          _CustomerSort.email => a.buyerEmail.toLowerCase().compareTo(b.buyerEmail.toLowerCase()),
          _CustomerSort.orders => a.orderCount.compareTo(b.orderCount),
          _CustomerSort.spend => a.totalSpend.compareTo(b.totalSpend),
        };
    shown.sort((a, b) => _descending ? compare(b, a) : compare(a, b));
    return shown;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customers = ref.watch(aggregatorCustomersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: customers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your customers",
          description: authErrorMessage(error),
          action: OutlinedButton(
            onPressed: () => ref.invalidate(aggregatorCustomersProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (all) {
          if (all.isEmpty) {
            return const EmptyState(
              icon: LucideIcons.users,
              title: 'No customers yet',
              description: 'Buyers from your recorded sales will show up here.',
            );
          }
          final shown = _visible(all);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(aggregatorCustomersProvider);
              await ref.read(aggregatorCustomersProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListSearchField(
                        controller: _search,
                        hint: 'Search by name or email',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Text('Sort', style: theme.textTheme.labelMedium),
                            const SizedBox(width: 8),
                            for (final sort in _CustomerSort.values)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    _sort == sort ? '${sort.label} ${_descending ? '↓' : '↑'}' : sort.label,
                                  ),
                                  selected: _sort == sort,
                                  onSelected: (_) => _pick(sort),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (shown.isEmpty)
                        const EmptyState(
                          icon: LucideIcons.searchX,
                          title: 'No customers match',
                          description: 'Try a different name or email.',
                        )
                      else
                        for (final customer in shown)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PortalCard(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          customer.buyerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        '${customer.orderCount} order${customer.orderCount == 1 ? '' : 's'}',
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  PortalDetailRow(label: 'Email', value: customer.buyerEmail),
                                  PortalDetailRow(label: 'Phone', value: customer.buyerPhone),
                                  PortalDetailRow(label: 'Total spend', value: formatInr(customer.totalSpend), gold: true),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- Shipping -----------------------------------------------------------------------------

/// Port of `features/aggregator/shipping-table.tsx` - pieces on their way to the
/// premises, and deliveries to buyers.
class AggregatorShippingScreen extends ConsumerWidget {
  const AggregatorShippingScreen({super.key});

  static const path = '/aggregator/dashboard/shipping';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collection = ref.watch(aggregatorCollectionProvider);
    final sales = ref.watch(aggregatorSalesProvider);
    final views = collection.value ?? const <AggregatorHoldingView>[];
    final inbound = views.where((view) => view.holding.status == HoldingStatus.reserved).take(3).toList();
    final titleOf = {for (final view in views) view.holding.id: view.artwork.title};

    return Scaffold(
      appBar: AppBar(title: const Text('Shipping & logistics')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(aggregatorSalesProvider);
          ref.invalidate(aggregatorCollectionProvider);
          await ref.read(aggregatorSalesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Inbound', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  // Illustrative, and said so on screen: the data model has no "in
                  // transit to the aggregator" state distinct from a holding being
                  // reserved, so this shows reserved holdings rather than inventing a
                  // tracking state machine that nothing writes to.
                  const SectionIntro(
                    text: "Artworks GalleryZone has assigned or you've reserved, en route to your premises. "
                        "Detailed transit tracking isn't modeled yet — this reflects your currently reserved "
                        'holdings.',
                  ),
                  if (inbound.isEmpty)
                    const EmptyState(
                      icon: LucideIcons.packageSearch,
                      title: 'Nothing inbound',
                      description: 'Reserve an artwork from Browse GalleryZone to see it here.',
                    )
                  else
                    for (final view in inbound)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PortalCard(
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: SizedBox(width: 40, height: 40, child: ArtworkImageView(url: view.artwork.thumbnailUrl)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  view.artwork.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const StatusPill(label: 'Due for pickup', color: Color(0xFF38BDF8), icon: LucideIcons.truck),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 24),
                  Text('Outbound', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  const SectionIntro(text: 'Post-sale shipments to buyers.'),
                  sales.when(
                    loading: () => const Center(
                      child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => EmptyState(
                      icon: LucideIcons.triangleAlert,
                      title: "Couldn't load your shipments",
                      description: authErrorMessage(error),
                      action: OutlinedButton(
                        onPressed: () => ref.invalidate(aggregatorSalesProvider),
                        child: const Text('Try again'),
                      ),
                    ),
                    data: (list) => list.isEmpty
                        ? const EmptyState(
                            icon: LucideIcons.packageCheck,
                            title: 'No outbound shipments yet',
                            description: 'Recorded sales will appear here for dispatch tracking.',
                          )
                        : Column(
                            children: [
                              for (final sale in list)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ShipmentCard(sale: sale, title: titleOf[sale.holdingId] ?? sale.artworkId),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShipmentCard extends ConsumerStatefulWidget {
  const _ShipmentCard({required this.sale, required this.title});

  final AggregatorSale sale;
  final String title;

  @override
  ConsumerState<_ShipmentCard> createState() => _ShipmentCardState();
}

class _ShipmentCardState extends ConsumerState<_ShipmentCard> {
  bool _busy = false;

  static const _nextAction = <ShipmentStatus, String?>{
    ShipmentStatus.preparing: 'Mark dispatched',
    ShipmentStatus.dispatched: 'Mark delivered',
    ShipmentStatus.delivered: null,
  };

  Future<void> _advance() async {
    final sale = widget.sale;
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context);

    // Dispatching a courier sale is when a tracking reference exists, so it is
    // asked for here. Optional: the API accepts a dispatch without one.
    String? courierRef;
    if (sale.shipmentStatus == ShipmentStatus.preparing && sale.deliveryMode == DeliveryMode.courier) {
      final entered = await showDialog<String>(context: context, builder: (context) => const _CourierRefDialog());
      if (entered == null) return;
      courierRef = entered;
    }

    setState(() => _busy = true);
    try {
      final updated = await ref.read(aggregatorRepositoryProvider).advanceShipment(sale.id, courierRef: courierRef);
      container.invalidate(aggregatorSalesProvider);
      messenger.showSnackBar(SnackBar(content: Text('Shipment marked ${updated.shipmentStatus.name}')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sale = widget.sale;
    final action = _nextAction[sale.shipmentStatus];

    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${sale.buyerName} · '
                      '${sale.deliveryMode == DeliveryMode.courier ? (sale.courierRef ?? 'Courier') : 'Self pickup'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ShipmentStatusPill(status: sale.shipmentStatus),
            ],
          ),
          const SizedBox(height: 6),
          PortalDetailRow(label: 'Deliver to', value: _address(sale.deliveryAddress)),
          if (sale.dispatchedAt != null) PortalDetailRow(label: 'Dispatched', value: formatShortDate(sale.dispatchedAt!)),
          if (sale.deliveredAt != null) PortalDetailRow(label: 'Delivered', value: formatShortDate(sale.deliveredAt!)),
          // The piece's NFC tag must be locked before it is dispatched (once the gate
          // is enforced); say so before the button is pressed, not after it fails.
          if (sale.shipmentStatus == ShipmentStatus.preparing && !sale.nfcReady) ...[
            const SizedBox(height: 8),
            Row(
              key: Key('nfc-unlocked-${sale.id}'),
              children: [
                const Icon(LucideIcons.lock, size: 13, color: AppColors.destructive),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Unlocked — lock the tag first (open the piece from My Inventory)',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.destructive, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          if (action != null)
            SizedBox(
              height: 38,
              child: OutlinedButton(
                onPressed: _busy ? null : _advance,
                child: Text(_busy ? 'Updating…' : action),
              ),
            )
          else
            Text('Done', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// The courier's tracking reference, asked for as a courier sale is dispatched.
/// Closing without choosing cancels the dispatch; "Mark dispatched" with the box
/// empty dispatches without one.
class _CourierRefDialog extends StatefulWidget {
  const _CourierRefDialog();

  @override
  State<_CourierRefDialog> createState() => _CourierRefDialogState();
}

class _CourierRefDialogState extends State<_CourierRefDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark dispatched'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Add the courier's tracking reference if you have it, so it shows against this sale.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Courier reference (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Mark dispatched'),
        ),
      ],
    );
  }
}
