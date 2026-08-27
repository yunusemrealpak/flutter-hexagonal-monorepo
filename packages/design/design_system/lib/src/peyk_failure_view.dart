import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

import 'l10n/peyk_system_localizations.dart';
import 'peyk_button.dart';
import 'peyk_gap.dart';
import 'peyk_text.dart';

/// What a screen shows when a read failed.
///
/// [message] is a sentence the feature produced by exhausting its own sealed
/// failure type — every presentation package in this workspace has a
/// `describe` for exactly that. This component draws it and offers the retry;
/// it never inspects it, and it has no idea which failure it is looking at.
///
/// The retry label is this package's, and its absence is the caller's
/// decision: a failure nothing can be done about should not offer a button
/// that does nothing.
final class PeykFailureView extends StatelessWidget {
  /// Creates the view.
  const PeykFailureView({required this.message, this.onRetry, super.key});

  /// What went wrong, in words a person can act on. Already resolved.
  final String message;

  /// What trying again does, or null when trying again is not the answer.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(PeykSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: PeykText.body(
              message,
              intent: PeykIntent.danger,
              textAlign: TextAlign.center,
            ),
          ),
          if (onRetry case final VoidCallback onRetry) ...[
            const PeykGap.vertical(PeykSpacing.lg),
            PeykButton(
              label: PeykSystemLocalizations.of(context).retry,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    ),
  );
}
