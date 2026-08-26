@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_dio/http_dio.dart';
import 'package:routing_infrastructure/routing_infrastructure.dart';
import 'package:routing_testing/routing_testing.dart';

/// A solver that answers with the stops sorted by identifier.
///
/// Not `FakeHttpTransport`: that fake is a *queue* of scripted answers, which
/// is the right shape for testing a mapping and the wrong shape for a contract
/// kit that sends a dozen different requests. What the kit needs behind the
/// adapter is something that behaves like a server — deterministic, and
/// answering whatever it is actually asked.
///
/// Sorting by identifier is a terrible route and a perfectly valid one, which
/// is the point: the contract is about validity, and the kit passes against an
/// answer no operation would ship. Quality is asserted next to the
/// implementation that promises it.
final class _SortingSolver implements HttpTransport {
  @override
  Future<Result<HttpResponse, TransportFailure>> send(
    HttpRequest request,
  ) async {
    final body = request.body! as Map<String, dynamic>;
    final stops = (body['stops'] as List<dynamic>).cast<Map<String, dynamic>>();
    final order = [for (final stop in stops) stop['id'] as String]..sort();

    return Success(
      HttpResponse(statusCode: 200, body: <String, dynamic>{'order': order}),
    );
  }
}

void main() {
  // The whole of scenario 4, in three lines. One description of what an
  // optimiser must do; a device-side heuristic, a remote solver and a fake
  // held to it; and `routing_application` unable to tell which one it has.
  runRouteOptimizerContract(LocalHeuristicOptimizer.new);
  runRouteOptimizerContract(
    () => RemoteSolverOptimizer(transport: _SortingSolver()),
  );

  runRouteCacheContract(
    () => KeyValueRouteCache(store: InMemoryKeyValueStore()),
  );
}
