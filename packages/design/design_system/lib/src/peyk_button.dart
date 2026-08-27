import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

import 'l10n/peyk_system_localizations.dart';
import 'peyk_button_tone.dart';
import 'peyk_gap.dart';
import 'peyk_text.dart';
import 'peyk_text_tone.dart';
import 'peyk_theme.dart';

/// The one button in the workspace.
///
/// [busy] is a state rather than the caller's problem. Every screen that sends
/// something has to stop taking a second tap while the first is in flight, and
/// leaving that to each caller produced, in the phase 6 screens, three
/// different answers to the same question. A busy button is disabled and says
/// so to a screen reader.
final class PeykButton extends StatelessWidget {
  /// Creates a button labelled [label].
  ///
  /// A null [onPressed] disables it. That is Flutter's convention and it is
  /// kept, because a separate `enabled` flag lets the two disagree.
  const PeykButton({
    required this.label,
    required this.onPressed,
    this.tone = PeykButtonTone.secondary,
    this.busy = false,
    super.key,
  });

  /// What it says. Already resolved — a widget never holds a key.
  final String label;

  /// What it does, or null if it cannot be pressed.
  final VoidCallback? onPressed;

  /// How much weight it carries.
  final PeykButtonTone tone;

  /// Whether what it started is still running.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = PeykTheme.of(context).palette;
    final enabled = onPressed != null && !busy;
    final strings = PeykSystemLocalizations.of(context);

    final (background, foreground, border) = switch (tone) {
      PeykButtonTone.primary => (
        palette.primary,
        palette.onPrimary,
        palette.primary,
      ),
      PeykButtonTone.secondary => (
        palette.surface,
        palette.onSurface,
        palette.outline,
      ),
      PeykButtonTone.destructive => (
        palette.surface,
        palette.danger.foreground,
        palette.danger.border,
      ),
    };

    return Semantics(
      button: true,
      enabled: enabled,
      // A busy button reads as "Send, Loading" rather than as an unexplained
      // disabled control. Without this, the only signal that anything is
      // happening is a spinner, which a screen reader does not see.
      label: busy ? '$label, ${strings.loading}' : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(PeykRadius.md),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(PeykRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: PeykSpacing.lg,
                vertical: PeykSpacing.md,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(PeykRadius.md),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy) ...[
                    SizedBox(
                      height: PeykSpacing.lg,
                      width: PeykSpacing.lg,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    ),
                    const PeykGap.horizontal(PeykSpacing.sm),
                  ],
                  PeykText.label(
                    label,
                    tone: tone == PeykButtonTone.primary
                        ? PeykTextTone.onPrimary
                        : PeykTextTone.standard,
                    intent: tone == PeykButtonTone.destructive
                        ? PeykIntent.danger
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
