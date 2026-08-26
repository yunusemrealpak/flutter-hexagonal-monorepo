import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:identity_api/identity_api.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:incidents_core/incidents_core.dart';
import 'package:shipments_api/shipments_api.dart';

/// Everything an incidents test needs, wired the way an app would wire it.
///
/// One fake — `InMemoryKeyValueStore` from `core_testing` — plus the recording
/// bus and logger. Everything between them is real: the adapter, the use
/// cases, the coordinator and the watcher.
final class IncidentsHarness {
  IncidentsHarness({
    EscalationPolicy policy = const EscalationPolicy.standard(),
  }) {
    final log = KeyValueIncidentLog(store: keyValue);
    final report = ReportIncident(log: log, clock: clock, ids: ids);
    facade = IncidentsCoordinator(
      report: report,
      list: ListOpenIncidents(log: log),
      escalate: EscalateOverdue(
        log: log,
        clock: clock,
        policy: policy,
        logger: logger,
      ),
      resolve: ResolveIncident(log: log, clock: clock),
    );
    watcher = ShipmentFailureWatcher(
      events: events,
      report: report,
      classify: const ReasonClassifier(),
      logger: logger,
    );
  }

  /// The store behind the log.
  final InMemoryKeyValueStore keyValue = InMemoryKeyValueStore();

  /// The bus `ShipmentFailed` arrives on.
  final RecordingEventBus events = RecordingEventBus();

  /// Time, under the test's control.
  final FakeClock clock = FakeClock(DateTime.utc(2026, 3, 4, 9));

  /// Identifiers, under the test's control.
  final FakeIdGenerator ids = FakeIdGenerator('INC');

  /// Where a swallowed failure is looked for.
  final RecordingLogger logger = RecordingLogger();

  /// The facade under test.
  late final IncidentsCoordinator facade;

  /// The watcher under test.
  late final ShipmentFailureWatcher watcher;

  /// The courier every test reports as.
  static final ActorId courier =
      (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

  /// The parcel most tests concern.
  static final ShipmentId parcel =
      (ShipmentId.parse('SHP-42') as Success<ShipmentId, ShipmentFailure>)
          .value;

  /// The incidents behind a successful list.
  static List<Incident> listOf(
    Result<List<Incident>, IncidentsFailure> result,
  ) => (result as Success<List<Incident>, IncidentsFailure>).value;

  /// The incident behind a successful result.
  static Incident valueOf(Result<Incident, IncidentsFailure> result) =>
      (result as Success<Incident, IncidentsFailure>).value;

  /// The failure behind an unsuccessful one.
  static IncidentsFailure failureOf(
    Result<Incident, IncidentsFailure> result,
  ) => (result as Failed<Incident, IncidentsFailure>).failure;

  /// Releases what the harness started.
  Future<void> dispose() => events.dispose();
}
