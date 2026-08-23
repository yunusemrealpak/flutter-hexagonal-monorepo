/// The workspace's HTTP transport contract, its Dio adapter and its fake.
///
/// A platform package owns a *technology* contract, and this is the clearest
/// example of the kind. `core_ports` declares what the product asks the
/// outside world for in the product's own words — a clock, a store, a
/// permission. Nothing in the product asks for "an HTTP request"; features ask
/// for a shipment or a payment, through ports their own `_api` declares. This
/// library is what an `_infrastructure` package uses to answer one of those
/// asks over one particular protocol.
///
/// The rule that follows from it is worth stating plainly: `_application`
/// packages never see this library, and the dependency table is what stops
/// them — an `_application` package may not depend on `platform/*` at all.
/// A use case that could build an `HttpRequest` would eventually decide a
/// retry policy, and retry policy is not a business rule.
///
/// Three things live here and nothing else does: the contract, exactly one
/// adapter, and a fake that stands in for the contract in tests. There is no
/// base URL, no authentication and no domain vocabulary — those are the
/// composition root's, an interceptor's and a feature's business respectively.
library;

export 'src/dio_http_transport.dart';
export 'src/fake_http_transport.dart';
export 'src/http_method.dart';
export 'src/http_request.dart';
export 'src/http_response.dart';
export 'src/http_transport.dart';
export 'src/transport_failure.dart';
