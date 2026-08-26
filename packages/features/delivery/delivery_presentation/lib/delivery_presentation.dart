/// The delivery UI: the screen a courier taps *done* on.
///
/// **This package is where scenario 6 turns up for the second time.**
/// `ProofCaptureController.canComplete` asks `identity_api`'s
/// `PermissionChecker` whether the signed-in actor may record a hand-over, and
/// learns nothing else — not the role, not the grant, not that `Actor` exists.
/// `shipments_presentation_dispatcher` asks the same port before it renders
/// bulk assignment. Two features, one contract, no shared implementation.
///
/// The check happens twice on purpose, at two different distances. The route
/// carries `requiredPermission: 'completeDelivery'` so an app's router keeps
/// the wrong person off the screen; the controller asks again before the
/// action, because a grant can be revoked while a courier is standing at a
/// door and they are already past the router by then.
///
/// **The camera arrives as a callback.** Capturing a signature or a photograph
/// means `platform/media_capture`, and section 2 forbids a presentation
/// package from depending on `platform/*`. So the app supplies the capture,
/// the screen offers the button, and the evidence comes back as a value from
/// `delivery_api`.
///
/// **There is no clock here, and there cannot be.** Section 2 allows this
/// package `core_kernel`, `core_navigation`, contracts and the Flutter SDK —
/// not `core_ports`. `ProofOfDelivery.from` derives the hand-over's instant
/// from the evidence, which is why the constraint costs nothing.
///
/// **The rule about how much evidence is enough is read, not restated.**
/// `AtTheDoor.missing` asks `ProofPolicy`, which lives in `delivery_api`. A
/// second copy here would tell a courier they were finished on the day the
/// policy changed and the use case disagreed.
library;

export 'src/delivery_routes.dart';
export 'src/proof_capture_controller.dart';
export 'src/proof_capture_screen.dart';
export 'src/proof_capture_state.dart';
