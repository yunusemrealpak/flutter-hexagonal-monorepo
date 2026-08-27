import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

import 'l10n/peyk_system_localizations.dart';
import 'peyk_text.dart';
import 'peyk_text_tone.dart';
import 'peyk_theme.dart';

/// A count, drawn as a filled disc.
///
/// Renders nothing at all when [count] is zero. A badge showing "0" is a badge
/// telling somebody they have something.
///
/// The accessible label comes from this package's own localisation rather than
/// from the app's catalogue, and that is the split §4.1 of CLAUDE.md draws
/// between the two `gen-l10n` sites: "3 unread" is a sentence about a
/// component, and Turkish and English disagree about what happens to the noun
/// after the number. A caller supplying that string would be fourteen callers
/// each getting the plural rule wrong.
final class PeykBadge extends StatelessWidget {
  /// Creates a badge showing [count].
  const PeykBadge({required this.count, super.key});

  /// How many. Zero draws nothing.
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }

    final palette = PeykTheme.of(context).palette;

    return Semantics(
      label: PeykSystemLocalizations.of(context).unreadCount(count),
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minWidth: PeykSpacing.xl),
          padding: const EdgeInsets.symmetric(horizontal: PeykSpacing.sm),
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(PeykRadius.pill),
          ),
          child: PeykText.caption(
            '$count',
            tone: PeykTextTone.onPrimary,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
