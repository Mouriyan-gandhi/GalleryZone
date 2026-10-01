import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/passport.dart';
import '../../coa/coa_pdf.dart';
import '../../coa/download_coa_button.dart';
import '../../ownership/providers/ownership_providers.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/artist_avatar.dart';
import '../widgets/artwork_card.dart';
import '../widgets/artwork_qr.dart';

/// Port of `app/verify/[artworkId]` - the public page a physical tag or a
/// printed QR code resolves to, for someone who may never have signed in.
/// A passport card, who owns and holds the piece and where, then the unbroken
/// record of every hand-over, and the QR that points back here.
class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key, required this.artworkId});

  static const path = '/verify/:artworkId';

  final String artworkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artwork = ref.watch(artworkProvider(artworkId));
    final passport = ref.watch(passportProvider(artworkId));

    return Scaffold(
      appBar: AppBar(title: const Text('Artwork Passport')),
      body: _body(context, ref, artwork, passport),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Artwork?> artwork,
    AsyncValue<Passport?> passport,
  ) {
    if (artwork.isLoading || passport.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading passport…'),
          ],
        ),
      );
    }
    if (artwork.hasError || passport.hasError) {
      return EmptyState(
        icon: LucideIcons.triangleAlert,
        title: "The passport didn't load",
        description: 'Check your connection and try again.',
        action: OutlinedButton(
          onPressed: () {
            ref.invalidate(artworkProvider(artworkId));
            ref.invalidate(passportProvider(artworkId));
          },
          child: const Text('Try again'),
        ),
      );
    }
    final piece = artwork.value;
    if (piece == null) {
      return const EmptyState(
        icon: LucideIcons.searchX,
        title: 'No passport for this tag',
        description:
            'This tag does not resolve to a registered artwork. If it came off a physical piece, contact '
            'GalleryZone support.',
      );
    }
    return PassportBody(artwork: piece, passport: passport.value);
  }
}

/// The passport itself, given the piece and (when the API has one) its public
/// record. Public so the artist's board can show the same preview.
class PassportBody extends ConsumerWidget {
  const PassportBody({super.key, required this.artwork, required this.passport});

  final Artwork artwork;
  final Passport? passport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sorted = [...artwork.images]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final coverUrl = sorted.isEmpty ? artwork.thumbnailUrl : sorted.first.url;
    final custody = resolveCustody(artwork);
    // The passport names the owner; the piece's own custody is the fallback
    // for a piece the record doesn't hold yet.
    final ownerName = passport?.ownerName ?? custody.legalOwnerName ?? custodyPartyLabel[custody.legalOwner]!;
    final coaNumber = passport?.coaCertificateNumber ?? '';
    final coaIssued = passport?.coaIssuedAt ?? '';
    final artist = ref.watch(artistProfileProvider(artwork.artistId)).value;

    final entries = [
      ...?passport?.events.where((e) => e.status != TransferStatus.cancelled),
    ]..sort((a, b) => DateTime.parse(a.initiatedAt).compareTo(DateTime.parse(b.initiatedAt)));

