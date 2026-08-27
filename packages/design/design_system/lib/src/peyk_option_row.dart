import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

import 'l10n/peyk_system_localizations.dart';
import 'peyk_gap.dart';
import 'peyk_gap_size.dart';
import 'peyk_text.dart';
import 'peyk_theme.dart';

/// One choice in a group of mutually exclusive ones.
///
/// The selected state is carried three ways on purpose: a filled wash, a mark,
/// and `Semantics(selected:)` together with the word "Selected" from this
/// package's own localisation. Colour alone is not a signal, and
/// `Semantics.selected` alone is not announced by every screen reader on every
/// platform.
final class PeykOptionRow extends StatelessWidget {
  /// Creates a choice.
  const PeykOptionRow({
    required this.label,
    required this.selected,
    this.onTap,
    super.key,
  });

  /// What it says. Already resolved.
  final String label;

  /// Whether this is the current choice.
  final bool selected;

  /// What choosing it does, or null while a write is in flight.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = PeykTheme.of(context).palette;
    final strings = PeykSystemLocalizations.of(context);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      enabled: onTap != null,
      button: true,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Material(
          color: selected ? palette.primaryMuted : palette.surface,
          borderRadius: BorderRadius.circular(PeykRadius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(PeykRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PeykSpacing.lg,
                vertical: PeykSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(child: PeykText.body(label)),
                  if (selected) ...[
                    const PeykGap.horizontal(PeykGapSize.betweenLines),
                    ExcludeSemantics(child: PeykText.caption(strings.selected)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
