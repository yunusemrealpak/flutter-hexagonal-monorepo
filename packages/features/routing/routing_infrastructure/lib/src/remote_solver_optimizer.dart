import 'package:core_kernel/core_kernel.dart';
import 'package:http_dio/http_dio.dart';
import 'package:routing_api/routing_api.dart';

import 'route_dto.dart';
import 'route_mapper.dart';

/// Orders stops by asking a vehicle-routing solver on a server.
///
/// **The other half of scenario 4.** `app_dispatcher` binds it, because an
/// operator planning forty routes at eight in the morning has a connection and
/// needs answers a phone cannot compute. `app_courier` binds
/// `LocalHeuristicOptimizer` instead, and `routing_application` cannot tell
/// them apart.
///
/// **It validates before it asks.** The constraints are checked here, using
/// the same `List<RouteConstraint>` extension the local optimiser uses, and an
/// impossible request never leaves the device. Two reasons, and the second is
/// the load-bearing one:
///
/// - There is no point spending a request on a question with no answer.
/// - **The port's contract cannot be delegated to a server.** A solver run by
///   another team is free to truncate a route that exceeds `maxStops`, and if
///   this adapter simply relayed whatever came back, the same code would
///   satisfy `runRouteOptimizerContract` on Monday and fail it after somebody
///   else's deploy on Tuesday. An adapter is responsible for the contract it
///   implements, whoever is behind it.
///
/// The answer is checked too: a solver that returns an order dropping a stop
/// gets a `SequenceDoesNotMatch`, not a route with a missing parcel.
final class RemoteSolverOptimizer implements RouteOptimizerPort {
  /// Creates the adapter over [transport].
  const RemoteSolverOptimizer({
    required this.transport,
    this.path = '/routes/solve',
  });

  /// The transport the request is sent on.
  final HttpTransport transport;

  /// Where the solver lives.
  final String path;

  @override
  Future<Result<StopSequence, RoutingFailure>> optimise(
    OptimisationRequest request,
  ) async {
    final constraints = request.constraints;

    final checked = constraints.checkAgainst(request.stops);
    if (checked case Failed(:final failure)) return Failed(failure);

    // An empty route needs no solver, and asking for one would spend a request
    // to be told what the caller already knows.
    if (request.stops.isEmpty) return const Success(StopSequence.empty);

    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.post,
        path: path,
        body: RouteMapper.solveRequest(request).toJson(),
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: final ok) => _readOrder(ok.body, request),
    };
  }

  Result<StopSequence, RoutingFailure> _readOrder(
    Object? body,
    OptimisationRequest request,
  ) {
    if (body is! Map<String, dynamic>) {
      return const Failed(
        MalformedRouteValue(
          field: 'body',
          reason: 'the solver did not answer with a JSON object',
        ),
      );
    }

    final raw = SolveResponseDto.fromJson(body).order;
    if (raw == null) {
      return const Failed(
        MalformedRouteValue(field: 'order', reason: 'is missing'),
      );
    }

    final order = <StopId>[];
    for (final id in raw) {
      switch (StopId.parse(id)) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          order.add(value);
      }
    }

    // The anchors are re-applied to the solver's answer rather than trusted.
    // A server that honours them produces the same list; one that does not is
    // corrected here, which is what keeps this adapter's behaviour a property
    // of this repository rather than of somebody else's deploy.
    return StopSequence.over(
      request.stops,
      request.constraints.anchored(order),
    );
  }

  /// Turns a transport failure into the vocabulary the port promises.
  ///
  /// Every case collapses to `RoutingUnavailable`, and unlike in
  /// `sync_infrastructure` that is not a loss of information: a caller of this
  /// port has exactly one thing it can do when the solver does not answer, and
  /// it is to plan without one. Distinguishing a 503 from a timeout here would
  /// be inventing cases nobody branches on.
  static RoutingFailure _translate(TransportFailure failure) =>
      switch (failure) {
        TransportOffline() => const RoutingUnavailable(detail: 'offline'),
        TransportTimeout(:final phase) => RoutingUnavailable(
          detail: 'timed out while ${phase.name}ing',
        ),
        TransportRejected(:final statusCode) => RoutingUnavailable(
          detail: 'the solver rejected the request with $statusCode',
        ),
        TransportCancelled() => const RoutingUnavailable(detail: 'cancelled'),
        TransportCertificateRejected() => const RoutingUnavailable(
          detail: 'certificate rejected',
        ),
        TransportUnexpected(:final detail) => RoutingUnavailable(
          detail: detail,
        ),
      };
}
