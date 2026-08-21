import 'package:flutter/material.dart';

/// Window-size classes, Material's own breakpoints. Every layout branch in
/// this app keys off available width — never a platform check, a device
/// name, or orientation, all of which lie in split-screen, foldables and
/// resizable windows.
enum WindowSize {
  compact, // < 600
  medium, // 600 - 839
  expanded; // >= 840

  static WindowSize of(BuildContext context) => fromWidth(MediaQuery.sizeOf(context).width);

  /// Takes a raw width so a `LayoutBuilder` subtree can classify its own
  /// constraints rather than the whole window.
  static WindowSize fromWidth(double width) {
    if (width >= 840) return WindowSize.expanded;
    if (width >= 600) return WindowSize.medium;
    return WindowSize.compact;
  }

  bool get isCompact => this == WindowSize.compact;
  bool get isExpanded => this == WindowSize.expanded;
}

/// Caps reading-width content and centres it. Text, forms and single-column
/// lists stretched across a 1200px window are unreadable, so anything that
/// isn't a grid goes through this.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
