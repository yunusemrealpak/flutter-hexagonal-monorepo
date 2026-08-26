import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:routing_api/routing_api.dart';

import 'route_dto.dart';
import 'route_mapper.dart';

/// Keeps a courier's plan on the device, in the key-value store.
///
/// The `KeyValueStore` port rather than a table of routing's own, and that is
/// a judgement worth stating: a plan is one blob per courier, read whole and
/// written whole, with no query over it. A drift table would buy indexing
/// nothing asks for and cost a migration every time a stop grew a field.
///
/// The port's own documentation warns against using it for domain data, and
/// the warning is about *entities a feature needs to query*. A cached
/// aggregate that is only ever fetched by its owner's identifier is what the
/// store is for. The line is real, and it is worth saying which side of it
/// this is on rather than assuming.
///
/// It is the cache `app_courier` binds. `app_dispatcher` binds
/// `InMemoryRouteCache`, because an operator's plans come from a server every
/// time the board opens.
final class KeyValueRouteCache implements RouteCache {
  /// Creates the adapter over [store].
  const KeyValueRouteCache({required this.store});

  /// The prefix every key this adapter owns starts with.
  ///
  /// Namespaced so that clearing routing's stored state is a prefix scan
  /// rather than a list of key names that has to be kept in step.
  static const String keyPrefix = 'routing.plan.';

  /// Where plans are kept.
  final KeyValueStore store;

  @override
  Future<Result<RoutePlan, RoutingFailure>> read(String courierId) async {
    final stored = await store.read(_keyFor(courierId));

    return switch (stored) {
      Failed(:final failure) => Failed(_translate(failure)),
      // No row is not a failure of the store — it is a courier who has not been
      // planned yet, which the port models as NoPlan.
      Success(value: null) => Failed(NoPlan(courierId)),
      Success(value: final json) => _decode(json!),
    };
  }

  @override
  Future<Result<void, RoutingFailure>> write(RoutePlan plan) async {
    final written = await store.write(
      _keyFor(plan.courier.value),
      jsonEncode(RouteMapper.planToDto(plan).toJson()),
    );
    return written.mapFailure(_translate);
  }

  @override
  Future<Result<void, RoutingFailure>> clear(String courierId) async {
    final removed = await store.delete(_keyFor(courierId));
    return removed.mapFailure(_translate);
  }

  Result<RoutePlan, RoutingFailure> _decode(String raw) {
    // The one place this adapter catches. A stored blob that is no longer
    // JSON — a half-written file, a downgrade — is not something a use case
    // can handle as an exception, and invariant 1.2.9 forbids it crossing the
    // boundary as one.
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const Failed(
        MalformedRouteValue(
          field: 'plan',
          reason: 'the stored plan is not JSON',
        ),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return const Failed(
        MalformedRouteValue(
          field: 'plan',
          reason: 'the stored plan is not a JSON object',
        ),
      );
    }

    return RouteMapper.planToDomain(RoutePlanDto.fromJson(decoded));
  }

  static String _keyFor(String courierId) => '$keyPrefix$courierId';

  /// Turns a store failure into the vocabulary the port promises.
  ///
  /// `StoreCorrupted` becomes a malformed value rather than an unavailable
  /// service, because the two lead somewhere different: one means "ask again
  /// later" and the other means "this plan is gone, replan". Collapsing them
  /// would have a courier waiting for a cache that is never going to answer.
  static RoutingFailure _translate(StoreFailure failure) => switch (failure) {
    StoreCorrupted(:final key) => MalformedRouteValue(
      field: 'plan',
      reason: 'the stored plan at $key could not be read',
    ),
    StoreOutOfSpace() => const RoutingUnavailable(
      detail: 'no room to store the plan',
    ),
    StoreUnavailable(:final detail) => RoutingUnavailable(detail: detail),
  };
}
