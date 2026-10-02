import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// A search box for a list on the same screen: it filters as you type, and has a
/// clear button once there is something to clear. The caller owns [controller]
/// and rebuilds in [onChanged], so the list and the box never disagree.
class ListSearchField extends StatelessWidget {
  const ListSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(LucideIcons.search, size: 16),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(LucideIcons.x, size: 16),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

/// A single-choice dropdown drawn as a pill: it reads [label] ("All Shipment")
/// while nothing is picked and the picked option's name once something is, in
/// gold. The menu's first entry clears it. The mobile form of the website's
/// popover pill filters.
class PillFilter<T> extends StatelessWidget {
  const PillFilter({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;
    final picked = options.where((option) => option.$1 == value).firstOrNull;

    return PopupMenuButton<int>(
      tooltip: label,
      // -1 is "clear"; PopupMenuButton treats a null value as a dismissal.
      onSelected: (index) => onChanged(index < 0 ? null : options[index].$1),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: -1,
          child: Text(label, style: TextStyle(color: picked == null ? gold : null)),
        ),
        for (var i = 0; i < options.length; i++)
          PopupMenuItem(
            value: i,
            child: Text(options[i].$2, style: TextStyle(color: options[i].$1 == value ? gold : null)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: picked == null ? theme.colorScheme.onSurface.withValues(alpha: 0.04) : gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: picked == null ? theme.colorScheme.outline : gold.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              picked?.$2 ?? label,
              style: theme.textTheme.labelLarge?.copyWith(color: picked == null ? null : gold),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronDown, size: 14, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
