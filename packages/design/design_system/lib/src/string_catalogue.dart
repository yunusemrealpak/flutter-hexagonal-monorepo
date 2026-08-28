/// Where a translated sentence comes from.
///
/// This is the seam that lets a presentation package write `theme.dark`
/// instead of "Dark". Section 2 of docs/DEPENDENCY_RULES.md gives a
/// presentation package `design_system` and no app, so the strings cannot come
/// from the app directly — but the app is the only place that knows which
/// languages this product ships and what the words are in them. The contract
/// is declared here and satisfied there, which is the same inversion a driven
/// port performs, applied to the UI layer.
///
/// **Total by construction.** [resolve] returns a `String` and never fails. A
/// `Result` here would put a failure branch in every label on every screen for
/// a fault that is not a runtime condition at all: a key with no entry behind
/// it is a mistake in the source, and the place to catch it is the catalogue's
/// own test, not a courier's screen.
abstract interface class StringCatalogue {
  /// The sentence for [key], with [arguments] substituted into it.
  ///
  /// Keys are dotted and namespaced by feature — `settings.theme.dark`,
  /// `shipments.courier.scan` — because a flat key space across fourteen
  /// features collides on its second word.
  String resolve(String key, {Map<String, Object?> arguments});
}
