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

const _maxImages = 8;
const _insuranceRecommendedThreshold = 20000;

/// Port of `features/dashboard/artwork-submit-form.tsx`, with the camera
/// wired up — the reason this screen was built second in the phase. Images
/// come from the device (camera or gallery) via `image_picker`; there is no
/// upload backend yet, so the picked file path is what's stored and rendered.
class ArtworkUploadScreen extends ConsumerStatefulWidget {
  const ArtworkUploadScreen({super.key});

  static const path = '/dashboard/artworks/upload';

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
  String _medium = 'Oil on Canvas';
  ListingType _listingType = ListingType.marketplaceAndAggregator;
  bool _insuranceOpted = false;
  bool _isSubmitting = false;
  final _images = <String>[];

  double get _artistPrice => double.tryParse(_price.text.trim()) ?? 0;

  @override
  void dispose() {
    for (final controller in [_title, _description, _dimensions, _year, _price, _nfcTag]) {
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
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one photo of the piece')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(artistRepositoryProvider).submitArtwork(
            SubmitArtworkInput(
              title: _title.text,
              description: _description.text.trim(),
              category: _category,
              medium: _medium,
              artistPrice: _artistPrice,
              listingType: _listingType,
              insuranceOpted: _insuranceOpted,
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
            ),
          );
      ref.invalidate(artistArtworksProvider);
      ref.invalidate(artistKpisProvider);
      ref.invalidate(artistActivityProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(asDraft ? 'Saved as draft' : 'Submitted for review'),
        ),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerPrice = _artistPrice * 1.3;

    return Scaffold(
      appBar: AppBar(title: const Text('Submit artwork')),
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
                  Text('Photos', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Up to $_maxImages. The first one becomes the listing thumbnail.',
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
                          label: 'Buyer pays (incl. 30% platform markup)',
                          value: formatInr(customerPrice),
                          gold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Listing', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  RadioGroup<ListingType>(
                    groupValue: _listingType,
                    onChanged: (value) => setState(() => _listingType = value!),
                    child: const Column(
                      children: [
                        RadioListTile<ListingType>(
                          contentPadding: EdgeInsets.zero,
                          value: ListingType.marketplaceOnly,
                          title: Text('Marketplace only'),
                          subtitle: Text("Sell directly through GalleryZone's online marketplace."),
                        ),
                        RadioListTile<ListingType>(
                          contentPadding: EdgeInsets.zero,
                          value: ListingType.marketplaceAndAggregator,
                          title: Text('Marketplace + Galleries'),
                          subtitle: Text(
                            'Also let verified galleries reserve and display this piece '
                            'physically.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _insuranceOpted,
                    onChanged: (value) => setState(() => _insuranceOpted = value),
                    title: const Text('Transit insurance'),
                    subtitle: Text(
                      _artistPrice > _insuranceRecommendedThreshold
                          ? 'Recommended above ₹20,000 — uninsured pieces carry no '
                              'platform liability in transit.'
                          : 'Optional at this price.',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nfcTag,
                    decoration: const InputDecoration(
                      labelText: 'NFC tag id (optional)',
                      helperText: 'For a physical tag already attached to the piece.',
                    ),
                  ),
                  const SizedBox(height: 24),
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
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final entry in items.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: onChanged,
    );
  }
}
