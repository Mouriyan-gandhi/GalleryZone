import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/auth.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:gallery_zone/features/auth/role_options.dart';
import 'package:gallery_zone/features/auth/screens/login_screen.dart';
import 'package:gallery_zone/features/splash/splash_screen.dart';

void main() {
  group('splash destination', () {
    test('signed out lands on login, each role on its own home', () {
      expect(splashDestination(null), LoginScreen.path);
      for (final role in Role.values) {
        expect(splashDestination(role), role.home);
      }
    });

    test('every role has a greeting name', () {
      for (final role in Role.values) {
        expect(splashGreetingName(role), isNotEmpty);
      }
    });
  });

  group('splash timing', () {
    Future<GoRouter> pumpSplash(WidgetTester tester, Role? role) async {
      final router = GoRouter(
        initialLocation: SplashScreen.path,
        routes: [
          GoRoute(path: SplashScreen.path, builder: (_, _) => const SplashScreen()),
          GoRoute(path: LoginScreen.path, builder: (_, _) => const Text('login')),
          for (final home in Role.values.map((r) => r.home))
            GoRoute(path: home, builder: (_, _) => Text('home $home')),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialRoleProvider.overrideWithValue(role)],
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      );
      return router;
    }

    String locationOf(GoRouter router) =>
        router.routerDelegate.currentConfiguration.uri.path;

    testWidgets('the mark holds for two seconds before anything moves',
        (tester) async {
      final router = await pumpSplash(tester, Role.artist);

      expect(find.text('GALLERYZONE'), findsOneWidget);
      await tester.pump(splashHold - const Duration(milliseconds: 1));
      expect(find.textContaining('Welcome to GalleryZone'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(find.textContaining('Welcome to GalleryZone'), findsOneWidget);
      expect(find.textContaining('Devika'), findsOneWidget);
      expect(locationOf(router), SplashScreen.path);

      await tester.pump(splashGreetingHold);
      await tester.pumpAndSettle();
      expect(locationOf(router), Role.artist.home);
    });

    testWidgets('signed out skips the greeting and goes straight to login',
        (tester) async {
      final router = await pumpSplash(tester, null);

      await tester.pump(splashHold);
      await tester.pumpAndSettle();
      expect(find.textContaining('Welcome to GalleryZone'), findsNothing);
      expect(locationOf(router), LoginScreen.path);
    });
  });
}
