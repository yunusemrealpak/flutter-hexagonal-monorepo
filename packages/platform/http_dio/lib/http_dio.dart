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
/// What lives here is the contract, exactly one adapter, the fake that stands
/// in for the contract in tests, and the interceptor chain that adapter runs
/// under. There is no base URL and no domain vocabulary — the first is the
/// composition root's and the second is a feature's.
///
/// **The interceptors are the part worth reading twice**, because they are
/// where a cross-cutting concern belongs and where the workspace previously
/// had nothing. Authorization, retry and correlation are properties of *every*
/// outbound call; a gateway that added its own header would be one of thirty
/// places to change a scheme, and a use case that owned a retry loop would
/// have turned a transport policy into a business rule. `AuthorizationProvider`
/// is how the credential reaches this package without it ever seeing a
/// feature: the contract is declared here in a technology's words, and
/// `identity_infrastructure` — allowed to see both — answers it.
library;

export 'src/authorization_interceptor.dart';
export 'src/authorization_provider.dart';
export 'src/dio_http_transport.dart';
export 'src/fake_authorization_provider.dart';
export 'src/fake_http_transport.dart';
export 'src/http_method.dart';
export 'src/http_request.dart';
export 'src/http_response.dart';
export 'src/http_transport.dart';
export 'src/observability_interceptor.dart';
export 'src/peyk_transport.dart';
export 'src/retry_interceptor.dart';
export 'src/transport_failure.dart';
