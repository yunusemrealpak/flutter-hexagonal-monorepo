@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_navigation/core_navigation.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:test/test.dart';

final class _ShiftStarted extends DomainEvent {
  const _ShiftStarted({required super.occurredAt});
}

final class _DeliveryCompleted extends DomainEvent {
  const _DeliveryCompleted({required super.occurredAt, required this.shipment});

  final String shipment;
}

void main() {
  group('RecordingLogger', () {
    test('keeps what it was told, at the severity it was told', () {
      final logger = RecordingLogger()
        ..info('drained outbox', context: {'entries': 3})
        ..error('gateway refused', error: const FormatException('bad json'));

      expect(logger.records, hasLength(2));
      expect(logger.recordsAt(LogLevel.info).single.context, {'entries': 3});
      expect(
        logger.recordsAt(LogLevel.error).single.error,
        isA<FormatException>(),
      );
    });

    test('can be cleared between phases of a test', () {
      final logger = RecordingLogger()
        ..info('a')
        ..clear();

      expect(logger.records, isEmpty);
    });
  });

  group('RecordingEventBus', () {
    test('really delivers, so two subscribers can be wired together', () async {
      final bus = RecordingEventBus();
      addTearDown(bus.dispose);

      final seen = <_DeliveryCompleted>[];
      final subscription = bus.on<_DeliveryCompleted>().listen(seen.add);
      addTearDown(subscription.cancel);

      bus
        ..publish(_ShiftStarted(occurredAt: _t))
        ..publish(_DeliveryCompleted(occurredAt: _t, shipment: 's-1'));
      await Future<void>.delayed(Duration.zero);

      expect(seen.single.shipment, 's-1');
    });

    test('filters by type, so an unrelated event is not delivered', () async {
      final bus = RecordingEventBus();
      addTearDown(bus.dispose);

      final seen = <_DeliveryCompleted>[];
      final subscription = bus.on<_DeliveryCompleted>().listen(seen.add);
      addTearDown(subscription.cancel);

      bus.publish(_ShiftStarted(occurredAt: _t));
      await Future<void>.delayed(Duration.zero);

      expect(seen, isEmpty);
    });

    test(
      'records, so the publishing side can be tested with no subscriber',
      () {
        final bus = RecordingEventBus();
        addTearDown(bus.dispose);

        bus.publish(_DeliveryCompleted(occurredAt: _t, shipment: 's-9'));

        expect(bus.published, hasLength(1));
        expect(bus.publishedOf<_DeliveryCompleted>().single.shipment, 's-9');
      },
    );
  });

  group('RecordingAnalyticsSink', () {
    test('keeps every call in order and in kind', () {
      final sink = RecordingAnalyticsSink()
        ..identify('actor-1', traits: {'role': 'courier'})
        ..track('delivery_completed', properties: {'attempts': 1})
        ..reset();

      expect(sink.records.map((r) => r.runtimeType), [
        IdentifiedActor,
        TrackedEvent,
        ResetIdentity,
      ]);
      expect(sink.eventNames, ['delivery_completed']);
    });

    test('makes a privacy regression a one-line assertion', () {
      final sink = RecordingAnalyticsSink()
        ..track('delivery_completed', properties: {'zone': 'north'});

      expect(
        sink.events.single.properties.keys,
        isNot(contains('consigneeName')),
      );
    });
  });

  group('FakeNetworkStatus', () {
    test('emits the current condition on subscription', () async {
      final network = FakeNetworkStatus(NetworkCondition.offline);
      addTearDown(network.dispose);

      expect(await network.changes().first, NetworkCondition.offline);
    });

    test('emits transitions but not repeats of the same condition', () async {
      final network = FakeNetworkStatus();
      addTearDown(network.dispose);

      final seen = <NetworkCondition>[];
      final subscription = network.changes().listen(seen.add);
      addTearDown(subscription.cancel);

      network
        ..set(NetworkCondition.offline)
        ..set(NetworkCondition.offline)
        ..set(NetworkCondition.metered);
      await Future<void>.delayed(Duration.zero);

      expect(seen, [
        NetworkCondition.unmetered,
        NetworkCondition.offline,
        NetworkCondition.metered,
      ]);
    });
  });

  group('FakeFeatureFlagReader', () {
    test('an unknown flag answers with the caller-supplied fallback', () {
      final flags = FakeFeatureFlagReader();

      expect(flags.isEnabled('unknown', orElse: true), isTrue);
      expect(flags.isEnabled('unknown', orElse: false), isFalse);
    });

    test('a known flag answers with its value regardless of the fallback', () {
      final flags = FakeFeatureFlagReader({'remote_solver': false});

      expect(flags.isEnabled('remote_solver', orElse: true), isFalse);
    });

    test('removing a flag models an unreachable flag service', () {
      final flags = FakeFeatureFlagReader({'x': true})..remove('x');

      expect(flags.isEnabled('x', orElse: false), isFalse);
    });
  });

  group('FakePermissionRequester', () {
    test('an unasked permission is notDetermined', () async {
      final permissions = FakePermissionRequester();

      expect(
        await permissions.status(DevicePermission.camera),
        PermissionState.notDetermined,
      );
    });

    test('records what was prompted for, in order', () async {
      final permissions = FakePermissionRequester();

      await permissions.request(DevicePermission.camera);
      await permissions.request(DevicePermission.locationWhenInUse);

      expect(permissions.requested, [
        DevicePermission.camera,
        DevicePermission.locationWhenInUse,
      ]);
    });

    test(
      'a permanently denied permission shows no prompt, as on a device',
      () async {
        final permissions = FakePermissionRequester({
          DevicePermission.camera: PermissionState.permanentlyDenied,
        });

        final state = await permissions.request(DevicePermission.camera);

        expect(state, PermissionState.permanentlyDenied);
        expect(permissions.requested, isEmpty);
      },
    );
  });

  group('RecordingNavigation', () {
    test('keeps a real history that back actually pops', () {
      final navigation = RecordingNavigation()
        ..goTo(RouteLocation('/stops'))
        ..goTo(RouteLocation('/stops/s-1'));

      expect(navigation.current, RouteLocation('/stops/s-1'));
      expect(navigation.back(), isTrue);
      expect(navigation.current, RouteLocation('/stops'));
    });

    test('back reports false at the root, so a bloc can branch on it', () {
      final navigation = RecordingNavigation()..goTo(RouteLocation('/stops'));

      expect(navigation.back(), isFalse);
      expect(navigation.current, RouteLocation('/stops'));
    });

    test('replaceWith swaps the current entry instead of stacking', () {
      final navigation = RecordingNavigation()
        ..goTo(RouteLocation('/sign-in'))
        ..replaceWith(RouteLocation('/stops'));

      expect(navigation.history, [RouteLocation('/stops')]);
      expect(navigation.records.last, isA<ReplacedWith>());
    });
  });
}

/// A fixed instant for the events above, so nothing in this file reads a clock.
/// DateTime has no const constructor, which is why the events below are built
/// at runtime rather than as constants.
final _t = DateTime.utc(2026, 3, 1, 8);
