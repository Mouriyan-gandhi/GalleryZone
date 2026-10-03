import '../../../data/models/mou.dart';

/// The MOU as data, and how its blanks are filled. Port of
/// `features/mou/mou-document.ts`: shared by the on-screen agreement and the
/// signed PDF so the two can never fill a blank differently.
///
/// The text comes from the website's generated data (see `artist/mou_data.dart`
/// and `aggregator/aggregator_mou_data.dart`). The values come from the API: the
/// draft (the signer's profile right now) before signing, the snapshot recorded
/// with the signature after.

/// Every blank the paper has.
enum MouFieldKey {
  partyName,
  partyBusinessName,
  partyAddress,
  partyMobile,
  partyEmail,
  partyGovernmentId,
  partyGstNo,
  partyEffectiveDate,
  partySignature,
  partyDate,
  companySignatory,
  companyName,
  companyDesignation,
  companySignature,
  companyDate,
}

/// One block of the document, in the order the company wrote it.
sealed class MouBlock {
  const MouBlock();
}

final class MouTitle extends MouBlock {
  const MouTitle(this.text);

  final String text;
}

final class MouHeading extends MouBlock {
  const MouHeading(this.text, {this.center = false});

  final String text;
  final bool center;
}

final class MouSubheading extends MouBlock {
  const MouSubheading(this.text);

  final String text;
}

final class MouParagraph extends MouBlock {
  const MouParagraph(this.text, {this.center = false});

  final String text;
  final bool center;
}

/// A lettered or numbered item: `a.` and its text.
final class MouItem extends MouBlock {
  const MouItem(this.marker, this.text);

  final String marker;
  final String text;
}

/// "FOR GALLERYZONE PRIVATE LIMITED", "ARTIST": the heading over a signature block.
final class MouSigner extends MouBlock {
  const MouSigner(this.text);

  final String text;
}

final class MouField extends MouBlock {
  const MouField(this.label, this.key);

  final String label;
  final MouFieldKey key;
}

final class MouNote extends MouBlock {
  const MouNote(this.text);

  final String text;
}

class MouDocument {
  const MouDocument({
    required this.party,
    required this.version,
    required this.title,
    required this.intro,
    required this.footer,
    required this.blocks,
  });

  final MouParty party;
  final String version;

  /// How the profile page names it - not part of the document text.
  final String title;
  final String intro;

  /// The running footer of the source PDF, repeated on every page of ours.
  final String footer;
  final List<MouBlock> blocks;
}

/// Everything a blank can be filled from, at one moment: before signing, or as
/// signed.
class MouFill {
  const MouFill({
    required this.parties,
    required this.date,
    required this.signed,
    this.signatureName,
    this.signatureDataUrl,
  });

  /// The agreement as it will be recorded if signed now.
  factory MouFill.draft(MouDraft draft) => MouFill(
    parties: draft.parties,
    date: draft.asOf ?? DateTime.now().toUtc().toIso8601String(),
    signed: false,
  );

  /// The agreement as it was signed. Records from before the blanks were
  /// snapshotted fall back to what the profile says today.
  factory MouFill.signed(MouAcceptance acceptance, MouDraft draft) => MouFill(
    parties: acceptance.parties ?? draft.parties,
    date: acceptance.acceptedAt,
    signed: true,
    signatureName: acceptance.signatureName,
    signatureDataUrl: acceptance.signatureDataUrl.isEmpty
        ? null
        : acceptance.signatureDataUrl,
  );

  final MouParties parties;

  /// The signing date: the acceptance time once signed, the server's today before.
  final String date;
  final bool signed;
  final String? signatureName;
  final String? signatureDataUrl;
}

/// What one blank reads.
sealed class MouFieldValue {
  const MouFieldValue();
}

final class MouFilled extends MouFieldValue {
  const MouFilled(this.text);

  final String text;
}

final class MouSignature extends MouFieldValue {
  const MouSignature(this.name, this.image);

  final String name;

  /// PNG data URL, if one was drawn.
  final String? image;
}

/// Will be written when the document is signed.
final class MouPending extends MouFieldValue {
  const MouPending(this.text);

  final String text;
}

/// A required detail the profile can't supply yet.
final class MouMissing extends MouFieldValue {
  const MouMissing();
}

final class MouBlank extends MouFieldValue {
  const MouBlank();
}

// --- Dates ---------------------------------------------------------------------------------------

// Dates on the document are Indian dates, whatever the reader's time zone: an
// MOU signed at 00:30 IST is dated that day, not the day before. India keeps no
// daylight saving, so a fixed offset is exact.
DateTime _ist(String iso) =>
    DateTime.parse(iso).toUtc().add(const Duration(hours: 5, minutes: 30));

String _two(int n) => n.toString().padLeft(2, '0');

