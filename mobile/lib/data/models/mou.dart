import 'package:freezed_annotation/freezed_annotation.dart';

part 'mou.freezed.dart';
part 'mou.g.dart';

/// Which agreement. Each party signs its own, at its own version.
enum MouParty { artist, aggregator }

/// The blanks on the signer's side of the agreement, filled from their
/// profile. Every field may be missing — [MouDraft.missing] lists the ones
/// signing can't go ahead without.
@freezed
abstract class MouPartyDetails with _$MouPartyDetails {
  const factory MouPartyDetails({
    String? name,
    String? businessName,
    String? address,
    String? mobile,
    String? email,
    String? governmentId,
    String? gstNo,
  }) = _MouPartyDetails;

  factory MouPartyDetails.fromJson(Map<String, dynamic> json) => _$MouPartyDetailsFromJson(json);
}

/// GalleryZone's side of the signature block (who signs for the company).
@freezed
abstract class MouCompanyDetails with _$MouCompanyDetails {
  const factory MouCompanyDetails({String? name, String? designation}) = _MouCompanyDetails;

  factory MouCompanyDetails.fromJson(Map<String, dynamic> json) =>
      _$MouCompanyDetailsFromJson(json);
}

@freezed
abstract class MouParties with _$MouParties {
  const factory MouParties({
    @Default(MouPartyDetails()) MouPartyDetails party,
    @Default(MouCompanyDetails()) MouCompanyDetails company,
  }) = _MouParties;

  factory MouParties.fromJson(Map<String, dynamic> json) => _$MouPartiesFromJson(json);
}

/// A party's acceptance of one version of their MOU. Versioned so a later
/// revision asks again rather than inheriting an acceptance of wording the
/// signer never saw.
@freezed
abstract class MouAcceptance with _$MouAcceptance {
  const factory MouAcceptance({
    required String version,
    required String acceptedAt,

    /// Typed by the signer; must match the account's name. Empty on records
    /// that predate the field.
    @Default('') String signatureName,

    /// The drawn signature as a PNG data URL. Empty on records that predate
    /// the signature pad (and on the offline mock, which only types a name).
    @Default('') String signatureDataUrl,

    /// The blanks as they stood when it was signed — what the signed copy
    /// shows, whatever the profile says since.
    MouParties? parties,
  }) = _MouAcceptance;

  factory MouAcceptance.fromJson(Map<String, dynamic> json) => _$MouAcceptanceFromJson(json);
}

/// The current version of the agreement with its blanks filled from the
/// profile *as it stands right now* — exactly what will be recorded if the
/// signer signs today. Saving the profile therefore refreshes the unsigned
/// document.
class MouDraft {
  const MouDraft({
    required this.version,
    this.parties = const MouParties(),
    this.missing = const [],
    this.asOf,
  });

  final String version;
  final MouParties parties;

  /// Required blanks the profile can't fill yet (`name`, `address`, …).
  /// Signing is refused while any remain.
  final List<String> missing;

  /// The server's "now": the date the document will carry if signed today.
  final String? asOf;

  bool get canSign => missing.isEmpty;
}

/// The signed state of one party's agreement.
class MouState {
  const MouState({required this.draft, this.acceptance});

  final MouDraft draft;

  /// Set only when it is a signature of [MouDraft.version]; an acceptance of
  /// an older text reads as unsigned.
  final MouAcceptance? acceptance;

  bool get isSigned => acceptance != null;
}
