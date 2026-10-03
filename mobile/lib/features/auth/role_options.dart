import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/auth.dart';

/// Port of `features/auth/data/role-options.ts` + `proxy.ts`'s `ROLE_HOME`.
/// Copy is sourced verbatim from the web app (which took it from the
/// Onboarding Guide's "Platform Overview") — don't reword it here.
class RoleOption {
  const RoleOption({
    required this.role,
    required this.label,
    required this.description,
    required this.icon,
  });

  final Role role;
  final String label;
  final String description;
  final IconData icon;
}

const roleOptions = <RoleOption>[
  RoleOption(
    role: Role.artist,
    label: 'Artist',
    description: 'List and sell your original artwork with full price privacy.',
    icon: LucideIcons.palette,
  ),
  RoleOption(
    role: Role.aggregator,
    label: 'Aggregator',
    description:
        'Reserve, display, and distribute verified art through your gallery or space.',
    icon: LucideIcons.building2,
  ),
  RoleOption(
    role: Role.customer,
    label: 'Customer',
    description: 'Discover and collect verified original artwork.',
    icon: LucideIcons.compass,
  ),
];

/// Where each role lands after login, and the only place a role is allowed
/// to be — same table `proxy.ts` guards with. Admin is deliberately absent:
/// it never mounts on mobile (SAD's mobile-architecture section).
const roleHome = <Role, String>{
  Role.artist: '/dashboard',
  Role.aggregator: '/aggregator/dashboard',
  Role.customer: '/account',
};

extension RoleX on Role {
  /// The exact string stored in secure storage / the web's `gz_session`
  /// cookie. Kept as an explicit accessor so a rename of the enum member
  /// can't silently change the persisted value.
  String get id => name;

  String get home => roleHome[this]!;

  RoleOption get option => roleOptions.firstWhere((o) => o.role == this);

  static Role? fromId(String? id) {
    for (final role in Role.values) {
      if (role.name == id) return role;
    }
    return null;
  }
}

/// Where a **sign-in** lands, in the order the website decides it:
///
///  1. a same-app `next` path, if the guard (or a link) sent them here from
///     somewhere — checked by [safeNextPath] so it can never leave the app;
///  2. an artist goes to the marketplace — they finished onboarding long ago,
///     so the shop reads better than a dashboard;
///  3. an aggregator opens on My Profile — the GST number, agreement and bank
///     details that gate reserving live there, so it is the first thing to check;
///  4. everyone else lands in their own portal.
String landingAfterLogin(Role role, {String? next}) {
  final target = safeNextPath(next);
  if (target != null) return target;
  return switch (role) {
    Role.artist => '/marketplace',
    Role.aggregator => '/aggregator/profile',
    Role.customer => role.home,
  };
}

/// Where a brand-new account lands. An artist or aggregator still has a
/// profile to fill in (KYC, bank, GST, agreement) before anything else is
/// useful, so land there instead of an empty dashboard.
String landingAfterRegister(Role role) => switch (role) {
      Role.artist => '/dashboard/profile',
      Role.aggregator => '/aggregator/profile',
      Role.customer => role.home,
    };

/// Only a path inside this app is a valid place to return to after signing
/// in. Anything else — a full URL, a protocol-relative `//host`, a path with
/// control characters, or the auth screens themselves — is ignored, so a
/// crafted link cannot send a freshly signed-in person somewhere else.
String? safeNextPath(String? next) {
  if (next == null || next.isEmpty) return null;
  final uri = Uri.tryParse(next);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (!next.startsWith('/') || next.startsWith('//') || next.startsWith(r'/\')) return null;
  if (next.contains(RegExp(r'[\u0000-\u001f\u007f\\]'))) return null;
  const authPaths = ['/login', '/register', '/forgot-password', '/reset-password', '/verify-email'];
  final path = uri.path;
  if (authPaths.any((auth) => path == auth || path.startsWith('$auth/'))) return null;
  return next;
}
