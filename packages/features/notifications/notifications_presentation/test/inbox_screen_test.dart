@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:notifications_presentation/notifications_presentation.dart';

/// A `NotificationsFacade` this test steers.
///
/// A fake, not a mock: it really holds an inbox and really announces a count,
/// so the tests exercise the controller's logic rather than a script of calls.
/// `notifications` ships no `_testing` package — nothing outside the feature
/// consumes its fakes — so the stand-in lives here.
final class _Notifications implements NotificationsFacade {
  final _counts = StreamController<int>.broadcast();

  /// What the inbox currently holds.
  List<InboxEntry> entries = [];

  /// Set to fail the next call, whatever it is.
  NotificationsFailure? failWith;

  @override
  Future<Result<List<InboxEntry>, NotificationsFailure>> inboxOf(
    ActorId actor,
  ) async {
    final failure = _taken();
    return failure == null ? Success(entries) : Failed(failure);
  }

  @override
  Future<Result<InboxEntry, NotificationsFailure>> markRead(
    ActorId actor,
    NotificationId id,
  ) async {
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }

    final index = entries.indexWhere((entry) => entry.id == id);
    if (index < 0) {
      return Failed(NotificationMissing(id.value));
    }
    final marked = entries[index].readAtInstant(DateTime.utc(2026, 3, 4, 10));
    entries = [...entries]..[index] = marked;
    _counts.add(entries.where((entry) => entry.isUnread).length);
    return Success(marked);
  }

  @override
  Future<Result<void, NotificationsFailure>> openAlertsFor(
    ActorId actor,
  ) async => const Success(null);

  @override
  Future<Result<void, NotificationsFailure>> closeAlertsFor(
    ActorId actor,
  ) async => const Success(null);

  @override
  Stream<int> unreadCount() => _counts.stream;

  /// Announces a count, as an arriving alert would.
  void announce(int count) => _counts.add(count);

  Future<void> dispose() => _counts.close();

  NotificationsFailure? _taken() {
    final failure = failWith;
    failWith = null;
    return failure;
  }
}

InboxEntry _entry({required String id, bool read = false}) {
  final built =
      (InboxEntry.arriving(
                id:
                    (NotificationId.parse(id)
                            as Success<NotificationId, NotificationsFailure>)
                        .value,
                kind: NotificationKind.assignment,
                subject: 'inbox.assignment',
                receivedAt: DateTime.utc(2026, 3, 4, 9),
              )
              as Success<InboxEntry, NotificationsFailure>)
          .value;
  return read ? built.readAtInstant(DateTime.utc(2026, 3, 4, 9, 5)) : built;
}

ActorId get _courier =>
    (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

/// The tree every component in this suite needs: a palette, the design
/// system's own delegates, and a catalogue.
///
/// The default catalogue echoes keys, which is why every assertion below reads
/// `find.text('notifications.inbox.empty')` — a claim about *which* string the
/// screen asked for. Asserting the English would be asserting an app's
/// wording, and this package does not have one.
Widget _wrap(Widget child) => PeykTheme.wrap(child: child);

void main() {
  late _Notifications notifications;
  late InboxController controller;

  setUp(() {
    notifications = _Notifications();
    controller = InboxController(
      notifications: notifications,
      actor: _courier,
    );
  });

  tearDown(() async {
    controller.dispose();
    await notifications.dispose();
  });

  testWidgets('an empty inbox says so rather than showing nothing', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(InboxScreen(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text(NotificationsStrings.inboxEmpty), findsOneWidget);
  });

  testWidgets('an alert is drawn as a key and its arguments', (tester) async {
    notifications.entries = [_entry(id: 'push-1')];

    await tester.pumpWidget(_wrap(InboxScreen(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('inbox.assignment'), findsOneWidget);
  });

  testWidgets('tapping an unread alert marks it read', (tester) async {
    notifications.entries = [_entry(id: 'push-1')];

    await tester.pumpWidget(_wrap(InboxScreen(controller: controller)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('inbox.assignment'));
    await tester.pumpAndSettle();

    expect(notifications.entries.single.isUnread, isFalse);
  });

  testWidgets('tapping an alert that is already read does nothing', (
    tester,
  ) async {
    notifications.entries = [_entry(id: 'push-1', read: true)];

    await tester.pumpWidget(_wrap(InboxScreen(controller: controller)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('inbox.assignment'));
    await tester.pumpAndSettle();

    expect(controller.state, isA<InboxReady>());
  });

  testWidgets('a failure is rendered as the key an app answers', (
    tester,
  ) async {
    notifications.failWith = const InboxUnavailable();

    await tester.pumpWidget(_wrap(InboxScreen(controller: controller)));
    await tester.pumpAndSettle();

    expect(
      find.text(NotificationsStrings.failureUnavailable),
      findsOneWidget,
    );
  });

  testWidgets('the badge is absent at zero and present above it', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(UnreadBadge(controller: controller)));
    controller.watch();
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNothing);

    notifications.announce(3);
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });
}
