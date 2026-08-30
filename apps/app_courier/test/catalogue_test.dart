@Tags(['widget'])
library;

import 'package:app_courier/main.dart';
import 'package:flutter_test/flutter_test.dart';

/// The test `app_harness` could not fail.
///
/// The harness answers every key by definition — `KeyEchoCatalogue` returns
/// the key — so its version of this test checks a *manifest*. This one checks
/// a *translation*: 163 sentences in two languages, against the keys twelve
/// presentation packages declare. A key with nothing behind it is a courier
/// looking at `settings.theme.dark` while choosing a palette, and it is the
/// kind of bug that ships looking like a translation somebody forgot.
void main() {
  group('every key a mounted feature asks for has a sentence', () {
    for (final MapEntry(key: feature, value: keys)
        in courierStringKeys.entries) {
      test(feature, () {
        final missing = keys
            .where((key) => !CourierCatalogue.answered.contains(key))
            .toList();

        expect(
          missing,
          isEmpty,
          reason: '$feature asks for keys this app does not answer',
        );
      });
    }
  });

  // The shell's own four. They are not a feature's words — which tabs exist is
  // this app's decision, so what they are called is too — and without this
  // they would be the only strings in the product with nothing asserting they
  // have a translation.
  test('the shell asks for four tab words and gets them', () {
    expect(
      courierShellStringKeys.where(
        (key) => !CourierCatalogue.answered.contains(key),
      ),
      isEmpty,
    );
  });

  // The other direction, and the one nobody writes. A sentence nobody asks for
  // is a translation somebody is paying to maintain in every language the
  // product ships — and the way it happens is a screen being rewritten while
  // its .arb entry stays behind.
  test('every sentence this app carries is asked for', () {
    final asked = {
      ...courierStringKeys.values.expand((keys) => keys),
      ...courierShellStringKeys,
    };
    final unused = CourierCatalogue.answered.difference(asked);

    expect(
      unused,
      isEmpty,
      reason: 'these sentences are translated and never shown',
    );
  });

  // Feature manifests only: the shell's keys are the app's own and are checked
  // above. A count over the union would have made this assertion mean two
  // things and catch neither.
  test('the manifests cover every feature this app mounts', () {
    expect(courierStringKeys, hasLength(courierModules.length));
  });
}
