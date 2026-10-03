import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart' show EmptyState;
import '../../shell/mou/mou_agreement_page.dart';
import '../mou_data.dart';
import '../providers/artist_providers.dart';
import 'artist_kyc_screen.dart';

/// The artist's Memorandum of Understanding with GalleryZone: the website's
/// document, word for word, with the artist's own details filled in from their
/// profile; read to the end, agree, type your name and draw your signature.
///
/// Stored against [mouVersion] so a later revision asks again rather than
/// silently inheriting an acceptance of different wording.
class MouScreen extends ConsumerWidget {
  const MouScreen({super.key});

  static const path = '/dashboard/mou';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(artistMouStateProvider);
    final loaded = state.value;

    if (loaded == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Artist MOU')),
        body: state.hasError
            ? EmptyState(
                icon: LucideIcons.triangleAlert,
                title: "Couldn't load the agreement",
                description: authErrorMessage(state.error!),
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(artistMouStateProvider),
                  child: const Text('Try again'),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return MouAgreementPage(
      title: 'Artist MOU',
      document: artistMou,
      state: loaded,
      profileRoute: ArtistKycScreen.path,
      onSign:
          ({
            required signatureName,
            required version,
            required signatureDataUrl,
          }) async {
            await ref
                .read(artistRepositoryProvider)
                .acceptMou(
                  signatureName: signatureName,
                  version: version,
                  signatureDataUrl: signatureDataUrl,
                );
            // Signing moves the verification ladder, the profile page and the
            // agreement itself.
            ref.invalidate(mouAcceptanceProvider);
            ref.invalidate(artistMouStateProvider);
            ref.invalidate(artistActivityProvider);
          },
    );
  }
}
