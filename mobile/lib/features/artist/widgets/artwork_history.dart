import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../ownership/providers/ownership_providers.dart';
import '../providers/artist_providers.dart';

/// Two histories, side by side on the website and one under the other here,
/// because a certificate answers two questions that are not the same question:
/// WHO OWNS THIS, and WHO IS ALLOWED TO SHOW IT. A piece can be owned by a
/// collector in Chennai and hanging in a gallery in Pune.
///
/// They are shaped differently, so they are drawn differently. Ownership is a
/// chain - it moves once, in one direction, and only the last link is current.
/// Display rights are episodes - each has a start and an end, and a piece coming
/// back is the normal end of one rather than an incident.
///
/// Port of `features/dashboard/artwork-history.tsx`.
class ArtworkHistoryView extends ConsumerWidget {
  const ArtworkHistoryView({super.key, required this.artwork});

  final Artwork artwork;

  /// Splitting by status is only honest because the two paths share none: a
  /// piece heading to an aggregator goes reserved -> preparing -> in transit ->
  /// with the aggregator, and a piece that has been bought goes sold ->
  /// delivered -> completed. Explicit maps rather than a list of exceptions, so
  /// a new status has to be given a side deliberately or it simply will not show.
  static const ownershipStatus = <ArtworkStatus, String>{
    ArtworkStatus.draft: 'Listing created by the artist',
    ArtworkStatus.pendingApproval: 'Submitted to GalleryZone for review',
    ArtworkStatus.marketplace: 'Approved and listed for sale',
    ArtworkStatus.sold: 'Sold',
    ArtworkStatus.settlementComplete: 'Settlement completed',
    ArtworkStatus.delivered: 'Delivered to the buyer',
    ArtworkStatus.completed: 'Sale completed',
    ArtworkStatus.soldExternally: 'Sold outside GalleryZone',
  };

  static const displayStatus = <ArtworkStatus, (String, IconData)>{
    ArtworkStatus.reserved: ('Reserved for aggregator display', LucideIcons.clock3),
    ArtworkStatus.preparingDispatch: ('Being prepared for dispatch', LucideIcons.packageCheck),
    ArtworkStatus.inTransit: ('In transit to the display space', LucideIcons.truck),
    ArtworkStatus.withAggregator: ('On display with an aggregator', LucideIcons.building2),
    ArtworkStatus.returned: ('Came back from display', LucideIcons.undo2),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfers = ref.watch(artworkTransfersProvider(artwork.id)).value ?? const <OwnershipTransfer>[];
    final requests = [
      for (final request in ref.watch(artistPhysicalCoaProvider).value ?? const <PhysicalCoaRequest>[])
        if (request.artworkId == artwork.id) request,
    ];
    final history = buildHistory(artwork, transfers, requests);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          icon: LucideIcons.userRoundCheck,
          title: 'Ownership',
          summary: 'Now with ${history.ownerName}',
          caption: 'Who owns this piece. Each hand-over is recorded when the other side accepts it.',
          events: history.ownership,
          emptyText: 'Nothing recorded yet.',
        ),
        const SizedBox(height: 12),
        _Panel(
          icon: LucideIcons.building2,
          title: 'Display rights',
          summary: history.onDisplayNow ? 'On display now' : 'Not on display',
          summaryMuted: !history.onDisplayNow,
          caption: 'Who has been allowed to show it. A loan never changes the owner.',
          events: history.display,
          emptyText: 'This piece has never been out on display.',
        ),
      ],
    );
  }

  /// The two timelines, newest first. Pure so it can be tested without a widget.
  static ArtworkHistory buildHistory(
    Artwork artwork,
    List<OwnershipTransfer> transfers,
    List<PhysicalCoaRequest> coaRequests,
  ) {
    final ownership = <HistoryEvent>[];
    final display = <HistoryEvent>[];

    for (final event in artwork.statusHistory) {
      final owned = ownershipStatus[event.status];
      if (owned != null) {
        ownership.add(HistoryEvent(at: event.changedAt, icon: LucideIcons.fileEdit, label: owned));
        continue;
      }
      final shown = displayStatus[event.status];
      if (shown != null) {
        display.add(HistoryEvent(at: event.changedAt, icon: shown.$2, label: shown.$1));
      }
    }

    // The certificate and the tag are ownership facts: they are what proves who
    // holds the piece, and they travel with it when it changes hands.
    if (artwork.coaIssueDate.isNotEmpty) {
      ownership.add(
        HistoryEvent(
          at: artwork.coaIssueDate,
          icon: LucideIcons.award,
          label: 'Certificate of Authenticity issued',
          detail: artwork.coaCertificateNumber,
        ),
      );
    }
    // The server times both steps, so these sit at the moment they happened.
    if (artwork.nfcLinkedAt != null) {
      ownership.add(
        HistoryEvent(
          at: artwork.nfcLinkedAt!,
          icon: LucideIcons.scanLine,
          label: 'NFC tag linked',
          detail: artwork.nfcTagUid,
        ),
      );
    }
    if (artwork.nfcLockedAt != null) {
      ownership.add(
        HistoryEvent(
          at: artwork.nfcLockedAt!,
          icon: LucideIcons.lock,
          label: 'NFC tag locked',
          detail: 'The chip is read-only for good',
        ),
      );
    }

    for (final transfer in transfers) {
      if (transfer.status == TransferStatus.cancelled) continue;
      if (transferKindOf(transfer) == TransferKind.display) {
        display.add(_displayEvent(transfer));
      } else {
        ownership.add(_ownershipEvent(transfer));
      }
    }

    for (final request in coaRequests) {
      ownership.add(
        HistoryEvent(
          at: request.requestedAt,
          icon: LucideIcons.printer,
          label: 'Paper certificate requested',
          detail: 'By ${request.requestedByName}',
        ),
      );
      if (request.status == PhysicalCoaStatus.dispatched && request.dispatchedAt != null) {
        ownership.add(
          HistoryEvent(
            at: request.dispatchedAt!,
            icon: LucideIcons.packageCheck,
            label: 'Signed paper certificate dispatched',
            detail: request.courierRef,
          ),
        );
      }
    }

    int newestFirst(HistoryEvent a, HistoryEvent b) =>
        (DateTime.tryParse(b.at) ?? DateTime(0)).compareTo(DateTime.tryParse(a.at) ?? DateTime(0));
    ownership.sort(newestFirst);
    display.sort(newestFirst);
    return ArtworkHistory(
      ownership: ownership,
      display: display,
      ownerName: resolveCustody(artwork).legalOwnerName ?? artwork.artistName,
    );
  }

  static HistoryEvent _ownershipEvent(OwnershipTransfer transfer) {
    if (transfer.status == TransferStatus.pending) {
      return HistoryEvent(
        at: transfer.initiatedAt,
        icon: LucideIcons.clock3,
        label: 'Transfer to ${transfer.toName}',
        detail: 'From ${transfer.fromName}',
        state: HistoryState.pending,
      );
    }
    return HistoryEvent(
      at: transfer.acceptedAt ?? transfer.initiatedAt,
      icon: LucideIcons.userRoundCheck,
      label: 'Transferred to ${transfer.toName}',
      detail: 'From ${transfer.fromName}',
    );
  }

  static HistoryEvent _displayEvent(OwnershipTransfer transfer) {
    if (transfer.status == TransferStatus.pending) {
      return HistoryEvent(
        at: transfer.initiatedAt,
        icon: LucideIcons.clock3,
        label: 'Offered to ${transfer.toName}',
        detail: 'Awaiting acceptance',
        state: HistoryState.pending,
      );
    }
    final at = transfer.acceptedAt ?? transfer.initiatedAt;
    // A loan still running, one that ran its course, and one the owner pulled
    // back early are three different facts.
    if (isDisplayActive(transfer)) {
      return HistoryEvent(
        at: at,
        icon: LucideIcons.calendarClock,
        label: 'With ${transfer.toName}',
        detail: transfer.displayEndsAt == null ? null : 'Until ${formatShortDate(transfer.displayEndsAt!)}',
        state: HistoryState.current,
      );
    }
    final endedOn = transfer.displayEndedAt ?? transfer.displayEndsAt;
    return HistoryEvent(
      at: at,
      icon: LucideIcons.undo2,
      label: 'With ${transfer.toName}',
      detail: endedOn == null
          ? 'Ended'
          : '${transfer.displayEndedAt != null ? 'Ended early' : 'Ran to'} ${formatShortDate(endedOn)}',
    );
  }
}

