@Tags(['widget'])
library;

import 'package:app_dispatcher/main.dart';
import 'package:flutter_test/flutter_test.dart';

/// The test `app_harness` could not fail.
///
/// The harness answers every key by definition — `KeyEchoCatalogue` returns
/// the key — so its version of this test checks a *manifest*. This one checks
/// a *translation*: 163 sentences in two languages, against the keys twelve
/// presentation packages declare. A key with nothing behind it is a dispatcher
/// looking at `settings.theme.dark` while choosing a palette, and it is the
/// kind of bug that ships looking like a translation somebody forgot.
void main() {
  group('every key a mounted feature asks for has a sentence', () {
    for (final MapEntry(key: feature, value: keys)
        in dispatcherStringKeys.entries) {
      test(feature, () {
        final missing = keys
            .where((key) => !DispatcherCatalogue.answered.contains(key))
            .toList();

        expect(
          missing,
          isEmpty,
          reason: '$feature asks for keys this app does not answer',
        );
      });
    }
  });

  // The other direction, and the one nobody writes. A sentence nobody asks for
  // is a translation somebody is paying to maintain in every language the
  // product ships — and the way it happens is a screen being rewritten while
  // its .arb entry stays behind.
  test('every sentence this app carries is asked for', () {
    final asked = dispatcherStringKeys.values.expand((keys) => keys).toSet();
    final unused = DispatcherCatalogue.answered.difference(asked);

    expect(
      unused,
      isEmpty,
      reason: 'these sentences are translated and never shown',
    );
  });

  test('the manifests cover every feature this app mounts', () {
    expect(dispatcherStringKeys, hasLength(dispatcherModules.length));
  });
}
