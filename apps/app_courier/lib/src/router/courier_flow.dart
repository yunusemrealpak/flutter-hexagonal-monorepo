import 'package:delivery_api/delivery_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// Where one step of a flow leads, and what it carries there.
///
/// A record rather than a call to the router, and that is the whole point: the
/// mapping from an outcome to a destination becomes a value a test can read.
/// [CourierFlow] therefore has no `BuildContext`, no `GoRouter` and nothing to
/// pump — and the route names it produces are checked against the routes this
/// app actually mounted, which is the guarantee a `context.goNamed` scattered
/// through fourteen presentation packages could never give.
typedef FlowStep = ({String route, Map<String, String> parameters});

/// The courier's day, as this app arranges it.
///
/// ```text
/// shipments.courier.manifest ──a stop was chosen──▶ delivery.proof
/// delivery.proof ──the visit was recorded──▶ payments.collect
/// payments.collect ──the courier is done──▶ shipments.courier.manifest
/// ```
///
/// **Three features, and not one import between them.** Each screen reports an
/// outcome in its own feature's words — a `ShipmentSummary`, a
/// `DeliveryAttempt` — and this class is where those words become a
/// destination. `shipments` does not know `delivery` has a screen;
/// `delivery` does not know what a parcel costs. §2.4.
///
/// **It lives in this app because the flow belongs to the audience, not to
/// the feature.** `app_dispatcher` mounts `delivery_presentation` too, and a
/// dispatcher looking at a delivery goes nowhere afterwards: it composes no
/// flow at all, and passes no callbacks. The same screens, arranged
/// differently, is scenario 7 one level up from where it was written.
final class CourierFlow {
  /// Creates the flow.
  const CourierFlow();

  /// Where a chosen stop leads.
  ///
  /// The summary carries its identifier as a plain string — a list does not
  /// re-parse eleven hundred of them — and the route takes it as a path
  /// segment, so nothing has to be parsed here either. The screen at the
  /// other end parses once, which is where a malformed one becomes a message
  /// instead of an exception.
  FlowStep fromStop(ShipmentSummary stop) => (
    route: 'delivery.proof',
    parameters: {'shipmentId': stop.id},
  );

  /// Where a recorded visit leads.
  ///
  /// **A hand-over leads to the money; a failed visit does not.** Nobody
  /// collects for a parcel they took away again, and `AttemptOutcome` is
  /// sealed, so this switch is where the day forks and the compiler says so
  /// if delivery ever learns a third ending.
  ///
  /// A completed hand-over goes to collection **even when the parcel is
  /// prepaid**. Delivery cannot know what is owed — it does not depend on
  /// `payments` and must not — and `NothingOwed` is a state payments already
  /// had, distinct from an amount of zero. Routing every hand-over through
  /// collection is what makes the prepaid case a screen somebody sees rather
  /// than a branch nobody exercises.
  ///
  /// `inProgress` cannot reach here — the screen announces on the transition
  /// into `Settled` — and it is answered rather than asserted, because an
  /// unreachable case that throws is a crash waiting for the day it becomes
  /// reachable.
  FlowStep afterProof(DeliveryAttempt attempt) => switch (attempt.outcome) {
    AttemptCompleted() => (
      route: 'payments.collect',
      parameters: {'shipmentId': attempt.shipment.value},
    ),
    AttemptFailed() || AttemptInProgress() => afterDoor(),
  };

  /// Where a finished door leads.
  ///
  /// Back to the manifest, which is also this app's home route. Named rather
  /// than "pop": a courier who arrived at collection from a deep link has
  /// nothing to pop to, and the next stop is what they want either way.
  FlowStep afterDoor() => (
    route: 'shipments.courier.manifest',
    parameters: const {},
  );

  /// Every destination this flow can name.
  ///
  /// The input to the test that checks each one against the routes the app
  /// mounted. A route name is a string, and this is what stops a typed one
  /// from being discovered by a courier instead of by CI.
  static const Set<String> destinations = {
    'delivery.proof',
    'payments.collect',
    'shipments.courier.manifest',
  };
}
