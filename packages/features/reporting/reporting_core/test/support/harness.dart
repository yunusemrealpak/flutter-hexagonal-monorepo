import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:reporting_core/reporting_core.dart';
import 'package:shipments_api/shipments_api.dart';

/// Everything a reporting test needs, wired the way an app would wire it.
///
/// One fake — the in-memory key-value store — plus the recording bus and
/// logger. The store adapter, the use cases, the coordinator and the watcher
/// are all real, which is the point: this feature's behaviour is what happens
/// between an event and a number.
final class ReportingHarness {
  ReportingHarness() {
    final store = KeyValueTallyStore(store: keyValue);
    facade = ReportingCoordinator(
      store: store,
      range: ReadRange(store: store),
    );
    watcher = ShipmentOutcomeWatcher(
      events: events,
      record: RecordOutcome(store: store),
      logger: logger,
    );
  }

  /// The store behind the totals.
  final InMemoryKeyValueStore keyValue = InMemoryKeyValueStore();

  /// The bus the outcomes arrive on.
  final RecordingEventBus events = RecordingEventBus();

  /// Where a swallowed write failure is looked for.
  final RecordingLogger logger = RecordingLogger();

  /// The facade under test.
  late final ReportingCoordinator facade;

  /// The watcher under test.
  late final ShipmentOutcomeWatcher watcher;

  /// Starts the watcher and stops it at the end of the test.
  void listen() {
    final subscriptions = watcher.start();
    addTearDownFor(subscriptions);
  }

  /// The subscriptions the test has to cancel.
  final List<StreamSubscription<DomainEvent>> started = [];

  /// Remembers [subscriptions] so [dispose] can cancel them.
  void addTearDownFor(List<StreamSubscription<DomainEvent>> subscriptions) =>
      started.addAll(subscriptions);

  /// Reads a shipment identifier, throwing on an invalid fixture.
  static ShipmentId parcel(String raw) =>
      (ShipmentId.parse(raw) as Success<ShipmentId, ShipmentFailure>).value;

  /// The day every test counts on.
  static ReportingDay get today => ReportingDay.of(DateTime.utc(2026, 3, 4, 9));

  /// The tally behind a successful read.
  static OperationTally valueOf(
    Result<OperationTally, ReportingFailure> result,
  ) => (result as Success<OperationTally, ReportingFailure>).value;

  /// The failure behind an unsuccessful one.
  static ReportingFailure failureOf(Object result) => switch (result) {
    Failed<OperationTally, ReportingFailure>(:final failure) => failure,
    Failed<List<OperationTally>, ReportingFailure>(:final failure) => failure,
    _ => throw StateError('$result is not a failure'),
  };

  /// Releases what the harness started.
  Future<void> dispose() async {
    for (final subscription in started) {
      await subscription.cancel();
    }
    await events.dispose();
  }
}
