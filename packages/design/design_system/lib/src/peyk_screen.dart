import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

import 'peyk_text.dart';
import 'peyk_theme.dart';

/// The frame every screen in the product is drawn inside.
///
/// It owns the two things that must not vary: the title bar and the margin
/// between the screen's edge and its content. [scrollable] is a parameter
/// rather than a caller's `SingleChildScrollView`, because a screen that
/// forgets it overflows only on a small phone with large text — which is the
/// device the courier app is actually used on.
final class PeykScreen extends StatelessWidget {
  /// Creates a screen titled [title].
  const PeykScreen({
    required this.title,
    required this.body,
    this.actions = const [],
    this.scrollable = false,
    super.key,
  });

  /// What the title bar says. Already resolved.
  final String title;

  /// What is on it.
  final Widget body;

  /// Controls in the title bar, right-aligned.
  final List<Widget> actions;

  /// Whether [body] should scroll when it is taller than the window.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final palette = PeykTheme.of(context).palette;
    const margin = EdgeInsets.all(PeykSpacing.lg);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: palette.surface,
        foregroundColor: palette.onSurface,
        title: PeykText.title(title, maxLines: 1),
        actions: actions,
      ),
      body: SafeArea(
        child: scrollable
            ? SingleChildScrollView(padding: margin, child: body)
            : Padding(padding: margin, child: body),
      ),
    );
  }
}
