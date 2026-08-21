import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/auth.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/role_options.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/account/screens/account_dashboard_screen.dart';
import '../../features/account/screens/account_settings_screen.dart';
import '../../features/account/screens/addresses_screen.dart';
import '../../features/account/screens/collection_screen.dart';
import '../../features/account/screens/orders_screen.dart';
import '../../features/account/screens/resale_screen.dart';
import '../../features/account/screens/support_screen.dart';
import '../../features/account/screens/wallet_screen.dart';
import '../../features/account/screens/wishlist_screen.dart';
import '../../features/account/widgets/customer_shell.dart';
import '../../features/aggregator/screens/aggregator_account_screens.dart';
import '../../features/aggregator/screens/aggregator_collection_screen.dart';
import '../../features/aggregator/screens/aggregator_dashboard_screen.dart';
import '../../features/aggregator/screens/aggregator_finance_screens.dart';
import '../../features/aggregator/screens/aggregator_inventory_screen.dart';
import '../../features/aggregator/screens/aggregator_operations_screens.dart';
import '../../features/aggregator/screens/aggregator_wallet_screen.dart';
import '../../features/aggregator/widgets/aggregator_shell.dart';
import '../../features/artist/screens/artist_account_screens.dart';
import '../../features/artist/screens/artist_analytics_screen.dart';
import '../../features/artist/screens/artist_artworks_screen.dart';
import '../../features/artist/screens/artist_catalog_screens.dart';
import '../../features/artist/screens/artist_dashboard_screen.dart';
import '../../features/artist/screens/artist_orders_screen.dart';
import '../../features/artist/screens/artist_wallet_screen.dart';
import '../../features/artist/screens/artwork_upload_screen.dart';
import '../../features/artist/screens/mou_screen.dart';
import '../../features/artist/widgets/artist_shell.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/marketing/screens/about_screen.dart';
import '../../features/marketplace/screens/artist_profile_screen.dart';
import '../../features/marketplace/screens/artwork_detail_screen.dart';
import '../../features/marketplace/screens/marketplace_screen.dart';
import '../../features/marketplace/screens/passport_screen.dart';
import '../../features/ownership/screens/transfer_accept_screen.dart';

/// Sections a signed-in role owns. Port of `proxy.ts`'s `GUARDED_PREFIXES`
/// minus `/admin`, which never mounts on mobile.
const _guardedPrefixes = ['/dashboard', '/aggregator', '/account'];

String? _guardedPrefix(String location) {
  for (final prefix in _guardedPrefixes) {
    if (location == prefix || location.startsWith('$prefix/')) return prefix;
  }
  return null;
}

