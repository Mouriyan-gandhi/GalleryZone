import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/seed/aggregator_seed.dart' show fixtureToday;
import '../auth/providers/auth_providers.dart';

/// "Now", for counting days down to a holding's expiry.
///
/// Against the real service this is the real clock. In the offline demo it is
/// the fixed date its seeded holdings are dated from ([fixtureToday]): counting
/// from the wall clock would age the demo data a day every day until every
/// placement had long expired. Reading a holding that the API dated in October
/// against that fixed August day is the bug this exists to prevent.
DateTime displayNow(WidgetRef ref) =>
    ref.watch(remoteBackendProvider) ? DateTime.now().toUtc() : fixtureToday;
