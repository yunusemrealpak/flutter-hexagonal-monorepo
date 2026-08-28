@Tags(['widget'])
library;

import 'package:design_system/design_system.dart';
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
Widget _wrap(Widget child) => PeykTheme.wrap(child: child);

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

    expect(find.text(MessagingStrings.threadEmpty), findsOneWidget);
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
    expect(
      find.text('${MessagingStrings.threadQueued}(count=1)'),
      findsOneWidget,
    );
  });

  // The status used to be a semantics label only, which meant a screen reader
  // could hear "written but not sent" and a person looking at the phone could
  // not. That is the wrong way round: the courier who needs it most is the one
  // glancing at a screen in a van.
  testWidgets('a queued message says so on the screen, not only aloud', (
    tester,
  ) async {
    messaging.offline = true;

    await tester.pumpWidget(_wrap(ThreadScreen(controller: controller)));
    await controller.send('waiting');
    await tester.pumpAndSettle();

    expect(find.text(MessagingStrings.statusQueued), findsOneWidget);
  });

  testWidgets('a failure is rendered as the key an app answers', (
    tester,
  ) async {
    messaging.failNextWith = const ThreadUnavailable();

    await tester.pumpWidget(_wrap(ThreadScreen(controller: controller)));
    await tester.pumpAndSettle();

    expect(
      find.text(MessagingStrings.failureThreadUnavailable),
      findsOneWidget,
    );
  });

  test('every failure maps to a key an app is asked to answer', () {
    const failures = <MessagingFailure>[
      ThreadUnavailable(),
      DeliveryDeferred(),
      DeliveryRefused(reason: 'too long'),
      MessageMissing('m-1'),
      MalformedMessage(field: 'body', reason: 'it is empty'),
    ];

    for (final failure in failures) {
      expect(MessagingStrings.all, contains(ThreadScreen.describe(failure)));
    }
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
