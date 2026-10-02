import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/artwork.dart' show ReviewStatus;
import '../shell/portal_widgets.dart';
import 'providers/aggregator_providers.dart';

/// What GalleryZone needs from an aggregator before it places a piece with them:
/// a signed MOU (custody, pricing, settlement) and an approved GST number
/// (client, 30 Sep 2026: "GST required for aggregators before reserving"). The
/// API refuses a reservation without both. This says so up front - on the
/// browse list and on the reserve page - rather than after a piece is picked.
/// Port of `reserve-requirements.tsx`.
///
/// Both flags are null while the profile loads. Only `false` blocks anything,
/// so a slow fetch never locks out someone who is fine.
class ReserveRequirements {
  const ReserveRequirements({this.mouSigned, this.gstStatus});

  final bool? mouSigned;
  final ReviewStatus? gstStatus;

  bool? get gstApproved => gstStatus == null ? null : gstStatus == ReviewStatus.approved;

  /// Why Reserve is closed, or null when it is open (or not known yet).
  String? get blockedReason => mouSigned == false
      ? 'Sign your Aggregator MOU first'
      : gstApproved == false
          ? 'Get your GST number approved first'
          : null;

  List<ReserveRequirement> get items => [
        if (mouSigned == false) _mouRequirement,
        if (gstApproved == false) _gstRequirements[gstStatus]!,
      ];
}

/// One thing still to do, with where to do it. [route] is null when there is
/// nothing to do but wait.
class ReserveRequirement {
  const ReserveRequirement({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.route,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final String? route;
}

const _mouRequirement = ReserveRequirement(
  icon: LucideIcons.fileSignature,
  title: 'Sign your Aggregator MOU to reserve artwork.',
  body: "It covers custody, pricing and settlement — GalleryZone can't place a piece with you until it's signed.",
  actionLabel: 'Read and sign',
  route: '/aggregator/dashboard/mou',
);

const _gstRequirements = {
  ReviewStatus.notSubmitted: ReserveRequirement(
    icon: LucideIcons.receipt,
    title: 'Add your GST number to reserve artwork.',
    body: "GalleryZone needs an approved GST registration before it can place a piece with you. Add it on your profile and we'll review it.",
    actionLabel: 'Go to My Profile',
    route: '/aggregator/dashboard/profile',
  ),
  ReviewStatus.submitted: ReserveRequirement(
    icon: LucideIcons.receipt,
    title: 'Your GST number is being reviewed.',
    body: 'You can reserve artwork as soon as GalleryZone approves it.',
  ),
  ReviewStatus.rejected: ReserveRequirement(
    icon: LucideIcons.receipt,
    title: "Your GST number wasn't approved.",
    body: 'Correct it on your profile and submit it again to reserve artwork.',
    actionLabel: 'Go to My Profile',
    route: '/aggregator/dashboard/profile',
  ),
};

final reserveRequirementsProvider = Provider.autoDispose<ReserveRequirements>((ref) {
  final profile = ref.watch(aggregatorProfileProvider).value;
  if (profile == null) return const ReserveRequirements();
  return ReserveRequirements(
    mouSigned: profile.mouAcceptance != null,
    gstStatus: profile.gstStatus,
  );
});

/// The requirements as gold notices; nothing at all when none is open.
class ReserveRequirementsNotice extends ConsumerWidget {
  const ReserveRequirementsNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(reserveRequirementsProvider).items;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RequirementCard(item: item),
          ),
      ],
    );
  }
}

/// The same message as the notice, shown when someone presses Reserve while a
/// requirement is still open - a disabled button says nothing when tapped.
Future<void> showReserveBlockedDialog(BuildContext context, ReserveRequirements requirements) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("You can't reserve this yet"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in requirements.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequirementCard(
                  item: item,
                  // Close the dialog first so Back from the profile lands on the list.
                  onNavigate: () => Navigator.of(dialogContext).pop(),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({required this.item, this.onNavigate});

  final ReserveRequirement item;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final route = item.route;
    return PortalNotice(
      icon: item.icon,
      title: item.title,
      body: item.body,
      gold: true,
      action: route == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  final router = GoRouter.of(context);
                  onNavigate?.call();
                  router.push(route);
                },
                child: Text(item.actionLabel!),
              ),
            ),
    );
  }
}
