import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

import 'l10n/peyk_system_localizations.dart';
import 'peyk_text.dart';

/// What a screen shows when the read succeeded and there was nothing in it.
///
/// Its own widget rather than an empty list, because a screen with nothing on
/// it reads as a screen that failed to load — and a courier who thinks the
/// manifest failed to load will pull over and reload it.
final class PeykEmptyView extends StatelessWidget {
  /// Creates the view.
  ///
  /// [message] is what this particular emptiness means — "no shipments left
  /// today" says far more than "nothing here". The default exists so that a
  /// caller with nothing specific to say still gets a sentence rather than a
  /// blank.
  const PeykEmptyView({this.message, super.key});

  /// The line to show. Already resolved. Null for the component's default.
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(PeykSpacing.xl),
      child: PeykText.body(
        message ?? PeykSystemLocalizations.of(context).empty,
        textAlign: TextAlign.center,
      ),
    ),
  );
}
