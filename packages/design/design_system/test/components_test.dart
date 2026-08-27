@Tags(['widget'])
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeykBadge', () {
    testWidgets('draws nothing at zero', (tester) async {
      await tester.pumpWidget(
        PeykTheme.wrap(child: const PeykBadge(count: 0)),
      );

      expect(find.text('0'), findsNothing);
    });

    // The plural rule is the component's, not the caller's. Fourteen
    // presentation packages each spelling this out would be fourteen chances
    // to get Turkish wrong, where the noun does not take the plural after a
    // number at all.
    testWidgets('announces a count as a sentence, not as a number', (
      tester,
    ) async {
      await tester.pumpWidget(
        PeykTheme.wrap(child: const PeykBadge(count: 3)),
      );

      expect(find.text('3'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(PeykBadge)).label,
        '3 unread',
      );
    });

    testWidgets('says so in Turkish when that is the locale', (tester) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          locale: const Locale('tr'),
          child: const PeykBadge(count: 3),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(PeykBadge)).label,
        '3 okunmamış',
      );
    });
  });

  group('PeykChip', () {
    // Colour is never the only signal. Roughly one courier in twelve cannot
    // tell the success wash from the danger one, and both are chips of the
    // same size in the same place.
    testWidgets('always draws its label, whatever the intent', (tester) async {
      for (final intent in PeykIntent.values) {
        await tester.pumpWidget(
          PeykTheme.wrap(
            child: PeykChip(label: 'status.${intent.name}', intent: intent),
          ),
        );

        expect(find.text('status.${intent.name}'), findsOneWidget);
      }
    });
  });

  group('PeykButton', () {
    testWidgets('a busy button refuses the second tap', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        PeykTheme.wrap(
          child: PeykButton(
            label: 'shipments.scan',
            busy: true,
            onPressed: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(PeykButton), warnIfMissed: false);

      expect(taps, 0);
    });

    testWidgets('a busy button says it is busy out loud', (tester) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: PeykButton(
            label: 'shipments.scan',
            busy: true,
            onPressed: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(PeykButton)).label,
        contains('Loading'),
      );
    });

    testWidgets('a button with nothing to do is disabled', (tester) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: const PeykButton(label: 'shipments.scan', onPressed: null),
        ),
      );

      expect(
        tester.getSemantics(find.byType(PeykButton)),
        isSemantics(isEnabled: false, isButton: true),
      );
    });
  });

  group('PeykOptionRow', () {
    // Three signals for one state: the wash, the word, and the semantics flag.
    // The flag alone is not announced by every screen reader on every
    // platform, and the wash alone is a colour.
    testWidgets('a chosen option is marked three ways', (tester) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: PeykOptionRow(
            label: 'settings.theme.dark',
            selected: true,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Selected'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(PeykOptionRow)),
        isSemantics(isSelected: true),
      );
    });

    // A screen passes null while a write is in flight rather than hiding the
    // rows. The row has to report that state to a screen reader too, or the
    // only signal that a tap did nothing is that nothing happened.
    testWidgets('an option with nothing to do reports itself disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: const PeykOptionRow(
            label: 'settings.theme.dark',
            selected: false,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(PeykOptionRow)),
        isSemantics(isEnabled: false),
      );
    });
  });

  group('PeykFailureView', () {
    testWidgets('offers no retry when trying again is not the answer', (
      tester,
    ) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: const PeykFailureView(message: 'This account is not active.'),
        ),
      );

      expect(find.text('This account is not active.'), findsOneWidget);
      expect(find.byType(PeykButton), findsNothing);
    });

    testWidgets('offers one when it is', (tester) async {
      var retries = 0;

      await tester.pumpWidget(
        PeykTheme.wrap(
          child: PeykFailureView(
            message: 'No signal.',
            onRetry: () => retries++,
          ),
        ),
      );
      await tester.tap(find.text('Try again'));

      expect(retries, 1);
    });
  });

  group('PeykEmptyView', () {
    // An empty list and a failed read look identical on a screen that draws
    // neither. A courier who thinks the manifest failed will pull over.
    testWidgets('says something rather than showing a blank', (tester) async {
      await tester.pumpWidget(PeykTheme.wrap(child: const PeykEmptyView()));

      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('prefers what the caller knows about this emptiness', (
      tester,
    ) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: const PeykEmptyView(message: 'No shipments left today.'),
        ),
      );

      expect(find.text('No shipments left today.'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsNothing);
    });
  });
}
