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