/// `29/09/2026`
String mouDate(String iso) {
  final d = _ist(iso);
  return '${_two(d.day)}/${_two(d.month)}/${d.year}';
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// `29 September 2026 at 6:45 pm IST`
String mouDateTime(String iso) {
  final d = _ist(iso);
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${d.day} ${_months[d.month - 1]} ${d.year} at $hour:${_two(d.minute)} ${d.hour < 12 ? 'am' : 'pm'} IST';
}

// --- Filling a blank -------------------------------------------------------------------------------

/// The blanks a party must be able to fill before signing. GST No. is not one:
/// not every aggregator is registered.
const _required = {
  MouParty.artist: {'name', 'address', 'mobile', 'email', 'governmentId'},
  MouParty.aggregator: {'name', 'businessName', 'address', 'mobile'},
};

/// What one blank reads, at this moment. Port of `mouFieldValue`.
MouFieldValue mouFieldValue(MouFieldKey key, MouFill fill, MouParty party) {
  final company = fill.parties.company;
  // Galleryzone signs through its configured signatory. Without one, its lines
  // stay blank rather than showing a name nobody gave.
  final companySigns = (company.name ?? '').isNotEmpty;

  switch (key) {
    case MouFieldKey.partySignature:
      if (fill.signed && (fill.signatureName ?? '').isNotEmpty) {
        return MouSignature(fill.signatureName!, fill.signatureDataUrl);
      }
      return const MouPending('Signed below');
    case MouFieldKey.partyDate:
      return fill.signed
          ? MouFilled(mouDate(fill.date))
          : MouPending(mouDate(fill.date));
    case MouFieldKey.partyEffectiveDate:
      final text = mouDate(fill.date).replaceAll('/', ' / ');
      return fill.signed ? MouFilled(text) : MouPending(text);
    case MouFieldKey.companySignatory:
    case MouFieldKey.companyName:
      return companySigns ? MouFilled(company.name!) : const MouBlank();
    case MouFieldKey.companyDesignation:
      return (company.designation ?? '').isNotEmpty
          ? MouFilled(company.designation!)
          : const MouBlank();
    case MouFieldKey.companySignature:
      if (!companySigns) return const MouBlank();
      return fill.signed
          ? const MouFilled('Signed electronically')
          : const MouPending('Signed electronically when you sign');
    case MouFieldKey.companyDate:
      if (!companySigns) return const MouBlank();
      return fill.signed
          ? MouFilled(mouDate(fill.date))
          : MouPending(mouDate(fill.date));
    case MouFieldKey.partyName:
    case MouFieldKey.partyBusinessName:
    case MouFieldKey.partyAddress:
    case MouFieldKey.partyMobile:
    case MouFieldKey.partyEmail:
    case MouFieldKey.partyGovernmentId:
    case MouFieldKey.partyGstNo:
      final detail = _detailOf(key);
      final value = _valueOf(fill.parties.party, detail);
      if ((value ?? '').isNotEmpty) return MouFilled(value!);
      return _required[party]!.contains(detail)
          ? const MouMissing()
          : const MouBlank();
  }
}

String _detailOf(MouFieldKey key) => switch (key) {
  MouFieldKey.partyName => 'name',
  MouFieldKey.partyBusinessName => 'businessName',
  MouFieldKey.partyAddress => 'address',
  MouFieldKey.partyMobile => 'mobile',
  MouFieldKey.partyEmail => 'email',
  MouFieldKey.partyGovernmentId => 'governmentId',
  MouFieldKey.partyGstNo => 'gstNo',
  _ => '',
};

String? _valueOf(MouPartyDetails party, String detail) => switch (detail) {
  'name' => party.name,
  'businessName' => party.businessName,
  'address' => party.address,
  'mobile' => party.mobile,
  'email' => party.email,
  'governmentId' => party.governmentId,
  'gstNo' => party.gstNo,
  _ => null,
};

/// How the profile page names a missing detail.
const mouDetailLabel = {
  'name': 'Full name',
  'businessName': 'Business name',
  'address': 'Address (line 1, city, state and pincode)',
  'mobile': 'Mobile number',
  'email': 'Email',
  'governmentId': 'PAN',
  'gstNo': 'GST number',
};

/// The blanks of the counterparty, filled from a profile exactly as the API
/// does it (`mouPartyDetails` in `backend/packages/db/src/mou.ts`), for the
/// offline demo: so what an artist reads before signing in the mock is what the
/// real service would record. Pure.
({MouPartyDetails details, List<String> missing}) mouPartyDetailsFor({
  required MouParty party,
  required String fullName,
  required String email,
  required String phone,
  String? pan,
  String? aadhaarMasked,
  String? gstin,
  String? companyName,
  String pickupLine1 = '',
  String pickupLine2 = '',
  String pickupCity = '',
  String pickupState = '',
  String pickupPincode = '',
}) {
  String? text(String? value) =>
      value != null && value.trim().isNotEmpty ? value.trim() : null;

  final line1 = text(pickupLine1);
  final line2 = text(pickupLine2);
  final city = text(pickupCity);
  final state = text(pickupState);
  final pincode = text(pickupPincode);
  final address =
      line1 != null && city != null && state != null && pincode != null
      ? [line1, ?line2, city, '$state $pincode'].join(', ')
      : null;

  final phoneText = text(phone);
  // Stored as the bare 10 digits; written the way it is read aloud.
  final mobile = phoneText == null
      ? null
      : RegExp(r'^\d{10}$').hasMatch(phoneText)
      ? '+91 ${phoneText.substring(0, 5)} ${phoneText.substring(5)}'
      : phoneText;

  // PAN identifies the signer for tax and is already required to list. An
  // Aadhaar number only ever appears masked, never in full.
  final panText = text(pan);
  final aadhaar = text(aadhaarMasked);
  final governmentId = panText != null
      ? 'PAN $panText'
      : aadhaar != null
      ? 'Aadhaar $aadhaar'
      : null;

  final details = MouPartyDetails(
    name: text(fullName),
    businessName: party == MouParty.aggregator ? text(companyName) : null,
    address: address,
    mobile: mobile,
    email: text(email),
    governmentId: party == MouParty.artist ? governmentId : null,
    gstNo: party == MouParty.aggregator ? text(gstin) : null,
  );
  return (
    details: details,
    missing: [
      for (final key in _requiredInOrder[party]!)
        if ((_valueOf(details, key) ?? '').isEmpty) key,
    ],
  );
}

const _requiredInOrder = {
  MouParty.artist: ['name', 'address', 'mobile', 'email', 'governmentId'],
  MouParty.aggregator: ['name', 'businessName', 'address', 'mobile'],
};
