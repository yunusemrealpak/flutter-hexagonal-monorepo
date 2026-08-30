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

  group('PeykTextField', () {
    testWidgets('always draws its label, not only its placeholder', (
      tester,
    ) async {
      // A field whose only label is its placeholder loses that label the
      // moment somebody types, and a screen reader never had it at all.
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: PeykTextField(
            label: 'delivery.recipient',
            hint: 'delivery.recipient.hint',
            value: 'Ayşe',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('delivery.recipient'), findsOneWidget);
    });

    testWidgets('reports every keystroke', (tester) async {
      final seen = <String>[];

      await tester.pumpWidget(
        PeykTheme.wrap(
          child: PeykTextField(
            label: 'delivery.recipient',
            value: '',
            onChanged: seen.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Ayşe');

      expect(seen.last, 'Ayşe');
    });

    // The classic controlled-field bug: assigning the controller's text on
    // every rebuild moves the caret to the end on every keystroke, and it is
    // invisible until somebody edits the middle of a name.
    testWidgets('a rebuild with the same value leaves the caret alone', (
      tester,
    ) async {
      Widget field(String value) => PeykTheme.wrap(
        child: PeykTextField(
          label: 'delivery.recipient',
          value: value,
          onChanged: (_) {},
        ),
      );

      await tester.pumpWidget(field('Ayşe Yılmaz'));
      final controller =
          tester.widget<TextField>(find.byType(TextField)).controller!
            ..selection = const TextSelection.collapsed(offset: 4);
      await tester.pump();

      await tester.pumpWidget(field('Ayşe Yılmaz'));

      expect(controller.selection.baseOffset, 4);
    });

    testWidgets('an error is announced when it appears', (tester) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: PeykTextField(
            label: 'delivery.recipient',
            value: '',
            error: 'delivery.recipient.required',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('delivery.recipient.required'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('delivery.recipient.required')),
        isSemantics(isLiveRegion: true),
      );
    });
  });

  group('PeykNavigationBar', () {
    const destinations = [
      PeykNavigationDestination(
        label: 'courier.tab.stops',
        icon: PeykIcon.list,
      ),
      PeykNavigationDestination(label: 'courier.tab.route', icon: PeykIcon.map),
      PeykNavigationDestination(
        label: 'courier.tab.more',
        icon: PeykIcon.more,
      ),
    ];

    Widget bar({
      required ValueChanged<int> onSelected,
      int current = 0,
    }) => PeykTheme.wrap(
      child: Scaffold(
        bottomNavigationBar: PeykNavigationBar(
          destinations: destinations,
          currentIndex: current,
          onSelected: onSelected,
        ),
      ),
    );

    // An icon is never the only signal, for the same reason a chip's colour
    // never is: the bar is used one-handed in a moving van by somebody who
    // learned this app in an afternoon.
    testWidgets('labels every destination, not just the selected one', (
      tester,
    ) async {
      await tester.pumpWidget(bar(onSelected: (_) {}));

      for (final destination in destinations) {
        expect(find.text(destination.label), findsOneWidget);
      }
    });

    testWidgets('reports the index that was tapped', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(bar(onSelected: taps.add));

      await tester.tap(find.text('courier.tab.route'));
      await tester.pumpAndSettle();

      expect(taps, [1]);
    });

    // The re-tap is not a no-op anywhere else in the industry, and this app
    // needs it: tapping the tab you are already on is how a courier three
    // screens deep gets back to the top of that tab. Swallowing it here would
    // make that impossible to implement above.
    testWidgets('reports a tap on the destination already selected', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(bar(current: 1, onSelected: taps.add));

      await tester.tap(find.text('courier.tab.route'));
      await tester.pumpAndSettle();

      expect(taps, [1]);
    });

    testWidgets('says which destination is the current one', (tester) async {
      await tester.pumpWidget(bar(current: 2, onSelected: (_) {}));

      expect(
        tester.getSemantics(find.text('courier.tab.more')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.text('courier.tab.stops')),
        isSemantics(isSelected: false),
      );
    });
  });
}
