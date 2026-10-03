import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/nfc/nfc_flow.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/verify_url.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/nfc.dart';
import '../providers/nfc_providers.dart';

/// Which of the two things the sheet is for.
enum NfcMode { link, lock }

/// The sheet that writes a tag, or locks one (NFC_IMPLEMENTATION.md §2). The
/// caller says what to refresh once something changed ([onChanged]) - this sheet
/// is shared by the artist's board and the aggregator's holding. Who may do what
/// (a gallery can lock a linked tag but not write over it) is the server's call.
Future<void> showNfcSheet(
  BuildContext context, {
  required Artwork artwork,
  required NfcMode mode,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => NfcSheet(artwork: artwork, mode: mode, onChanged: onChanged),
  );
}

enum _Phase { idle, working, linked, locked, failed }

class NfcSheet extends ConsumerStatefulWidget {
  const NfcSheet({super.key, required this.artwork, required this.mode, required this.onChanged});

  final Artwork artwork;
  final NfcMode mode;
  final VoidCallback onChanged;

  @override
  ConsumerState<NfcSheet> createState() => _NfcSheetState();
}

class _NfcSheetState extends ConsumerState<NfcSheet> {
  late NfcMode _mode = widget.mode;
  _Phase _phase = _Phase.idle;
  NfcProgress? _progress;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.working;
      _progress = NfcProgress.waitingForTag;
      _error = null;
    });
    final flow = ref.read(nfcFlowProvider);
    try {
      void onProgress(NfcProgress progress) {
        if (mounted) setState(() => _progress = progress);
      }

      if (_mode == NfcMode.link) {
        await flow.link(widget.artwork.id, onProgress: onProgress);
      } else {
        await flow.lock(widget.artwork.id, onProgress: onProgress);
      }
      widget.onChanged();
      if (mounted) setState(() => _phase = _mode == NfcMode.link ? _Phase.linked : _Phase.locked);
    } on NfcFlowException catch (failure) {
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _error = failure.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linking = _mode == NfcMode.link;
    final replacing = linking && widget.artwork.nfcNeedsLock;
    final title = linking ? (replacing ? 'Replace NFC tag' : 'Link NFC tag') : 'Lock NFC tag';

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(LucideIcons.nfc, size: 18, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 4),
            Text('“${widget.artwork.title}”', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            ..._body(context, linking: linking, replacing: replacing),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, {required bool linking, required bool replacing}) {
    final theme = Theme.of(context);
    switch (_phase) {
      case _Phase.working:
        return [_Working(progress: _progress ?? NfcProgress.waitingForTag, linking: linking)];

      case _Phase.linked:
        return [
          _Notice(
            icon: LucideIcons.shieldCheck,
            title: 'Tag linked',
            body: "The chip is paired to this artwork. Attach it behind the artist's signature on the canvas.",
            tone: _Tone.good,
          ),
          const SizedBox(height: 12),
          const _Notice(
            icon: LucideIcons.lock,
            title: 'Not locked yet — must lock before shipping',
            body:
                'Until it is locked, anyone with a phone could rewrite the chip, and the piece can’t be dispatched. '
                'Locking is permanent, so do it once the chip is attached.',
            tone: _Tone.warn,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('nfc-lock-now'),
            onPressed: () => setState(() {
              _mode = NfcMode.lock;
              _phase = _Phase.idle;
            }),
            icon: const Icon(LucideIcons.lock, size: 16),
            label: const Text('Lock now (recommended)'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('nfc-lock-later'),
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Lock later'),
          ),
          const SizedBox(height: 6),
          Text(
            'Lock later and the piece stays flagged in red on your dashboard until you do.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
        ];

      case _Phase.locked:
        return [
          const _Notice(
            icon: LucideIcons.lock,
            title: 'Tag locked',
            body: 'The chip is read-only for good. The piece can now be dispatched.',
            tone: _Tone.good,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Done'),
          ),
        ];

      case _Phase.failed:
        return [
          _Notice(
            icon: LucideIcons.triangleAlert,
            title: linking ? "The tag wasn't linked" : "The tag wasn't locked",
            body: _error ?? 'Please try again.',
            tone: _Tone.bad,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('nfc-try-again'),
            onPressed: _start,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Try again'),
          ),
        ];

      case _Phase.idle:
        return linking ? _linkIdle(context, replacing: replacing) : _lockIdle(context);
    }
  }

  List<Widget> _linkIdle(BuildContext context, {required bool replacing}) {
    final theme = Theme.of(context);
    final url = verifyUrlFor(widget.artwork.id);
    return [
      _Steps(
        title: 'How to program the tag',
        steps: const [
          'Tap the button, then hold a blank NTAG213 chip to the back of your phone.',
          'The address below is written to it as a single NDEF record.',
          'Lock the chip afterwards. Until it is locked it can be rewritten, and the piece can’t be dispatched.',
        ],
      ),
      if (replacing) ...[
        const SizedBox(height: 12),
        const _Notice(
          icon: LucideIcons.triangleAlert,
          title: 'This replaces the linked chip',
          body: 'The chip linked now stops being the record for this piece the moment the new one is written.',
          tone: _Tone.warn,
        ),
      ],
      const SizedBox(height: 12),
      Text('NFC ADDRESS (NDEF PAYLOAD)', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 0.8)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: theme.colorScheme.tertiary),
              ),
            ),
            IconButton(
              tooltip: 'Copy address',
              icon: const Icon(LucideIcons.copy, size: 16),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: url));
                messenger.showSnackBar(const SnackBar(content: Text('Address copied')));
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        key: const Key('nfc-start'),
        onPressed: _start,
        icon: const Icon(LucideIcons.radio, size: 16),
        label: Text(replacing ? 'Write a new tag' : 'Write tag'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    ];
  }

  List<Widget> _lockIdle(BuildContext context) {
    return [
      const _Notice(
        icon: LucideIcons.triangleAlert,
        title: 'Locking is permanent',
        body:
            'Once locked, the chip can never be rewritten — not by you, not by GalleryZone. Make sure it is the chip '
            'attached to this piece.',
        tone: _Tone.warn,
      ),
      const SizedBox(height: 12),
      const _Steps(
        title: 'How to lock it',
        steps: [
          'Tap the button, then hold the same chip you linked to the back of your phone.',
          'Keep it there until the app says it is done. Moving it away halfway can leave it partly locked; just run it again.',
        ],
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        key: const Key('nfc-start'),
        onPressed: _start,
        icon: const Icon(LucideIcons.lock, size: 16),
        label: const Text('Lock tag'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    ];
  }
}

enum _Tone { good, warn, bad }

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.body, required this.tone});

  final IconData icon;
  final String title;
  final String body;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (tone) {
      _Tone.good => theme.colorScheme.tertiary,
      _Tone.warn => const Color(0xFFD9A441),
      _Tone.bad => theme.colorScheme.error,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall?.copyWith(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 20, child: Text('${i + 1}.', style: theme.textTheme.bodySmall)),
                  Expanded(child: Text(steps[i], style: theme.textTheme.bodySmall?.copyWith(height: 1.45))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Working extends StatelessWidget {
  const _Working({required this.progress, required this.linking});

  final NfcProgress progress;
  final bool linking;

  String get _line => switch (progress) {
    NfcProgress.waitingForTag => 'Hold the tag to the back of your phone…',
    NfcProgress.checking => 'Checking the tag with GalleryZone…',
    NfcProgress.writing => 'Writing the address — keep holding it…',
    NfcProgress.verifyingWrite => 'Checking what was written…',
    NfcProgress.locking => 'Locking the tag — keep holding it…',
    NfcProgress.verifyingLock => 'Checking the lock took…',
    NfcProgress.recording => linking ? 'Recording the link…' : 'Recording the lock…',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            ),
            child: Icon(LucideIcons.nfc, size: 30, color: theme.colorScheme.tertiary),
          ),
          const SizedBox(height: 16),
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(height: 14),
          Text(_line, key: const Key('nfc-progress'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
