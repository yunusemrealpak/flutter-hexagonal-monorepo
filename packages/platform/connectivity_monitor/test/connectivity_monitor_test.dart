@Tags(['unit'])
library;

import 'dart:async';

import 'package:connectivity_monitor/connectivity_monitor.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:core_ports/core_ports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A connectivity platform the test drives directly.
final class FakeConnectivityPlatform extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  FakeConnectivityPlatform(this.initial);

  /// What [checkConnectivity] answers with.
  List<ConnectivityResult> initial;

  /// Thrown by the next [checkConnectivity], if set.
  Object? throwOnCheck;

  final StreamController<List<ConnectivityResult>> controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  /// Pushes a transport change to every listener.
  void emit(List<ConnectivityResult> results) => controller.add(results);

  /// Pushes an error to every listener.
  void emitError(Object error) => controller.addError(error);

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    final error = throwOnCheck;
    if (error != null) {
      throwOnCheck = null;
      // Typed as Object so a test can reproduce anything a platform channel
      // is capable of throwing, including something that is neither an
      // Exception nor an Error.
      // ignore: only_throw_errors
      throw error;
    }
    return initial;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      controller.stream;
}

void main() {
  late FakeConnectivityPlatform platform;
  late ConnectivityMonitor monitor;

  setUp(() {
    platform = FakeConnectivityPlatform([ConnectivityResult.wifi]);
    monitor = ConnectivityMonitor(platform);
  });

  tearDown(() async {
    await monitor.dispose();
    await platform.controller.close();
  });

  group('before start', () {
    test('reports offline', () {
      // The conservative direction: work is queued rather than attempted. A
      // queued item that was sendable costs seconds; an attempt with no
      // connection costs a failed request and a retry schedule.
      expect(monitor.current, NetworkCondition.offline);
    });
  });

  group('after start', () {
    test('reports the condition the platform answered with', () async {
      await monitor.start();

      expect(monitor.current, NetworkCondition.unmetered);
    });

    test('reports offline when the platform cannot answer', () async {
      platform.throwOnCheck = StateError('subsystem unavailable');

      await monitor.start();

      // Reading connectivity cannot fail: the answer when the subsystem is
      // unreachable is "offline", not an error.
      expect(monitor.current, NetworkCondition.offline);
    });

    test('follows changes', () async {
      await monitor.start();

      platform.emit([ConnectivityResult.mobile]);
      await pumpEventQueue();

      expect(monitor.current, NetworkCondition.metered);
    });

    test('starting twice does not subscribe twice', () async {
      await monitor.start();
      await monitor.start();

      final seen = <NetworkCondition>[];
      final subscription = monitor.changes().listen(seen.add);
      addTearDown(subscription.cancel);

      platform.emit([ConnectivityResult.mobile]);
      await pumpEventQueue();

      expect(seen, [NetworkCondition.unmetered, NetworkCondition.metered]);
    });
  });

  group('changes', () {
    test('emits the current condition on subscription', () async {
      await monitor.start();

      // So a listener does not have to read `current` and subscribe
      // separately, and risk missing a change between the two.
      expect(await monitor.changes().first, NetworkCondition.unmetered);
    });

    test(
      'does not emit when the transport changes but the affordance does not',
      () async {
        await monitor.start();
        final seen = <NetworkCondition>[];
        final subscription = monitor.changes().skip(1).listen(seen.add);
        addTearDown(subscription.cancel);

        // Gaining a VPN over the same wifi is a transport change and not an
        // affordance change. A listener woken for it would be woken for
        // nothing.
        platform.emit([ConnectivityResult.wifi, ConnectivityResult.vpn]);
        await pumpEventQueue();

        expect(seen, isEmpty);
      },
    );

    test('treats a stream error as going offline', () async {
      await monitor.start();
      final seen = <NetworkCondition>[];
      final subscription = monitor.changes().skip(1).listen(seen.add);
      addTearDown(subscription.cancel);

      platform.emitError(StateError('subsystem stopped answering'));
      await pumpEventQueue();

      expect(seen, [NetworkCondition.offline]);
    });
  });
}
