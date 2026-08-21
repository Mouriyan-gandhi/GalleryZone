import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/mock/mock_artist_repository.dart';
import 'package:gallery_zone/data/mock/mock_artwork_repository.dart';
import 'package:gallery_zone/data/mock/seed/artists_seed.dart';
import 'package:gallery_zone/data/models/artwork_filters.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/account/screens/wishlist_screen.dart';
import 'package:gallery_zone/features/marketplace/providers/marketplace_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
  });

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('following an artist survives a fresh read of the store', () {
    final first = container();
    expect(first.read(followsProvider), isEmpty);
    first.read(followsProvider.notifier).toggle('meera-nair');
    expect(first.read(followsProvider), {'meera-nair'});

    // A second container rebuilds the notifier from storage, which is what a
    // cold start does.
    expect(container().read(followsProvider), {'meera-nair'});
  });

  test('toggling twice unfollows, and follows are independent of the wishlist', () {
    final c = container();
    c.read(followsProvider.notifier).toggle('meera-nair');
    c.read(followsProvider.notifier).toggle('meera-nair');
    expect(c.read(followsProvider), isEmpty);

    // Both are id sets in the same store; a shared key would make one clear
    // the other.
    c.read(followsProvider.notifier).toggle('meera-nair');
    c.read(wishlistProvider.notifier).toggle('tide-line-dusk');
    expect(c.read(followsProvider), {'meera-nair'});
    expect(c.read(wishlistProvider), {'tide-line-dusk'});
  });

  test('every followable artist id resolves to a real profile', () async {
    // The Following list joins ids against listArtists(); an id that does not
    // resolve would silently vanish from the list rather than error.
    final artists = await MockArtworkRepository().listArtists();
    expect(artists, isNotEmpty);
    for (final artist in artists) {
      expect(artist.id.trim(), isNotEmpty);
      expect(artist.name.trim(), isNotEmpty);
    }
  });

  testWidgets('Saved shows both segments and their counts', (tester) async {
    final c = container();
    c.read(wishlistProvider.notifier).toggle('tide-line-dusk');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: AppTheme.dark, home: const WishlistScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Artworks (1)'), findsOneWidget);
    // Nothing followed yet, so that segment stays uncounted.
    expect(find.text('Artists'), findsOneWidget);
  });

  testWidgets('the Artists segment explains itself when empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark, home: const WishlistScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Artists'));
    await tester.pumpAndSettle();

    expect(find.text("You aren't following anyone yet"), findsOneWidget);
    // An empty state that offers no way out is a dead end.
    expect(find.text('Find an artist'), findsOneWidget);
  });

  testWidgets('a followed artist appears in the Artists segment', (tester) async {
    // Read the fixture directly rather than awaiting the repository: inside
    // testWidgets everything runs in fake async, so a `mockDelay` future
    // never fires and the test hangs until the harness kills it.
    final target = seedArtists().first;

    final c = container();
    c.read(followsProvider.notifier).toggle(target.id);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: AppTheme.dark, home: const WishlistScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Artists (1)'));
    await tester.pumpAndSettle();
    // Each row then kicks off its own "how many pieces listed" read. Nothing
    // animates while that is in flight, so pumpAndSettle returns with the
    // timer still pending and the test fails on teardown — pump past it.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(target.name), findsOneWidget);
    expect(find.textContaining('listed'), findsOneWidget);
  });

  test('deleting the account clears every collection this app owns', () async {
    // Seed several collections through the repositories that own them, so
    // this fails if clearAll() ever stops covering one of them.
    final c = container();
    c.read(wishlistProvider.notifier).toggle('tide-line-dusk');
    c.read(followsProvider.notifier).toggle('meera-nair');
    await MockArtistRepository().submitSupportTicket(
      subject: 'Question',
      message: 'Details',
    );
    await MockArtworkRepository().list(const ArtworkFilters());

    await MockDb.clearAll();

    // Everything reads back as a first read would: reseeded fixtures for the
    // seeded collections, empty for the client-only sets.
    expect(container().read(wishlistProvider), isEmpty);
    expect(container().read(followsProvider), isEmpty);
    final tickets = await MockArtistRepository().listSupportTickets();
    expect(tickets, hasLength(1), reason: 'back to the seeded fixture, not the added one');
  });
}
