import 'package:flutter/widgets.dart';

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

  /// How large, in logical pixels. A `PeykSpacing` value.
  final double size;

  final bool _vertical;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _vertical ? size : null,
    width: _vertical ? null : size,
  );
}
