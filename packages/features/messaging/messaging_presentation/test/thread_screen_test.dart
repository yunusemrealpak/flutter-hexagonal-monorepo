@Tags(['widget'])
library;

import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  setUp(() {
    messaging = FakeMessagingFacade();
    addTearDown(messaging.dispose);
  });

  ThreadBloc build({ThreadId? thread}) => ThreadBloc(
    messaging: messaging,
    thread: thread ?? MessagingFixtures.thread,
    reader: MessagingFixtures.courier,
  );

  /// The tree the screen needs, with the bloc **owned by the provider**.
  ///
  /// A widget test must never close a bloc itself: `Bloc.close()` completes on
  /// microtasks scheduled inside the fake-async zone, so awaiting it from the
  /// body or from `addTearDown` hangs with no failure and no timeout.
  Widget screen() => _wrap(
    BlocProvider<ThreadBloc>(
      create: (_) => build(),
      child: const ThreadScreen(),
    ),
  );

  /// Sends [body] through the tree, the way the app does.
  Future<void> send(WidgetTester tester, String body) async {
    tester
        .element(find.byType(ThreadScreen))
        .read<ThreadBloc>()
        .add(MessageSent(body));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty thread says so rather than showing nothing', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text(MessagingStrings.threadEmpty), findsOneWidget);
  });

  testWidgets('a message shows what the person actually typed', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await send(tester, 'Gate code, please');

    expect(find.text('Gate code, please'), findsOneWidget);
  });

  testWidgets('a queued message stays in the list, and is counted', (
    tester,
  ) async {
    messaging.offline = true;

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await send(tester, 'no signal here');

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

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await send(tester, 'waiting');

    expect(find.text(MessagingStrings.statusQueued), findsOneWidget);
  });

  // Two messages typed quickly are two different things somebody said, and
  // they have to arrive in the order they were written. `droppable()` would
  // lose the second sentence of a two-line answer; re-run with `sequential()`
  // swapped for it and the second body is missing.
  //
  // The gate is what gives that claim teeth. Ungated, the fake answers in the
  // same microtask, so the first handler is finished before the second event
  // is delivered and `droppable()` has nothing to drop — the test passes
  // against every transformer and therefore asserts nothing.
  testWidgets('two messages sent in a row both arrive, in order', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    final gate = Completer<void>();
    messaging.gate = gate;
    addTearDown(() => gate.isCompleted ? null : gate.complete());

    final bloc = tester.element(find.byType(ThreadScreen)).read<ThreadBloc>()
      ..add(const MessageSent('first'))
      ..add(const MessageSent('second'));
    await tester.pump();

    gate.complete();
    await tester.pumpAndSettle();

    final bodies = (bloc.state as ThreadReady).messages
        .map((message) => message.body)
        .toList();
    expect(bodies, ['first', 'second']);
  });

  testWidgets('a failure is rendered as the key an app answers', (
    tester,
  ) async {
    messaging.failNextWith = const ThreadUnavailable();

    await tester.pumpWidget(screen());
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
    final bloc = build()
      ..add(const ThreadWatched())
      ..add(const ThreadRequested());
    addTearDown(bloc.close);
    await bloc.stream.firstWhere((state) => state is ThreadReady);

    final other = build(thread: ThreadId.withActor('courier-9'));
    addTearDown(other.close);
    other.add(const MessageSent('elsewhere'));
    await pumpEventQueue();

    expect((bloc.state as ThreadReady).messages, isEmpty);
  });

  test('marking read touches only what somebody else wrote', () async {
    final bloc = build()
      ..add(const ThreadRequested())
      ..add(const MessageSent('mine'));
    addTearDown(bloc.close);
    await pumpEventQueue();
    await messaging.send(
      thread: MessagingFixtures.thread,
      author: MessagingFixtures.dispatcher,
      body: 'theirs',
    );

    bloc.add(const ThreadMarkedRead());
    await pumpEventQueue();

    final messages = (bloc.state as ThreadReady).messages;
    expect(messages.firstWhere((m) => m.body == 'mine').isRead, isFalse);
    expect(messages.firstWhere((m) => m.body == 'theirs').isRead, isTrue);
  });
}
