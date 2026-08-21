import '../models/artist.dart';
import '../models/artwork.dart';
import '../models/artwork_filters.dart';

/// Contract mirroring `artworkService.ts` (plus its co-located
/// `artistService.get`, same file on the web side). One implementation for
/// now — [MockArtworkRepository] — a `Remote`-prefixed dio-backed
/// implementation swaps in behind this same interface once a real backend
/// exists, matching SAD §3.3/§3.4 (Artwork Service, Marketplace Service).
///
/// Note: unlike the TS source, this doesn't split `ArtworkSummary` vs
/// `Artwork` into two types — [Artwork] here already carries every summary
/// field plus the rest, so `list`/`listByArtist` just return the same type
/// `get` does. No behavior difference, one less type to keep in sync.
abstract class ArtworkRepository {
  Future<List<Artwork>> list(ArtworkFilters filters);
  Future<Artwork?> get(String id);
  Future<List<Artwork>> listByArtist(String artistId);
  Future<ArtistProfile?> getArtistProfile(String id);

  /// Every public artist profile. The Following list joins against this
  /// rather than fanning out one [getArtistProfile] call per followed id.
  Future<List<ArtistProfile>> listArtists();
}
