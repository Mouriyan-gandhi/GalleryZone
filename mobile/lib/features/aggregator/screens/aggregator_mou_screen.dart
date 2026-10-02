import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart' show EmptyState;
import '../../shell/mou/mou_agreement_page.dart';
import '../aggregator_mou_data.dart';
import '../providers/aggregator_providers.dart';
import 'aggregator_account_screens.dart';

/// The aggregator's partner agreement with GalleryZone: the website's document,
/// word for word, with the business's details filled in from the profile; read
/// to the end, agree, type your name and draw your signature.
///
/// Signing is not a formality here: an unsigned aggregator has no agreement
/// covering custody, pricing or settlement, so reserving is refused until it is
/// done - this is the only way to open the portal's inventory. Stored against
/// [aggregatorMouVersion], so a later revision asks again.
class AggregatorMouScreen extends ConsumerWidget {
  const AggregatorMouScreen({super.key});

  static const path = '/aggregator/mou';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aggregatorMouStateProvider);
    final loaded = state.value;

    if (loaded == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aggregator MOU')),
        body: state.hasError
            ? EmptyState(
                icon: LucideIcons.triangleAlert,
                title: "Couldn't load the agreement",
                description: authErrorMessage(state.error!),
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(aggregatorMouStateProvider),
                  child: const Text('Try again'),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return MouAgreementPage(
      title: 'Aggregator MOU',
      document: aggregatorMou,
      state: loaded,
      profileRoute: AggregatorProfileScreen.path,
      onSign:
          ({
            required signatureName,
            required version,
            required signatureDataUrl,
          }) async {
            await ref
                .read(aggregatorRepositoryProvider)
                .acceptMou(
                  signatureName: signatureName,
                  version: version,
                  signatureDataUrl: signatureDataUrl,
                );
            // Reserving, the profile and the agreement itself all read this.
            ref.invalidate(aggregatorProfileProvider);
            ref.invalidate(aggregatorMouStateProvider);
          },
    );
  }
}
