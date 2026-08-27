import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

import 'peyk_text.dart';
import 'peyk_theme.dart';

/// A small labelled mark carrying one intent.
///
/// What a status becomes on a screen. The mapping from a feature's sealed
/// state to a [PeykIntent] stays in that feature's presentation package — a
/// chip that took a `ShipmentStatus` would be a design system that had learnt
/// what a shipment is.
///
/// The colour is never the only signal. [label] is always drawn, because a
/// green dot and a red dot are the same dot to a large minority of couriers.
final class PeykChip extends StatelessWidget {
  /// Creates a chip.
  const PeykChip({
    required this.label,
    this.intent = PeykIntent.neutral,
    super.key,
  });

  /// What it says. Already resolved.
  final String label;

  /// What it means.
  final PeykIntent intent;

  @override
  Widget build(BuildContext context) {
    final colors = PeykTheme.of(context).palette.of(intent);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PeykSpacing.sm,
        vertical: PeykSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(PeykRadius.pill),
      ),
      child: PeykText.caption(label, intent: intent),
    );
  }
}
