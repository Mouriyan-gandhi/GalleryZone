import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../shell/brand_mark.dart';
import '../validators.dart';

/// Shared pieces of the five Auth screens, ported from
/// `features/auth/components/*`. Kept in one file because each is a handful
/// of lines and they are only ever used together, by those five screens.

/// The `app/(auth)/layout.tsx` shell: one centered, scrollable column with
/// the same max width the web caps the form card at.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered wordmark atop every Auth screen.
class AuthCrest extends StatelessWidget {
  const AuthCrest({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const BrandMark(size: 92),
        const SizedBox(height: 8),
        // The brand line, directly under the wordmark rather than tucked at
        // the bottom of a panel a phone never scrolls to.
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: theme.textTheme.titleMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
            children: [
              const TextSpan(text: 'Art, that Connects. '),
              TextSpan(
                text: 'Culture that inspires.',
                style: TextStyle(
                  color: theme.colorScheme.tertiary,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(height: 1, width: 40, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
      ],
    );
  }
}

/// Shared heading — optional haloed icon + display-font title + description.
class AuthFormHeader extends StatelessWidget {
  const AuthFormHeader({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.centered = false,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleText = Text(
      title,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    );

    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (icon != null && !centered)
          Row(
            children: [
              _IconHalo(icon: icon!),
              const SizedBox(width: 14),
              Expanded(child: titleText),
            ],
          )
        else
          titleText,
        if (description != null) ...[
          const SizedBox(height: 10),
          Text(
            description!,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ],
      ],
    );
  }
}

class _IconHalo extends StatelessWidget {
  const _IconHalo({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint.withValues(alpha: 0.12),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.tertiary),
    );
  }
}

/// The terminal state shared by Register ("Check your email"), Forgot
/// ("Check your email"), Reset ("Password reset") and Verify ("Email
/// verified" / the error variant) — same circle-icon + title + body layout
/// in all five places on the web.
class AuthResultPanel extends StatelessWidget {
  const AuthResultPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isError = false,
    this.children = const [],
  });

  final IconData icon;
  final String title;
  final Widget description;
  final bool isError;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _IconHalo(icon: icon, color: isError ? theme.colorScheme.error : null),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DefaultTextStyle.merge(
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall!.copyWith(height: 1.5),
          child: description,
        ),
        for (final child in children) ...[const SizedBox(height: 20), child],
      ],
    );
  }
}

/// Labelled text field with a leading glyph and, for passwords, a
/// reveal toggle. Validation runs on interaction (not only on submit), same
/// as react-hook-form's default `onTouched`-ish feel.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.hint,
    this.icon,
    this.keyboardType,
    this.obscure = false,
    this.autofillHints,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final List<String>? autofillHints;
  final ValueChanged<String>? onChanged;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 18),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
                    onPressed: () => setState(() => _hidden = !_hidden),
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Three discrete role buttons, not a connected segmented control — each
/// role is its own choice, not a step along a track. On Login this toggle
/// IS "sign in as": with no backend there's nothing else that could know an
/// account's role.
class RoleToggle<T> extends StatelessWidget {
  const RoleToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<({String label, IconData icon, T value})> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in options) ...[
          Expanded(
            child: _RoleToggleButton(
              label: option.label,
              icon: option.icon,
              selected: option.value == value,
              onTap: () => onChanged(option.value),
            ),
          ),
          if (option != options.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _RoleToggleButton extends StatelessWidget {
  const _RoleToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = selected ? theme.colorScheme.tertiary : Colors.transparent;
    final foreground = selected ? theme.colorScheme.onTertiary : theme.textTheme.bodySmall?.color;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.xl4),
            border: Border.all(
              color: selected ? theme.colorScheme.tertiary : theme.colorScheme.outline,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              // Shrink-to-fit rather than ellipsis: "Aggregator" is the
              // longest of the three and truncates at phone widths, which
              // reads as a broken label rather than a tight one.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed gold frame + "DEV" chip around every control that only exists
/// because there is no real backend. Same treatment on every screen so
/// these stay instantly recognizable as non-production.
class DevPanel extends StatelessWidget {
  const DevPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            ),
            child: Text(
              'DEV',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Gold-scale strength bar (`--chart-1..5`), not a red/yellow/green traffic
/// light — brand consistency, same call the web makes.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  static const _labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final score = scorePassword(password);
    // chart-5 (dimmest) → chart-1 (brightest) as the score climbs.
    const colors = [
      AppColors.darkMutedForeground,
      AppColors.darkMutedForeground,
      AppColors.darkGoldDeep,
      AppColors.darkGold,
      AppColors.darkGoldBright,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: score / 4,
            minHeight: 6,
            backgroundColor: theme.colorScheme.outline,
            valueColor: AlwaysStoppedAnimation(colors[score]),
            semanticsLabel: 'Password strength',
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            text: 'Password strength: ',
            children: [
              TextSpan(
                text: _labels[score],
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// OAuth buttons stay a styled, honest dead end — no backend to hand off
/// to, so they say so rather than faking a redirect (same as the web).
class SocialAuthRow extends StatelessWidget {
  const SocialAuthRow({super.key});

  static const _googleSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
<path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.16v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
<path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.16C1.43 8.55 1 10.22 1 12s.43 3.45 1.16 4.93l3.68-2.84z" fill="#FBBC05"/>
<path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.16 7.07l3.68 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
</svg>''';

  void _notWired(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$provider sign-in isn't wired up in this demo yet.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: theme.colorScheme.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR CONTINUE WITH',
                style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
              ),
            ),
            Expanded(child: Divider(color: theme.colorScheme.outline)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _notWired(context, 'Google'),
                icon: SvgPicture.string(_googleSvg, width: 16, height: 16),
                label: const Text('Google'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _notWired(context, 'Apple'),
                icon: const Icon(Icons.apple, size: 18),
                label: const Text('Apple'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Primary submit button with the inline spinner every Auth form shows
/// while its mutation is pending.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

/// Inline destructive banner — the `Alert variant="destructive"` the forms
/// render above the fields when a mutation fails.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertCircle, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
