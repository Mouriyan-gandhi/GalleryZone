import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart' show ReviewStatus;
import '../../../data/models/mou.dart';
import '../../auth/providers/auth_providers.dart';
import '../portal_widgets.dart';
import 'mou_document.dart';
import 'mou_pdf.dart';
import 'signature_pad.dart';

/// Signs the agreement. Throws a readable message if the API refuses.
typedef SignMou = Future<void> Function({
  required String signatureName,
  required String version,
  required String signatureDataUrl,
});

/// One signing surface for both Memoranda of Understanding, the artist's and
/// the aggregator's. Port of `features/mou/mou-agreement.tsx`. They are
/// different documents with the same mechanics: read the whole thing with your
/// own details filled in, agree, sign with your own name. The caller supplies
/// the document and owns the mutation; this page owns the reading and signing.
///
/// On the website the text sits in a box with its own scrollbar. On a phone
/// that would be a scroll area inside a scroll area, so the page itself is the
/// reading surface: reaching the end of the text is what unlocks the rest.
class MouAgreementPage extends ConsumerStatefulWidget {
  const MouAgreementPage({
    super.key,
    required this.title,
    required this.document,
    required this.state,
    required this.onSign,
    required this.profileRoute,
    this.share = shareMouPdf,
  });

  final String title;
  final MouDocument document;
  final MouState state;
  final SignMou onSign;

  /// Where the person goes to fill in the details the agreement is missing.
  final String profileRoute;

  /// Replaced in tests; the platform share sheet is not there to talk to.
  final ShareMouPdf share;

  @override
  ConsumerState<MouAgreementPage> createState() => _MouAgreementPageState();
}

class _MouAgreementPageState extends ConsumerState<MouAgreementPage> {
  final _name = TextEditingController();
  bool _readToEnd = false;
  bool _agreed = false;
  String? _signature;
  bool _busy = false;
  bool _justSigned = false;
  bool _exporting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// The name the signature has to match: the account's.
  String get _signerName => widget.state.draft.parties.party.name ?? '';

