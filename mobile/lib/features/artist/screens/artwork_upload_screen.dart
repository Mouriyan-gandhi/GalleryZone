import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../../data/repositories/artist_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';

const _categories = <String, String>{
  'painting': 'Painting',
  'sculpture': 'Sculpture',
  'photography': 'Photography',
  'printmaking': 'Printmaking',
  'mixed-media': 'Mixed Media',
  'textile': 'Textile Art',
  'ceramics': 'Ceramics',
};

const _mediums = <String, String>{
  'Oil on Canvas': 'Oil on Canvas',
  'Acrylic on Canvas': 'Acrylic on Canvas',
  'Watercolor': 'Watercolor',
  'Charcoal': 'Charcoal',
  'Ink': 'Ink',
  'Bronze': 'Bronze',
  'Ceramic & Mixed Media': 'Ceramic & Mixed Media',
  'Other': 'Other',
};

const _formats = <String, String>{
  'canvas': 'Canvas',
  'paper': 'Paper',
  'board': 'Board / panel',
  'wood': 'Wood',
  'metal': 'Metal',
  'stone': 'Stone',
  'textile': 'Textile',
  'other': 'Other',
};

const _maxImages = 8;
const _insuranceRecommendedThreshold = 20000;

/// Port of `features/dashboard/artwork-submit-form.tsx`, with the camera
/// wired up — the reason this screen was built second in the phase. Images
/// come from the device (camera or gallery) via `image_picker`; there is no
/// upload backend yet, so the picked file path is what's stored and rendered.
///
/// Doubles as the edit form (`features/dashboard/artwork-edit-view.tsx`) when
/// [artworkId] is set: same fields, same rules, one screen. The repository
/// still enforces the edit window, so arriving here on a locked piece fails
/// on save rather than silently writing.
class ArtworkUploadScreen extends ConsumerStatefulWidget {
  const ArtworkUploadScreen({super.key, this.artworkId});

  static const path = '/dashboard/artworks/upload';

  /// Null on the submit route; the piece being edited otherwise.
  final String? artworkId;

  @override
  ConsumerState<ArtworkUploadScreen> createState() => _ArtworkUploadScreenState();
}

