import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/api/json_utils.dart';
import '../models/artist.dart';
import '../models/artwork.dart';
import '../models/artwork_filters.dart';
import '../models/marketplace.dart';
import '../repositories/artwork_repository.dart';
import 'mappers/catalog_mappers.dart';

/// The public catalogue from the real API. Filtering, sorting, search and
/// paging all happen on the server — the phone never downloads the whole
/// catalogue — and the filter choices come back as facets computed from what
/// is actually live, so nothing about the filter UI is hard-coded.
///
/// Every route here is public, so none sends a credential.
class RemoteArtworkRepository implements ArtworkRepository {
  RemoteArtworkRepository(this.api);

  final ApiClient api;

  static Map<String, dynamic> queryOf(ArtworkFilters filters) {
    final query = <String, dynamic>{'pageSize': '${filters.pageSize}'};
    if (filters.categories.isNotEmpty) query['category'] = filters.categories.join(',');
    if (filters.mediums.isNotEmpty) query['medium'] = filters.mediums.join(',');
    if (filters.rarity != null) query['rarity'] = artworkRarityCode[filters.rarity]!;
    if (filters.artistId != null) query['artistId'] = filters.artistId;
    if (filters.location != null) query['location'] = filters.location;
    if (filters.size != null) query['size'] = sizeBandToApi(filters.size!);
    if (filters.minPrice != null) query['minPricePaise'] = '${rupeesToPaise(filters.minPrice!)}';
    if (filters.maxPrice != null) query['maxPricePaise'] = '${rupeesToPaise(filters.maxPrice!)}';
    final text = filters.query?.trim() ?? '';
    if (text.isNotEmpty) query['q'] = text;
    final sort = switch (filters.sortBy) {
      ArtworkSortBy.priceAsc => 'price_asc',
      ArtworkSortBy.priceDesc => 'price_desc',
      ArtworkSortBy.newest => 'newest',
      null => null,
    };
    if (sort != null) query['sort'] = sort;
    if (filters.page > 1) query['page'] = '${filters.page}';
    return query;
  }

  @override
  Future<MarketplacePage> list(ArtworkFilters filters) async =>
      marketplacePageFromApi(await api.getMap('/v1/artworks', query: queryOf(filters), auth: false));

  @override
  Future<Artwork?> get(String id) async {
    try {
      return artworkFromApi(await api.getMap('/v1/artworks/${Uri.encodeComponent(id)}', auth: false));
    } on ApiError catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<List<Artwork>> getMany(Iterable<String> ids) async {
    final unique = ids.toSet().toList();
    final found = <String, Artwork>{};
    // A few at a time: a long wishlist must not open a long queue of sockets.
    for (var start = 0; start < unique.length; start += 6) {
      final batch = unique.skip(start).take(6);
      final results = await Future.wait(batch.map(get));
      for (final artwork in results) {
        if (artwork != null) found[artwork.id] = artwork;
      }
    }
    return [for (final id in unique) if (found[id] != null) found[id]!];
  }

  @override
  Future<List<Artwork>> listByArtist(String artistId) async {
    try {
      final json = await api.getMap('/v1/artists/${Uri.encodeComponent(artistId)}/artworks', auth: false);
      return asMapList(json['artworks']).map(artworkFromApi).toList();
    } on ApiError catch (error) {
      if (error.isNotFound) return const [];
      rethrow;
    }
  }

  @override
  Future<ArtistProfile?> getArtistProfile(String id) async {
    try {
      return artistProfileFromApi(await api.getMap('/v1/artists/${Uri.encodeComponent(id)}', auth: false));
    } on ApiError catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<List<ArtistProfile>> listArtists() async =>
      [for (final card in await listArtistCards()) card.profile];

  @override
  Future<List<ArtistCard>> listArtistCards() async {
    final json = await api.getMap('/v1/artists', auth: false);
    return asMapList(json['artists']).map(artistCardFromApi).toList();
  }
}
