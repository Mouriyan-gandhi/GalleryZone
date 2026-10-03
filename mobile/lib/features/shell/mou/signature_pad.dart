import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// The strokes of a drawn signature, in the pad's own coordinates.
typedef SignatureStrokes = List<List<Offset>>;

/// Turns strokes into a PNG data URL, or null if there is nothing drawn.
typedef SignatureEncoder = Future<String?> Function(
  SignatureStrokes strokes,
  Size size,
);

const _ink = Color(0xFF1A1410);

void _paintStrokes(Canvas canvas, SignatureStrokes strokes) {
  final paint = Paint()
    ..color = _ink
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  for (final stroke in strokes) {
    if (stroke.isEmpty) continue;
    if (stroke.length == 1) {
      // A tap is a dot, not nothing.
      canvas.drawCircle(stroke.first, 1, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
      continue;
    }
    final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
    for (var i = 1; i < stroke.length - 1; i++) {
      // Curves through the midpoints, so a quick stroke isn't a polyline.
      final mid = Offset(
        (stroke[i].dx + stroke[i + 1].dx) / 2,
        (stroke[i].dy + stroke[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(stroke[i].dx, stroke[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(stroke.last.dx, stroke.last.dy);
    canvas.drawPath(path, paint);
  }
}

/// The most the API will take for a signature (300 KB of data URL); the
/// encoder stays comfortably under it.
const _maxSignatureChars = 280000;

Future<String> _png(SignatureStrokes strokes, Size size, double scale) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);
  _paintStrokes(canvas, strokes);
  final image = await recorder.endRecording().toImage((size.width * scale).ceil(), (size.height * scale).ceil());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return 'data:image/png;base64,${base64Encode(data!.buffer.asUint8List())}';
}

/// A drawn signature as a PNG data URL: near-black ink on a transparent
/// ground, at twice the pad's size so it stays crisp. Port of the website's
/// `toDataURL("image/png")`. A scribble too dense for that is redrawn at the
/// pad's own size rather than being refused by the API.
Future<String?> encodeSignaturePng(SignatureStrokes strokes, Size size) async {
  if (strokes.every((stroke) => stroke.isEmpty)) return null;
  final sharp = await _png(strokes, size, 2);
  if (sharp.length <= _maxSignatureChars) return sharp;
  return _png(strokes, size, 1);
}

/// Behind a provider so a test, which cannot rasterise, can stand in for it.
final signatureEncoderProvider = Provider<SignatureEncoder>(
  (ref) => encodeSignaturePng,
);

/// A drawn signature, finger or stylus. Port of `features/mou/signature-pad.tsx`.
///
/// Drawing reads the raw pointer, and claims the gesture outright, so the page
/// behind never scrolls out from under a stroke.
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.onChanged,
    required this.encode,
    this.enabled = true,
  });

  /// Fires with a PNG data URL after each stroke, or null once cleared.
  final ValueChanged<String?> onChanged;
  final SignatureEncoder encode;
  final bool enabled;

  static const height = 144.0;

  /// The drawing surface itself (the pad's widget also holds its Clear button).
  static const surfaceKey = ValueKey('signature-pad-surface');

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final SignatureStrokes _strokes = [];
  Size _size = Size.zero;
  bool _drawing = false;

  /// Only the newest encoding may report: a slow one must not overwrite a
  /// later stroke, or a clear.
  int _generation = 0;

  bool get _isEmpty => _strokes.isEmpty;

  Offset _inside(Offset point) =>
      Offset(point.dx.clamp(0, _size.width), point.dy.clamp(0, _size.height));

  void _down(PointerDownEvent event) {
    if (!widget.enabled) return;
    setState(() {
      _drawing = true;
      _strokes.add([_inside(event.localPosition)]);
    });
  }

  void _move(PointerMoveEvent event) {
    if (!_drawing) return;
    setState(() => _strokes.last.add(_inside(event.localPosition)));
  }

  void _finish() {
    if (!_drawing) return;
    _drawing = false;
    final generation = ++_generation;
    final strokes = [for (final stroke in _strokes) List<Offset>.of(stroke)];
    widget.encode(strokes, _size).then((url) {
      if (mounted && generation == _generation) widget.onChanged(url);
    });
  }

  void _clear() {
    _generation++;
    setState(() {
      _strokes.clear();
      _drawing = false;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: widget.enabled ? 1 : 0.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              key: SignaturePad.surfaceKey,
              height: SignaturePad.height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _size = Size(constraints.maxWidth, constraints.maxHeight);
                  return RawGestureDetector(
                    gestures: {
                      EagerGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            EagerGestureRecognizer
                          >(EagerGestureRecognizer.new, (instance) {}),
                    },
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _down,
                      onPointerMove: _move,
                      onPointerUp: (_) => _finish(),
                      onPointerCancel: (_) => _finish(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            painter: _PadPainter(
                              _strokes,
                              _strokes.fold<int>(0, (n, s) => n + s.length),
                            ),
                          ),
                          if (_isEmpty)
                            Center(
                              child: Text(
                                'Draw your signature here',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          TextButton.icon(
            onPressed: widget.enabled && !_isEmpty ? _clear : null,
            icon: const Icon(LucideIcons.eraser, size: 14),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _PadPainter extends CustomPainter {
  _PadPainter(this.strokes, this.points);

  final SignatureStrokes strokes;

  /// How many points there were when this was built; the strokes list is
  /// mutated in place, so this is what tells a repaint it has something new.
  final int points;

  @override
  void paint(Canvas canvas, Size size) => _paintStrokes(canvas, strokes);

  @override
  bool shouldRepaint(_PadPainter old) =>
      old.points != points || old.strokes != strokes;
}