class _ArtworkUploadScreenState extends ConsumerState<ArtworkUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _dimensions = TextEditingController();
  final _year = TextEditingController();
  final _price = TextEditingController();
  final _nfcTag = TextEditingController();

  String _category = 'painting';
  ArtworkRarity? _rarity;
  String _medium = 'Oil on Canvas';
  ListingType _listingType = ListingType.marketplaceAndAggregator;
  bool _insuranceOpted = false;
  bool _isSubmitting = false;
  final _weight = TextEditingController();
  FramingState? _framing;
  String? _format;
  bool _hangersIncluded = false;
  bool _packagingConfirmed = false;
  final _images = <String>[];

  bool get _isEdit => widget.artworkId != null;

  /// Non-null once an edit target has loaded. The form is hidden until then,
  /// so the controllers are seeded exactly once with no effect-on-data dance.
  Artwork? _editing;
  String? _loadError;

  /// Aggregator display puts the piece in someone else's custody, so
  /// insurance stops being a choice the moment that channel is picked. The
  /// repository enforces the same rule.
  bool get _insuranceRequired => isAggregatorListed(_listingType);

  double get _artistPrice => double.tryParse(_price.text.trim()) ?? 0;

  ArtworkPhysical get _physical => ArtworkPhysical(
    weightKg: double.tryParse(_weight.text.trim()),
    framing: _framing,
    format: _format,
    hangingHardwareIncluded: _hangersIncluded,
    packagingConfirmed: _packagingConfirmed,
  );

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadForEdit();
  }

  Future<void> _loadForEdit() async {
    try {
      final entries = await ref.read(artistRepositoryProvider).listArtworks();
      final entry = entries.where((e) => e.artwork.id == widget.artworkId).firstOrNull;
      if (!mounted) return;
      if (entry == null) {
        setState(() => _loadError = 'Artwork not found');
        return;
      }
      final artwork = entry.artwork;
      _title.text = artwork.title;
      _description.text = artwork.description;
      _dimensions.text = artwork.dimensions ?? '';
      _year.text = artwork.yearCreated?.toString() ?? '';
      _price.text = entry.artistPrice == 0 ? '' : entry.artistPrice.round().toString();
      _nfcTag.text = artwork.nfcTagId ?? '';
      _weight.text = artwork.physical?.weightKg?.toString() ?? '';
      setState(() {
        _editing = artwork;
        _category = artwork.category;
        _rarity = artwork.rarityType;
        _medium = artwork.medium;
        _listingType = artwork.listingType;
        _insuranceOpted = artwork.insured;
        _framing = artwork.physical?.framing;
        _format = artwork.physical?.format;
        _hangersIncluded = artwork.physical?.hangingHardwareIncluded ?? false;
        _packagingConfirmed = artwork.physical?.packagingConfirmed ?? false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = authErrorMessage(error));
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _dimensions,
      _year,
      _price,
      _nfcTag,
      _weight,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_images.length >= _maxImages) return;
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 2000);
      if (picked == null || !mounted) return;
      setState(() => _images.add(picked.path));
    } on Exception catch (error) {
      if (!mounted) return;
      // A denied camera/photos permission surfaces here as a PlatformException
      // — say so plainly instead of silently doing nothing.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open that source: ${authErrorMessage(error)}')),
      );
    }
  }

  Future<void> _submit({required bool asDraft}) async {
    if (!_formKey.currentState!.validate()) return;
    // On an edit, no new photos means "keep the ones already on the piece" —
    // the repository does exactly that with an empty image list.
    if (_images.isEmpty && !_isEdit) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add at least one photo of the piece')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final input = SubmitArtworkInput(
        title: _title.text,
        description: _description.text.trim(),
        category: _category,
        rarityType: _rarity,
        medium: _medium,
        artistPrice: _artistPrice,
        listingType: _listingType,
        insuranceOpted: _insuranceRequired || _insuranceOpted,
        images: [
          for (var i = 0; i < _images.length; i++)
            ArtworkImage(
              url: _images[i],
              thumbnailUrl: _images[i],
              sortOrder: i,
              altText: _title.text.trim(),
            ),
        ],
        asDraft: asDraft,
        dimensions: _dimensions.text.trim().isEmpty ? null : _dimensions.text.trim(),
        yearCreated: int.tryParse(_year.text.trim()),
        nfcTagId: _nfcTag.text.trim().isEmpty ? null : _nfcTag.text.trim(),
        physical: _physical,
      );
      final repository = ref.read(artistRepositoryProvider);
      if (_isEdit) {
        await repository.updateArtwork(artworkId: widget.artworkId!, patch: input);
      } else {
        await repository.submitArtwork(input);
      }
      ref.invalidate(artistArtworksProvider);
      ref.invalidate(artistKpisProvider);
      ref.invalidate(artistActivityProvider);
      ref.invalidate(artistWalletProvider);
      ref.invalidate(artistWalletTransactionsProvider);
      ref.invalidate(artistPenaltiesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Changes saved'
                : asDraft
                ? 'Saved as draft'
                : 'Submitted for review',
          ),
        ),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerPrice = _artistPrice * 1.3;

    if (_isEdit && _editing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit artwork')),
        body: _loadError == null
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: LucideIcons.triangleAlert,
                title: "Couldn't open this artwork",
                description: _loadError!,
              ),
      );
    }

    final editState = _editing == null ? null : artworkEditState(_editing!);
    // Only on a new listing: an edit isn't the "next listing" the fee waits
    // for, so showing it there would be a lie about what Save does.
    final outstandingFee = _isEdit
        ? 0.0
        : (ref.watch(artistPenaltiesProvider).value ?? [])
              .where((penalty) => penalty.settledAt == null)
              .fold<double>(0, (sum, penalty) => sum + penalty.amount);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit artwork' : 'Submit artwork')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          ContentWidth(
            maxWidth: 620,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (outstandingFee > 0) ...[
                    PortalCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.triangleAlert,
                            size: 16,
                            color: AppColors.destructive,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${formatInr(outstandingFee)} off-platform sale fee '
                                  'is due on this listing',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You marked artwork as sold on another platform. The '
                                  '1% fee is charged to your wallet when you submit this '
                                  "piece for review. Saving a draft doesn't trigger it.",
                                  style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (editState != null) ...[
                    PortalCard(
                      gold: editState.editable,
                      child: Row(
                        children: [
                          Icon(
                            editState.editable ? LucideIcons.clock3 : LucideIcons.lock,
                            size: 16,
                            color: editState.editable
                                ? theme.colorScheme.tertiary
                                : AppColors.destructive,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(switch (editState.reason) {
                              ArtworkEditReason.draft =>
                                'This piece is still a draft — edit it freely until '
                                    'you send it for review.',
                              ArtworkEditReason.withinWindow =>
                                '${editState.daysLeft} '
                                    '${editState.daysLeft == 1 ? "day" : "days"} left '
                                    'of the $artworkEditWindowDays-day edit window.',
                              ArtworkEditReason.purchased =>
                                'This artwork has been claimed or sold — changes can '
                                    'no longer be saved.',
                              ArtworkEditReason.windowClosed =>
                                'The $artworkEditWindowDays-day edit window for this '
                                    'artwork has closed.',
                            }, style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text('Photos', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    _isEdit
                        ? 'Add photos to replace the current set — leave this empty and '
                              'the existing ones stay.'
                        : 'Up to $_maxImages. The first one becomes the listing thumbnail.',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 12),
                  _ImageStrip(
                    paths: _images,
                    onRemove: (index) => setState(() => _images.removeAt(index)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pick(ImageSource.camera),
                          icon: const Icon(LucideIcons.camera, size: 16),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pick(ImageSource.gallery),
                          icon: const Icon(LucideIcons.imagePlus, size: 16),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Details', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _title,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'A title is required' : null,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 14),
                  _Dropdown(
                    label: 'Category',
                    value: _category,
                    items: _categories,
                    onChanged: (value) => setState(() => _category = value!),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ArtworkRarity>(
                    initialValue: _rarity,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Artwork type / rarity',
                      helperText:
                          'R = Rare · U = Unique · O = Original · N = Normal. '
                          'Shown as a badge on your artwork card.',
                    ),
                    items: [
                      for (final rarity in ArtworkRarity.values)
                        DropdownMenuItem(
                          value: rarity,
                          child: Text(artworkRarityLabel[rarity]!),
                        ),
                    ],
                    onChanged: (value) => setState(() => _rarity = value),
                  ),
                  const SizedBox(height: 14),
                  _Dropdown(
                    label: 'Medium',
                    value: _medium,
                    items: _mediums,
                    onChanged: (value) => setState(() => _medium = value!),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dimensions,
                          decoration: const InputDecoration(
                            labelText: 'Dimensions',
                            hintText: '60 × 90 cm',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _year,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Year'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Sales channel', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Marketplace and Aggregator are separate channels. Pick one, '
                    'or both.',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<ListingType>(
                    groupValue: _listingType,
                    onChanged: (value) => setState(() => _listingType = value!),
                    child: const Column(
                      children: [
                        RadioListTile<ListingType>(
                          contentPadding: EdgeInsets.zero,
                          value: ListingType.marketplaceOnly,
                          title: Text('Marketplace'),
                          subtitle: Text("Sell online through GalleryZone's own marketplace."),
                        ),
                        RadioListTile<ListingType>(
                          contentPadding: EdgeInsets.zero,
                          value: ListingType.aggregatorOnly,
                          title: Text('Aggregator'),
                          subtitle: Text(
                            'Send the physical piece to a verified aggregator to display '
                            'and sell in person. It stays off the online marketplace.',
                          ),
                        ),
                        RadioListTile<ListingType>(
                          contentPadding: EdgeInsets.zero,
                          value: ListingType.marketplaceAndAggregator,
                          title: Text('Both'),
                          subtitle: Text(
                            'List online and make the piece available for aggregator '
                            'display at the same time.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text('Pricing', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Enter your price for this artwork';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Your price (₹)',
                      helperText: 'Only you ever see this figure.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  PortalCard(
                    gold: true,
                    child: Column(
                      children: [
                        PortalDetailRow(
                          label: 'Listed price buyers see (incl. 30% markup)',
                          value: formatInr(customerPrice),
                          gold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nfcTag,
                    decoration: const InputDecoration(
                      labelText: 'NFC tag id (optional)',
                      helperText: 'Links the physical tag to this piece and its passport.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _insuranceRequired || _insuranceOpted,
                    // Locked on, not merely defaulted on, for an aggregator
                    // listing — the piece leaves the studio into a partner's
                    // custody, so cover isn't the artist's call there.
                    onChanged: _insuranceRequired
                        ? null
                        : (value) => setState(() => _insuranceOpted = value),
                    title: Text(
                      _insuranceRequired ? 'Transit insurance — required' : 'Transit insurance',
                    ),
                    subtitle: Text(
                      _insuranceRequired
                          ? 'Mandatory for aggregator listings: the piece leaves your '
                                'studio and is held by a partner while on display. The '
                                'premium is deducted from your settlement.'
                          : _artistPrice > _insuranceRecommendedThreshold
                          ? 'Strongly recommended for a piece at this price — '
                                'uninsured pieces carry no platform liability in transit.'
                          : 'Optional at this price.',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  if (_insuranceRequired) ...[
                    const SizedBox(height: 20),
                    Text('The physical piece', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'An aggregator has to move, hang and insure this — MOU §12. '
                      'Only asked for when you pick that channel.',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weight,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        helperText: 'Framed and packed, as it ships.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Dropdown(
                      label: 'Framing',
                      value: _framing?.name ?? '',
                      items: {
                        '': 'Select…',
                        for (final state in FramingState.values)
                          state.name: framingLabel[state]!,
                      },
                      onChanged: (value) => setState(() {
                        _framing = value == null || value.isEmpty
                            ? null
                            : FramingState.values.byName(value);
                      }),
                    ),
                    if (_framing != null && !aggregatorReadyFraming.contains(_framing))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Aggregator display needs a framed or stretched-canvas '
                          'piece. You can still list this on the marketplace.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.destructive,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _Dropdown(
                      label: 'Format',
                      value: _format ?? '',
                      items: {'': 'Select…', ..._formats},
                      onChanged: (value) => setState(
                        () => _format = value == null || value.isEmpty ? null : value,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _hangersIncluded,
                      onChanged: (value) => setState(() => _hangersIncluded = value),
                      title: const Text('Hangers ship with the piece'),
                      subtitle: Text(
                        'MOU §12 — the aggregator cannot hang it otherwise.',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _packagingConfirmed,
                      onChanged: (value) => setState(() => _packagingConfirmed = value),
                      title: const Text("Packed to GalleryZone's standard"),
                      subtitle: Text(
                        'Corner protection, rigid outer, moisture barrier.',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    if (missingForAggregator(_physical).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Still needed for an aggregator listing: '
                          '${missingForAggregator(_physical).join(", ")}. You can save '
                          'this as a draft in the meantime.',
                          style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                  PortalCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.scrollText, size: 16, color: theme.colorScheme.tertiary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Certificate of Authenticity — required',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'GalleryZone issues a numbered Certificate of '
                                'Authenticity for every accepted artwork. Nothing to '
                                'fill in here: the number is generated on approval and '
                                'stays linked to this piece for its whole life, '
                                'alongside its NFC/QR passport.',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isEdit)
                    FilledButton(
                      onPressed: _isSubmitting || !(editState?.editable ?? false)
                          ? null
                          : () => _submit(asDraft: false),
                      child: Text(_isSubmitting ? 'Saving…' : 'Save changes'),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : () => _submit(asDraft: true),
                            child: const Text('Save draft'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : () => _submit(asDraft: false),
                            child: Text(_isSubmitting ? 'Sending…' : 'Submit for review'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Picked files are device paths, not bundled assets or URLs, so they render
/// through `Image.file` rather than [ArtworkImageView].
class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.paths, required this.onRemove});

  final List<String> paths;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (paths.isEmpty) {
      return Container(
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.outline, style: BorderStyle.solid),
        ),
        child: Text('No photos yet', style: theme.textTheme.bodySmall),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.file(
                File(paths[index]),
                width: 90,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 90,
                  height: 110,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: IconButton(
                iconSize: 14,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85),
                ),
                icon: const Icon(Icons.close),
                onPressed: () => onRemove(index),
              ),
            ),
            if (index == 0)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text('Cover', style: theme.textTheme.labelSmall),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // An artwork being edited can carry a category/medium the current list
    // doesn't offer (the fixtures predate these options — "landscape",
    // "Mixed Media"). Dropdown asserts on a value it has no item for, so the
    // existing one is kept as an option rather than silently rewritten.
    final options = items.containsKey(value) ? items : {value: titleCase(value), ...items};
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final entry in options.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: onChanged,
    );
  }
}
