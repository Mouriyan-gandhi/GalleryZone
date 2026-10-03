import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gallery_zone/core/router/app_router.dart';
import 'package:gallery_zone/data/models/auth.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:gallery_zone/features/shell/portal_menu.dart';

void main() {
  group('portal menus', () {
    test('every menu row points at a route the router actually has', () {
      final container = ProviderContainer(
        overrides: [initialRoleProvider.overrideWithValue(Role.artist)],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      addTearDown(router.dispose);

      final routes = [
        for (final menu in [customerMenu, artistMenu, aggregatorMenu])
          for (final section in menu)
            for (final item in section.items) item.route,
      ];
      expect(routes, isNotEmpty);

      for (final route in routes) {
        final match = router.configuration.findMatch(Uri.parse(route));
        expect(match.isError, isFalse, reason: '$route is not a registered route');
      }
    });

    test('no route is listed twice within one portal', () {
      for (final menu in [customerMenu, artistMenu, aggregatorMenu]) {
        final routes = [
          for (final section in menu)
            for (final item in section.items) item.route,
        ];
        expect(routes.toSet().length, routes.length);
      }
    });

    testWidgets('the avatar opens the drawer from the app bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [PortalAvatarButton(name: 'Devika Rao', badgeCount: 2)],
              ),
              endDrawer: PortalMenuDrawer(
                name: 'Devika Rao',
                roleLabel: 'Artist',
                groups: artistMenu,
                homeRoute: '/dashboard',
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      expect(find.text('Profile & KYC'), findsNothing);
      await tester.tap(find.byType(PortalAvatarButton));
      await tester.pumpAndSettle();

      expect(find.text('Artist'), findsOneWidget);
      // The list is longer than a test window, so this checks the top of it
      // plus the pinned footer — not every row.
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('Profile & KYC'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    test('every section is titled, and every portal ends in help and legal', () {
      for (final menu in [customerMenu, artistMenu, aggregatorMenu]) {
        for (final section in menu) {
          expect(section.title.trim(), isNotEmpty);
          expect(section.items, isNotEmpty);
        }
        // Support, FAQs and About & legal are the same three rows everywhere,
        // and they are always the last thing in the menu.
        expect(menu.last.items.map((item) => item.label).toList(),
            ['Support', 'FAQs', 'About & legal']);
      }
    });

    test('initials take at most two letters', () {
      expect(portalInitials('Devika Rao'), 'DR');
      expect(portalInitials('Verandah Art House'), 'VH');
      expect(portalInitials('Aarav'), 'A');
      expect(portalInitials('   '), '?');
    });
  });
}
