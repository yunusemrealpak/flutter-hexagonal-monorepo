import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

import 'peyk_gap.dart';
import 'peyk_gap_size.dart';
import 'peyk_text.dart';

/// One line of a list: a title, an optional second line, an optional mark on
/// the right, and optionally something to do when it is tapped.
///
/// The whole row is the target rather than the title, because the target is
/// used in a moving van with one hand.
final class PeykListRow extends StatelessWidget {
  /// Creates a row.
  const PeykListRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  /// The first line. Already resolved.
  final String title;

  /// The second line, if there is one. Already resolved.
  final String? subtitle;

  /// A chip, a badge or an icon on the right.
  final Widget? trailing;

  /// What tapping it does, or null if it does nothing.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: InkWell(
      onTap: onTap,
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
                  PeykText.body(title, maxLines: 2),
                  if (subtitle case final String subtitle) ...[
                    const PeykGap.vertical(PeykGapSize.tight),
                    PeykText.caption(subtitle, maxLines: 2),
                  ],
                ],
              ),
            ),
            if (trailing case final Widget trailing) ...[
              const PeykGap.horizontal(PeykGapSize.betweenLines),
              trailing,
            ],
          ],
        ),
      ),
    ),
  );
}
