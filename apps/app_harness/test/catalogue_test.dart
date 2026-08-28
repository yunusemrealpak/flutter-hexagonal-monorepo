@Tags(['widget'])
library;

import 'package:app_harness/main.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the key manifests are for.
///
/// Every presentation package declares the keys it asks an app to answer, and
/// this is the app answering. A key with nothing behind it is a screen showing
/// `settings.theme.dark` to somebody choosing a palette — a bug that ships
/// looking like a translation that was forgotten, which is exactly how it gets
/// left alone for a release.
///
/// This app is the one that cannot fail it, and saying why is the point of the
/// test existing here at all: `KeyEchoCatalogue` answers every key by
/// definition. What the test asserts is therefore not "the harness is
/// translated" but "the harness resolves every key a mounted feature asks
/// for" — which catches a manifest that names a key no catalogue can even be
/// asked for, and which is the same test the two product apps run against a
/// catalogue that *can* fail it.
void main() {
  const catalogue = KeyEchoCatalogue();

  group('every key a mounted feature asks for resolves', () {
    for (final MapEntry(key: feature, value: keys)
        in harnessStringKeys.entries) {
      test(feature, () {
        for (final key in keys) {
          expect(
            catalogue.resolve(key),
            isNotEmpty,
            reason: '$feature asks for "$key" and nothing answers it',
          );
        }
      });
    }
  });

  group('the manifests themselves', () {
    test('cover every feature this app mounts', () {
      // Fourteen modules and fourteen manifests. A feature mounted without one
      // is a feature whose keys nobody is checking.
      expect(harnessStringKeys, hasLength(harnessModules.length));
    });

    test('name no key twice within a feature', () {
      for (final MapEntry(key: feature, value: keys)
          in harnessStringKeys.entries) {
        expect(keys.toSet(), hasLength(keys.length), reason: feature);
      }
    });

    // The two shipments packages share the status keys by spelling, because a
    // presentation package may not depend on another presentation package.
    // This is where that sharing is visible: the same key, declared twice, and
    // an app answers it once.
    test('the two shipments packages agree about the status keys', () {
      final courier = harnessStringKeys['shipments.courier']!;
      final dispatcher = harnessStringKeys['shipments.dispatcher']!;
      final shared = courier.toSet().intersection(dispatcher.toSet());

      expect(
        shared,
        isEmpty,
        reason:
            'the manifests list their own keys; the status keys are in '
            'ShipmentsDispatcherStrings.statusKeys and are asked for by both',
      );
    });
  });
}
