import 'package:core_kernel/core_kernel.dart';
import 'http_request.dart';
import 'http_response.dart';
import 'transport_failure.dart';

/// Sends a request and reports what came back, without throwing.
///
/// This is the contract every feature's `_infrastructure` package talks to
/// when it needs the network, and it is declared here rather than in
/// `core_ports` on purpose. `core_ports` holds capabilities the product asks
/// for in its own words — a clock, a store, a permission. This is a technology
/// contract: it speaks in paths, verbs and status codes, and the only packages
/// entitled to see it are the adapters that translate between a feature's own
/// outbound port and one particular protocol.
///
/// That distinction is what keeps the layering honest. `shipments_application`
/// depends on `ShipmentGateway`, a port declared in `shipments_api` in domain
/// terms; `shipments_infrastructure` implements that port using this
/// transport. An `_application` package that could see an `HttpRequest` would
/// have a transport decision to make, and it would eventually make one.
///
/// Nothing here throws. A non-2xx status is a [TransportRejected] failure and
/// not an exception, because "the server said no" is an answer the caller has
/// to handle rather than an interruption of its flow.
abstract interface class HttpTransport {
  /// Sends [request].
  ///
  /// Succeeds for any 2xx status. Every other outcome — including a status the
  /// server considers perfectly normal, like a 404 — is a [TransportFailure],
  /// because deciding that a 404 means "not found rather than broken" requires
  /// knowing what was asked for, and only the caller knows that.
  Future<Result<HttpResponse, TransportFailure>> send(HttpRequest request);
}
