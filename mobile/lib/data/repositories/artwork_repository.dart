import '../models/artist.dart';
import '../models/artwork.dart';
import '../models/artwork_filters.dart';
import '../models/marketplace.dart';

/// The public catalogue: the marketplace listing, one piece, an artist and
/// their work. Everything here is readable without signing in, and none of it
/// ever carries an artist's private price.
///
/// Two implementations: [MockArtworkRepository] (offline fixtures) and
/// `RemoteArtworkRepository` (the real API, where filtering, sorting, search
/// and paging all happen on the server).
abstract class ArtworkRepository {
  /// One page of the live marketplace for [filters], with the whole
  /// marketplace's facets (the filter choices that exist right now).
  Future<MarketplacePage> list(ArtworkFilters filters);

  /// One piece by id, in any status — a passport or certificate link must
  /// still resolve after the piece has sold. Null when there is no such id.
  Future<Artwork?> get(String id);

  /// Several pieces by id, in any status; ids that don't resolve are left
  /// out. For the wishlist and for rows that carry only an `artworkId`.
  Future<List<Artwork>> getMany(Iterable<String> ids);

  Future<List<Artwork>> listByArtist(String artistId);
  Future<ArtistProfile?> getArtistProfile(String id);

  /// Every public artist profile. The Following list joins against this
  /// rather than fanning out one [getArtistProfile] call per followed id.
  Future<List<ArtistProfile>> listArtists();

  /// The artists directory: artists with at least one live listing, with how
  /// many and a cover image.
  Future<List<ArtistCard>> listArtistCards();
}
