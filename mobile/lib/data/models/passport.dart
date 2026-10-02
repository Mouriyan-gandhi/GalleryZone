import 'artwork.dart';

/// Who holds a piece today, as far as the public record goes.
enum PassportOwnerKind { artist, collector }

/// One entry in a passport's provenance: a hand-over of ownership, or a
/// loan of display rights. Names only — a scan never shows an email.
class PassportEvent {
  const PassportEvent({
    required this.id,
    required this.kind,
    required this.status,
    required this.fromName,
    required this.toName,
    required this.viaSale,
    required this.initiatedAt,
    this.acceptedAt,
    this.cancelledAt,
    this.displayEndsAt,
    this.displayEndedAt,
  });

  final String id;
  final TransferKind kind;
  final TransferStatus status;
  final String fromName;
  final String toName;

  /// True when the hand-over was a marketplace sale rather than a gift.
  final bool viaSale;
  final String initiatedAt;
  final String? acceptedAt;
  final String? cancelledAt;
  final String? displayEndsAt;
  final String? displayEndedAt;

  /// The record in the shape the existing ownership/display widgets draw.
  OwnershipTransfer toTransfer({required String artworkId, required String artworkTitle}) =>
      OwnershipTransfer(
        id: id,
        artworkId: artworkId,
        artworkTitle: artworkTitle,
        fromName: fromName,
        toName: toName,
        // The invite address never reaches the public record.
        toEmail: '',
        initiatedAt: initiatedAt,
        acceptedAt: acceptedAt,
        cancelledAt: cancelledAt,
        status: status,
        kind: kind,
        displayEndsAt: displayEndsAt,
        displayEndedAt: displayEndedAt,
      );
}

/// What happened at one step of a piece's life (NFC_IMPLEMENTATION.md §6).
enum LifecycleKind {
  created,
  approved,
  listed,
  placedWithGallery,
  returnedFromGallery,
  soldMarketplace,
  soldAtGallery,
  transferred,
  displayed,
  delivered,
}

/// Who did it. A collector is named (the passport already names the owner),
/// but never given a place.
enum LifecycleActorKind { artist, gallery, collector, platform }

/// Where a step happened. Only ever the artist's or a gallery's: a collector's
/// home is private, and the server sends none.
class LifecyclePlace {
  const LifecyclePlace({required this.city, required this.state, required this.country});

  final String city;
  final String state;
  final String country;

  /// "Pune, Maharashtra, India", leaving out what the source did not say.
  String get label => [city, state, country].where((part) => part.isNotEmpty).join(', ');
}

/// One step in a piece's life, oldest first on the passport: made, approved,
/// listed, shown at a gallery, sold, handed over, delivered.
class LifecycleEntry {
  const LifecycleEntry({
    required this.id,
    required this.kind,
    required this.at,
    required this.actorKind,
    required this.actorName,
    this.place,
    this.note,
  });

  final String id;
  final LifecycleKind kind;
  final String at;
  final LifecycleActorKind actorKind;
  final String actorName;
  final LifecyclePlace? place;
  final String? note;
}

/// The public artwork passport — what a printed QR code or an NFC tag
/// resolves to. Anyone can read it: it carries no price of any kind, no
/// email, phone or address, and no collector's user id.
class Passport {
  const Passport({
    required this.artworkId,
    required this.productCode,
    required this.title,
    required this.artistId,
    required this.artistName,
    required this.category,
    required this.medium,
    required this.images,
    required this.status,
    required this.ownerKind,
    required this.ownerName,
    required this.events,
    required this.listedAt,
    this.dimensions,
    this.yearCreated,
    this.coaCertificateNumber,
    this.coaIssuedAt,
    this.nfcLinked = false,
    this.nfcLocked = false,
    this.lifecycle = const [],
  });

  final String artworkId;
  final String productCode;
  final String title;
  final String artistId;
  final String artistName;
  final String category;
  final String medium;
  final String? dimensions;
  final int? yearCreated;
  final List<ArtworkImage> images;

  /// The piece's current status, as a raw API string.
  final String status;

  /// The certificate number, once issued on approval. Null before that.
  final String? coaCertificateNumber;
  final String? coaIssuedAt;
  final String listedAt;
  final PassportOwnerKind ownerKind;
  final String ownerName;
  final List<PassportEvent> events;

  /// A physical tag is linked to the piece. The chip's own id is never public.
  final bool nfcLinked;

  /// The tag was locked read-only for good, so it cannot be rewritten to point
  /// anywhere else.
  final bool nfcLocked;

  /// Everything that happened to the piece, oldest first.
  final List<LifecycleEntry> lifecycle;

  String get coverUrl => images.isEmpty ? '' : images.first.url;

  /// Ownership hand-overs only, oldest first.
  List<PassportEvent> get ownershipEvents =>
      events.where((e) => e.kind == TransferKind.ownership).toList();

  /// Display-rights loans only, oldest first.
  List<PassportEvent> get displayEvents =>
      events.where((e) => e.kind == TransferKind.display).toList();
}

/// How the signed-in viewer relates to a piece in [MyPassport].
enum PassportRelation { owner, artist, holder }

/// A passport plus how the viewer is connected to the piece.
class MyPassport {
  const MyPassport({
    required this.relations,
    required this.passport,
    this.nfcLinked,
    this.holdingId,
  });

  final List<PassportRelation> relations;
  final Passport passport;

  /// Only for a piece the viewer made: whether a physical tag is linked.
  final bool? nfcLinked;

  /// Only for a piece the viewer holds on display: the holding to open.
  final String? holdingId;
}

class MyPassports {
  const MyPassports({required this.total, required this.items});

  /// The full count; [items] is capped by the API.
  final int total;
  final List<MyPassport> items;

  static const empty = MyPassports(total: 0, items: []);
}
