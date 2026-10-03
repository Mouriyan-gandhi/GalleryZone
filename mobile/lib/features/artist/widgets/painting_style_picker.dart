import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../painting_styles.dart';

/// What the picker hands back: the chosen style's name (`Other` for the free
/// text option), or null when the artist cleared their choice. Dismissing the
/// sheet returns nothing at all, so "no change" and "cleared" stay different.
class PaintingStylePick {
  const PaintingStylePick(this.name);

  final String? name;
}

/// The 97 world painting traditions, searchable by name, region or category.
/// Port of the website's painting-style combobox, as a bottom sheet - the
/// native way to pick from a list this long.
Future<PaintingStylePick?> showPaintingStylePicker(
  BuildContext context, {
  required String selected,
}) {
  return showModalBottomSheet<PaintingStylePick>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _PaintingStyleSheet(selected: selected),
  );
}

class _PaintingStyleSheet extends StatefulWidget {
  const _PaintingStyleSheet({required this.selected});

  final String selected;

  @override
  State<_PaintingStyleSheet> createState() => _PaintingStyleSheetState();
}

class _PaintingStyleSheetState extends State<_PaintingStyleSheet> {
  String _query = '';

  bool _matches(PaintingStyle style) {
    final query = _query.trim().toLowerCase();
    return query.isEmpty ||
        style.name.toLowerCase().contains(query) ||
        style.region.toLowerCase().contains(query) ||
        style.category.toLowerCase().contains(query);
  }

  /// Choosing the style that is already chosen clears it, as on the website.
  void _choose(String name) {
    Navigator.of(context)
        .pop(PaintingStylePick(widget.selected == name ? null : name));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = paintingStyles.where(_matches).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  autofocus: false,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.search, size: 16),
                    hintText: 'Search name, region, or category...',
                  ),
                ),
              ),
              Expanded(
                child: matches.isEmpty
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Text(
                            'No matching style.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final style = matches[index];
                          return _StyleTile(
                            title: style.name,
                            subtitle: '${style.region} · ${style.category}',
                            selected: widget.selected == style.name,
                            onTap: () => _choose(style.name),
                          );
                        },
                      ),
              ),
              // Pinned, not the last of ninety-seven: someone whose tradition is not
              // in the list should not have to scroll to the bottom to say so.
              const Divider(height: 1),
              _StyleTile(
                title: 'Other',
                selected: widget.selected == 'Other',
                onTap: () => _choose('Other'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: selected
          ? Icon(
              LucideIcons.check,
              size: 16,
              color: Theme.of(context).colorScheme.tertiary,
            )
          : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
