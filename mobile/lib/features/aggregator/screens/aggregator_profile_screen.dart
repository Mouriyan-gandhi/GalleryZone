import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/input_formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artwork.dart' show ReviewStatus, reviewStatusLabel;
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart' show EmptyState;
import '../../shell/portal_menu.dart' show portalInitials;
import '../../shell/portal_widgets.dart';
import '../country_codes.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/phone_field.dart';

const _designationPresets = ['Gallery Manager', 'Owner or Director', 'Operations Manager'];
const _otherDesignation = '__other__';

/// Port of `app/aggregator/profile/page.tsx`: the business at a glance, the partner
/// agreement, then the forms that edit it - company profile and coordinator, bank
/// account - and the identity on file.
///
/// What the website's form offers and the API cannot keep is not offered here as if
/// it could be: a photo, a country, the coordinator's own phone and email, and an
/// Aadhaar number all "save" there and are gone on the next load. The coordinator's
/// phone and email are the company phone and the account email, and say so; the
/// identity is read-only, as it already is on the artist's profile.
class AggregatorProfileScreen extends ConsumerWidget {
  const AggregatorProfileScreen({super.key});

  static const path = '/aggregator/dashboard/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(aggregatorProfileProvider);
    final profile = profileAsync.value;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Company profile')),
        body: profileAsync.hasError
            ? EmptyState(
                icon: LucideIcons.triangleAlert,
                title: "Couldn't load your profile",
                description: authErrorMessage(profileAsync.error!),
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(aggregatorProfileProvider),
                  child: const Text('Try again'),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    final signed = profile.mouAcceptance != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Company profile')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(aggregatorProfileProvider);
          ref.invalidate(aggregatorStatsProvider);
          await ref.read(aggregatorProfileProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileSummary(profile: profile),
                  const SizedBox(height: 16),
                  // Unsigned, this is the most important thing on the page - nothing can
                  // be reserved until it is done - so it leads. Signed, it is a receipt,
                  // and goes to the bottom.
                  if (!signed) ...[_MouCard(profile: profile), const SizedBox(height: 16)],
                  _CompanyForm(profile: profile),
                  const SizedBox(height: 16),
                  const _SecurityDepositCard(),
                  const SizedBox(height: 16),
                  _BankForm(profile: profile),
                  const SizedBox(height: 16),
                  _IdentityCard(profile: profile),
                  if (signed) ...[const SizedBox(height: 16), _MouCard(profile: profile)],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- The business at a glance ---------------------------------------------------------

class _ProfileSummary extends ConsumerWidget {
  const _ProfileSummary({required this.profile});

  final AggregatorProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(aggregatorStatsProvider);
    final stats = statsAsync.value;

    if (stats == null) {
      return PortalCard(
        padding: const EdgeInsets.all(20),
        child: statsAsync.hasError
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.companyName, style: theme.textTheme.titleLarge),
                  TextButton(
                    onPressed: () => ref.invalidate(aggregatorStatsProvider),
                    child: const Text("Couldn't load your summary. Try again"),
                  ),
                ],
              )
            : const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
      );
    }

    final cells = <({String label, String value, IconData icon})>[
      (label: 'On display now', value: '${stats.onDisplay}', icon: LucideIcons.frame),
      (label: 'Pieces sold', value: '${stats.piecesSold}', icon: LucideIcons.circleCheckBig),
      (label: 'Buyers', value: '${stats.distinctBuyers}', icon: LucideIcons.users),
      (label: 'Display capacity', value: '${stats.onDisplay} / ${stats.displayCapacity}', icon: LucideIcons.building2),
      (label: 'Commission earned', value: formatInr(stats.commissionEarned), icon: LucideIcons.landmark),
      (label: 'Held against reservations', value: formatInr(stats.heldAgainstReservations), icon: LucideIcons.landmark),
    ];