  Future<void> _sign() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSign(
        signatureName: _name.text.trim(),
        version: widget.document.version,
        signatureDataUrl: _signature!,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _justSigned = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrorMessage(error);
      });
    }
  }

  Future<void> _download(MouFill fill) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      final Uint8List bytes = await buildMouPdf(widget.document, fill);
      await widget.share(bytes, mouPdfFileName(widget.document, fill));
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't build the PDF.")),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acceptance = widget.state.acceptance;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // The reading column: full width on a phone, a comfortable measure on
          // anything wider.
          final side = math.max(16.0, (constraints.maxWidth - 640) / 2);
          final slivers = acceptance != null
              ? _signedSlivers(acceptance)
              : _unsignedSlivers();
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, 16, side, 40),
                sliver: SliverMainAxisGroup(slivers: slivers),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Signed ---------------------------------------------------------------------------------------

  List<Widget> _signedSlivers(MouAcceptance acceptance) {
    final theme = Theme.of(context);
    final fill = MouFill.signed(acceptance, widget.state.draft);
    final emerald = reviewStatusColor(context, ReviewStatus.approved);
    return [
      SliverToBoxAdapter(
        child: PortalCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoundIcon(icon: LucideIcons.shieldCheck, color: emerald),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.document.title,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Signed ${mouDateTime(acceptance.acceptedAt)}. Version ${acceptance.version}.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(label: 'Signed', color: emerald),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Signed by', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      acceptance.signatureName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (acceptance.signatureDataUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SignatureImage(
                        dataUrl: acceptance.signatureDataUrl,
                        name: acceptance.signatureName,
                        height: 56,
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _exporting ? null : () => _download(fill),
                      icon: const Icon(LucideIcons.download, size: 14),
                      label: Text(
                        _exporting ? 'Preparing…' : 'Download signed PDF',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Once signed, the document is reference material rather than
              // something to read: it folds away.
              Material(
                type: MaterialType.transparency,
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(
                      'Read the signed agreement',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    children: [
                      for (final block in widget.document.blocks)
                        _BlockView(
                          block: block,
                          fill: fill,
                          party: widget.document.party,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // --- Not yet signed ---------------------------------------------------------------------------------

  List<Widget> _unsignedSlivers() {
    final theme = Theme.of(context);
    final draft = widget.state.draft;
    final fill = MouFill.draft(draft);

    // The API has a newer text than this build was made with: signing would be refused.
    final stale = draft.version != widget.document.version;
    final blocked = stale || draft.missing.isNotEmpty;
    final nameTyped = _name.text.trim();
    final nameMatches =
        nameTyped.toLowerCase() == _signerName.trim().toLowerCase();
    final canSign =
        !blocked && _readToEnd && _agreed && nameMatches && _signature != null;

    return [
      SliverToBoxAdapter(
        child: PortalCard(
          gold: true,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundIcon(
                icon: LucideIcons.fileSignature,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.document.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.document.intro,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _Steps(read: _readToEnd, agree: _agreed, sign: _justSigned),
        ),
      ),
      if (stale || draft.missing.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: PortalNotice(
              icon: LucideIcons.triangleAlert,
              destructive: true,
              title: stale
                  ? null
                  : 'Your profile is missing details this agreement needs',
              body: stale
                  ? 'This agreement has been updated since this version of the app was made. Update the app to read '
                        'and sign the current version.'
                  : '${draft.missing.map((key) => mouDetailLabel[key] ?? key).join(', ')}. Add them to your profile and '
                        'save. They fill in here, and you can sign.',
              action: stale
                  ? null
                  : TextButton(
                      onPressed: () => context.push(widget.profileRoute),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Open my profile'),
                    ),
            ),
          ),
        ),
      // The text, set like the paper: headings as written, lettered items
      // hanging, the opening block centred.
      SliverPadding(
        padding: const EdgeInsets.only(top: 16),
        sliver: DecoratedSliver(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          sliver: SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList.builder(
              itemCount: widget.document.blocks.length,
              itemBuilder: (context, index) => _BlockView(
                block: widget.document.blocks[index],
                fill: fill,
                party: widget.document.party,
              ),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _EndSentinel(
          onReached: () {
            if (!_readToEnd) setState(() => _readToEnd = true);
          },
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_readToEnd)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.chevronDown,
                        size: 14,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Read to the end to continue',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              InkWell(
                onTap: !_readToEnd || blocked
                    ? null
                    : () => setState(() => _agreed = !_agreed),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 8, 14, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: !_readToEnd || blocked
                            ? null
                            : (value) =>
                                  setState(() => _agreed = value ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'I have read this Memorandum of Understanding in full, the details above are mine, and I '
                            'agree to be bound by it.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _name,
                enabled: _agreed,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                decoration: InputDecoration(
                  labelText: 'Type your full name',
                  hintText: _signerName,
                  helperText:
                      'Exactly as it appears on your profile ($_signerName). It is recorded with your drawn '
                      'signature, the date and the document version.',
                  helperMaxLines: 4,
                  errorText: nameTyped.isNotEmpty && !nameMatches
                      ? "This doesn't match the name on your profile. Update your profile first if your legal name is "
                            'different.'
                      : null,
                  errorMaxLines: 4,
                ),
              ),
              const SizedBox(height: 18),
              Text('Draw your signature', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SignaturePad(
                enabled: _agreed,
                encode: ref.watch(signatureEncoderProvider),
                onChanged: (url) => setState(() => _signature = url),
              ),
              Text(
                'Sign with your finger or a stylus.',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton(
                    onPressed: canSign && !_busy ? _sign : null,
                    child: Text(_busy ? 'Signing…' : 'Sign and accept'),
                  ),
                  Text.rich(
                    TextSpan(
                      text: 'Dated ',
                      children: [
                        TextSpan(
                          text: mouDate(fill.date),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (_justSigned)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.check,
                          size: 14,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Signed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }
}

// --- Pieces ---------------------------------------------------------------------------------------------

/// Fires once, the first time the end of the text is on the screen.
class _EndSentinel extends StatefulWidget {
  const _EndSentinel({required this.onReached});

  final VoidCallback onReached;

  @override
  State<_EndSentinel> createState() => _EndSentinelState();
}

class _EndSentinelState extends State<_EndSentinel> {
  ScrollPosition? _position;
  bool _fired = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (_fired || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    // The sliver list only builds this when it is near the screen; it counts as
    // reached once its top edge is above the bottom of the screen.
    if (box.localToGlobal(Offset.zero).dy < MediaQuery.sizeOf(context).height) {
      _fired = true;
      widget.onReached();
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 1);
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

/// Small progress cue so a first-time signer knows where they are in the read,
/// agree, sign flow before they've done any of it, rather than discovering the
/// rules one disabled control at a time.
class _Steps extends StatelessWidget {
  const _Steps({required this.read, required this.agree, required this.sign});

  final bool read;
  final bool agree;
  final bool sign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [('Read', read), ('Agree', agree), ('Sign', sign)];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: steps[i].$2 ? theme.colorScheme.primary : null,
              border: Border.all(
                color: steps[i].$2
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
            child: steps[i].$2
                ? Icon(
                    LucideIcons.check,
                    size: 12,
                    color: theme.colorScheme.onPrimary,
                  )
                : Text('${i + 1}', style: theme.textTheme.labelSmall),
          ),
          const SizedBox(width: 6),
          Text(
            steps[i].$1,
            style: theme.textTheme.labelMedium?.copyWith(
              color: steps[i].$2
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (i < steps.length - 1) ...[
            const SizedBox(width: 8),
            Container(width: 24, height: 1, color: theme.colorScheme.outline),
            const SizedBox(width: 8),
          ],
        ],
      ],
    );
  }
}

/// A drawn signature, from its data URL. On a dark theme the ink is flipped, as
/// the website does, so it doesn't vanish into the background.
class _SignatureImage extends StatelessWidget {
  const _SignatureImage({
    required this.dataUrl,
    required this.name,
    required this.height,
  });

  final String dataUrl;
  final String name;
  final double height;

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      bytes = UriData.parse(dataUrl).contentAsBytes();
    } catch (_) {
      bytes = null;
    }
    if (bytes == null) return const SizedBox.shrink();
    final image = Image.memory(
      bytes,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: "$name's signature",
      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
    );
    if (Theme.of(context).brightness != Brightness.dark) return image;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -1, 0, 0, 0, 255, //
        0, -1, 0, 0, 255,
        0, 0, -1, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: image,
    );
  }
}

/// One block of the document, as the company wrote it, with its blanks filled.
class _BlockView extends StatelessWidget {
  const _BlockView({
    required this.block,
    required this.fill,
    required this.party,
  });

  final MouBlock block;
  final MouFill fill;
  final MouParty party;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium?.copyWith(
      height: 1.55,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
    );
    final strong = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.4,
    );

    Widget spaced(Widget child, {double top = 0, double bottom = 10}) =>
        Padding(
          padding: EdgeInsets.only(top: top, bottom: bottom),
          child: child,
        );

    switch (block) {
      case MouTitle(:final text):
        return spaced(
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          bottom: 12,
        );
      case MouHeading(:final text, :final center):
        return spaced(
          Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: strong,
          ),
          top: 14,
          bottom: 6,
        );
      case MouSubheading(:final text):
        return spaced(
          Text(text, style: strong?.copyWith(fontWeight: FontWeight.w500)),
          top: 6,
          bottom: 4,
        );
      case MouParagraph(:final text, :final center):
        return spaced(
          Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: body,
          ),
        );
      case MouItem(:final marker, :final text):
        return spaced(
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 28, child: Text(marker, style: body)),
                Expanded(child: Text(text, style: body)),
              ],
            ),
          ),
          bottom: 6,
        );
      case MouSigner(:final text):
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.colorScheme.outline)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(text, style: strong),
            ),
          ),
        );
      case MouField(:final label, :final key):
        return spaced(
          _FieldView(label: label, value: mouFieldValue(key, fill, party)),
          bottom: 6,
        );
      case MouNote(:final text):
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.colorScheme.outline)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                text,
                style: theme.textTheme.labelSmall?.copyWith(height: 1.5),
              ),
            ),
          ),
        );
    }
  }
}

