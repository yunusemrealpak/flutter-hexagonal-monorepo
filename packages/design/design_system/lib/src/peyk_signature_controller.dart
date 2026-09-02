import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The ink on a `PeykSignaturePad`, and the only way to get it off again.
///
/// A controller rather than a callback per stroke, because three separate
/// things need the same ink and none of them is the pad: the surface draws it,
/// a *clear* button empties it, and a *done* button has to know whether there
/// is any before it offers itself. A pad that reported strokes upward would
/// make every host reassemble the list to answer the second and third.
///
/// **Rasterising lives here rather than in the pad**, because the geometry
/// does. The pad tells this object what size it was given and nothing else;
/// [render] is then a pure function of the strokes and that size, and can be
/// called from a button that is nowhere near the surface.
///
/// The bytes come out black on white regardless of the palette in force, and
/// that is the one decision in this file that is not a taste question. A proof
/// captured at night on the dark palette and stored as white ink on nothing is
/// a proof that vanishes the first time somebody prints it.
final class PeykSignatureController extends ChangeNotifier {
  /// Creates an empty controller.
  PeykSignatureController();

  /// How wide the line is, in logical pixels.
  ///
  /// Here rather than in `design_tokens`: the tokens package holds decisions
  /// that repeat across components — five colour triples, seven distances —
  /// and a stroke width used by exactly one surface is not one of them.
  static const double strokeWidth = 2.5;

  /// How many image pixels each logical pixel becomes in [render].
  ///
  /// A signature is drawn on a 300-point strip and read on a desk, so
  /// rendering at the size it was drawn produces a proof nobody can enlarge.
  /// Three is the smallest factor that survives being printed.
  static const double renderScale = 3;

  static const Color _ink = Color(0xFF000000);
  static const Color _ground = Color(0xFFFFFFFF);

  final List<List<Offset>> _strokes = [];
  Size _surface = Size.zero;

  /// Whether anything has been drawn.
  bool get isEmpty => _strokes.isEmpty;

  /// Throws the ink away.
  ///
  /// Silent when there was none. A notification per press of a button that
  /// changed nothing is how a rebuild ends up happening inside a frame that
  /// had no reason to run.
  void clear() {
    if (_strokes.isEmpty) return;
    _strokes.clear();
    notifyListeners();
  }

  /// Renders the ink as a PNG, or `null` when there is none.
  ///
  /// `null` rather than a transparent image, because an empty capture is what
  /// a screen produces when somebody presses *done* without drawing — and a
  /// caller that turned that into evidence would be putting a proof in the
  /// record that proves nothing. `SignatureCapture.of` refuses it a layer
  /// later; this refuses it before anybody is told they signed.
  Future<Uint8List?> render() async {
    if (_strokes.isEmpty || _surface.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(renderScale)
      ..drawRect(Offset.zero & _surface, Paint()..color = _ground);
    paintOn(canvas, _ink);
    final picture = recorder.endRecording();

    final image = await picture.toImage(
      (_surface.width * renderScale).round(),
      (_surface.height * renderScale).round(),
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  /// Draws the strokes onto [canvas] in [colour].
  ///
  /// Public because two things paint the same ink and they disagree about the
  /// colour: the surface draws it in the palette's foreground so it looks like
  /// the screen around it, and [render] draws it black so the proof does not
  /// depend on which palette a courier had on at the door.
  void paintOn(Canvas canvas, Color colour) {
    final brush = Paint()
      ..color = colour
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.length == 1) {
        // A stroke of one point is a dot somebody deliberately made — a
        // `Path` with no segment draws nothing at all, which would lose it.
        canvas.drawCircle(
          stroke.first,
          strokeWidth / 2,
          Paint()..color = colour,
        );
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, brush);
    }
  }

  /// Records the room the surface was given.
  ///
  /// Called from the pad's layout, and it takes the constraints rather than a
  /// size because that is what the pad has in hand. It does not notify: the
  /// size is what the ink is drawn *in* rather than part of it, and notifying
  /// from a build would schedule a rebuild inside the frame that produced it.
  @internal
  void laidOutWithin(BoxConstraints constraints) =>
      _surface = constraints.biggest;

  /// Starts a stroke at [point].
  @internal
  void beginStroke(Offset point) {
    _strokes.add([point]);
    notifyListeners();
  }

  /// Continues the stroke in progress.
  ///
  /// Ignores a move with no stroke open, which is what arrives when a pointer
  /// enters the surface having gone down outside it.
  @internal
  void extendStroke(Offset point) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(point);
    notifyListeners();
  }
}
