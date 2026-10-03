/// Port of `frontend-web/features/legal/types.ts`. Every legal document is a
/// list of these, so one screen renders all five.
class LegalSection {
  const LegalSection({required this.id, required this.heading, required this.body});

  final String id;
  final String heading;

  /// One paragraph per entry. Empty for a section whose content is a table
  /// rather than prose — Cookies' category list is the only one today.
  final List<String> body;
}
