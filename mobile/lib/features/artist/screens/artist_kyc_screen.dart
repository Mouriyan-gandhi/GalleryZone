import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/launch.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/mock/seed/artist_seed.dart' show currentArtistId;
import '../../../data/models/artist_portal.dart';
import '../../../data/models/artwork.dart'
    show ReviewStatus, SocialProofPlatform, reviewStatusLabel;
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart' show EmptyState;
import '../../marketplace/widgets/social_glyphs.dart';
import '../kyc_rules.dart';
import '../providers/artist_network_providers.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';

/// Port of `features/dashboard/profile-kyc-form.tsx`: the artist's public
/// profile, the private identity and tax details, where work is collected from,
/// and where settlements are paid.
///
/// Named `Kyc`, not `Profile`, to stay distinct from the *public* artist
/// profile a collector browses. The website lays this out in two columns; on a
/// phone it is one, in the same order, and each card saves on its own because
/// each is a different promise: the public profile is what buyers see, the
/// pickup address is what only a courier sees, the payout account is where the
/// money goes.
class ArtistKycScreen extends ConsumerWidget {
  const ArtistKycScreen({super.key});

  static const path = '/dashboard/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(artistProfileDetailsProvider);
    // `.value` rather than `when`: after a save the provider reloads, and the
    // forms below must not be thrown away (and their typing with them) for the
    // moment that takes.
    final loaded = profile.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & KYC')),
      body: loaded != null
          ? _KycBody(profile: loaded)
          : profile.hasError
          ? EmptyState(
              icon: LucideIcons.triangleAlert,
              title: "Couldn't load your profile",
              description: authErrorMessage(profile.error!),
              action: OutlinedButton(
                onPressed: profile.isLoading
                    ? null
                    : () => ref.invalidate(artistProfileDetailsProvider),
                child: Text(profile.isLoading ? 'Trying again…' : 'Try again'),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _KycBody extends ConsumerWidget {
  const _KycBody({required this.profile});

  final ArtistProfileDetails profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Signing reorders this page (an unsigned artist gets the agreement first)
    // and is what gates listing work for aggregator display.
    final mouSigned = ref.watch(mouAcceptanceProvider).value;
    final panMissing = (profile.pan ?? '').trim().isEmpty;
    final location = [
      profile.pickupCity,
      profile.pickupState,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        ContentWidth(
          maxWidth: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ref.watch(mouAcceptanceProvider).hasValue &&
                  mouSigned == null) ...[
                const _MouCard(signed: false),
                const SizedBox(height: 16),
              ],
              _ProfileSummary(profile: profile, location: location),
              const SizedBox(height: 12),
              PortalCard(
                gold: true,
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => context.push('/dashboard/verification'),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'View verification status',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: theme.colorScheme.tertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (panMissing) ...[
                const SizedBox(height: 12),
                const PortalNotice(
                  icon: LucideIcons.triangleAlert,
                  gold: true,
                  title: 'Add your PAN.',
                  body: 'Required before any artwork can go live — GST is optional.',
                ),
              ],
              if (profile.gstStatus == ReviewStatus.submitted) ...[
                const SizedBox(height: 12),
                const PortalNotice(
                  icon: LucideIcons.receipt,
                  body:
                      "Your GST registration is with GalleryZone for review — this doesn't block listing, and "
                      "we'll update the status here once it's reviewed.",
                ),
              ],
              const SizedBox(height: 16),
              _PublicProfileForm(profile: profile),
              const SizedBox(height: 16),
              _AadhaarCard(profile: profile),
              const SizedBox(height: 16),
              const _IdentityDocumentsCard(),
              const SizedBox(height: 16),
              const _CommissionsCard(),
              const SizedBox(height: 16),
              _PickupForm(profile: profile),
              const SizedBox(height: 16),
              _PayoutForm(profile: profile),
              if (mouSigned != null) ...[
                const SizedBox(height: 16),
                _MouCard(signed: true, acceptance: mouSigned),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// --- The agreement ----------------------------------------------------------------------------

/// The artist agreement is a long document with a signature pad, so it keeps its
/// own screen; here it is the card that leads the page until it is signed (the
/// one thing an artist has to do here), then settles at the foot as a record.
class _MouCard extends StatelessWidget {
  const _MouCard({required this.signed, this.acceptance});

  final bool signed;
  final MouAcceptance? acceptance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      gold: !signed,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.scrollText,
                size: 17,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  signed ? 'Artist agreement' : 'Sign the artist agreement',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (signed)
                StatusPill(
                  label: 'Signed',
                  color: reviewStatusColor(context, ReviewStatus.approved),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            signed
                ? 'Signed ${formatLongDate(acceptance!.acceptedAt)} · version ${acceptance!.version}. It covers '
                      'listing, sale, settlement and provenance.'
                : 'It covers listing, sale, settlement and provenance, and it is what lets your work be shown by '
                      'an aggregator. Read it, draw your signature and sign.',
            style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
          signed
              ? OutlinedButton(
                  onPressed: () => context.push('/dashboard/mou'),
                  child: const Text('View the agreement'),
                )
              : FilledButton(
                  onPressed: () => context.push('/dashboard/mou'),
                  child: const Text('Read and sign'),
                ),
        ],
      ),
    );
  }
}

// --- Both halves of the profile ---------------------------------------------------------------------

/// The artist's own profile at a glance: what collectors can see of them, and
/// what only they can - the one place the two legitimately appear together, and
/// labelled so that an artist can tell which is which.
class _ProfileSummary extends ConsumerWidget {
  const _ProfileSummary({required this.profile, required this.location});

  final ArtistProfileDetails profile;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artistId = ref.watch(accountProvider).value?.uid ?? currentArtistId;
    final artworks = ref.watch(artistArtworksProvider).value ?? const [];
    final wallet = ref.watch(artistWalletProvider).value;
    final transactions =
        ref.watch(artistWalletTransactionsProvider).value ?? const [];
    final rating = ref.watch(artistRatingProvider(artistId)).value;

    final shown = artistPublicStatsFor(artworks);
    final mine = wallet == null
        ? null
        : artistPrivateStatsFor(
            transactions: transactions,
            wallet: wallet,
            artworks: artworks,
          );

    return PortalCard(
      padding: EdgeInsets.zero,
      // The tile paints on a Material of its own: the card's decoration would
      // otherwise hide its ink, and Flutter says so loudly.
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text('Your profile', style: theme.textTheme.titleMedium),
            subtitle: Text(
              [
                if (location.isNotEmpty) location,
                'Since ${joinedLabelFor(profile.joinedAt)}',
              ].join(' · '),
              style: theme.textTheme.labelSmall,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('WHAT COLLECTORS SEE', style: _heading(theme)),
              ),
              const SizedBox(height: 10),
              _Cells(
                cells: [
                  _Cell(LucideIcons.frame, 'Listed', '${shown.listed}'),
                  _Cell(LucideIcons.circleCheckBig, 'Sold', '${shown.sold}'),
                  _Cell(
                    LucideIcons.store,
                    'At galleries',
                    '${shown.atGalleries}',
                  ),
                  _Cell(
                    LucideIcons.star,
                    'Rating',
                    rating == null || rating.count == 0
                        ? '—'
                        : rating.average.toStringAsFixed(1),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.push('/artists/$artistId'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('View your public profile'),
                ),
              ),
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('ONLY YOU SEE THIS', style: _heading(theme)),
              ),
              const SizedBox(height: 10),
              _Cells(
                cells: [
                  // The website's own labels here read "Withdrawable" for what is
                  // really the lifetime total and "On the way" for the pending
                  // withdrawals; these say what the figures are.
                  _Cell(
                    LucideIcons.landmark,
                    'Earned to date',
                    mine == null ? '—' : formatInr(mine.earned),
                  ),
                  _Cell(
                    LucideIcons.clock,
                    'Withdrawal pending',
                    mine == null ? '—' : formatInr(mine.pending),
                  ),
                  _Cell(
                    LucideIcons.landmark,
                    'Average per sale',
                    mine == null || mine.averageSale == 0
                        ? '—'
                        : formatInr(mine.averageSale),
                  ),
                  _Cell(
                    LucideIcons.fileText,
                    'Drafts',
                    mine == null ? '—' : '${mine.drafts}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Your prices and earnings are never shown on your public page.',
                style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static TextStyle? _heading(ThemeData theme) => theme.textTheme.labelSmall
      ?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w600);
}

class _Cell {
  const _Cell(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

/// Four figures, two to a row, so a long label never pushes its neighbour's
/// number out of line.
class _Cells extends StatelessWidget {
  const _Cells({required this.cells});

  final List<_Cell> cells;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(_Cell c) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(c.icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  c.label,
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(c.value, style: theme.textTheme.titleMedium),
          ),
        ],
      ),
    );

    return Column(
      children: [
        for (var i = 0; i < cells.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell(cells[i]),
              const SizedBox(width: 12),
              if (i + 1 < cells.length)
                cell(cells[i + 1])
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }
}

// --- Shared bits of the forms ---------------------------------------------------------------------------

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(icon, size: 16, color: theme.colorScheme.tertiary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// A save button with the "Saved" tick that follows it.
class _SaveRow extends StatelessWidget {
  const _SaveRow({
    required this.label,
    required this.busy,
    required this.saved,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final bool busy;
  final bool saved;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Text(busy ? 'Saving…' : label);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        outlined
            ? OutlinedButton(onPressed: busy ? null : onPressed, child: child)
            : FilledButton(onPressed: busy ? null : onPressed, child: child),
        if (saved)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.check, size: 14, color: theme.colorScheme.tertiary),
              const SizedBox(width: 4),
              Text(
                'Saved',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary),
              ),
            ],
          ),
      ],
    );
  }
}

/// Saves a change to the profile on top of the freshest copy there is, so a
/// card saved after another one never writes the first one's old values back.
Future<void> _saveProfile(
  WidgetRef ref,
  ArtistProfileDetails fallback,
  ArtistProfileDetails Function(ArtistProfileDetails latest) change,
) async {
  final latest = ref.read(artistProfileDetailsProvider).value ?? fallback;
  await ref.read(artistRepositoryProvider).updateProfile(change(latest));
  ref.invalidate(artistProfileDetailsProvider);
}

// --- Public profile ---------------------------------------------------------------------------------------

class _PublicProfileForm extends ConsumerStatefulWidget {
  const _PublicProfileForm({required this.profile});

  final ArtistProfileDetails profile;

  @override
  ConsumerState<_PublicProfileForm> createState() => _PublicProfileFormState();
}

class _PublicProfileFormState extends ConsumerState<_PublicProfileForm> {
  late final _fullName = TextEditingController(text: widget.profile.fullName);
  late final _phone = TextEditingController(text: widget.profile.phone);
  late final _bio = TextEditingController(text: widget.profile.bio);
  late final _instagram = TextEditingController(text: widget.profile.instagram);
  late final _website = TextEditingController(text: widget.profile.website);
  late final _video = TextEditingController(
    text: widget.profile.socialProofVideoUrl ?? '',
  );
  late final _pan = TextEditingController(text: widget.profile.pan ?? '');
  late final _gstin = TextEditingController(text: widget.profile.gstin ?? '');
  late final _email = TextEditingController(text: widget.profile.email);

  bool _saving = false;
  bool _saved = false;

  /// Set by the first attempt to save, after which every mistake is spelled out.
  bool _tried = false;

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _phone,
      _bio,
      _instagram,
      _website,
      _video,
      _pan,
      _gstin,
      _email,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  // GST is optional for artists (preferred, not required): leaving it blank is
  // valid. When something IS entered its shape is still checked - there is no
  // GST portal *integration* (the business doesn't want one); artists apply on
  // the official portal themselves and paste the number in here.
  bool get _gstinInvalid {
    final gstin = _gstin.text.trim();
    return gstin.isNotEmpty && !gstinPattern.hasMatch(gstin);
  }

  // PAN, unlike GST, is compulsory - it is what gates listing.
  bool get _panEmpty => _pan.text.trim().isEmpty;
  bool get _panInvalid => _panEmpty || !panPattern.hasMatch(_pan.text.trim());
  bool get _instagramInvalid => _instagram.text.trim().isEmpty;
  bool get _nameInvalid => _fullName.text.trim().length < 2;

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_nameInvalid || _instagramInvalid || _panInvalid || _gstinInvalid) {
      return;
    }
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      await _saveProfile(
        ref,
        widget.profile,
        (latest) => latest.copyWith(
          fullName: _fullName.text.trim(),
          phone: _phone.text.trim(),
          bio: _bio.text.trim(),
          instagram: _instagram.text.trim(),
          website: _website.text.trim(),
          socialProofVideoUrl: _video.text.trim().isEmpty
              ? null
              : _video.text.trim(),
          pan: _pan.text.trim().toUpperCase(),
          gstin: _gstin.text.trim().isEmpty
              ? null
              : _gstin.text.trim().toUpperCase(),
        ),
      );
      if (!mounted) return;
      setState(() => _saved = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _edited() => setState(() => _saved = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panShowsError = _panInvalid && (_tried || !_panEmpty);
    return _FormCard(
      icon: LucideIcons.user,
      title: 'Public profile',
      children: [
        TextField(
          controller: _fullName,
          onChanged: (_) => _edited(),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Full name',
            errorText: _tried && _nameInvalid ? 'Enter your name' : null,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          // The address you sign in with: the API has no way to change it, so
          // it is shown, not offered as a field that would quietly do nothing.
          controller: _email,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Email',
            helperText: 'Your sign-in address. Contact support to change it.',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phone,
          onChanged: (_) => _edited(),
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _bio,
          onChanged: (_) => _edited(),
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Tell collectors about your practice.',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _instagram,
          onChanged: (_) => setState(() => _saved = false),
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Instagram handle (required, private)',
            hintText: 'yourhandle',
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: SocialGlyph(
                platform: SocialProofPlatform.instagram,
                size: 16,
              ),
            ),
            helperText:
                'Used by GalleryZone for verification and analytics only — never shown on your public '
                'profile.',
            helperMaxLines: 3,
            errorText: _tried && _instagramInvalid
                ? 'Add your Instagram handle'
                : null,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _website,
          onChanged: (_) => _edited(),
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Website (optional)',
            hintText: 'yoursite.com',
            prefixIcon: Icon(LucideIcons.globe, size: 16),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _video,
          onChanged: (_) => _edited(),
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Behind-the-scenes video, YouTube / TikTok (optional)',
            hintText: 'https://youtube.com/watch?v=...',
            prefixIcon: Icon(LucideIcons.video, size: 16),
            helperText: 'A studio or process video collectors can watch as proof of your practice.',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _pan,
          onChanged: (_) => _edited(),
          maxLength: 10,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            _UpperCaseFormatter(),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          ],
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: InputDecoration(
            labelText: 'PAN (admin-only · required)',
            hintText: 'ABCDE1234F',
            prefixIcon: const Icon(LucideIcons.creditCard, size: 16),
            counterText: '',
            helperText: 'Seen only by GalleryZone admins — never shown on your public profile.',
            helperMaxLines: 2,
            errorText: panShowsError
                ? (_panEmpty
                      ? 'PAN is required before you can list artwork.'
                      : "That doesn't look like a valid PAN.")
                : null,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 6,
          children: [
            Text('GSTIN (optional · preferred)', style: theme.textTheme.labelLarge),
            GstStatusBadge(status: widget.profile.gstStatus),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _gstin,
          onChanged: (_) => _edited(),
          maxLength: 15,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            _UpperCaseFormatter(),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          ],
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: '22AAAAA0000A1Z5',
            prefixIcon: const Icon(LucideIcons.receipt, size: 16),
            counterText: '',
            helperText:
                'Not required to list or sell, but worth adding: a GSTIN lets you claim input tax credit on '
                'your art costs and gives you better access to sales channels. If your yearly income is above '
                '${formatInr(gstSuggestedIncomeThreshold)}, we recommend it. Used only for invoicing and '
                'settlement, never shown on your public profile or to buyers.',
            helperMaxLines: 8,
            errorText: _gstinInvalid
                ? "That doesn't look like a valid GSTIN. Leave it blank if you don't have one."
                : null,
            errorMaxLines: 3,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => openExternal(context, 'https://www.gst.gov.in/'),
            icon: const Icon(LucideIcons.externalLink, size: 14),
            label: const Text(
              "Don't have a GSTIN? Apply on the government GST portal",
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const ComingSoonTile(
          icon: LucideIcons.circlePlay,
          title: 'GST application guide',
          text: 'A short walkthrough of registering for GST goes here. Coming soon.',
        ),
        const SizedBox(height: 18),
        _SaveRow(
          label: 'Save profile',
          busy: _saving,
          saved: _saved,
          onPressed: _save,
        ),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

// --- Identity ----------------------------------------------------------------------------------------------------

class _AadhaarCard extends StatelessWidget {
  const _AadhaarCard({required this.profile});

  final ArtistProfileDetails profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = profile.aadhaarStatus;
    return PortalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Aadhaar verification',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              StatusPill(
                label: status == ReviewStatus.approved
                    ? 'Verified'
                    : reviewStatusLabel[status]!,
                color: reviewStatusColor(context, status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.lock,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.aadhaarMasked.isEmpty
                      ? 'Not on file'
                      : profile.aadhaarMasked,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Encrypted at rest and used only for identity verification. Contact support to update your Aadhaar '
            'details.',
            style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _IdentityDocumentsCard extends StatelessWidget {
  const _IdentityDocumentsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Identity documents', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Submit an additional ID or address proof if support has requested one for your account. (optional)',
            style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 10),
          // The website's uploader only ever says "Submitted for review"; there is
          // no route that receives a document. So the app doesn't pretend to take
          // one - support does, by email.
          Text(
            'Documents are not uploaded in the app yet. Email them to support and mention your account.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 10),
          ContactLinkRow(
            icon: LucideIcons.mail,
            label: galleryZoneEmail,
            url: 'mailto:$galleryZoneEmail',
          ),
        ],
      ),
    );
  }
}

class _CommissionsCard extends StatelessWidget {
  const _CommissionsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              LucideIcons.palette,
              size: 16,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Commissions', style: theme.textTheme.titleMedium),
                    StatusPill(
                      label: 'Coming soon',
                      color: theme.colorScheme.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Let collectors commission a custom piece directly from you, start to finish, through '
                  'GalleryZone.',
                  style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Pickup address ------------------------------------------------------------------------------------------------

/// Its own card and its own save, because it is the opposite of the profile
/// above: that is what buyers see, this is what only a courier ever sees.
/// Without a pincode here no delivery can be priced - the carrier quotes on the
/// distance between two of them.
class _PickupForm extends ConsumerStatefulWidget {
  const _PickupForm({required this.profile});

  final ArtistProfileDetails profile;

  @override
  ConsumerState<_PickupForm> createState() => _PickupFormState();
}

class _PickupFormState extends ConsumerState<_PickupForm> {
  late final _line1 = TextEditingController(text: widget.profile.pickupLine1);
  late final _line2 = TextEditingController(text: widget.profile.pickupLine2);
  late final _city = TextEditingController(text: widget.profile.pickupCity);
  late final _state = TextEditingController(text: widget.profile.pickupState);
  late final _pincode = TextEditingController(
    text: widget.profile.pickupPincode,
  );

  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    for (final controller in [_line1, _line2, _city, _state, _pincode]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _pincodeInvalid =>
      _pincode.text.trim().isNotEmpty &&
      !pincodePattern.hasMatch(_pincode.text.trim());
  bool get _complete =>
      _line1.text.trim().isNotEmpty &&
      _city.text.trim().isNotEmpty &&
      _state.text.trim().isNotEmpty &&
      pincodePattern.hasMatch(_pincode.text.trim());

  Future<void> _save() async {
    if (_pincodeInvalid) return;
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      await _saveProfile(
        ref,
        widget.profile,
        (latest) => latest.copyWith(
          pickupLine1: _line1.text.trim(),
          pickupLine2: _line2.text.trim(),
          pickupCity: _city.text.trim(),
          pickupState: _state.text.trim(),
          pickupPincode: _pincode.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() => _saved = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _edited() => setState(() => _saved = false);

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      icon: LucideIcons.truck,
      title: 'Pickup address',
      subtitle:
          'Where your work is collected from. Private — buyers never see it.',
      children: [
        if (!_complete) ...[
          const PortalNotice(
            icon: LucideIcons.info,
            gold: true,
            body:
                "Add this before your first sale. Delivery is priced on the distance between your address and the "
                "buyer's, so without it we can't quote a shipping cost for your work.",
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _line1,
          onChanged: (_) => _edited(),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Address',
            hintText: 'House / studio number and street',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _line2,
          onChanged: (_) => _edited(),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Area, landmark (optional)',
            hintText: 'Locality or a nearby landmark',
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _city,
                onChanged: (_) => _edited(),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'Udaipur',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _state,
                onChanged: (_) => _edited(),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'State',
                  hintText: 'Rajasthan',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _pincode,
          onChanged: (_) => _edited(),
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: InputDecoration(
            labelText: 'PIN code',
            hintText: '313001',
            counterText: '',
            errorText: _pincodeInvalid ? 'A PIN code is six digits.' : null,
          ),
        ),
        const SizedBox(height: 18),
        _SaveRow(
          label: 'Save pickup address',
          busy: _saving,
          saved: _saved,
          outlined: true,
          onPressed: _pincodeInvalid ? null : _save,
        ),
      ],
    );
  }
}

// --- Payout account ------------------------------------------------------------------------------------------------------

/// Where settlements are paid. The number is write-only: the API keeps it where
/// no read route reaches and returns only the last four digits.
class _PayoutForm extends ConsumerStatefulWidget {
  const _PayoutForm({required this.profile});

  final ArtistProfileDetails profile;

  @override
  ConsumerState<_PayoutForm> createState() => _PayoutFormState();
}

class _PayoutFormState extends ConsumerState<_PayoutForm> {
  final _number = TextEditingController();
  final _confirm = TextEditingController();
  late final _ifsc = TextEditingController(text: widget.profile.ifsc);

  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _number.dispose();
    _confirm.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  // Account numbers are typed twice and can never be pasted into the second
  // field, so a slip in one shows up as a mismatch instead of a payout to a
  // stranger.
  bool get _numberInvalid => bankAccountNumberInvalid(_number.text);
  bool get _mismatch =>
      _confirm.text.isNotEmpty && _confirm.text != _number.text;
  bool get _unconfirmed => _number.text.isNotEmpty && _confirm.text.isEmpty;
  bool get _ifscInvalid =>
      _ifsc.text.isNotEmpty && !ifscPattern.hasMatch(_ifsc.text.toUpperCase());
  bool get _canSave =>
      !_numberInvalid &&
      !_mismatch &&
      !_unconfirmed &&
      !_ifscInvalid &&
      (_number.text.isNotEmpty || _ifsc.text.isNotEmpty);

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      await ref
          .read(artistRepositoryProvider)
          .updateBankDetails(
            accountNumber: _number.text,
            ifsc: _ifsc.text.toUpperCase(),
          );
      ref.invalidate(artistProfileDetailsProvider);
      if (!mounted) return;
      // The number is never kept on screen once it has been sent.
      _number.clear();
      _confirm.clear();
      setState(() => _saved = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _edited() => setState(() => _saved = false);

  @override
  Widget build(BuildContext context) {
    final latest =
        ref.watch(artistProfileDetailsProvider).value ?? widget.profile;
    final onFile = latest.bankAccountMasked.isEmpty
        ? 'Nothing on file yet — withdrawals need this.'
        : 'On file: ${latest.bankAccountMasked}${latest.ifsc.isEmpty ? '' : ' · ${latest.ifsc}'}.';
    return _FormCard(
      icon: LucideIcons.landmark,
      title: 'Payout account',
      subtitle: 'Where your settlements are paid. $onFile',
      children: [
        TextField(
          controller: _number,
          onChanged: (_) => _edited(),
          keyboardType: TextInputType.number,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Account number',
            hintText: latest.bankAccountMasked.isEmpty
                ? '9–18 digits'
                : 'Enter a new number to replace it',
            errorText: _numberInvalid
                ? 'Enter the real 9–18 digit account number printed on your passbook or cheque.'
                : null,
            errorMaxLines: 3,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirm,
          onChanged: (_) => _edited(),
          keyboardType: TextInputType.number,
          autocorrect: false,
          enableSuggestions: false,
          // Pasting is refused on purpose: the second entry has to be typed.
          enableInteractiveSelection: false,
          contextMenuBuilder: (context, editableTextState) =>
              const SizedBox.shrink(),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _NoPasteFormatter(),
          ],
          decoration: InputDecoration(
            labelText: 'Re-enter account number',
            hintText: 'Type it again — pasting is disabled',
            errorText: _mismatch
                ? 'The two account numbers don’t match.'
                : null,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _ifsc,
          onChanged: (_) => _edited(),
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          maxLength: 11,
          inputFormatters: [
            _UpperCaseFormatter(),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          ],
          decoration: InputDecoration(
            labelText: 'IFSC',
            hintText: 'HDFC0001234',
            counterText: '',
            errorText: _ifscInvalid ? 'IFSC looks like HDFC0001234.' : null,
          ),
        ),
        const SizedBox(height: 18),
        _SaveRow(
          label: 'Save payout account',
          busy: _saving,
          saved: _saved,
          outlined: true,
          onPressed: _canSave ? _save : null,
        ),
      ],
    );
  }
}

/// Refuses anything that arrives more than one character at a time - a paste -
/// so the second entry of an account number is a re-typing, not a copy.
class _NoPasteFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.text.length - oldValue.text.length > 1 ? oldValue : newValue;
}
