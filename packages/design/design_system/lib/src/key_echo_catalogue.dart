import 'string_catalogue.dart';

/// A catalogue that answers with the key it was asked for.
///
/// It ships here, beside the contract, for the reason §2.2 of
/// docs/DEPENDENCY_RULES.md gives: a fake belongs with the interface it
/// imitates. Two callers want it.
///
/// `app_harness` uses it as its real catalogue. A harness whose job is to
/// prove every feature can be stood up wants to see *which* string each screen
/// asked for; a screen full of finished English would hide a label wired to
/// the wrong key behind a sentence that reads fine.
///
/// A widget test uses it so that an assertion reads `find.text('theme.dark')`
/// — a claim about which string the screen asked for — rather than
/// `find.text('Dark')`, which is a claim about a translation and breaks the
/// day somebody improves the wording.
final class KeyEchoCatalogue implements StringCatalogue {
  /// Creates the catalogue.
  const KeyEchoCatalogue();

  @override
  String resolve(String key, {Map<String, Object?> arguments = const {}}) {
    if (arguments.isEmpty) {
      return key;
    }
    final pairs = arguments.entries.map((e) => '${e.key}=${e.value}');
    return '$key(${pairs.join(', ')})';
  }
}
