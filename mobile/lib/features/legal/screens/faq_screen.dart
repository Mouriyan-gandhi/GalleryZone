import 'package:flutter/material.dart';

import '../../../core/adaptive.dart';
import '../data/faq_data.dart';

/// Native FAQ, one tab per audience. Replaces the link-out to the website's
/// `/faq`: the answers ship with the app so they work offline and match the
/// build the reader is holding.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key, this.initialAudience});

  static const path = '/faq';

  /// Which tab opens first. Support screens pass their own portal's audience
  /// so an artist does not land on the buyer questions.
  final FaqAudience? initialAudience;

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: FaqAudience.values.length,
    initialIndex: FaqAudience.values.indexOf(widget.initialAudience ?? FaqAudience.general),
    vsync: this,
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            for (final audience in FaqAudience.values)
              Tab(text: faqAudienceLabel[audience]),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          for (final audience in FaqAudience.values) _AudienceList(audience: audience),
        ],
      ),
    );
  }
}

class _AudienceList extends StatelessWidget {
  const _AudienceList({required this.audience});

  final FaqAudience audience;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = faqItems.where((item) => item.audience == audience).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in items)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(
                    item.question,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  children: [
                    Text(item.answer, style: theme.textTheme.bodySmall?.copyWith(height: 1.55)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
