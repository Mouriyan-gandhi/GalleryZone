import 'package:flutter/material.dart';

import 'artist_account_screens.dart' show ArtistSettlementsTab;
import 'artist_orders_screen.dart' show ArtistOrdersTab;
import 'artist_wallet_screen.dart' show ArtistWalletTab;

/// Merges what used to be two separate bottom-nav tabs (Orders, Wallet) plus
/// the drawer-only Settlements screen into one "Sales & Earnings" surface,
/// each still backed by its own untouched provider/body — Overview is the
/// wallet balance and withdraw path, Sales is the per-order payout list,
/// Payouts is the per-sale settlement breakdown (also still reachable on its
/// own from the More menu via [ArtistSettlementsScreen]).
class ArtistSalesScreen extends StatelessWidget {
  const ArtistSalesScreen({super.key});

  static const path = '/dashboard/sales';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales & Earnings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Sales'),
              Tab(text: 'Payouts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ArtistWalletTab(),
            ArtistOrdersTab(),
            ArtistSettlementsTab(),
          ],
        ),
      ),
    );
  }
}
