import 'package:core_kernel/core_kernel.dart';
import 'package:http_dio/http_dio.dart';
import 'package:routing_api/routing_api.dart';

import 'route_dto.dart';
import 'route_mapper.dart';

/// Answers `TrafficDataPort` from the operation's traffic service.
///
/// Small, and the smallness is the point: the port asks one question and this
/// class turns it into one `GET`. What it does *not* do is decide what to plan
/// with when the service is unreachable — `PlanRoute` does that, by falling
/// back to `TrafficProfile.assumed`, because "plan anyway" is a product
/// decision rather than a transport one.
///
/// The `at` argument is a parameter of the port rather than a clock read
/// here, and that is what makes the adapter able to answer the question a
/// dispatcher actually asks: a route planned at five in the afternoon for
/// tomorrow morning wants tomorrow morning's traffic.
final class RestTrafficData implements TrafficDataPort {
  /// Creates the adapter over [transport].
  const RestTrafficData({required this.transport, this.path = '/traffic'});

  /// The transport the question is asked on.
  final HttpTransport transport;

  /// Where the traffic service lives.
  final String path;

  @override
  Future<Result<TrafficProfile, RoutingFailure>> around(
    GeoPoint area, {
    required DateTime at,
  }) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.get,
        path: path,
        query: {
          'lat': '${area.latitude}',
          'lng': '${area.longitude}',
          'at': at.toUtc().toIso8601String(),
        },
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: final ok) => _read(ok.body),
    };
  }

  Result<TrafficProfile, RoutingFailure> _read(Object? body) {
    if (body is! Map<String, dynamic>) {
      return const Failed(
        MalformedRouteValue(
          field: 'body',
          reason: 'the traffic service did not answer with a JSON object',
        ),
      );
    }
    return RouteMapper.trafficToDomain(TrafficDto.fromJson(body));
  }

  static RoutingFailure _translate(TransportFailure failure) =>
      RoutingUnavailable(detail: '$failure');
}
