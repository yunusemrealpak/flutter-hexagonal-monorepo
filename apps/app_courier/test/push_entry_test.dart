@Tags(['widget'])
library;

import 'dart:async';

import 'package:app_courier/main.dart';
import 'package:core_testing/core_testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_presentation/identity_presentation.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:messaging_presentation/messaging_presentation.dart';
import 'package:push_messaging/push_messaging.dart';
import 'package:shipments_presentation_courier/shipments_presentation_courier.dart';

import 'support/test_platform.dart';

/// Entry from a notification: the mapping, the orchestrator, and the round
/// trip through the guard that makes entry a URL rather than a callback.
void main() {
  group('the mapping', () {
    const entries = CourierEntryPoints();

    test('opens the manifest for an assignment', () {
      // Not a detail screen: a courier's app has no screen for one shipment,
      // and the point of the assignment is that a stop appeared in the list.
      expect(
        entries.forMessage(_push(PushMessageKind.shipmentAssigned))?.route,
        'shipments.courier.manifest',
      );
    });

    test('opens the thread a dispatch message names', () {
      final step = entries.forMessage(
        _push(PushMessageKind.dispatchMessage, threadId: 'shipment:SHP-9'),
      );

      expect(step?.route, 'messaging.thread');
      expect(step?.parameters, {'threadId': 'shipment:SHP-9'});
    });

    // A server-side mistake arrives as ordinary traffic. Guessing a thread
    // would open somebody else's conversation.
    test('opens nothing for a thread message that names no thread', () {
      expect(
        entries.forMessage(_push(PushMessageKind.dispatchMessage)),
        isNull,
      );
      expect(
        entries.forMessage(
          _push(PushMessageKind.dispatchMessage, threadId: ''),
        ),
        isNull,
      );
    });

    // A fleet updates over weeks, so a kind this version has never seen is
    // normal traffic rather than a fault.
    test('opens nothing for a kind this version does not know', () {
      expect(entries.forMessage(_push(PushMessageKind.unknown)), isNull);
    });
  });

  group('the orchestrator', () {
    late FakePushMessagingClient push;
    late RecordingLogger logger;
    late List<String> opened;
    late PushEntry entry;

    setUp(() {
      push = FakePushMessagingClient();
      logger = RecordingLogger();
      opened = [];
      entry = PushEntry(
        push: push,
        logger: logger,
        go: (step) => opened.add(step.route),
      );
      addTearDown(entry.dispose);
      addTearDown(push.dispose);
    });

    test('opens what a pressed notification points at', () async {
      await entry.start();

      push.open(_push(PushMessageKind.routeUpdated));
      await pumpEventQueue();

      expect(opened, ['routing.myRoute']);
    });

    // Receipt is not intent. A push arriving while a courier is capturing a
    // signature must not take them off that screen.
    test('ignores a push that merely arrived', () async {
      await entry.start();

      push.deliver(_push(PushMessageKind.routeUpdated));
      await pumpEventQueue();

      expect(opened, isEmpty);
    });

    test('opens the notification the app was launched from', () async {
      push.launchedWith = _push(
        PushMessageKind.dispatchMessage,
        threadId: 'shipment:SHP-1',
      );

      await entry.start();

      expect(opened, ['messaging.thread']);
    });

    // The provider hands the launch message over once, so a resume must not
    // reopen it. The fake consumes it for the same reason the device does.
    test('does not reopen the launch notification on a second start', () async {
      push.launchedWith = _push(PushMessageKind.routeUpdated);

      await entry.start();
      await entry.start();

      expect(opened, ['routing.myRoute']);
    });

    test('says so and opens nothing when a message leads nowhere', () async {
      await entry.start();

      push.open(_push(PushMessageKind.unknown));
      await pumpEventQueue();

      expect(opened, isEmpty);
      expect(
        logger.records.map((record) => record.message),
        contains('push opened nothing'),
      );
    });
  });

  group('in the app', () {
    late GetIt container;
    late _MutableSession sessions;

    setUp(() async {
      container = await configureCourier(testPlatform());
      sessions = _MutableSession(SessionBuilder().build());
      await container.unregister<SessionReader>();
      await container.unregister<PermissionChecker>();
      container
        ..registerSingleton<SessionReader>(sessions)
        ..registerSingleton<PermissionChecker>(
          const _Permissions({Permission.viewAssignedShipments}),
        );
    });

    tearDown(() => container.reset());

    test('every destination it can name is a route this app mounted', () {
      final router = buildCourierRouter(container);

      expect(
        CourierEntryPoints.destinations.difference(
          router.definitions.keys.toSet(),
        ),
        isEmpty,
      );
    });

    testWidgets('a pressed notification arrives at its screen', (
      tester,
    ) async {
      final push = FakePushMessagingClient();
      addTearDown(push.dispose);
      final router = buildCourierRouter(container).build();
      final entry = PushEntry(
        push: push,
        logger: RecordingLogger(),
        go: (step) =>
            router.goNamed(step.route, pathParameters: step.parameters),
      );
      addTearDown(entry.dispose);

      await tester.pumpWidget(CourierApp(router: router));
      await tester.pumpAndSettle();
      await entry.start();

      push.open(
        _push(PushMessageKind.dispatchMessage, threadId: 'shipment:SHP-1'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ThreadScreen), findsOneWidget);
    });

    // The reason entry is a URL and not a callback. A tap while signed out
    // goes through the guard, which remembers the destination in `?from=` —
    // and the courier arrives at it once there is a session, rather than at
    // whatever screen the app starts on.
    testWidgets('a tap while signed out is remembered across signing in', (
      tester,
    ) async {
      sessions.end();
      final push = FakePushMessagingClient();
      addTearDown(push.dispose);
      final router = buildCourierRouter(container).build();
      final entry = PushEntry(
        push: push,
        logger: RecordingLogger(),
        go: (step) =>
            router.goNamed(step.route, pathParameters: step.parameters),
      );
      addTearDown(entry.dispose);

      await tester.pumpWidget(CourierApp(router: router));
      await tester.pumpAndSettle();
      await entry.start();

      push.open(
        _push(PushMessageKind.dispatchMessage, threadId: 'shipment:SHP-1'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      final from =
          router.routeInformationProvider.value.uri.queryParameters['from'];
      // Compared by segment rather than by string: the colon a thread
      // identifier carries is percent-encoded inside the path, and asserting
      // the encoded spelling would be a test of go_router's encoder.
      expect(Uri.parse(from!).pathSegments, ['threads', 'shipment:SHP-1']);

      sessions.begin(SessionBuilder().build());
      await tester.pumpAndSettle();

      expect(find.byType(ThreadScreen), findsOneWidget);
      expect(find.byType(CourierManifestScreen), findsNothing);
    });
  });
}

PushMessage _push(PushMessageKind kind, {String? threadId}) => PushMessage(
  id: 'msg-1',
  kind: kind,
  data: const {},
  sentAt: DateTime.utc(2026, 3),
  threadId: threadId,
);

/// A session that can end and begin again, as in the shell test.
final class _MutableSession implements SessionReader {
  _MutableSession(this._session);

  final _changes = StreamController<Session?>.broadcast();
  Session? _session;

  @override
  Session? get current => _session;

  @override
  Stream<Session?> changes() => _changes.stream;

  void end() {
    _session = null;
    _changes.add(null);
  }

  void begin(Session session) {
    _session = session;
    _changes.add(session);
  }
}

final class _Permissions implements PermissionChecker {
  const _Permissions(this._granted);

  final Set<Permission> _granted;

  @override
  bool can(Permission permission) => _granted.contains(permission);
}
