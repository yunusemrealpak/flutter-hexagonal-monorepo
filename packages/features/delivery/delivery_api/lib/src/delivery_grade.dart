/// How much proof a parcel is worth, in delivery's own words.
///
/// **This is the whole of what delivery knows about a shipment's nature**, and
/// it is deliberately not shipments' word for it. A `Shipment` has a
/// declared value, a service level, a consignee and a dozen other things; a
/// grade has two cases, because the only question delivery asks about a parcel
/// is how hard the hand-over has to be to prove.
///
/// Taking `ShipmentSummary` instead would have been easier to wire and would
/// have cost the boundary: delivery would carry a model shipments owns, would
/// have to be recompiled when a field it never reads changes, and would end up
/// with an opinion about what "high value" means that shipments could
/// contradict. Section 2.1 of docs/DEPENDENCY_RULES.md is the rule; this enum
/// is what following it looks like.
///
/// Whoever starts an attempt supplies the grade. In an app that is the screen
/// that already had the manifest row in its hand, which is the one place where
/// translating between the two vocabularies is somebody's job.
enum DeliveryGrade {
  /// The ordinary parcel: one piece of evidence closes it.
  standard,

  /// Worth enough to insist on a signature *and* a photograph.
  ///
  /// Two independent pieces of evidence rather than one better one. A
  /// signature says somebody accepted it and a photograph says what was handed
  /// over; a dispute about a valuable parcel is usually about the second, and
  /// a scrawl on a screen answers the wrong question.
  highValue,
}
