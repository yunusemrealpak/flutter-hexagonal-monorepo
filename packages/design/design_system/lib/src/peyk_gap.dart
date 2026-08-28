import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

import 'peyk_gap_size.dart';

/// A fixed gap from the spacing scale.
///
/// Two constructors rather than one that reads the enclosing `Flex`: a widget
/// that inferred its axis would silently become a zero-height box the day
/// somebody moved it into a `Stack`, and the failure would look like a
/// spacing bug rather than a misplaced widget.
final class PeykGap extends StatelessWidget {
  /// A gap between two things stacked on top of each other.
  const PeykGap.vertical(this.size, {super.key}) : _vertical = true;

  /// A gap between two things side by side.
  const PeykGap.horizontal(this.size, {super.key}) : _vertical = false;

  /// Which step of the scale, said as what the distance means.
  final PeykGapSize size;

  /// [size] in logical pixels.
  static double pixels(PeykGapSize size) => switch (size) {
    PeykGapSize.tight => PeykSpacing.xs,
    PeykGapSize.betweenLines => PeykSpacing.sm,
    PeykGapSize.betweenRows => PeykSpacing.lg,
    PeykGapSize.betweenGroups => PeykSpacing.xl,
  };

  final bool _vertical;

  @override
  Widget build(BuildContext context) {
    final extent = pixels(size);
    return SizedBox(
      height: _vertical ? extent : null,
      width: _vertical ? null : extent,
    );
  }
}
