import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

import 'peyk_gap.dart';
import 'peyk_gap_size.dart';
import 'peyk_intent.dart';
import 'peyk_text.dart';
import 'peyk_theme.dart';
import 'peyk_type_style.dart';

/// The one text field in the workspace.
///
/// It exists because the alternative was worse than a missing component: the
/// delivery screen was drawing a bare `EditableText` with a hand-built
/// `TextEditingController`, a `FocusNode` neither disposed, and a hard-coded
/// black cursor that vanished on a dark palette. A screen reaching that far
/// down is a screen that has to get accessibility, theming and lifecycle right
/// on its own, fourteen times over.
///
/// The controller is owned here. A caller passes the current value and a
/// callback, which is the same shape every other component in this package
/// has — and it means a screen cannot leak one.
final class PeykTextField extends StatefulWidget {
  /// Creates a field labelled [label], showing [value].
  const PeykTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.error,
    this.enabled = true,
    super.key,
  });

  /// What the field is called. Already resolved, and always drawn: a field
  /// whose only label is its placeholder loses that label the moment somebody
  /// types.
  final String label;

  /// What is in it.
  final String value;

  /// Called on every keystroke.
  final ValueChanged<String> onChanged;

  /// A placeholder shown while it is empty. Already resolved.
  final String? hint;

  /// What is wrong with the current value, if anything. Already resolved.
  final String? error;

  /// Whether it can be typed in.
  final bool enabled;

  @override
  State<PeykTextField> createState() => _PeykTextFieldState();
}

class _PeykTextFieldState extends State<PeykTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(PeykTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only when the value genuinely changed underneath us. Assigning on every
    // rebuild would move the caret to the end on every keystroke, which is the
    // classic controlled-text-field bug and is invisible until somebody edits
    // the middle of a name.
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = PeykTheme.of(context).palette;
    final error = widget.error;
    final border = error == null
        ? palette.outline
        : palette.colorsFor(PeykIntent.danger).border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PeykText.label(widget.label),
        const PeykGap.vertical(PeykGapSize.tight),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          style: PeykTypeScale.body.toTextStyle(palette.onSurface),
          cursorColor: palette.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: PeykTypeScale.body.toTextStyle(palette.onSurfaceMuted),
            filled: true,
            fillColor: palette.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: PeykSpacing.md,
              vertical: PeykSpacing.md,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PeykRadius.sm),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PeykRadius.sm),
              borderSide: BorderSide(color: palette.focus, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PeykRadius.sm),
              borderSide: BorderSide(color: border),
            ),
          ),
        ),
        // The error is a live region, so it is announced when it appears
        // rather than only when somebody navigates back to the field.
        if (error != null) ...[
          const PeykGap.vertical(PeykGapSize.tight),
          Semantics(
            liveRegion: true,
            child: PeykText.caption(error, intent: PeykIntent.danger),
          ),
        ],
      ],
    );
  }
}