    return ContentWidth(
      maxWidth: 620,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          if (artwork.nfcTagId != null) const _NfcVerifiedBanner(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/marketplace/${artwork.id}'),
              icon: const Icon(LucideIcons.arrowLeft, size: 14),
              label: const Text('Back to listing'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: theme.textTheme.bodySmall?.color),
            ),
          ),
          const SizedBox(height: 12),
          _PassportCard(
            artwork: artwork,
            coverUrl: coverUrl,
            coaNumber: coaNumber,
            nfcLinked: artwork.nfcTagId != null,
          ),
          const SizedBox(height: 20),
          // IntrinsicHeight: a list gives its children unbounded height, and a
          // row that stretches its cells to equal height needs a bound to stretch to.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _FactCard(icon: LucideIcons.user, label: 'Owner', value: ownerName)),
                const SizedBox(width: 10),
                Expanded(
                  child: _FactCard(
                    icon: LucideIcons.warehouse,
                    label: 'Held by',
                    value: custodyPartyLabel[custody.custodian]!,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _FactCard(icon: LucideIcons.mapPin, label: 'Location', value: custody.locationLabel)),
              ],
            ),
          ),
          if (coaIssued.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clock, size: 14, color: theme.textTheme.bodySmall?.color),
                  const SizedBox(width: 8),
                  Text('COA issued ${formatLongDate(coaIssued)}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 36),
            _ProvenanceTimeline(entries: entries),
          ],
          const SizedBox(height: 36),
          Center(child: ArtworkQr(artworkId: artwork.id, size: 128, showUrl: true)),
          const SizedBox(height: 16),
          Center(
            child: DownloadCoaButton(
              certificate: CoaPdfInput(
                artworkId: artwork.id,
                productCode: passport?.productCode,
                title: artwork.title,
                artistName: artwork.artistName,
                category: humanize(artwork.category),
                medium: humanize(artwork.medium),
                dimensions: dimensionsLabel(artwork.dimensions),
                yearCreated: artwork.yearCreated,
                coaCertificateNumber: coaNumber,
                coaIssueDate: coaIssued,
                ownerName: ownerName,
              ),
            ),
          ),
          if (artwork.artistId.isNotEmpty) ...[
            const SizedBox(height: 40),
            Divider(color: theme.colorScheme.outline),
            const SizedBox(height: 20),
            Row(
              children: [
                ArtistAvatar(name: artist?.name ?? artwork.artistName, imageUrl: artist?.profileImageUrl ?? '', size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist?.name ?? artwork.artistName,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text('Verified GalleryZone artist', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => context.push('/artists/${artwork.artistId}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.tertiary,
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Text('View portfolio'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(LucideIcons.shieldCheck, size: 14, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Authenticated by GalleryZone · One tag. One artwork. One unbroken record.',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown only when the piece has a linked tag: immediate confirmation that the
/// tap resolved to a live passport.
class _NfcVerifiedBanner extends StatelessWidget {
  const _NfcVerifiedBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.nfc, size: 16, color: theme.colorScheme.tertiary),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Verified via NFC scan',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.circleCheck, size: 16, color: theme.colorScheme.tertiary),
          ],
        ),
      ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({
    required this.artwork,
    required this.coverUrl,
    required this.coaNumber,
    required this.nfcLinked,
  });

  final Artwork artwork;
  final String coverUrl;
  final String coaNumber;
  final bool nfcLinked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: -8),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.xl4),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.shieldCheck, size: 13, color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Text(
                  'ARTWORK PASSPORT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(width: 176, height: 176, child: ArtworkImageView(url: coverUrl)),
          ),
          const SizedBox(height: 20),
          Text(
            artwork.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodySmall,
              children: [
                const TextSpan(text: 'by '),
                TextSpan(
                  text: artwork.artistName,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.badgeCheck, size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CERTIFICATE OF AUTHENTICITY',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 0.8),
                      ),
                      Text(
                        coaNumber.isEmpty ? 'Pending issuance' : coaNumber,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // That a physical tag is linked is public; which chip it is stays
          // between the artist and GalleryZone - a cloned tag is only as good
          // as the identifier it can copy.
          if (nfcLinked) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.nfc, size: 14, color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Text('NFC tag linked', style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color?.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 14, color: theme.colorScheme.tertiary),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, height: 1.25),
          ),
        ],
      ),
    );
  }
}

/// Every hand-over of ownership and every loan of display rights, oldest
/// first, from the public record - never from the artwork's own status log.
/// A hand-over that was cancelled never happened, so it is not shown.
class _ProvenanceTimeline extends StatelessWidget {
  const _ProvenanceTimeline({required this.entries});

  final List<PassportEvent> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROVENANCE',
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < entries.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == entries.length - 1 ? theme.colorScheme.primary.withValues(alpha: 0.15) : theme.cardTheme.color,
                        border: Border.all(
                          color: i == entries.length - 1
                              ? theme.colorScheme.primary.withValues(alpha: 0.6)
                              : theme.colorScheme.outline,
                        ),
                      ),
                      child: Icon(
                        i == entries.length - 1 ? LucideIcons.sparkles : LucideIcons.circleCheck,
                        size: 14,
                        color: i == entries.length - 1 ? theme.colorScheme.tertiary : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    if (i != entries.length - 1) Expanded(child: Container(width: 1, color: theme.colorScheme.outline)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(entries[i].fromName, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
                            Icon(LucideIcons.arrowRight, size: 12, color: theme.colorScheme.tertiary),
                            Text(entries[i].toName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                            if (entries[i].kind == TransferKind.display)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'Display',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.tertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatShortDate(entries[i].acceptedAt ?? entries[i].initiatedAt),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
