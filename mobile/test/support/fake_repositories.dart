import 'package:gallery_zone/data/models/artist.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/artwork_filters.dart';
import 'package:gallery_zone/data/models/marketplace.dart';
import 'package:gallery_zone/data/models/passport.dart';
import 'package:gallery_zone/data/repositories/artwork_repository.dart';
import 'package:gallery_zone/data/repositories/ownership_repository.dart';

/// A catalogue that serves whatever it is handed - for screens that read the
/// public catalogue and nothing else.
class FakeCatalog implements ArtworkRepository {
  FakeCatalog({this.artworks = const [], this.artists = const [], this.failArtists = false});

  final List<Artwork> artworks;
  final List<ArtistProfile> artists;
  bool failArtists;

  @override
  Future<MarketplacePage> list(ArtworkFilters filters) async => MarketplacePage(
        artworks: artworks,
        total: artworks.length,
        page: 1,
        pageSize: filters.pageSize,
      );

  @override
  Future<Artwork?> get(String id) async => artworks.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<Artwork>> getMany(Iterable<String> ids) async => [
        for (final a in artworks) if (ids.contains(a.id)) a,
      ];

  @override
  Future<List<ArtistCard>> listArtistCards() async => const [];

  @override
  Future<List<Artwork>> listByArtist(String artistId) async =>
      [for (final a in artworks) if (a.artistId == artistId) a];

  @override
  Future<ArtistProfile?> getArtistProfile(String id) async => artists.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<ArtistProfile>> listArtists() async {
    if (failArtists) {
      failArtists = false;
      throw Exception('offline');
    }
    return artists;
  }
}

/// The public passport and the transfers behind it. Everything else on the
/// interface is deliberately unimplemented: a test that reaches for it fails
/// loudly instead of quietly getting an empty answer.
class FakeOwnership implements OwnershipRepository {
  FakeOwnership({this.passports = const {}, this.transfers = const []});

  final Map<String, Passport> passports;
  final List<OwnershipTransfer> transfers;
  bool failPassport = false;

  @override
  Future<Passport?> getPassport(String artworkId) async {
    if (failPassport) {
      failPassport = false;
      throw Exception('offline');
    }
    return passports[artworkId];
  }

  @override
  Future<List<OwnershipTransfer>> listForArtwork(String artworkId) async =>
      [for (final t in transfers) if (t.artworkId == artworkId) t];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
