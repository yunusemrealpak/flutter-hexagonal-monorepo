import 'package:incidents_api/incidents_api.dart';

/// Turns the free text on a `ShipmentFailed` into a category this feature can
/// escalate.
///
/// **An anticorruption layer, and it is small on purpose.** `ShipmentFailed`
/// carries its reason as a `String`, and that is not an oversight in
/// `shipments_api` — the taxonomy of *why a delivery failed* belongs to
/// `delivery`, which owns `NonDeliveryReason`, and an enum on the event would
/// have been a second copy of it quietly diverging. What crosses the bus is a
/// shipment identifier and a phrase, which is exactly as much as an unrelated
/// feature should be able to depend on.
///
/// The classification is therefore a guess, and it says so: anything it cannot
/// place becomes [IncidentCategory.unclassified] rather than the nearest
/// plausible category. A wrong category is worse than an honest "other",
/// because it is invisible in a report — somebody counting damage claims would
/// count a locked gate among them and never know.
final class ReasonClassifier {
  /// Creates the classifier.
  const ReasonClassifier();

  /// The phrases this product's operations actually write, lower-cased.
  ///
  /// A table rather than a chain of `contains` calls, so that adding a phrase
  /// is a data change. Ordered by specificity: `damag` is checked before
  /// `adres`, because "damaged at the address" is a damage claim.
  ///
  /// **Every key must be written lower-cased, and Turkish is why it is worth
  /// saying.** Matching folds the incoming text with `toLowerCase`, which is
  /// locale-independent in Dart: `ı` upper-cases to `I` and back to `i`, so a
  /// key written `ALICI` would never match the `alıcı` an operation actually
  /// types. Keys stay in the form they are compared in, and no folding is
  /// applied to them.
  static const phrases = <String, IncidentCategory>{
    'damag': IncidentCategory.damage,
    'hasar': IncidentCategory.damage,
    'address': IncidentCategory.addressNotFound,
    'adres': IncidentCategory.addressNotFound,
    'absent': IncidentCategory.recipientUnavailable,
    'recipient': IncidentCategory.recipientUnavailable,
    'alıcı': IncidentCategory.recipientUnavailable,
    'access': IncidentCategory.accessDenied,
    'gate': IncidentCategory.accessDenied,
  };

  /// What [reason] most likely is.
  IncidentCategory call(String reason) {
    final text = reason.toLowerCase();
    for (final phrase in phrases.entries) {
      if (text.contains(phrase.key)) {
        return phrase.value;
      }
    }
    return IncidentCategory.unclassified;
  }
}
