import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/similar_artworks.dart';
import 'package:gallery_zone/data/models/artwork.dart';

import 'support/catalog_fixtures.dart';

/// Port of the web's `lib/similar-artworks.ts`: category alone is enough, price
/// and size together are enough, either of those on their own is not.
Artwork _piece(String id, {String category = 'painting', double price = 50000, ArtworkSizeBand? size}) =>
    fixtureArtwork(id: id, category: category, price: price).copyWith(sizeBand: size);

void main() {
  group('similarityScore', () {
    test('the same category is worth 3, a price within a quarter 2, the same size 1', () {
      final a = _piece('a', size: ArtworkSizeBand.medium);
      expect(similarityScore(a, _piece('b', category: 'sculpture', price: 51000)), 2, reason: 'price only');
      expect(similarityScore(a, _piece('b', category: 'sculpture', price: 51000, size: ArtworkSizeBand.medium)), 3);
      expect(similarityScore(a, _piece('b', price: 500000)), 3, reason: 'category only');
      expect(similarityScore(a, _piece('b', price: 51000, size: ArtworkSizeBand.medium)), 6, reason: 'everything');
    });

    test('exactly three quarters apart still counts as similar in price', () {
      expect(similarityScore(_piece('a', category: 'x', price: 100000), _piece('b', category: 'y', price: 75000)), 2);
      expect(similarityScore(_piece('a', category: 'x', price: 100000), _piece('b', category: 'y', price: 74999)), 0);
    });

    test('a missing price or size scores nothing', () {
      expect(similarityScore(_piece('a', category: 'x', price: 0), _piece('b', category: 'y', price: 0)), 0);
      expect(similarityScore(_piece('a', category: 'x'), _piece('b', category: 'y')), 2, reason: 'no size on either');
    });
  });

  group('similarTo', () {
    final held = _piece('held', price: 50000, size: ArtworkSizeBand.medium);

    test('best first, ties in list order, and never the piece itself', () {
      final candidates = [
        _piece('weak', category: 'sculpture', price: 52000), // 2: below the bar
        _piece('tie-1', price: 900000), // 3
        _piece('best', price: 51000, size: ArtworkSizeBand.medium), // 6
        _piece('tie-2', price: 900000), // 3
        held,
      ];
      expect(similarTo([held], candidates, (a) => a).map((a) => a.id), ['best', 'tie-1', 'tie-2']);
    });

    test('is the highest score against ANY reference, and skips every reference', () {
      final other = _piece('other', category: 'sculpture', price: 10000);
      final candidates = [_piece('near-other', category: 'sculpture', price: 11000), other, held];
      expect(similarTo([held, other], candidates, (a) => a).map((a) => a.id), ['near-other']);
    });

    test('stops at the limit', () {
      final candidates = [for (var i = 0; i < 9; i++) _piece('c$i')];
      expect(similarTo([held], candidates, (a) => a), hasLength(4));
      expect(similarTo([held], candidates, (a) => a, limit: 6), hasLength(6));
    });

    test('works over wrappers, not just artworks', () {
      final wrapped = [(id: 1, art: _piece('x'))];
      expect(similarTo([held], wrapped, (w) => w.art).single.id, 1);
    });

    test('nothing to suggest when nothing is alike', () {
      expect(similarTo([held], [_piece('far', category: 'textile', price: 5000000)], (a) => a), isEmpty);
    });
  });
}