    return PortalCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.companyName.isEmpty ? 'Your gallery' : profile.companyName,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (stats.cities.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 13, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${stats.cities.join(' · ')} · ${stats.gallerySpaces == 1 ? '1 space' : '${stats.gallerySpaces} spaces'}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusPill(
              label: stats.mouSignedAt != null ? 'MOU signed ${formatShortDate(stats.mouSignedAt!)}' : 'MOU not signed',
              color: stats.mouSignedAt != null ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant,
              icon: LucideIcons.fileSignature,
            ),
          ),
          // An obligation, not an entitlement - so it sits apart from the grid rather
          // than reading as another figure they have earned.
          if (stats.owedToGalleryZone > 0) ...[
            const SizedBox(height: 14),
            PortalNotice(
              icon: LucideIcons.landmark,
              gold: true,
              body: '${formatInr(stats.owedToGalleryZone)} collected in cash is owed to GalleryZone. Transfer the full '
                  'amount — your commission is settled separately.',
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            runSpacing: 14,
            children: [
              for (final cell in cells)
                FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(cell.icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(child: Text(cell.label, style: theme.textTheme.labelSmall)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            cell.value,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (stats.returned > 0) ...[
            const Divider(height: 28),
            Text(
              '${stats.returned} ${stats.returned == 1 ? 'piece has' : 'pieces have'} gone back to GalleryZone unsold.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

// --- The partner agreement ------------------------------------------------------------

class _MouCard extends StatelessWidget {
  const _MouCard({required this.profile});

  final AggregatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acceptance = profile.mouAcceptance;

    if (acceptance == null) {
      return PortalNotice(
        icon: LucideIcons.fileSignature,
        gold: true,
        title: 'Sign your Aggregator MOU',
        body: "It covers custody, pricing and settlement — GalleryZone can't place a piece with you until it's signed.",
        action: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: FilledButton(
            onPressed: () => context.push('/aggregator/dashboard/mou'),
            child: const Text('Read and sign'),
          ),
        ),
      );
    }

    return PortalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Aggregator MOU', style: theme.textTheme.titleMedium)),
              const StatusPill(label: 'Signed', color: Color(0xFF34D399), icon: LucideIcons.circleCheckBig),
            ],
          ),
          const SizedBox(height: 6),
          PortalDetailRow(label: 'Signed by', value: acceptance.signatureName),
          PortalDetailRow(label: 'Signed on', value: formatShortDate(acceptance.acceptedAt)),
          PortalDetailRow(label: 'Version', value: acceptance.version),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/aggregator/dashboard/mou'),
              child: const Text('Read the signed copy'),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Company profile and coordinator ---------------------------------------------------

class _CompanyForm extends ConsumerStatefulWidget {
  const _CompanyForm({required this.profile});

  final AggregatorProfile profile;

  @override
  ConsumerState<_CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends ConsumerState<_CompanyForm> {
  final _formKey = GlobalKey<FormState>();
  late final _company = TextEditingController(text: widget.profile.companyName);
  late final _contact = TextEditingController(text: widget.profile.contactPerson);
  late final _gst = TextEditingController(text: widget.profile.gstNumber);
  late final _phone = PhoneController(widget.profile.phone);
  late final _address = TextEditingController(text: widget.profile.addressLine1);
  late final _city = TextEditingController(text: widget.profile.addressCity);
  late final _state = TextEditingController(text: widget.profile.addressState);
  late final _pin = TextEditingController(text: widget.profile.addressPincode);
  late String _designationOption = _designationPresets.contains(widget.profile.coordinatorDesignation)
      ? widget.profile.coordinatorDesignation
      : _otherDesignation;
  late final _designationText = TextEditingController(
    text: _designationPresets.contains(widget.profile.coordinatorDesignation) ? '' : widget.profile.coordinatorDesignation,
  );
  late final _coordinatorPhone = PhoneController(widget.profile.coordinatorPhone);
  late final _coordinatorEmail = TextEditingController(text: widget.profile.coordinatorEmail);

  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    for (final controller in [_company, _contact, _gst, _address, _city, _state, _pin, _designationText, _coordinatorEmail]) {
      controller.dispose();
    }
    _phone.dispose();
    _coordinatorPhone.dispose();
    super.dispose();
  }

  String get _designation => _designationOption == _otherDesignation ? _designationText.text.trim() : _designationOption;

  String? _atLeast(String? value, int length, String message) => (value ?? '').trim().length < length ? message : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final remote = ref.read(remoteBackendProvider);
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      var next = widget.profile.copyWith(
        companyName: _company.text.trim(),
        contactPerson: _contact.text.trim(),
        gstNumber: _gst.text.trim().toUpperCase(),
        phone: _phone.value,
        addressLine1: _address.text.trim(),
        addressCity: _city.text.trim(),
        addressState: _state.text.trim(),
        addressPincode: _pin.text.trim(),
        coordinatorDesignation: _designation,
      );
      // Against the API the coordinator's phone and email are the company phone and
      // the account email; only the offline demo keeps its own.
      if (!remote) {
        next = next.copyWith(coordinatorPhone: _coordinatorPhone.value, coordinatorEmail: _coordinatorEmail.text.trim());
      }
      await ref.read(aggregatorRepositoryProvider).updateProfile(next);
      // The agreement's blanks, the reserve gate and the summary all read this profile.
      container
        ..invalidate(aggregatorProfileProvider)
        ..invalidate(aggregatorMouStateProvider)
        ..invalidate(aggregatorStatsProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;
    final remote = ref.watch(remoteBackendProvider);
    final gold = theme.colorScheme.tertiary;

    return PortalCard(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () {
          if (_saved) setState(() => _saved = false);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Company profile', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: gold.withValues(alpha: 0.12),
                  child: Text(
                    portalInitials(profile.contactPerson),
                    style: theme.textTheme.titleSmall?.copyWith(color: gold, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.companyName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      Text('Shown to GalleryZone admin and support.', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Company name'),
              validator: (value) => _atLeast(value, 2, 'Enter your company name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contact,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Contact person'),
              validator: (value) => _atLeast(value, 2, 'Enter a contact person'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'GST number ',
                      style: theme.textTheme.labelLarge,
                      children: [TextSpan(text: '(required to reserve)', style: theme.textTheme.labelMedium)],
                    ),
                  ),
                ),
                GstStatusBadge(status: profile.gstStatus),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _gst,
              maxLength: 15,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: const [UpperCaseFormatter()],
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(helperText: 'GalleryZone reviews it before you can reserve artwork.'),
              // Blank still saves, so the rest can be filled in first, but nothing can be
              // reserved until an approved GST number is on file.
              validator: (value) {
                final text = (value ?? '').trim();
                return text.isEmpty || gstinPattern.hasMatch(text) ? null : 'Enter a valid 15-character GSTIN, or leave it blank';
              },
            ),
            const SizedBox(height: 4),
            PhoneField(
              controller: _phone,
              label: 'Phone',
              validator: (value) => isValidPhoneNumber(value) ? null : 'Enter a valid phone number',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Business address', hintText: 'Building, street, area'),
              validator: (value) => _atLeast(value, 5, 'Enter your business address'),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (value) => _atLeast(value, 2, 'Enter the city'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _state,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'State'),
                    validator: (value) => _atLeast(value, 2, 'Enter the state'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pin,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'PIN code'),
              // The MOU's Address blank and GalleryZone's shipments both need the full address.
              validator: (value) =>
                  RegExp(r'^[1-9][0-9]{5}$').hasMatch((value ?? '').trim()) ? null : 'Enter the 6-digit PIN code',
            ),
            const SizedBox(height: 16),
            _CoordinatorBox(
              profile: profile,
              remote: remote,
              companyPhone: _phone,
              designationOption: _designationOption,
              designationText: _designationText,
              coordinatorPhone: _coordinatorPhone,
              coordinatorEmail: _coordinatorEmail,
              onDesignation: (value) => setState(() => _designationOption = value),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_saving) ...[
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 8),
                      ],
                      Text(_saving ? 'Saving…' : 'Save profile'),
                    ],
                  ),
                ),
                if (_saved) ...[
                  const SizedBox(width: 12),
                  Icon(LucideIcons.check, size: 14, color: gold),
                  const SizedBox(width: 4),
                  Text('Saved', style: theme.textTheme.bodySmall?.copyWith(color: gold)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// MOU §10: one nominated GalleryZone coordinator per premises. The company's
/// contact person is who GalleryZone deals with commercially; this is the named
/// person on the floor who receives audit notices, expiry reminders and inbound
/// shipments.
class _CoordinatorBox extends StatelessWidget {
  const _CoordinatorBox({
    required this.profile,
    required this.remote,
    required this.companyPhone,
    required this.designationOption,
    required this.designationText,
    required this.coordinatorPhone,
    required this.coordinatorEmail,
    required this.onDesignation,
  });

  final AggregatorProfile profile;
  final bool remote;
  final PhoneController companyPhone;
  final String designationOption;
  final TextEditingController designationText;
  final PhoneController coordinatorPhone;
  final TextEditingController coordinatorEmail;
  final ValueChanged<String> onDesignation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(LucideIcons.userRoundCog, size: 16, color: gold)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nominated GalleryZone coordinator', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      'Required by your MOU (§10). This person receives audit notices, display-expiry reminders and '
                      'inbound shipment alerts on your behalf.',
                      style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.bellRing, size: 13, color: gold),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "We'll send a reminder every month to keep this contact current.",
                            style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Name',
              helperText: 'Taken from the contact person above — change it there.',
              helperMaxLines: 2,
            ),
            child: Text(profile.contactPerson, style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: designationOption,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Designation'),
            items: [
              for (final preset in _designationPresets) DropdownMenuItem(value: preset, child: Text(preset)),
              const DropdownMenuItem(value: _otherDesignation, child: Text('Other')),
            ],
            onChanged: (value) {
              if (value != null) onDesignation(value);
            },
            // The preset itself is the designation; only "Other" has a text box to check.
            validator: (_) => null,
          ),
          if (designationOption == _otherDesignation) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: designationText,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Their designation', hintText: 'e.g. Gallery Manager'),
              validator: (value) => (value ?? '').trim().length < 2 ? 'Enter their role, e.g. Gallery Manager' : null,
            ),
          ],
          const SizedBox(height: 12),
          if (remote) ...[
            // The API keeps one phone and one email for the account, so these are those.
            ListenableBuilder(
              listenable: companyPhone,
              builder: (context, _) => InputDecorator(
                decoration: const InputDecoration(labelText: 'Direct phone', helperText: 'Uses your company phone above.'),
                child: Text(companyPhone.number.text.trim().isEmpty ? '—' : companyPhone.value, style: theme.textTheme.bodyLarge),
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Email', helperText: 'Uses your account email.'),
              child: Text(profile.coordinatorEmail.isEmpty ? '—' : profile.coordinatorEmail, style: theme.textTheme.bodyLarge),
            ),
          ] else ...[
            PhoneField(
              controller: coordinatorPhone,
              label: 'Direct phone',
              validator: (value) => isValidPhoneNumber(value) ? null : 'Enter a valid phone number',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: coordinatorEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((value ?? '').trim())
                  ? null
                  : 'Enter a valid email address',
            ),
          ],
        ],
      ),
    );
  }
}

// --- Security deposit ------------------------------------------------------------------

class _SecurityDepositCard extends StatelessWidget {
  const _SecurityDepositCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Security deposit', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
              const StatusPill(label: 'Active', color: Color(0xFF34D399), icon: LucideIcons.shieldCheck),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Held per your onboarding MOU and refunded after a final audit if you exit the program. This is managed by '
            'GalleryZone admin — contact support with questions.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

// --- Bank account ----------------------------------------------------------------------

class _BankForm extends ConsumerStatefulWidget {
  const _BankForm({required this.profile});

