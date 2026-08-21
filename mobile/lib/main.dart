import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/storage/secure_session.dart';
import 'core/theme/app_theme.dart';
import 'data/storage/mock_db.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/role_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Every mock repository reads collections synchronously, so the
  // shared_preferences handle behind them has to exist before the first
  // frame — same single init the web's mock-db does lazily on first read.
  await MockDb.init();
  // Read the stored session once, before the first frame, so the router can
  // decide its initial route synchronously — no splash route, no
  // loading-state branch in the redirect.
  final role = RoleX.fromId(await SecureSession.getRole());
  runApp(
    ProviderScope(
      overrides: [initialRoleProvider.overrideWithValue(role)],
      child: const GalleryZoneApp(),
    ),
  );
}

class GalleryZoneApp extends ConsumerWidget {
  const GalleryZoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'GalleryZone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Dark is the product's hard default — the web forces it with
      // `next-themes` `enableSystem: false`. A user-facing toggle lands with
      // the settings screens (Phase 4).
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
