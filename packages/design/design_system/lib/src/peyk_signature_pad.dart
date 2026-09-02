import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

import 'l10n/peyk_system_localizations.dart';
import 'peyk_signature_controller.dart';
import 'peyk_theme.dart';

/// A surface somebody signs with a finger.
///
/// The only component in this package that produces an image rather than
/// reading one, and the only one whose output a feature stores. Everything it
/// knows is in [controller]; this widget is the gesture and the paint.
///
/// **Pointer events rather than a pan gesture, and it matters.** A
/// `GestureDetector`'s drag enters the gesture arena, where an ancestor
/// `Scrollable` beats it — so a pad inside a list would scroll the list
/// instead of drawing, and only on the vertical strokes, which is the kind of
/// defect that reaches a courier rather than a test. A `Listener` is outside
/// the arena and always gets the events; the no-op drag callbacks beneath it
/// are what stop an ancestor claiming the same drag and scrolling underneath
/// the ink.
final class PeykSignaturePad extends StatelessWidget {
  /// Creates a pad over [controller].
  const PeykSignaturePad({required this.controller, super.key});

  /// Where the ink goes.
  final PeykSignatureController controller;

  @override
  Widget build(BuildContext context) {
    final palette = PeykTheme.of(context).palette;

    return Semantics(
      label: PeykSystemLocalizations.of(context).signatureArea,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          border: Border.all(color: palette.outline),
          borderRadius: BorderRadius.circular(PeykRadius.sm),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            controller.laidOutWithin(constraints);

            return GestureDetector(
              // Claims the drag so that an ancestor scrollable cannot. The
              // callbacks are empty on purpose: the Listener below is what
              // actually draws, and it gets the events either way.
              onVerticalDragUpdate: (_) {},
              onHorizontalDragUpdate: (_) {},
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) =>
                    controller.beginStroke(event.localPosition),
                onPointerMove: (event) =>
                    controller.extendStroke(event.localPosition),
                child: CustomPaint(
                  painter: _SignaturePainter(
                    controller: controller,
                    colour: palette.onSurface,
                  ),
                  size: Size.infinite,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Paints whatever the controller currently holds.
///
/// It repaints on the controller's notification rather than on a rebuild of
/// the pad: `repaint` takes the `Listenable`, so a stroke in progress redraws
/// the canvas without rebuilding the widget tree above it.
final class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.controller, required this.colour})
    : super(repaint: controller);

  final PeykSignatureController controller;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) => controller.paintOn(canvas, colour);

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) =>
      oldDelegate.controller != controller || oldDelegate.colour != colour;
}
