@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:messaging_presentation/messaging_presentation.dart';
import 'package:messaging_testing/messaging_testing.dart';

/// The fake this feature publishes, driven by the package that consumes it.
///
/// This file is the second consumer of `messaging_testing` — the first is
/// `messaging_core`, which runs the store contract kit — and between them they
/// are the reason messaging has a `_testing` package while the other six light
/// features do not.
Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  late FakeMessagingFacade messaging;
  late ThreadController controller;

  setUp(() {
    messaging = FakeMessagingFacade();
    controller = ThreadController(
      messaging: messaging,
      thread: MessagingFixtures.thread,
      reader: MessagingFixtures.courier,
    );
    addTearDown(controller.dispose);
    addTearDown(messaging.dispose);
  });

  testWidgets('an empty thread says so rather than showing nothing', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(ThreadScreen(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('thread.empty'), findsOneWidget);
  });

  testWidgets('a message shows what the person actually typed', (tester) async {
    await tester.pumpWidget(_wrap(ThreadScreen(controller: controller)));
    await controller.send('Gate code, please');
    await tester.pumpAndSettle();

    expect(find.text('Gate code, please'), findsOneWidget);
  });

  testWidgets('a queued message stays in the list, and is counted', (
    tester,
  ) async {
    messaging.offline = true;

    await tester.pumpWidget(_wrap(ThreadScreen(controller: controller)));
    await controller.send('no signal here');
    await tester.pumpAndSettle();

    expect(find.text('no signal here'), findsOneWidget);
    expect(find.text('thread.queued 1'), findsOneWidget);
  });

  testWidgets('the status of a message is a key, not a sentence', (
    tester,
  ) async {
    messaging.offline = true;

    await tester.pumpWidget(_wrap(ThreadScreen(controller: controller)));
    await controller.send('waiting');
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('waiting')).label,
      contains('thread.status.queued'),
    );
  });

  testWidgets('a failure is rendered as a sentence, not a type name', (
    tester,
  ) async {
    messaging.failNextWith = const ThreadUnavailable();

    await tester.pumpWidget(_wrap(ThreadScreen(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('This conversation could not be opened.'), findsOneWidget);
  });

  test('a change to another thread does not reload this one', () async {
    controller.watch();
    await controller.load();
    final other = ThreadController(
      messaging: messaging,
      thread: ThreadId.withActor('courier-9'),
      reader: MessagingFixtures.courier,
    );
    addTearDown(other.dispose);

    await other.send('elsewhere');
    await pumpEventQueue();

    expect((controller.state as ThreadReady).messages, isEmpty);
  });

  test('marking read touches only what somebody else wrote', () async {
    await controller.load();
    await controller.send('mine');
    await messaging.send(
      thread: MessagingFixtures.thread,
      author: MessagingFixtures.dispatcher,
      body: 'theirs',
    );

    await controller.markRead();

    final messages = (controller.state as ThreadReady).messages;
    expect(messages.firstWhere((m) => m.body == 'mine').isRead, isFalse);
    expect(messages.firstWhere((m) => m.body == 'theirs').isRead, isTrue);
  });
}
