import 'package:flutter_riverpod/misc.dart' show Override;

import '../data/remote/remote_aggregator_repository.dart';
import '../data/remote/remote_artist_network_repository.dart';
import '../data/remote/remote_artist_repository.dart';
import '../data/remote/remote_artwork_repository.dart';
import '../data/remote/remote_auth_repository.dart';
import '../data/remote/remote_checkout_repository.dart';
import '../data/remote/remote_customer_repository.dart';
import '../data/remote/remote_nfc_repository.dart';
import '../data/remote/remote_ownership_repository.dart';
import '../features/account/providers/account_providers.dart';
import '../features/aggregator/providers/aggregator_providers.dart';
import '../features/artist/providers/artist_network_providers.dart';
import '../features/artist/providers/artist_providers.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/checkout/providers/checkout_providers.dart';
import '../features/marketplace/providers/marketplace_providers.dart';
import '../features/nfc/providers/nfc_providers.dart';
import '../features/ownership/providers/ownership_providers.dart';
import 'auth/token_manager.dart';
import 'payments/payment_gateway.dart';

/// The composition root: the one place the real implementations are named.
///
/// Every provider defaults to its offline mock, so tests and
/// `--dart-define=GZ_MOCK=true` run on fixtures with nothing to configure.
/// `main()` adds these overrides to put the app on the real API; screens never
/// import a concrete repository.
///
/// [gateway] is the payment sheet; until a native one is registered the app
/// says plainly that online payment isn't available rather than pretending.
List<Override> remoteBackendOverrides(
  TokenManager tokens, {
  PaymentGateway gateway = const UnavailablePaymentGateway(),
}) =>
    [
      remoteBackendProvider.overrideWithValue(true),
      tokenManagerProvider.overrideWithValue(tokens),
      paymentGatewayProvider.overrideWithValue(gateway),
      authRepositoryProvider.overrideWith(
        (ref) => RemoteAuthRepository(
          api: ref.watch(apiClientProvider),
          firebase: ref.watch(firebaseAuthProvider),
          tokens: ref.watch(tokenManagerProvider),
        ),
      ),
      artworkRepositoryProvider.overrideWith((ref) => RemoteArtworkRepository(ref.watch(apiClientProvider))),
      checkoutRepositoryProvider.overrideWith(
        (ref) => RemoteCheckoutRepository(api: ref.watch(apiClientProvider), gateway: ref.watch(paymentGatewayProvider)),
      ),
      customerRepositoryProvider.overrideWith((ref) => RemoteCustomerRepository(ref.watch(apiClientProvider))),
      ownershipRepositoryProvider.overrideWith((ref) => RemoteOwnershipRepository(ref.watch(apiClientProvider))),
      artistRepositoryProvider.overrideWith((ref) => RemoteArtistRepository(ref.watch(apiClientProvider))),
      nfcRepositoryProvider.overrideWith((ref) => RemoteNfcRepository(ref.watch(apiClientProvider))),
      artistNetworkRepositoryProvider.overrideWith(
        (ref) => RemoteArtistNetworkRepository(ref.watch(apiClientProvider)),
      ),
      aggregatorRepositoryProvider.overrideWith(
        (ref) => RemoteAggregatorRepository(api: ref.watch(apiClientProvider), gateway: ref.watch(paymentGatewayProvider)),
      ),
    ];