/// One blank, filled. The value sits on the line the paper leaves for it, so
/// the reader sees their own details written into the agreement.
class _FieldView extends StatelessWidget {
  const _FieldView({required this.label, required this.value});

  final String label;
  final MouFieldValue value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium?.copyWith(height: 1.4);
    final line = theme.colorScheme.primary.withValues(alpha: 0.6);

    Widget underlined(Widget child, {Color? color}) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color ?? line)),
      ),
      child: Padding(padding: const EdgeInsets.only(bottom: 2), child: child),
    );

    final Widget filled = switch (value) {
      MouFilled(:final text) => underlined(
        Text(text, style: body?.copyWith(fontWeight: FontWeight.w600)),
      ),
      MouSignature(:final name, :final image) => underlined(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null && image.isNotEmpty)
              _SignatureImage(dataUrl: image, name: name, height: 48),
            Text(
              name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      MouPending(:final text) => underlined(
        Text(
          text,
          style: body?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        color: theme.colorScheme.outline,
      ),
      MouMissing() => underlined(
        Text(
          'Missing from your profile',
          style: body?.copyWith(color: AppColors.destructive),
        ),
        color: AppColors.destructive.withValues(alpha: 0.7),
      ),
      MouBlank() => Container(
        width: 160,
        height: 18,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
        ),
      ),
    };

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Text(
          '$label: ',
          style: body?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
        filled,
      ],
    );
  }
}