enum HistoryState { current, pending }

class HistoryEvent {
  const HistoryEvent({required this.at, required this.icon, required this.label, this.detail, this.state});

  final String at;
  final IconData icon;
  final String label;
  final String? detail;

  /// Present when this is the live state of the record rather than a past event.
  final HistoryState? state;
}

class ArtworkHistory {
  const ArtworkHistory({required this.ownership, required this.display, required this.ownerName});

  final List<HistoryEvent> ownership;
  final List<HistoryEvent> display;
  final String ownerName;

  bool get onDisplayNow => display.any((e) => e.state == HistoryState.current);
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.summary,
    required this.caption,
    required this.events,
    required this.emptyText,
    this.summaryMuted = false,
  });

  final IconData icon;
  final String title;
  final String summary;
  final bool summaryMuted;
  final String caption;
  final List<HistoryEvent> events;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Icon(icon, size: 14, color: theme.colorScheme.tertiary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Text('${events.length}', style: theme.textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: summaryMuted ? null : theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(caption, style: theme.textTheme.labelSmall?.copyWith(height: 1.4)),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(emptyText, textAlign: TextAlign.center, style: theme.textTheme.labelMedium),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  for (var i = 0; i < events.length; i++)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: events[i].state == HistoryState.current
                                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                      : theme.colorScheme.surface,
                                  border: Border.all(
                                    color: events[i].state == HistoryState.current
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline,
                                  ),
                                ),
                                child: Icon(
                                  events[i].icon,
                                  size: 12,
                                  color: events[i].state == HistoryState.current
                                      ? theme.colorScheme.tertiary
                                      : theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              if (i < events.length - 1)
                                Expanded(child: Container(width: 1, color: theme.colorScheme.outline)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(events[i].label, style: theme.textTheme.bodyMedium?.copyWith(height: 1.25)),
                                      if (events[i].state != null) _StateChip(state: events[i].state!),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      formatShortDate(events[i].at),
                                      if (events[i].detail != null && events[i].detail!.isNotEmpty) events[i].detail!,
                                    ].join(' · '),
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
              ),
            ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = state == HistoryState.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: current ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: current ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.circleDot,
            size: 10,
            color: current ? theme.colorScheme.tertiary : theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 4),
          Text(
            current ? 'Active' : 'Awaiting',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: current ? theme.colorScheme.tertiary : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
