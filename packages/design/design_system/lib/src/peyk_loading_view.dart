import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

import 'l10n/peyk_system_localizations.dart';
import 'peyk_theme.dart';

/// What a screen shows while its first read is in flight.
///
/// A screen reader hears the word "Loading" rather than nothing, which is what
/// a bare indicator amounts to. The word comes from this package's own
/// localisation for the reason §4.1 of CLAUDE.md splits the two `gen-l10n`
/// sites: it is a sentence about a component, not about the product.
final class PeykLoadingView extends StatelessWidget {
  /// Creates the view.
  const PeykLoadingView({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: PeykSystemLocalizations.of(context).loading,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(PeykSpacing.xl),
        child: CircularProgressIndicator(
          color: PeykTheme.of(context).palette.primary,
        ),
      ),
    ),
  );
}
