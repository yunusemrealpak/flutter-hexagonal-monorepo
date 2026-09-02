import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'l10n/peyk_system_localizations.dart';
import 'peyk_button.dart';
import 'peyk_button_tone.dart';
import 'peyk_gap.dart';
import 'peyk_gap_size.dart';
import 'peyk_screen.dart';
import 'peyk_signature_controller.dart';
import 'peyk_signature_pad.dart';

/// A whole surface for taking a signature: the pad, and the three things
/// somebody can do with it.
///
/// **It occupies a screen rather than sitting in one, and that is not a
/// layout preference.** `PeykSignaturePad` has to own its whole surface —
/// see its own notes on the gesture arena — and every screen in this product
/// that would ask for a signature draws a list. An app pushes this as a route;
/// the pad then has nothing to compete with.
///
/// **It navigates nowhere, and does not close itself.** §2.4 of
/// `docs/DEPENDENCY_RULES.md` gives navigation to the app, and rule `A6`
/// makes that mechanical: no package outside `apps/` may touch a `Navigator`.
/// So this reports [onSigned] and [onCancelled] and the app decides that both
/// mean *pop*. The rule reads as being about destinations, and this is a modal
/// returning a value rather than a screen choosing where to go next — but the
/// alternative to obeying it here is a component that decides how it is
/// presented, which forecloses a dispatcher's desk showing the same pad in a
/// side panel.
///
/// The three actions are this package's words, like the failure view's retry:
/// *clear*, *cancel* and *done* are the same sentence in every product that
/// takes a signature. [title] is the caller's, because what somebody is being
/// asked to sign is not.
final class PeykSignaturePanel extends StatefulWidget {
  /// Creates the panel.
  const PeykSignaturePanel({
    required this.title,
    required this.onSigned,
    required this.onCancelled,
    super.key,
  });

  /// What the person holding the device is being asked to do. Already
  /// resolved.
  final String title;

  /// Hands over what was drawn, as a PNG.
  ///
  /// Called once, and never with an empty capture: *done* is not offered
  /// until there is ink. `SignatureCapture.of` refuses an empty one a layer
  /// later, which is a layer after somebody has been told they signed.
  final void Function(Uint8List ink) onSigned;

  /// Reports that the panel was left with nothing captured.
  final VoidCallback onCancelled;

  @override
  State<PeykSignaturePanel> createState() => _PeykSignaturePanelState();
}

class _PeykSignaturePanelState extends State<PeykSignaturePanel> {
  final PeykSignatureController _controller = PeykSignatureController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykSystemLocalizations.of(context);

    return PeykScreen(
      title: widget.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: PeykSignaturePad(controller: _controller)),
          const PeykGap.vertical(PeykGapSize.betweenRows),
          // Rebuilt on every stroke, because two of the three actions are
          // only offered once there is something to act on.
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => Row(
              children: [
                Expanded(
                  child: PeykButton(
                    label: strings.cancel,
                    onPressed: widget.onCancelled,
                  ),
                ),
                const PeykGap.horizontal(PeykGapSize.betweenRows),
                Expanded(
                  child: PeykButton(
                    label: strings.clear,
                    onPressed: _controller.isEmpty ? null : _controller.clear,
                  ),
                ),
                const PeykGap.horizontal(PeykGapSize.betweenRows),
                Expanded(
                  child: PeykButton(
                    label: strings.done,
                    tone: PeykButtonTone.primary,
                    onPressed: _controller.isEmpty
                        ? null
                        : () => unawaited(_finish()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    final ink = await _controller.render();
    // Null is unreachable while *done* is armed only over ink, and it is
    // still checked: the two facts are guarded in different places and a
    // future change to either should not turn into an empty proof.
    if (ink != null) widget.onSigned(ink);
  }
}
