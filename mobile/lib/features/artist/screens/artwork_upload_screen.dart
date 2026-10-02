import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/launch.dart';
import '../../../core/pricing.dart' as pricing;
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../../data/repositories/artist_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../legal/screens/legal_document_screen.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../artwork_form_data.dart';
import '../painting_styles.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';
import '../widgets/painting_style_picker.dart';

enum _SubmitMode { draft, review }

/// A photo on the form: one already on the piece (it carries the API's id), or
/// a file just picked from the device.
class _FormImage {
  _FormImage.existing(ArtworkImage image)
      : url = image.url,
        thumbnailUrl = image.thumbnailUrl,
        id = image.id,
        isNew = false;

  _FormImage.picked(String path)
      : url = path,
        thumbnailUrl = path,
        id = null,
        isNew = true;

  final String url;
  final String thumbnailUrl;
  final String? id;

  /// A device file that has not been uploaded yet.
  final bool isNew;
}

/// What the finished form says, in place of the form.
class _Outcome {
  const _Outcome({required this.title, required this.body, this.artworkId});

  final String title;
  final String body;

  /// Set when the piece is live, so the artist can go and look at it.
  final String? artworkId;
}

/// Port of `features/dashboard/artwork-submit-form.tsx`, with the camera wired
/// up. Photos come from the device (camera or gallery) via `image_picker` and
/// upload when the piece is saved.
///
/// Doubles as the edit form (`artwork-edit-view.tsx`) when [artworkId] is set:
/// same fields, same rules, one screen. The API still enforces the edit
/// window, so arriving here on a locked piece fails on save rather than
/// silently writing.
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
  final _typeOther = TextEditingController();
  final _styleOther = TextEditingController();
  final _year = TextEditingController();
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _price = TextEditingController();
  final _insuranceNumber = TextEditingController();

  String _category = '';
  String _medium = '';
  String _type = '';
  String _style = '';
  String _unit = 'in';
  String _format = '';
  FramingState? _framing;
  ListingType _listingType = ListingType.marketplaceAndAggregator;
  bool _insuranceOpted = false;
  bool _hangers = false;
  bool _packaging = false;

  /// Re-confirmed on every edit rather than assumed: the physical facts they
  /// attest to may have changed since the last time.
  bool _termsAccepted = false;

  final _images = <_FormImage>[];
  bool _busy = false;
  String? _error;
  _Outcome? _outcome;

  /// Which button was pressed, read by the validators: a draft may be missing a
  /// title, a submission may not. Lenient until a submission is attempted, so
  /// an empty title isn't flagged to someone who only touched the field.
  _SubmitMode _mode = _SubmitMode.draft;

  bool get _isEdit => widget.artworkId != null;

  /// Non-null once an edit target has loaded. The form is hidden until then,
  /// so the controllers are seeded exactly once.
  ArtistArtwork? _editing;
  String? _loadError;

  /// Aggregator display puts the piece in someone else's custody, so
  /// insurance stops being a choice the moment that channel is picked. The
  /// repository enforces the same rule.
  bool get _aggregatorSelected => isAggregatorListed(_listingType);
  bool get _insuranceRequired => _aggregatorSelected;

  double get _artistPrice => double.tryParse(_price.text.trim()) ?? 0;

  ArtworkPhysical get _physical => ArtworkPhysical(
        weightKg: double.tryParse(_weight.text.trim()),
        framing: _framing,
        format: _format.isEmpty ? null : _format,
        hangingHardwareIncluded: _hangers,
        packagingConfirmed: _packaging,
      );

  List<String> get _missingForAggregator =>
      _aggregatorSelected ? missingForAggregatorListing(_physical, termsAccepted: _termsAccepted) : const [];

  Dimensions get _dimensions => (
        length: tidyMeasurement(_length.text) ?? '',
        width: tidyMeasurement(_width.text) ?? '',
        height: tidyMeasurement(_height.text) ?? '',
        unit: _unit,
      );

  @override
  void initState() {
    super.initState();
    // The preview and the ladder follow what is typed.
    for (final controller in [_title, _year, _weight, _price, _length, _width, _height]) {
      controller.addListener(_refresh);
    }
    if (_isEdit) _loadForEdit();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadForEdit() async {
    try {
      final entry = await ref.read(artistRepositoryProvider).getArtwork(widget.artworkId!);
      if (!mounted) return;
      if (entry == null) {
        setState(() => _loadError = 'Artwork not found');
        return;
      }
      final artwork = entry.artwork;
      final dimensions = parseDimensions(artwork.dimensions);
      final type = artworkTypeFields(artwork.artworkType);
      final style = paintingStyleFields(artwork.paintingStyle);
      _title.text = artwork.title;
      _description.text = artwork.description;
      _typeOther.text = type.other;
      _styleOther.text = style.other;
      _year.text = artwork.yearCreated?.toString() ?? '';
      _length.text = dimensions.length;
      _width.text = dimensions.width;
      _height.text = dimensions.height;
      _price.text = entry.artistPrice <= 0 ? '' : entry.artistPrice.round().toString();
      _weight.text = _weightText(artwork.physical?.weightKg);
      _insuranceNumber.text = artwork.insuranceNumber ?? '';
      setState(() {
        _editing = entry;
        _category = normalizeOption(artwork.category, artworkCategories);
        _medium = normalizeOption(artwork.medium, artworkMediums);
        _type = type.type;
        _style = style.style;
        _unit = dimensions.unit;
        _format = normalizeOption(artwork.physical?.format ?? '', artworkFormats);
        _framing = artwork.physical?.framing;
        _listingType = artwork.listingType;
        _insuranceOpted = artwork.insured;
        _hangers = artwork.physical?.hangingHardwareIncluded ?? false;
        _packaging = artwork.physical?.packagingConfirmed ?? false;
        _images
          ..clear()
          ..addAll(artwork.images.map(_FormImage.existing));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = authErrorMessage(error));
    }
  }

  static String _weightText(double? kg) {
    if (kg == null || kg <= 0) return '';
    return kg == kg.roundToDouble() ? kg.round().toString() : kg.toString();
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _typeOther,
      _styleOther,
      _year,
      _length,
      _width,
      _height,
      _weight,
      _price,
      _insuranceNumber,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Photos --------------------------------------------------------------------

  Future<void> _addPhotos(ImageSource source) async {
    final room = maxArtworkImages - _images.length;
    if (room <= 0) return;
    try {
      final picker = ref.read(imagePickerProvider);
      // The gallery can hand over several at once; the camera and a last free
      // slot take one.
      final picked = source == ImageSource.gallery && room >= 2
          ? await picker.pickMultiImage(maxWidth: 2000, limit: room)
          : [
              ?await picker.pickImage(source: source, maxWidth: 2000),
            ];
      if (picked.isEmpty || !mounted) return;

      final accepted = <_FormImage>[];
      final problems = <String>[];
      for (final file in picked) {
        // A refused file doesn't use up a place.
        if (accepted.length >= room) break;
        // The file's own name, whichever way the platform writes its paths.
        final problem = imageProblem(file.path.split(RegExp(r'[\\/]')).last, await file.length());
        if (problem == null) {
          accepted.add(_FormImage.picked(file.path));
        } else {
          problems.add(problem);
        }
      }
      if (!mounted) return;
      setState(() => _images.addAll(accepted));
      if (problems.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problems.join('\n'))));
      }
    } on Exception catch (error) {
      if (!mounted) return;
      // A denied camera/photos permission surfaces here as a PlatformException
      // - say so plainly instead of silently doing nothing.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open that source: ${authErrorMessage(error)}')),
      );
    }
  }

  // --- Painting style ----------------------------------------------------------------

  Future<void> _pickStyle() async {
    final pick = await showPaintingStylePicker(context, selected: _style);
    if (pick == null || !mounted) return;
    setState(() => _style = pick.name ?? '');
  }

  // --- Submitting --------------------------------------------------------------------

  /// Takes the screen to the first field that is wrong, so a mistake near the
  /// top of a long form isn't missed behind the buttons.
  void _revealFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Element? first;
      void visit(Element element) {
        if (first != null) return;
        if (element is StatefulElement) {
          final state = element.state;
          if (state is FormFieldState && state.hasError) {
            first = element;
            return;
          }
        }
        element.visitChildren(visit);
      }

      _formKey.currentContext?.visitChildElements(visit);
      final target = first;
      if (target != null) {
        Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 250), alignment: 0.15);
      }
    });
  }

  Future<void> _submit(_SubmitMode mode) async {
    _mode = mode;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) {
      _revealFirstError();
      return;
    }
    // A listing with nothing to look at is the one thing a review can't use.
    // Drafts, and edits, are the artist's own business.
    if (mode == _SubmitMode.review && !_isEdit && _images.isEmpty) {
      setState(() => _error = 'Add at least one photo of the piece');
      return;
    }

    final title = _title.text.trim().isEmpty ? 'Untitled artwork' : _title.text.trim();
    final composed = composeDimensions(_dimensions);
    final insuranceNumber = _insuranceNumber.text.trim();
    final input = SubmitArtworkInput(
      title: title,
      description: _description.text.trim(),
      category: _category,
      medium: _medium,
      artistPrice: _artistPrice,
      listingType: _listingType,
      insuranceOpted: _insuranceRequired || _insuranceOpted,
      images: [
        for (var i = 0; i < _images.length; i++)
          ArtworkImage(
            url: _images[i].url,
            thumbnailUrl: _images[i].thumbnailUrl,
            sortOrder: i,
            altText: '$title, photo ${i + 1}',
            id: _images[i].id,
          ),
      ],
      asDraft: mode == _SubmitMode.draft,
      // Older records carry a free-text size this form can't split; leaving the
      // boxes empty keeps it as it was.
      dimensions: composed.isNotEmpty ? composed : _editing?.artwork.dimensions,
      yearCreated: int.tryParse(_year.text.trim()) ?? DateTime.now().year,
      // This form doesn't touch the tag; an edit must send it back as it was or
      // the API reads the omission as "unlink".
      nfcTagId: _editing?.artwork.nfcTagId,
      physical: _physical,
      artworkType: artworkTypeToStore(_type, _typeOther.text),
      paintingStyle: paintingStyleToStore(_category, _style, _styleOther.text),
      insuranceNumber: insuranceNumber.isEmpty ? null : insuranceNumber,
    );

    setState(() => _busy = true);
    final repository = ref.read(artistRepositoryProvider);
    // Taken now: the artist may leave the screen while the photos upload, and
    // the lists still have to hear that the piece exists.
    final container = ProviderScope.containerOf(context);
    try {
      final saved = _isEdit
          ? await repository.updateArtwork(artworkId: widget.artworkId!, patch: input)
          : await repository.submitArtwork(input);
      _refreshLists(container);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _outcome = _outcomeFor(saved, title: title, mode: mode);
      });
    } on ArtworkSavedAsDraft catch (error) {
      _refreshLists(container);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _outcome = _Outcome(title: 'Saved as draft.', body: error.message);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrorMessage(error);
      });
    }
  }

  void _refreshLists(ProviderContainer container) {
    container.invalidate(artistArtworksProvider);
    container.invalidate(artistKpisProvider);
    container.invalidate(artistActivityProvider);
    container.invalidate(artistWalletProvider);
    container.invalidate(artistWalletTransactionsProvider);
    container.invalidate(artistPenaltiesProvider);
  }

  /// The words follow what the API says happened, not what was asked for: a
  /// submission is live only if it actually went live.
  _Outcome _outcomeFor(Artwork saved, {required String title, required _SubmitMode mode}) {
    final name = _title.text.trim().isEmpty ? 'Your artwork' : title;
    if (_isEdit) return _Outcome(title: 'Changes saved.', body: '“$name” has been updated.');
    if (mode == _SubmitMode.draft) {
      return _Outcome(
        title: 'Saved as draft.',
        body: '“$name” has been saved. You can continue editing it any time from My Artworks.',
      );
    }
    if (saved.status == ArtworkStatus.marketplace) {
      return _Outcome(
        title: 'Approved and live.',
        body: '“$name” is on the marketplace now. Collectors can see it and buy it.',
        artworkId: saved.id,
      );
    }
    return _Outcome(
      title: 'Submitted for review.',
      body: '“$name” is with the GalleryZone team. We’ll let you know once it’s approved and live.',
    );
  }

  // --- Build -----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final outcome = _outcome;
    if (outcome != null) return _Done(outcome: outcome);

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

    final theme = Theme.of(context);
    final editState = _editing == null ? null : artworkEditState(_editing!.artwork);

    // PAN, not GST, is what gates going live. A draft is never blocked, and
    // neither is an edit to a piece that is already listed.
    final profile = ref.watch(artistProfileDetailsProvider);
    final panMissing = !_isEdit && profile.hasValue && (profile.requireValue.pan ?? '').trim().isEmpty;
    final panPending = !_isEdit && profile.isLoading;

    // Two different things, and conflating them is what made the old banner
    // lie: an approved fee WILL be charged on this listing; one still under
    // review may never be charged at all.
    final penalties = _isEdit ? const <ExternalSalePenalty>[] : (ref.watch(artistPenaltiesProvider).value ?? []);
    final approvedFee = penalties.where(isPenaltyCollectable).fold<double>(0, (sum, p) => sum + p.amount);
    final reviewingFee = penalties
        .where((p) => penaltyStatusOf(p) == PenaltyStatus.pendingReview)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final waived = penalties
        .where((p) => penaltyStatusOf(p) == PenaltyStatus.waived && (p.decisionNote ?? '').isNotEmpty)
        .firstOrNull;

    // The whole ladder is quoted from the rules GalleryZone published; the
    // bundled constants only stand in until they arrive (or if they can't).
    final rules = ref.watch(pricingRulesProvider).value;
    final markup = rules?.platformMarkup ?? pricing.platformMarkup;
    final gstRate = rules?.gstRate ?? pricing.gstRate;
    final threshold = rules?.insuranceThreshold ?? insuranceRecommendedThreshold;
    final ladder = priceLadderFor(_artistPrice, markup: markup, gstRate: gstRate);

    final missing = _missingForAggregator;
    final canSubmit = !_busy &&
        missing.isEmpty &&
        !panMissing &&
        !panPending &&
        (!_isEdit || (editState?.editable ?? false));

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit artwork' : 'Submit artwork')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ContentWidth(
          maxWidth: 620,
          child: Form(
            key: _formKey,
            // Once a field has been touched it re-checks itself as it is fixed,
            // so a stale message never outlives the mistake.
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (panMissing) ...[
                  PortalNotice(
                    icon: LucideIcons.triangleAlert,
                    gold: true,
                    title: 'PAN required before this can go live',
                    body: 'Add your PAN on your Profile page — you can still save this as a draft. GST is '
                        "optional and won't block this listing.",
                    action: TextButton(
                      onPressed: () => context.push('/dashboard/profile'),
                      child: const Text('Go to Profile'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (approvedFee > 0) ...[
                  PortalNotice(
                    icon: LucideIcons.triangleAlert,
                    destructive: true,
                    title: '${formatInr(approvedFee)} off-platform sale fee is due on this listing',
                    body: 'You marked artwork as sold on another platform and GalleryZone approved the fee. It '
                        "is charged to your wallet when you submit this piece for review. Saving a draft doesn't "
                        'trigger it.',
                  ),
                  const SizedBox(height: 16),
                ],
                if (reviewingFee > 0) ...[
                  PortalNotice(
                    icon: LucideIcons.clock3,
                    gold: true,
                    title: '${formatInr(reviewingFee)} off-platform sale fee is with GalleryZone for review',
                    body: "Selling elsewhere doesn't always mean a fee — a piece promised to a gallery before you "
                        'listed it, say. Nothing is charged unless GalleryZone approves it, and this listing goes '
                        'through either way.',
                  ),
                  const SizedBox(height: 16),
                ],
                if (waived != null) ...[
                  Text(
                    'An earlier off-platform sale fee was waived: ${waived.decisionNote}',
                    style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 16),
                ],
                if (editState != null) ...[
                  PortalNotice(
                    icon: editState.editable ? LucideIcons.clock3 : LucideIcons.lock,
                    gold: editState.editable,
                    destructive: !editState.editable,
                    body: switch (editState.reason) {
                      ArtworkEditReason.draft =>
                        'This piece is still a draft — edit it freely until you send it for review.',
                      ArtworkEditReason.withinWindow =>
                        '${editState.daysLeft} ${editState.daysLeft == 1 ? "day" : "days"} left of the '
                            '$artworkEditWindowDays-day edit window.',
                      ArtworkEditReason.purchased =>
                        'This artwork has been claimed or sold — changes can no longer be saved.',
                      ArtworkEditReason.windowClosed =>
                        'The $artworkEditWindowDays-day edit window for this artwork has closed.',
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                _photosSection(theme),
                const SizedBox(height: 16),
                _detailsSection(theme),
                const SizedBox(height: 16),
                _channelSection(theme, ladder: ladder, gstRate: gstRate),
                const SizedBox(height: 16),
                _insuranceSection(theme, threshold: threshold),
                const SizedBox(height: 16),
                _Preview(
                  image: _images.firstOrNull,
                  title: _title.text.trim(),
                  medium: _medium.isEmpty
                      ? 'Medium'
                      : artworkMediums.where((m) => m.value == _medium).firstOrNull?.label ?? humanize(_medium),
                  year: _year.text.trim(),
                  artistPrice: _artistPrice,
                  customerPrice: ladder.customer,
                  markup: markup,
                  gstRate: gstRate,
                  insured: _insuranceRequired || _insuranceOpted,
                ),
                const SizedBox(height: 16),
                const _CertificateNote(),
                const SizedBox(height: 20),
                if (missing.isNotEmpty) ...[
                  Text.rich(
                    TextSpan(
                      text: 'Still needed for an aggregator listing: ',
                      children: [
                        TextSpan(
                          text: missing.join(', '),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        const TextSpan(text: '. You can still save this as a draft.'),
                      ],
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_error != null) ...[
                  Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.destructive)),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: canSubmit ? () => _submit(_SubmitMode.review) : null,
                  child: Text(_busy ? 'Saving…' : (_isEdit ? 'Save changes' : 'Submit for review')),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : (_isEdit ? () => context.pop() : () => _submit(_SubmitMode.draft)),
                  child: Text(_isEdit ? 'Cancel' : 'Save as draft'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Sections ------------------------------------------------------------------------

  Widget _photosSection(ThemeData theme) {
    final full = _images.length >= maxArtworkImages;
    return _Section(
      title: 'Artwork images',
      children: [
        Text(
          'Up to $maxArtworkImages photos, cover image first. JPEG, PNG or WebP, 15 MB each. Photos upload when '
          'you save.',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 12),
        _ImageGrid(
          images: _images,
          onRemove: (index) => setState(() => _images.removeAt(index)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: full ? null : () => _addPhotos(ImageSource.camera),
                icon: const Icon(LucideIcons.camera, size: 16),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: full ? null : () => _addPhotos(ImageSource.gallery),
                icon: const Icon(LucideIcons.imagePlus, size: 16),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('${_images.length} / $maxArtworkImages uploaded', style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _detailsSection(ThemeData theme) {
    return _Section(
      title: 'Artwork details',
      children: [
        TextFormField(
          controller: _title,
          maxLength: 160,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Monsoon Over Madurai',
            counterText: '',
          ),
          validator: (value) {
            final title = (value ?? '').trim();
            if (title.isEmpty) return _mode == _SubmitMode.review ? 'A title is required' : null;
            return title.length < 3 ? 'Use at least 3 characters' : null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _description,
          minLines: 3,
          maxLines: 6,
          maxLength: 5000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Oil on canvas, painted during the 2025 monsoon season.',
            counterText: '',
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(LucideIcons.info, size: 12),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Don't mention price here. Your listed price stays private and only the marketplace price is "
                'shown to buyers.',
                style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _OptionField(
          label: 'Category',
          value: _category,
          options: artworkCategories,
          requiredMessage: 'Select a category',
          onChanged: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: 14),
        _OptionField(
          label: 'Medium',
          value: _medium,
          options: artworkMediums,
          requiredMessage: 'Select a medium',
          onChanged: (value) => setState(() => _medium = value),
        ),
        const SizedBox(height: 14),
        _OptionField(
          label: 'Type of artwork',
          value: _type,
          options: artworkTypes,
          onChanged: (value) => setState(() => _type = value),
        ),
        if (_type == 'other') ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _typeOther,
            maxLength: 80,
            decoration: const InputDecoration(hintText: 'Describe the type', counterText: ''),
          ),
        ],
        if (_category == 'painting') ...[
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickStyle,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Painting style',
                suffixIcon: const Icon(LucideIcons.chevronsUpDown, size: 16),
                helperText: 'One of ${paintingStyles.length} world painting traditions — search by name, region, '
                    'or category.',
                helperMaxLines: 2,
              ),
              isEmpty: _style.isEmpty,
              child: Text(_style, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          if (_style == 'Other') ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _styleOther,
              maxLength: 80,
              decoration: const InputDecoration(hintText: 'Name the painting style', counterText: ''),
            ),
          ],
        ],
        const SizedBox(height: 14),
        TextFormField(
          controller: _year,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
          decoration: InputDecoration(labelText: 'Year created', hintText: '${DateTime.now().year}'),
          autovalidateMode: AutovalidateMode.disabled,
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return null;
            final year = int.tryParse(text);
            return year == null || year < 1900 || year > 2100 ? 'Enter a year between 1900 and 2100' : null;
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(LucideIcons.ruler, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('Dimensions', style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _MeasureField(controller: _length, label: 'Length', validator: _dimensionPair)),
            const SizedBox(width: 12),
            Expanded(child: _MeasureField(controller: _width, label: 'Width', validator: _dimensionPair)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _MeasureField(controller: _height, label: 'Height', validator: _dimensionPair)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _unit,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: [for (final unit in dimensionUnits) DropdownMenuItem(value: unit, child: Text(unit))],
                onChanged: (value) => setState(() => _unit = value ?? 'in'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text("Length and width, and height if it's a 3D piece.", style: theme.textTheme.labelSmall),
        const SizedBox(height: 18),
        TextFormField(
          controller: _weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          decoration: const InputDecoration(labelText: 'Weight (kg)', hintText: '3.5'),
          autovalidateMode: AutovalidateMode.disabled,
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return null;
            final kg = double.tryParse(text);
            return kg == null || kg <= 0 || kg > 500 ? 'Enter the weight in kg (up to 500)' : null;
          },
        ),
        const SizedBox(height: 14),
        _FramingField(
          value: _framing,
          // MOU §12: only these two ship to an aggregator's premises - don't offer
          // an option the artist would just have to undo.
          aggregatorOnly: _aggregatorSelected,
          onChanged: (value) => setState(() => _framing = value),
        ),
        const SizedBox(height: 14),
        _OptionField(
          label: 'Format / surface',
          value: _format,
          options: artworkFormats,
          onChanged: (value) => setState(() => _format = value),
        ),
      ],
    );
  }

  /// Length and width go together; a lone height is no size at all.
  String? _dimensionPair(String? _) {
    final any = [_length, _width, _height].any((c) => c.text.trim().isNotEmpty);
    if (!any) return null;
    final length = tidyMeasurement(_length.text) != null;
    final width = tidyMeasurement(_width.text) != null;
    if (!length || !width) return 'Add the length and width';
    if (_height.text.trim().isNotEmpty && tidyMeasurement(_height.text) == null) return 'Enter a number above 0';
    return null;
  }

  Widget _channelSection(ThemeData theme, {required PriceLadder ladder, required double gstRate}) {
    return _Section(
      title: 'Sales channel & pricing',
      children: [
        Text('Sales channel', style: theme.textTheme.labelLarge),
        const SizedBox(height: 2),
        Text(
          'Marketplace and Aggregator are separate channels. Pick one, or both.',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 10),
        for (final choice in listingChoices) ...[
          _ChoiceCard(
            label: choice.label,
            description: choice.description,
            active: _listingType == choice.type,
            onTap: () => setState(() => _listingType = choice.type),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        TextFormField(
          controller: _price,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
          decoration: const InputDecoration(labelText: 'Your rate (₹)', hintText: '18000'),
          validator: (value) {
            final price = int.tryParse((value ?? '').trim());
            if (price == null || price <= 0) return 'Enter your price for this artwork';
            return price > 10000000 ? 'The most a piece can be listed at is ₹1,00,00,000' : null;
          },
        ),
        const SizedBox(height: 6),
        Text(
          "Your own price for this piece. It stays private — buyers never see it. You're paid within "
          '${pricing.artistPayoutDaysAfterDelivery} days of the artwork being delivered.',
          style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
        ),
        if (_artistPrice > 0) ...[
          const SizedBox(height: 12),
          // The whole ladder, not just the top of it: the artist sees every
          // component of the listed price, so the number buyers see is never a
          // mystery.
          PortalCard(
            gold: true,
            child: Column(
              children: [
                PortalDetailRow(label: 'You receive', value: formatInr(_artistPrice)),
                PortalDetailRow(label: 'GalleryZone margin', value: formatInr(ladder.base - _artistPrice)),
                PortalDetailRow(label: 'GST (${percentLabel(gstRate)}%)', value: formatInr(ladder.gstIncluded)),
                const Divider(height: 16),
                PortalDetailRow(label: 'Listed price buyers see', value: formatInr(ladder.customer), gold: true),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Listing is free for your first 6 months.', style: theme.textTheme.labelSmall),
        ],
        if (_aggregatorSelected) ...[
          const SizedBox(height: 16),
          _aggregatorRequirements(theme),
        ],
      ],
    );
  }

  Widget _aggregatorRequirements(ThemeData theme) {
    final physical = _physical;
    final framingOk = _framing != null && aggregatorReadyFraming.contains(_framing);
    return PortalCard(
      gold: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.building2, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(child: Text('Aggregator requirements', style: theme.textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'An aggregator holds and displays the physical piece, so it has to arrive ready to hang. These are '
            'required before this artwork can go for review.',
            style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 10),
          _Requirement(met: (physical.weightKg ?? 0) > 0, text: 'Weight entered — the piece has to be moved and hung'),
          _Requirement(met: framingOk, text: 'Framed, or professionally stretched on canvas (MOU §12)'),
          _Requirement(met: _format.isNotEmpty, text: 'Format / surface stated'),
          const SizedBox(height: 10),
          _CheckTile(
            value: _hangers,
            onChanged: (value) => setState(() => _hangers = value),
            title: 'Hangers are included with the artwork.',
            detail: 'Required for display — an aggregator cannot hang a piece that arrives without them.',
          ),
          const SizedBox(height: 8),
          _CheckTile(
            value: _packaging,
            onChanged: (value) => setState(() => _packaging = value),
            title: "Packed to GalleryZone's shipping standard.",
            detail: 'Improperly packed artworks can be rejected on arrival.',
          ),
          const SizedBox(height: 8),
          _CheckTile(
            value: _termsAccepted,
            onChanged: (value) => setState(() => _termsAccepted = value),
            gold: true,
            title: 'I accept the aggregator display terms for this artwork.',
            detail: 'Initial display period is 30 days per aggregator; if unsold GalleryZone may relocate the '
                'piece to another aggregator or channel. Transport to the assigned aggregator is deducted from '
                'your settlement after a sale.',
            action: TextButton(
              onPressed: () => context.push(LegalDocumentScreen.routeFor(LegalDoc.terms)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                alignment: Alignment.centerLeft,
              ),
              child: const Text('Read the full terms'),
            ),
          ),
          const SizedBox(height: 10),
          const ComingSoonTile(
            icon: LucideIcons.circlePlay,
            title: 'Explainer video',
            text: 'A short walkthrough of the aggregator process goes here. Coming soon.',
          ),
          const SizedBox(height: 8),
          const ComingSoonTile(icon: LucideIcons.layoutTemplate, title: 'Display card', text: 'Coming soon.'),
        ],
      ),
    );
  }

  Widget _insuranceSection(ThemeData theme, {required double threshold}) {
    final on = _insuranceRequired || _insuranceOpted;
    final status = _editing?.artwork.insuranceStatus ?? ReviewStatus.notSubmitted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortalCard(
          gold: _insuranceRequired,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text('Insure this artwork', style: theme.textTheme.titleSmall),
                        if (_insuranceRequired)
                          Text(
                            'Required',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _insuranceRequired
                          ? 'Mandatory for aggregator listings — the piece leaves your studio and is held by a '
                              'partner while on display. Cover is arranged with $insurancePartner; the premium is '
                              'deducted from your settlement.'
                          : _artistPrice > threshold
                              ? 'Strongly recommended for a piece at this price ($insurancePartner). Decline it and '
                                  'theft, fire, transit damage and loss are yours alone.'
                              : 'Optional, arranged with $insurancePartner. Uninsured artworks carry no platform '
                                  'liability in transit.',
                      style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: on,
                // Locked on, not merely defaulted on, for an aggregator listing.
                onChanged: _insuranceRequired ? null : (value) => setState(() => _insuranceOpted = value),
              ),
            ],
          ),
        ),
        if (on) ...[
          const SizedBox(height: 12),
          PortalCard(
            gold: true,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Insurance verification', style: theme.textTheme.titleSmall)),
                    if (_isEdit)
                      StatusPill(label: insuranceStatusLabel[status]!, color: reviewStatusColor(context, status)),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => openExternal(context, insurancePartnerUrl),
                  icon: const Icon(LucideIcons.externalLink, size: 14),
                  label: const Text('Take out cover with $insurancePartner'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _insuranceNumber,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Policy / certificate number',
                    hintText: 'Paste the number once your policy is issued',
                    helperText:
                        'Enter it here once you have it — GalleryZone verifies it before the piece can be marked '
                        'insured.',
                    helperMaxLines: 3,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                const _InsuranceFaq(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// --- Pieces ---------------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// A dropdown over [FormOption]s. An artwork being edited can carry a value the
/// list doesn't offer (older records predate these options); it is kept as an
/// option rather than silently rewritten, because the dropdown asserts on a
/// value it has no item for.
class _OptionField extends StatelessWidget {
  const _OptionField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.requiredMessage,
  });

  final String label;
  final String value;
  final List<FormOption> options;
  final ValueChanged<String> onChanged;
  final String? requiredMessage;

  @override
  Widget build(BuildContext context) {
    final known = options.any((option) => option.value == value);
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (value.isNotEmpty && !known) DropdownMenuItem(value: value, child: Text(humanize(value))),
        for (final option in options) DropdownMenuItem(value: option.value, child: Text(option.label)),
      ],
      validator: requiredMessage == null
          ? null
          : (selected) => selected == null || selected.isEmpty ? requiredMessage : null,
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

class _FramingField extends StatelessWidget {
  const _FramingField({required this.value, required this.aggregatorOnly, required this.onChanged});

  final FramingState? value;
  final bool aggregatorOnly;
  final ValueChanged<FramingState> onChanged;

  @override
  Widget build(BuildContext context) {
    final offered = [
      for (final state in FramingState.values)
        if (!aggregatorOnly || aggregatorReadyFraming.contains(state) || state == value) state,
    ];
    return DropdownButtonFormField<FramingState>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Framing'),
      items: [for (final state in offered) DropdownMenuItem(value: state, child: Text(framingLabel[state]!))],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

class _MeasureField extends StatelessWidget {
  const _MeasureField({required this.controller, required this.label, required this.validator});

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      decoration: InputDecoration(labelText: label),
      // Length and width are typed one after the other: only judged on submit.
      autovalidateMode: AutovalidateMode.disabled,
      validator: validator,
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.label, required this.description, required this.active, required this.onTap});

  final String label;
  final String description;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    return Semantics(
      button: true,
      selected: active,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active ? gold.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: active ? gold.withValues(alpha: 0.5) : theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: active ? theme.colorScheme.tertiary : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(description, style: theme.textTheme.labelSmall?.copyWith(height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.met, required this.text});

  final bool met;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              met ? LucideIcons.check : LucideIcons.circle,
              size: 14,
              color: met ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: met ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.detail,
    this.gold = false,
    this.action,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String detail;
  final bool gold;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: gold ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.colorScheme.outline,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (checked) => onChanged(checked ?? false),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.labelLarge?.copyWith(height: 1.4)),
                    const SizedBox(height: 2),
                    Text(detail, style: theme.textTheme.labelSmall?.copyWith(height: 1.4)),
                    ?action,
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

/// Port of `insurance-faq-chat.tsx`: not a chatbot - there is nothing to answer
/// a free question - but a fixed set of questions that read as a conversation.
class _InsuranceFaq extends StatefulWidget {
  const _InsuranceFaq();

  @override
  State<_InsuranceFaq> createState() => _InsuranceFaqState();
}

class _InsuranceFaqState extends State<_InsuranceFaq> {
  final _asked = <String>[];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = insuranceFaqs.where((faq) => !_asked.contains(faq.question)).toList();
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.messageCircleQuestionMark, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(child: Text('Insurance — common questions', style: theme.textTheme.labelLarge)),
            ],
          ),
          for (final question in _asked) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(question, style: theme.textTheme.labelMedium),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Text(
                insuranceFaqs.firstWhere((faq) => faq.question == question).answer,
                style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (remaining.isEmpty)
            Text(
              "That's everything we've got preset — for anything else, reach Support.",
              style: theme.textTheme.labelSmall,
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final faq in remaining)
                  ActionChip(
                    label: Text(faq.question),
                    labelStyle: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _asked.add(faq.question)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CertificateNote extends StatelessWidget {
  const _CertificateNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.scrollText, size: 16, color: theme.colorScheme.tertiary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certificate of Authenticity — required',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'GalleryZone issues a numbered Certificate of Authenticity for every accepted artwork. Nothing '
                  'to fill in here: the certificate number is generated on approval and stays linked to this '
                  'piece for its whole life, alongside its NFC/QR passport.',
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

/// How the listing will read, with the artist's private price beside the one
/// buyers will see.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.image,
    required this.title,
    required this.medium,
    required this.year,
    required this.artistPrice,
    required this.customerPrice,
    required this.markup,
    required this.gstRate,
    required this.insured,
  });

  final _FormImage? image;
  final String title;
  final String medium;
  final String year;
  final double artistPrice;
  final double customerPrice;
  final double markup;
  final double gstRate;
  final bool insured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = image;
    return PortalCard(
      gold: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: cover == null
                    ? Icon(
                        LucideIcons.imagePlus,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      )
                    : cover.isNew
                        ? Image.file(
                            File(cover.url),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                          )
                        : ArtworkImageView(url: cover.url),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVE PREVIEW',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title.isEmpty ? 'Untitled artwork' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                Text(year.isEmpty ? medium : '$medium · $year', style: theme.textTheme.labelSmall),
                const Divider(height: 24),
                PortalDetailRow(
                  label: 'Your price (private)',
                  value: artistPrice > 0 ? formatInr(artistPrice) : 'N/A',
                ),
                PortalDetailRow(
                  label: 'Listed price',
                  value: artistPrice > 0 ? formatInr(customerPrice) : 'N/A',
                  gold: true,
                ),
                const SizedBox(height: 4),
                Text(
                  'You receive your price in full. The listed price adds GalleryZone’s '
                  '${percentLabel(markup)}% margin and ${percentLabel(gstRate)}% GST on top — that’s what buyers '
                  'see.',
                  style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                ),
                if (insured) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 14, color: theme.colorScheme.tertiary),
                        const SizedBox(width: 8),
                        Text(
                          'Insured artwork',
                          style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.tertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Picked files are device paths, not bundled assets or URLs, so they render
/// through `Image.file`; photos already on the piece go through
/// [ArtworkImageView].
class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images, required this.onRemove});

  final List<_FormImage> images;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (images.isEmpty) {
      return Container(
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Text('No photos yet', style: theme.textTheme.bodySmall),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: image.isNew
                  ? Image.file(
                      File(image.url),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                    )
                  : ArtworkImageView(url: image.url),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: IconButton(
                iconSize: 14,
                tooltip: 'Remove photo ${index + 1}',
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85)),
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
        );
      },
    );
  }
}

/// What the form says once it has done its job, in place of the form.
class _Done extends StatelessWidget {
  const _Done({required this.outcome});

  final _Outcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Artwork')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ContentWidth(
            maxWidth: 620,
            child: PortalCard(
              gold: true,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                    ),
                    child: Icon(LucideIcons.check, size: 20, color: theme.colorScheme.tertiary),
                  ),
                  const SizedBox(height: 14),
                  Text(outcome.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(outcome.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.go('/dashboard/artworks'),
                    icon: const Icon(LucideIcons.arrowLeft, size: 16),
                    label: const Text('Back to My Artworks'),
                  ),
                  if (outcome.artworkId != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push('/marketplace/${outcome.artworkId}'),
                      child: const Text('View it on the marketplace'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
