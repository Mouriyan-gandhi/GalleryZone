import '../../models/artist_network.dart';
import 'artist_seed.dart' show currentArtistId, currentArtistName;
import 'artists_seed.dart';

/// Ratings, connections and collaborations for the demo — the Dart side of
/// `lib/mock-data/artist-network.ts`. There is no backend, so nothing here is
/// earned at runtime: reviews are seeded, and the write paths (send a request,
/// accept it, propose a collaboration) act on this seed.
///
/// The demo artist is deliberately mid-table rather than a perfect five — an
/// artist looking at their own rating card needs to see what a mixed one
/// looks like.

/// The demo artist's own avatar, from the public fixtures.
const currentArtistAvatar = '/early-program/avatar-3.png';

String _daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).toIso8601String();

({String name, String avatar}) _publicArtist(String id) {
  final artist = seedArtists().firstWhere(
    (a) => a.id == id,
    orElse: () => throw StateError('artist_network_seed: unknown artist "$id"'),
  );
  return (name: artist.name, avatar: artist.profileImageUrl);
}

const _reviewSeeds = <({
  String artistId,
  String reviewerName,
  int rating,
  String artworkTitle,
  String comment,
  int daysAgo,
})>[
  (
    artistId: currentArtistId,
    reviewerName: 'Aarav Shah',
    rating: 5,
    artworkTitle: 'Whispers in Bronze',
    comment:
        'Arrived exactly as photographed, packed properly, and the certificate '
        'was in the box. Would buy again.',
    daysAgo: 112,
  ),
  (
    artistId: currentArtistId,
    reviewerName: 'Nandini Verma',
    rating: 5,
    artworkTitle: 'Monsoon Reverie',
    comment:
        'The colour is richer in person than on screen. She answered two '
        'questions before I bought, which decided it for me.',
    daysAgo: 61,
  ),
  (
    artistId: currentArtistId,
    reviewerName: 'Karthik Menon',
    rating: 4,
    artworkTitle: 'Fragments of Dawn',
    comment:
        'Beautiful piece. Shipping took a few days longer than the estimate, '
        'otherwise no complaints.',
    daysAgo: 34,
  ),
  (
    artistId: currentArtistId,
    reviewerName: 'Sanjana Rao',
    rating: 4,
    artworkTitle: 'Eclipse of Thoughts',
    comment:
        'Saw it at the gallery before buying. Framed well and ready to hang '
        'straight away.',
    daysAgo: 21,
  ),
  (
    artistId: currentArtistId,
    reviewerName: 'Imran Qureshi',
    rating: 3,
    artworkTitle: 'Monsoon Reverie',
    comment:
        'Good work, but the dimensions read larger on the listing than the '
        'piece felt on the wall.',
    daysAgo: 9,
  ),
  (
    artistId: 'meera-nair',
    reviewerName: 'Divya Pillai',
    rating: 5,
    artworkTitle: 'Before the Rain',
    comment: 'Second purchase from Meera. Consistent quality both times.',
    daysAgo: 74,
  ),
  (
    artistId: 'meera-nair',
    reviewerName: 'Rahul Nanda',
    rating: 4,
    artworkTitle: 'Coastal Elegy',
    comment: 'Lovely canvas, minor scuff on the frame corner in transit.',
    daysAgo: 30,
  ),
  (
    artistId: 'arjun-mehta',
    reviewerName: 'Tara Bhatia',
    rating: 5,
    artworkTitle: 'Reclaimed Stone Vessel',
    comment: 'The finish is extraordinary up close. Worth the wait.',
    daysAgo: 96,
  ),
  (
    artistId: 'kavya-iyer',
    reviewerName: 'Aditi Roy',
    rating: 4,
    artworkTitle: 'Ink Field No. 2',
    comment: 'Delicate work. Packaging could have been sturdier.',
    daysAgo: 58,
  ),
  (
    artistId: 'priya-subramaniam',
    reviewerName: 'Gaurav Iyer',
    rating: 5,
    artworkTitle: 'Thread Count',
    comment:
        'Textile work that photographs badly and looks superb in person.',
    daysAgo: 66,
  ),
];

List<ArtistReview> seedArtistReviews() => [
  for (var i = 0; i < _reviewSeeds.length; i++)
    ArtistReview(
      id: 'rev-${i + 1}',
      artistId: _reviewSeeds[i].artistId,
      reviewerName: _reviewSeeds[i].reviewerName,
      rating: _reviewSeeds[i].rating,
      comment: _reviewSeeds[i].comment,
      artworkTitle: _reviewSeeds[i].artworkTitle,
      createdAt: _daysAgo(_reviewSeeds[i].daysAgo),
    ),
];

/// One accepted connection so the demo artist has a peer to collaborate with,
/// and one incoming request waiting on them so Accept/Ignore has something to
/// act on the first time the screen is opened.
List<ArtistConnection> seedArtistConnections() {
  final meera = _publicArtist('meera-nair');
  final arjun = _publicArtist('arjun-mehta');
  return [
    ArtistConnection(
      id: 'conn-1',
      requesterId: currentArtistId,
      requesterName: currentArtistName,
      requesterAvatar: currentArtistAvatar,
      recipientId: 'meera-nair',
      recipientName: meera.name,
      recipientAvatar: meera.avatar,
      status: ConnectionStatus.accepted,
      message: 'We both work coastal light — would be good to compare notes.',
      requestedAt: _daysAgo(48),
      respondedAt: _daysAgo(47),
    ),
    ArtistConnection(
      id: 'conn-2',
      requesterId: 'arjun-mehta',
      requesterName: arjun.name,
      requesterAvatar: arjun.avatar,
      recipientId: currentArtistId,
      recipientName: currentArtistName,
      recipientAvatar: currentArtistAvatar,
      status: ConnectionStatus.pending,
      message:
          'Planning a sculpture-and-canvas pairing for a Jaipur show. '
          'Interested?',
      requestedAt: _daysAgo(3),
    ),
  ];
}

List<ArtistCollaboration> seedArtistCollaborations() {
  final meera = _publicArtist('meera-nair');
  return [
    ArtistCollaboration(
      id: 'collab-1',
      proposerId: 'meera-nair',
      proposerName: meera.name,
      partnerId: currentArtistId,
      partnerName: currentArtistName,
      title: 'Two Coasts',
      brief:
          'A paired series — six canvases each, hung as alternating pairs, on '
          'the monsoon light either side of the peninsula.',
      status: CollaborationStatus.proposed,
      proposedAt: _daysAgo(6),
    ),
  ];
}
