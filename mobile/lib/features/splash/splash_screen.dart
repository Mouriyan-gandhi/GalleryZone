import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/seed/aggregator_seed.dart' show currentAggregatorContact;
import '../../data/mock/seed/artist_seed.dart' show currentArtistName;
import '../../data/mock/seed/customer_seed.dart' show seedCustomerProfile;
import '../../data/models/auth.dart';
import '../auth/providers/auth_providers.dart';
import '../auth/role_options.dart';
import '../auth/screens/login_screen.dart';
import '../shell/brand_mark.dart';

/// How long the mark holds on its own before anything else moves.
const splashHold = Duration(seconds: 2);

/// How long the greeting stays up before the app lands on the role's home.
/// Only signed-in launches show it — there is nobody to greet otherwise.
const splashGreetingHold = Duration(milliseconds: 1600);

/// Who the greeting names. There is no real session yet (see [SecureSession]:
/// the stored value is the role, nothing more), so the name comes from the
/// same "signed in as" fixture each portal's own screens already greet with.
String splashGreetingName(Role role) => switch (role) {
      Role.artist => currentArtistName,
      Role.customer => seedCustomerProfile().name,
      // The aggregator fixture is a business; greet the contact person, not
      // the gallery, so the first name split below reads as a person.
      Role.aggregator => currentAggregatorContact,
    };

/// Where a launch ends up once the splash is done.
String splashDestination(Role? role) => role?.home ?? LoginScreen.path;

/// The launch screen: the mark alone for [splashHold], then — when there is a
/// session — a greeting, then the role's home. It is the router's initial
/// location, so it runs on every cold start and never sits in the back stack
/// (`go` replaces it).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const path = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  bool _greeting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(splashHold, _afterMark);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _afterMark() {
    if (!mounted) return;
    if (ref.read(sessionProvider) == null) return _leave();
    setState(() => _greeting = true);
    _timer = Timer(splashGreetingHold, _leave);
  }

  void _leave() {
    if (!mounted) return;
    context.go(splashDestination(ref.read(sessionProvider)));
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(sessionProvider);
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: _greeting && role != null
              ? _Greeting(name: splashGreetingName(role))
              : const _Mark(),
        ),
      ),
    );
  }
}

/// The brand mark, centered and alone. Same asset the native splash draws, so
/// the handoff from the OS window to the first Flutter frame is invisible.
/// Falls back to the lettered mark the Auth screens use if the asset is
/// missing, so a broken image never becomes a blank launch screen.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Image.asset(
      brandMarkAsset,
      width: size,
      height: size,
      errorBuilder: (context, error, stack) => SizedBox(
        height: size,
        child: Center(
          child: Text(
            'GZ',
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.tertiary,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Monogram(size: 148),
          Text(
            'GALLERYZONE',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 3.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// The mark moves to the top and the greeting takes the page — one screen, so
/// the mark travels rather than blinking out and back.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Center(child: _Monogram(size: 64)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Welcome to GalleryZone,\n${name.split(' ').first}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w300,
              height: 1.15,
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
