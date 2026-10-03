import '../../core/api/api_client.dart';
import '../../core/api/json_utils.dart';
import '../models/nfc.dart';
import '../repositories/nfc_repository.dart';

/// The NFC routes on the real API. The chip's UID is sent as the phone read it;
/// the server accepts either case and normalises it.
class RemoteNfcRepository implements NfcRepository {
  RemoteNfcRepository(this.api);

  final ApiClient api;

  String _path(String artworkId, String leaf) => '/v1/artist/artworks/${Uri.encodeComponent(artworkId)}/nfc/$leaf';

  @override
  Future<NfcCheckAction> check(String artworkId, String tagUid, NfcIntent intent) async {
    final json = asMap(await api.post(_path(artworkId, 'check'), body: {'tagUid': tagUid, 'intent': intent.name}));
    return switch (json['action']) {
      'link' => NfcCheckAction.link,
      'replace' => NfcCheckAction.replace,
      'lock' => NfcCheckAction.lock,
      _ => NfcCheckAction.noop,
    };
  }

  @override
  Future<NfcState> confirmLinked(String artworkId, String tagUid) async =>
      _state(await api.post(_path(artworkId, 'link'), body: {'tagUid': tagUid}));

  @override
  Future<NfcState> confirmLocked(String artworkId, String tagUid) async =>
      _state(await api.post(_path(artworkId, 'lock'), body: {'tagUid': tagUid}));

  @override
  Future<void> reportFailure(String artworkId, NfcFailureStep step, String message, {String? tagUid}) async {
    try {
      await api.post(
        _path(artworkId, 'failure'),
        body: {
          'step': step.api,
          'message': message.length > 300 ? message.substring(0, 300) : message,
          'tagUid': ?tagUid,
        },
      );
    } catch (_) {
      // Reporting is best-effort; the artist already has their error.
    }
  }

  NfcState _state(Object? body) {
    final json = asMap(body);
    return NfcState(
      artworkId: json['artworkId'] as String? ?? '',
      tagUid: json['nfcTagUid'] as String?,
      linkedAt: isoOrNull(json['nfcLinkedAt']),
      lockedAt: isoOrNull(json['nfcLockedAt']),
    );
  }
}
