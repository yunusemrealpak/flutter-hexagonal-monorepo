@Tags(['widget'])
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Draws a line across [pad], the way a finger would.
///
/// Several moves rather than one, because a signature is a polyline and a
/// single-step drag would also pass against an implementation that only ever
/// keeps the last point.
Future<void> sign(WidgetTester tester, Finder pad) async {
  final origin = tester.getTopLeft(pad) + const Offset(20, 20);
  final gesture = await tester.startGesture(origin);
  for (var step = 1; step <= 5; step++) {
    await gesture.moveTo(origin + Offset(step * 20.0, step * 8.0));
  }
  await gesture.up();
  await tester.pump();
}

/// Lets real asynchronous work finish, pumping between attempts.
///
/// **Every test in this file that reaches the engine needs this, and the
/// reason is worth writing down.** `Picture.toImage` and
/// `instantiateImageCodec` complete on the engine rather than on the Dart
/// event loop, and a `testWidgets` body runs in fake async where that never
/// gets a turn. The work does complete — but the test then hangs forever
/// waiting on a port fake async will not drain, which looks exactly like an
/// implementation bug and is not one. `runAsync` is the window in which the
/// engine is allowed to answer.
///
/// The two have to alternate, and that is the part that is not obvious. No
/// widget advances inside `runAsync` — `pump` throws there — so a route
/// leaving the screen cannot finish while the window is open, and a poll that
/// waited for [until] inside one would always run to its limit. A window, then
/// a settle, then look again.
Future<void> settleEngine(
  WidgetTester tester, {
  required bool Function() until,
}) async {
  for (var round = 0; !until() && round < 100; round++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

/// The colour of one pixel of a rendered PNG.
///
/// Call it inside a `runAsync` window, for the reason above.
Future<Color> pixelOf(Uint8List png, int x, int y) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  // No format: raw RGBA is the default, and naming it trips
  // `avoid_redundant_argument_values`.
  final data = await frame.image.toByteData();
  final bytes = data!.buffer.asUint8List();
  final offset = (y * frame.image.width + x) * 4;
  frame.image.dispose();
  codec.dispose();
  return Color.fromARGB(
    bytes[offset + 3],
    bytes[offset],
    bytes[offset + 1],
    bytes[offset + 2],
  );
}

void main() {
  Widget padIn({
    required PeykSignatureController controller,
    PeykPalette palette = PeykPalette.light,
  }) => PeykTheme.wrap(
    palette: palette,
    child: Center(
      child: SizedBox(
        width: 300,
        height: 200,
        child: PeykSignaturePad(controller: controller),
      ),
    ),
  );

  PeykButton buttonSaying(WidgetTester tester, String label) =>
      tester.widget<PeykButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(PeykButton),
        ),
      );

  group('PeykSignatureController', () {
    test('a pad nobody has drawn on holds no ink', () {
      final controller = PeykSignatureController();
      addTearDown(controller.dispose);

      expect(controller.isEmpty, isTrue);
    });

    testWidgets('a drag leaves ink', (tester) async {
      final controller = PeykSignatureController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(padIn(controller: controller));
      await sign(tester, find.byType(PeykSignaturePad));

      expect(controller.isEmpty, isFalse);
    });

    testWidgets('clear takes it away, and says so', (tester) async {
      final controller = PeykSignatureController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await tester.pumpWidget(padIn(controller: controller));
      await sign(tester, find.byType(PeykSignaturePad));
      final drawn = notifications;
      controller.clear();

      expect(controller.isEmpty, isTrue);
      expect(notifications, greaterThan(drawn));
    });

    testWidgets('clearing an empty pad notifies nobody', (tester) async {
      // A notification per press of a button that changed nothing is how a
      // rebuild ends up scheduled inside a frame that had no reason to run.
      final controller = PeykSignatureController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await tester.pumpWidget(padIn(controller: controller));
      controller.clear();

      expect(notifications, 0);
    });

    test('render answers nothing while there is nothing to render', () async {
      final controller = PeykSignatureController();
      addTearDown(controller.dispose);

      expect(await controller.render(), isNull);
    });

    testWidgets('render answers a PNG', (tester) async {
      final controller = PeykSignatureController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(padIn(controller: controller));
      await sign(tester, find.byType(PeykSignaturePad));
      final png = await tester.runAsync(controller.render);

      expect(png, isNotNull);
      // The magic number rather than a length: a non-empty list of bytes is
      // what a wrong encoder produces too.
      expect(png!.take(4), [0x89, 0x50, 0x4E, 0x47]);
    });

    testWidgets('the ink is black on white whatever the palette is', (
      tester,
    ) async {
      // The one thing about this rendering that is not a taste question. A
      // proof captured at night on the dark palette and stored as white ink on
      // nothing is a proof that disappears the first time somebody prints it.
      final controller = PeykSignatureController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        padIn(controller: controller, palette: PeykPalette.dark),
      );
      await sign(tester, find.byType(PeykSignaturePad));
      final corner = await tester.runAsync(() async {
        final png = await controller.render();
        return pixelOf(png!, 2, 2);
      });

      expect(corner, const Color(0xFFFFFFFF));
    });
  });

  group('PeykSignaturePanel', () {
    /// Pumps a panel and reports what it hands back.
    ///
    /// Lists rather than single values, so that "called once" is assertable —
    /// a panel that reported twice would be a screen popped twice.
    Future<(List<Uint8List>, List<void>)> panel(WidgetTester tester) async {
      final signed = <Uint8List>[];
      final cancelled = <void>[];

      await tester.pumpWidget(
        PeykTheme.wrap(
          child: PeykSignaturePanel(
            title: 'Ask them to sign',
            onSigned: signed.add,
            onCancelled: () => cancelled.add(null),
          ),
        ),
      );

      expect(find.text('Ask them to sign'), findsOneWidget);
      return (signed, cancelled);
    }

    testWidgets('cancelling reports it, and hands nothing over', (
      tester,
    ) async {
      final (signed, cancelled) = await panel(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelled, hasLength(1));
      expect(signed, isEmpty);
    });

    testWidgets('done is not offered until something is drawn', (tester) async {
      // The empty capture `SignatureCapture.of` refuses, refused one layer
      // earlier so that nobody is told their signature was rejected after they
      // thought they had given one.
      await panel(tester);

      expect(buttonSaying(tester, 'Done').onPressed, isNull);
      expect(buttonSaying(tester, 'Clear').onPressed, isNull);

      await sign(tester, find.byType(PeykSignaturePad));

      expect(buttonSaying(tester, 'Done').onPressed, isNotNull);
      expect(buttonSaying(tester, 'Clear').onPressed, isNotNull);
    });

    testWidgets('a signature is handed over as bytes', (tester) async {
      final (signed, cancelled) = await panel(tester);

      await sign(tester, find.byType(PeykSignaturePad));
      await tester.tap(find.text('Done'));
      await settleEngine(tester, until: () => signed.isNotEmpty);

      expect(signed, hasLength(1));
      expect(signed.single.take(4), [0x89, 0x50, 0x4E, 0x47]);
      expect(cancelled, isEmpty);
    });

    testWidgets('clearing disarms done again', (tester) async {
      await panel(tester);

      await sign(tester, find.byType(PeykSignaturePad));
      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(buttonSaying(tester, 'Done').onPressed, isNull);
    });

    testWidgets('the panel closes nothing, because it cannot', (tester) async {
      // §2.4 and rule A6: no package outside apps/ touches a Navigator. The
      // panel reports and stays; an app pushed it and an app pops it. Asserted
      // rather than described, because the alternative — a component that
      // decides how it is presented — is what the rule exists to prevent.
      final (_, cancelled) = await panel(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelled, hasLength(1));
      expect(find.byType(PeykSignaturePad), findsOneWidget);
    });
  });
}
