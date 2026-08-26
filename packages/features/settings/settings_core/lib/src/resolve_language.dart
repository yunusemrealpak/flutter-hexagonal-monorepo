import 'package:settings_api/settings_api.dart';

/// Picks the language to actually speak, out of the ones this build ships.
///
/// A stored preference and an available translation are two different facts,
/// and this is where they meet. Somebody who chose `en-GB` on a build that
/// shipped it keeps it; on a build that ships only `en` they get `en`, which
/// is the same language spelled for another region; on a build that ships
/// neither they get the fallback rather than an untranslated screen.
///
/// **Not a `UseCase`.** `UseCase.call` returns a `Future` because almost every
/// intention in the product touches something outside itself, and this one
/// touches nothing: it is a decision over two values already in hand. Wrapping
/// it would make every caller `await` something that never suspends, which is
/// a cost paid at each call site for a uniformity nobody reads.
///
/// **Not in `settings_api`.** Which languages a build ships changes with every
/// release. A rule that moves that often is a deployment fact, and putting it
/// in the contract would make it something other features could come to depend
/// on.
final class ResolveLanguage {
  /// Creates the resolver over what this build actually has.
  const ResolveLanguage({required this._available, required this._fallback});

  final Set<LanguageTag> _available;
  final LanguageTag _fallback;

  /// The language to speak to somebody who asked for [wanted].
  LanguageTag call(LanguageTag wanted) {
    if (_available.contains(wanted)) {
      return wanted;
    }

    for (final candidate in _available) {
      if (candidate.language == wanted.language) {
        return candidate;
      }
    }

    return _fallback;
  }
}
