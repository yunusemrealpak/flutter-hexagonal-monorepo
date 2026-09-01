import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

import 'peyk_gap.dart';
import 'peyk_gap_size.dart';
// Imported for the doc reference below: [PeykOptionRow] is the component this
// one is deliberately not.
import 'peyk_option_row.dart';
import 'peyk_text.dart';
import 'peyk_theme.dart';

/// One thing that is on or off.
///
/// **Not a [PeykOptionRow] with two positions**, and the difference is not
/// cosmetic. That component declares `Semantics(inMutuallyExclusiveGroup: true,
/// selected: …)` — a screen reader announces it as one choice among several,
/// and moving between them is navigating a group. A switch is a single control
/// whose state is toggled, which is what `Semantics(toggled: …)` says. Somebody
/// who cannot see the screen is told two different things by the two widgets,
/// so reusing one for the other would be a lie told only to the people least
/// able to check it.
///
/// [description] is where the explanation goes, and having a slot for it is
/// half the reason this component exists. A permission a person is about to
/// grant needs its reason next to the control, not on a screen before it: the
/// operating system's own prompt appears immediately after the tap, and by
/// then whatever was said elsewhere is gone.
///
/// A null [onChanged] disables the row rather than removing it, for the reason
/// the settings screen gives about its choices: a control that vanished for the
/// duration of a write would flicker on every tap, and somebody would tap the
/// same thing twice because the first tap left no trace.
final class PeykSwitchRow extends StatelessWidget {
  /// Creates a switch row.
  const PeykSwitchRow({
    required this.label,
    required this.value,
    this.description,
    this.onChanged,
    super.key,
  });

  /// What it says. Already resolved.
  final String label;

  /// Why somebody would want it on. Already resolved, and optional — a switch
  /// whose label says everything does not need a sentence under it.
  final String? description;

  /// Whether it is currently on.
  final bool value;

  /// What changing it does, or null while a write is in flight.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = PeykTheme.of(context).palette;
    final explanation = description;
    final change = onChanged;

    return Semantics(
      toggled: value,
      enabled: change != null,
      child: Opacity(
        opacity: change == null ? 0.5 : 1,
        child: Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(PeykRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PeykSpacing.lg,
              vertical: PeykSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PeykText.body(label),
                      if (explanation != null) ...[
                        const PeykGap.vertical(PeykGapSize.betweenLines),
                        PeykText.caption(explanation),
                      ],
                    ],
                  ),
                ),
                const PeykGap.horizontal(PeykGapSize.betweenLines),
                // The switch carries no semantics of its own: the row above
                // already announces the state, and a nested toggle would make
                // a screen reader read it twice.
                ExcludeSemantics(
                  child: Switch(value: value, onChanged: change),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
