import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/nfc/nfc_device.dart';
import '../../../core/nfc/nfc_flow.dart';
import '../../../data/mock/mock_nfc_repository.dart';
import '../../../data/repositories/nfc_repository.dart';

/// The server's side of the tag. The offline mock by default; `main()` puts it
/// on the real API (core/backend.dart).
final nfcRepositoryProvider = Provider<NfcRepository>((ref) => MockNfcRepository());

/// The phone's NFC reader. A test swaps in a fake one: simulators have no NFC.
final nfcDeviceProvider = Provider<NfcDevice>((ref) => const FlutterNfcKitDevice());

/// Does this phone have NFC switched on? A phone without it doesn't see the
/// Link and Lock buttons at all (NFC_IMPLEMENTATION.md §7.3).
final nfcAvailableProvider = FutureProvider.autoDispose<bool>((ref) => ref.watch(nfcDeviceProvider).isAvailable());

final nfcFlowProvider = Provider<NfcFlow>(
  (ref) => NfcFlow(device: ref.watch(nfcDeviceProvider), repository: ref.watch(nfcRepositoryProvider)),
);
