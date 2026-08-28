/// The four ambient sources this app is allowed to touch, and nothing else.
///
/// Rules A1 to A3 forbid `DateTime.now()`, `Random()` and a UUID call in every
/// package in the workspace. `apps/*` is the exception, and this file is what
/// makes that exception a boundary rather than a hole: four small classes, all
/// private, each one a single line of ambient state behind a port.
///
/// Everything else in this app — every module, every screen — takes `Clock`,
/// `IdGenerator` or `RandomSource` and cannot tell the difference between this
/// file and the fakes `app_harness` binds.
library;

import 'dart:async';
import 'dart:math';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';

/// The device clock, in UTC.
///
/// The one place in the workspace `DateTime.now()` is called.
final class SystemClock implements Clock {
  /// Creates it.
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

/// The platform random source.
///
/// The one place `Random()` is constructed.
final class PlatformRandom implements RandomSource {
  /// Creates it.
  const PlatformRandom();

  @override
  int nextInt(int max) => Random().nextInt(max);

  @override
  double nextDouble() => Random().nextDouble();
}

/// Version-4 identifiers, from an injected [RandomSource].
final class UuidGenerator implements IdGenerator {
  /// Creates it.
  const UuidGenerator(this._random);

  final RandomSource _random;

  /// A version-4 UUID, built from the injected source.
  ///
  /// Hand-rolled rather than taken from `package:uuid`, and the reason is the
  /// port: `uuid` reaches for `Random.secure()` itself, so an app that used it
  /// would have a `RandomSource` port that nothing behind it obeys.
  @override
  String newId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

/// The in-process event bus.
///
/// In-process is the only kind: a domain event is a fact one feature states
/// and another hears inside one app. A bus that crossed a process boundary
/// would be a message queue, and the product has one — it is called `sync`.
final class BroadcastEventBus implements DomainEventBus {
  /// Creates it.
  BroadcastEventBus();

  final StreamController<DomainEvent> _controller =
      StreamController<DomainEvent>.broadcast();

  @override
  void publish(DomainEvent event) => _controller.add(event);

  @override
  Stream<T> on<T extends DomainEvent>() =>
      _controller.stream.where((event) => event is T).cast<T>();

  /// Closes the bus.
  Future<void> dispose() => _controller.close();
}

/// A reader with no source behind it.
///
/// The product has no flag service. Inventing one here would put an adapter
/// in an app, which is the one place section 2 permits it and the last place
/// it belongs.
final class NoFeatureFlags implements FeatureFlagReader {
  /// Creates it.
  const NoFeatureFlags();

  /// Always the caller's fallback.
  ///
  /// The port takes `orElse` precisely so that an unreachable source is not a
  /// decision this class gets to make: a caller that wants a feature on when
  /// nothing answers says so, and one that wants it off says that.
  @override
  bool isEnabled(String key, {required bool orElse}) => orElse;
}