  final AggregatorProfile profile;

  @override
  ConsumerState<_BankForm> createState() => _BankFormState();
}

class _BankFormState extends ConsumerState<_BankForm> {
  final _formKey = GlobalKey<FormState>();
  final _account = TextEditingController();
  late final _ifsc = TextEditingController(text: widget.profile.ifsc);
  bool _saving = false;

  @override
  void dispose() {
    _account.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      // Only the last four digits are ever kept: the number is write-only.
      await ref.read(aggregatorRepositoryProvider).updateBankDetails(
            accountNumber: _account.text.trim(),
            ifsc: _ifsc.text.trim(),
          );
      container.invalidate(aggregatorProfileProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Bank details updated')));
      if (mounted) _account.clear();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masked = widget.profile.bankAccountMasked;
    return PortalCard(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bank account', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.building2, size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.lock, size: 12, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              masked.isEmpty ? 'Not on file' : masked,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      Text(masked.isEmpty ? 'Add the account GalleryZone should pay' : 'Currently on file', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _account,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'New account number',
                hintText: 'Enter to update',
                helperText: 'Only the last 4 digits are ever kept.',
              ),
              validator: (value) => (value ?? '').trim().length < 4 ? 'Enter your account number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ifsc,
              maxLength: 11,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: const [UpperCaseFormatter()],
              decoration: const InputDecoration(labelText: 'IFSC code'),
              validator: (value) =>
                  RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch((value ?? '').trim()) ? null : 'Enter a valid IFSC code',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _saving ? null : _save,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_saving) ...[
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 8),
                    ],
                    Text(_saving ? 'Updating…' : 'Update bank details'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Identity ---------------------------------------------------------------------------

/// What is on file, read-only. The API takes no Aadhaar number from an aggregator -
/// GalleryZone adds it - so, as on the artist's profile, this says so rather than
/// offering a form that sends nothing.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final AggregatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = profile.aadhaarStatus;
    final masked = profile.aadhaarMasked ?? '';
    return PortalCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Identity verification', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
              StatusPill(
                label: status == ReviewStatus.approved ? 'Verified' : reviewStatusLabel[status]!,
                color: reviewStatusColor(context, status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.fingerprint, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.lock, size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            masked.isEmpty ? 'Not on file' : masked,
                            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                    if (masked.isNotEmpty) Text('Aadhaar currently on file', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Encrypted at rest and used only for identity verification. Contact support to update your Aadhaar details.',
            style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () => context.push('/aggregator/dashboard/support'),
              child: const Text('Contact support'),
            ),
          ),
        ],
      ),
    );
  }
}
