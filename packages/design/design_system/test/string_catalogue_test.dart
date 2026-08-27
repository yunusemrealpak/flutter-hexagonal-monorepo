@Tags(['widget'])
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A catalogue with two entries, standing in for an app's real one.
final class _TwoEntries implements StringCatalogue {
  const _TwoEntries();

  @override
  String resolve(String key, {Map<String, Object?> arguments = const {}}) =>
      switch (key) {
        'settings.home' => 'Settings',
        'shipments.count' => '${arguments['count']} shipments',
        _ => key,
      };
}

void main() {
  group('KeyEchoCatalogue', () {
    test('answers with the key it was asked for', () {
      expect(
        const KeyEchoCatalogue().resolve('settings.theme.dark'),
        'settings.theme.dark',
      );
    });

    test('shows the arguments a caller passed', () {
      expect(
        const KeyEchoCatalogue().resolve(
          'inbox.unread',
          arguments: {
            'count': 3,
          },
        ),
        'inbox.unread(count=3)',
      );
    });
  });

  group('PeykStrings', () {
    testWidgets('hands a screen the catalogue the app installed', (
      tester,
    ) async {
      late StringCatalogue seen;

      await tester.pumpWidget(
        PeykTheme.wrap(
          catalogue: const _TwoEntries(),
          child: Builder(
            builder: (context) {
              seen = PeykStrings.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen.resolve('settings.home'), 'Settings');
      expect(
        seen.resolve('shipments.count', arguments: {'count': 4}),
        '4 shipments',
      );
    });

    // An app that forgot to install a catalogue has a wiring bug, and the
    // assertion names the fix. In release the same path falls back to
    // KeyEchoCatalogue instead, so the screen shows `settings.home` rather
    // than dying in a van — behaviour a debug-mode test cannot observe, and
    // which is stated in PeykStrings.of rather than asserted here.
    testWidgets('trips an assertion when an app installed none', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              PeykStrings.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
  });
}