/// Same three outcomes as `proxy.ts`: unguarded route passes; no session
/// bounces to `/login?next=…`; a session for the wrong section bounces to
/// that role's own home rather than a blank guard.
@visibleForTesting
String? redirectFor(Role? role, String location) {
  final prefix = _guardedPrefix(location);
  if (prefix == null) return null;

  if (role == null) {
    return Uri(path: '/login', queryParameters: {'next': location}).toString();
  }
  if (!role.home.startsWith(prefix)) return role.home;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter is built once and kept — it can't be rebuilt on sign-in/out
  // without losing the navigation stack. `refreshListenable` is the
  // supported way to re-run `redirect` when the session changes, so the
  // role is bridged into a ValueNotifier rather than watched directly.
  final session = ValueNotifier<Role?>(ref.read(sessionProvider));
  ref.listen<Role?>(sessionProvider, (_, next) => session.value = next);
  ref.onDispose(session.dispose);

  return GoRouter(
    initialLocation: session.value?.home ?? LoginScreen.path,
    refreshListenable: session,
    redirect: (context, state) => redirectFor(session.value, state.matchedLocation),
    // A bad deep link (or a stale link to a screen a later phase hasn't
    // built yet) lands here instead of go_router's raw error page.
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'That page does not exist',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(state.uri.toString(), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(session.value?.home ?? LoginScreen.path),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: LoginScreen.path,
        builder: (context, state) =>
            LoginScreen(next: state.uri.queryParameters['next']),
      ),
      GoRoute(
        path: RegisterScreen.path,
        builder: (context, state) => RegisterScreen(
          initialRole: RoleX.fromId(state.uri.queryParameters['role']),
        ),
      ),
      GoRoute(
        path: ForgotPasswordScreen.path,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: ResetPasswordScreen.path,
        builder: (context, state) =>
            ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: VerifyEmailScreen.path,
        builder: (context, state) =>
            VerifyEmailScreen(token: state.uri.queryParameters['token']),
      ),
      // Public, unguarded — same as the web, where none of these sit under
      // a GUARDED_PREFIX. A physical NFC tag resolving to /verify/<id> has
      // to work for someone who has never signed in.
      GoRoute(
        path: MarketplaceScreen.path,
        builder: (context, state) => MarketplaceScreen(
          initialCategory: state.uri.queryParameters['category'],
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
      GoRoute(
        path: ArtworkDetailScreen.path,
        builder: (context, state) =>
            ArtworkDetailScreen(artworkId: state.pathParameters['artworkId']!),
      ),
      GoRoute(
        path: ArtistProfileScreen.path,
        builder: (context, state) =>
            ArtistProfileScreen(artistId: state.pathParameters['artistId']!),
      ),
      GoRoute(
        path: CheckoutScreen.path,
        builder: (context, state) =>
            CheckoutScreen(artworkId: state.uri.queryParameters['artworkId']),
      ),
      // Marketing and legal live behind one native screen that links out —
      // unguarded, because someone who has never signed in still needs to
      // read the terms.
      GoRoute(
        path: AboutScreen.path,
        builder: (context, state) => const AboutScreen(),
      ),
      // An ownership transfer link has to open for whoever is handed the
      // piece, account or not — same reasoning as the passport above.
      GoRoute(
        path: TransferAcceptScreen.path,
        builder: (context, state) =>
            TransferAcceptScreen(transferId: state.pathParameters['transferId']!),
      ),
      GoRoute(
        path: PassportScreen.path,
        builder: (context, state) =>
            PassportScreen(artworkId: state.pathParameters['artworkId']!),
      ),
      // The customer's real shell: four branches, each with its own
      // navigator, so switching tabs (or resizing between the bottom bar and
      // the rail) keeps each branch's scroll position and stack.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CustomerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AccountDashboardScreen.path,
                builder: (context, state) => const AccountDashboardScreen(),
                routes: [
                  // Nested under /account so these push onto the Account
                  // branch's own navigator, keeping the shell visible.
                  GoRoute(
                    path: 'wallet',
                    builder: (context, state) => const WalletScreen(),
                  ),
                  GoRoute(
                    path: 'resale',
                    builder: (context, state) => const ResaleScreen(),
                  ),
                  GoRoute(
                    path: 'addresses',
                    builder: (context, state) => const AddressesScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const AccountSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'support',
                    builder: (context, state) => const SupportScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: OrdersScreen.path,
                builder: (context, state) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) =>
                        OrderDetailScreen(orderId: state.pathParameters['orderId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: CollectionScreen.path,
                builder: (context, state) => const CollectionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: WishlistScreen.path,
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
        ],
      ),
      // The artist portal: four branches, everything else pushed onto the
      // Dashboard branch so the shell stays visible.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ArtistShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ArtistDashboardScreen.path,
                builder: (context, state) => const ArtistDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'analytics',
                    builder: (context, state) => const ArtistAnalyticsScreen(),
                  ),
                  GoRoute(
                    path: 'coa-nfc',
                    builder: (context, state) => const CoaNfcScreen(),
                  ),
                  GoRoute(
                    path: 'gallery-spaces',
                    builder: (context, state) => const GallerySpacesScreen(),
                  ),
                  GoRoute(
                    path: 'portfolio',
                    builder: (context, state) => const PortfolioScreen(),
                  ),
                  GoRoute(
                    path: 'mou',
                    builder: (context, state) => const MouScreen(),
                  ),
                  GoRoute(
                    path: 'settlements',
                    builder: (context, state) => const ArtistSettlementsScreen(),
                  ),
                  GoRoute(
                    path: 'verification',
                    builder: (context, state) => const ArtistVerificationScreen(),
                  ),
                  GoRoute(
                    path: 'messages',
                    builder: (context, state) => const ArtistMessagesScreen(),
                  ),
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const ArtistKycScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const ArtistSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'support',
                    builder: (context, state) => const ArtistSupportScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ArtistArtworksScreen.path,
                builder: (context, state) => const ArtistArtworksScreen(),
                routes: [
                  GoRoute(
                    path: 'upload',
                    builder: (context, state) => const ArtworkUploadScreen(),
                  ),
                  // Same screen in edit mode — one form, one set of rules.
                  GoRoute(
                    path: ':artworkId/edit',
                    builder: (context, state) => ArtworkUploadScreen(
                      artworkId: state.pathParameters['artworkId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ArtistOrdersScreen.path,
                builder: (context, state) => const ArtistOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ArtistWalletScreen.path,
                builder: (context, state) => const ArtistWalletScreen(),
              ),
            ],
          ),
        ],
      ),
      // The aggregator portal: four branches, everything else pushed onto
      // the Dashboard branch so the shell stays visible.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AggregatorShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AggregatorDashboardScreen.path,
                builder: (context, state) => const AggregatorDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'orders',
                    builder: (context, state) => const AggregatorOrdersScreen(),
                  ),
                  GoRoute(
                    path: 'customers',
                    builder: (context, state) => const AggregatorCustomersScreen(),
                  ),
                  GoRoute(
                    path: 'shipping',
                    builder: (context, state) => const AggregatorShippingScreen(),
                  ),
                  GoRoute(
                    path: 'gallery-spaces',
                    builder: (context, state) => const AggregatorGallerySpacesScreen(),
                  ),
                  GoRoute(
                    path: 'settlements',
                    builder: (context, state) => const AggregatorSettlementsScreen(),
                  ),
                  GoRoute(
                    path: 'analytics',
                    builder: (context, state) => const AggregatorAnalyticsScreen(),
                  ),
                  GoRoute(
                    path: 'messages',
                    builder: (context, state) => const AggregatorMessagesScreen(),
                  ),
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const AggregatorProfileScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const AggregatorSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'support',
                    builder: (context, state) => const AggregatorSupportScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AggregatorBrowseScreen.path,
                builder: (context, state) => const AggregatorBrowseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AggregatorCollectionScreen.path,
                builder: (context, state) => const AggregatorCollectionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AggregatorWalletScreen.path,
                builder: (context, state) => const AggregatorWalletScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
