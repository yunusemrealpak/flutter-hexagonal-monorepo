import 'package:flutter/widgets.dart';

import 'peyk_gap.dart';
import 'peyk_gap_size.dart';
import 'peyk_text.dart';

/// A titled group of rows.
///
/// The vertical rhythm is here rather than in each screen: one step between
/// the heading and the group, one step between the rows. Fourteen screens
/// choosing their own would be fourteen screens that do not line up when
/// somebody puts two of them side by side on a dispatcher's tablet.
final class PeykSection extends StatelessWidget {
  /// Creates a section headed [title].
  const PeykSection({
    required this.title,
    required this.children,
    super.key,
  });

  /// The heading. Already resolved.
  final String title;

  /// What is in it.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(header: true, child: PeykText.title(title)),
      const PeykGap.vertical(PeykGapSize.betweenLines),
      for (final (index, child) in children.indexed) ...[
        if (index > 0) const PeykGap.vertical(PeykGapSize.betweenLines),
        child,
      ],
    ],
  );
}
