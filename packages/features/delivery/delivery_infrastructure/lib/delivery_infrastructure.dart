/// The delivery adapters: two answers to the proof store, the gateway, the
/// geofence, and the mappers between them.
///
/// **`LocalEncryptedProofStore` and `RemoteProofStore` both implement
/// `ProofStorePort`**, both pass `runProofStoreContract`, and
/// `delivery_application` cannot tell them apart. `app_courier` binds the
/// first because a signature captured in a basement still has to be kept;
/// `app_dispatcher` binds the second because an operator's machine has no
/// business holding a thousand couriers' photographs. No use case changes
/// between them — the same shape as routing's two optimisers.
///
/// **`HttpGeoFence` is where two platform capabilities meet.** The port asks
/// *am I there yet*; both halves of the answer are lookups — a fix from
/// `LocationSource`, a target from the operation's own service — and neither
/// is a domain fact. It refuses a fix too vague to answer the question rather
/// than measuring with it: the difference between "I do not know where you
/// are" and "you are somewhere over there" is a delivery recorded from the far
/// side of a car park.
///
/// **`BudgetMediaCompressor` does not re-encode**, and that is the design
/// rather than a gap. The cheapest place to make a photograph small is the
/// camera, where `MediaCapture` already takes a width and a quality. This
/// adapter is the decision half of the port — does it fit, and what happens if
/// not — which is the half that belongs to delivery and has to be testable
/// without a device.
///
/// **`DeliveryMapper` reads an attempt back by replaying its transitions.**
/// There is no hydrating constructor: a stored attempt is started and then
/// completed or failed, exactly as it happened. So no shape this package
/// produces is one the domain could not have produced — including the proof
/// policy, which means a stored high-value proof that has lost its photograph
/// fails to load instead of quietly becoming a valid delivery.
///
/// **This package depends on the Flutter SDK**, transitively through
/// `location_service`, which needs it for the plugin it registers. That is
/// what binding a device capability costs, and it is visible: the tests here
/// run under the Flutter test runner rather than `dart test`. The pure Dart
/// half of the feature — `delivery_api` and `delivery_application`, where the
/// rules live — is untouched by it.
library;

export 'src/budget_media_compressor.dart';
export 'src/camera_proof_source.dart';
export 'src/delivery_dto.dart';
export 'src/delivery_mapper.dart';
export 'src/http_geo_fence.dart';
export 'src/local_encrypted_proof_store.dart';
export 'src/remote_proof_store.dart';
export 'src/rest_delivery_gateway.dart';
