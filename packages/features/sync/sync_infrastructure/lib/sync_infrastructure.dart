/// The sync adapters: what answers its ports, the DTOs that cross the wire,
/// and the mappers between them.
///
/// Three adapters, and each one is a boundary where something stops:
///
/// **`DriftOutboxStore`** is where SQL stops, and where exceptions stop. A DAO
/// below it may throw; every method here catches and returns a `SyncFailure`,
/// because invariant 1.2.9 says nothing crosses a port boundary as an
/// exception. It is the store `app_courier` binds — an offline-first app has
/// to survive the operating system reclaiming it mid-shift — while
/// `app_dispatcher` binds the in-memory one from `sync_testing`.
///
/// **`HttpCommandTransport`** is where status codes stop. It is the only place
/// in the feature that knows a 409 is a conflict, that a 5xx is worth
/// retrying and a 4xx is not. `DrainOutbox` decides what to *do* about each of
/// those without ever learning that HTTP is involved, which is what would let
/// this API become gRPC without touching a retry policy.
///
/// **`HttpClockSkew`** is where "what time does the server think it is" stops.
///
/// The mappers are hand-written on purpose. A generated one would still have
/// to be told what a missing field, an unrecognised policy name and a
/// non-UTC instant mean — which is the whole content of those files, so
/// generating them would only move the decisions into a configuration nobody
/// reads.
library;

export 'src/drift_outbox_store.dart';
export 'src/http_clock_skew.dart';
export 'src/http_command_transport.dart';
export 'src/outbox_row_mapper.dart';
export 'src/sync_envelope_dto.dart';
export 'src/sync_envelope_mapper.dart';
