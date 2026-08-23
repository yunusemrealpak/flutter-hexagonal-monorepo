/// How precise a position needs to be, and what the product will pay for it.
///
/// Three values rather than the plugin's seven, because these are the three
/// choices the product actually makes. Accuracy is bought with battery and
/// with time to first fix, and a courier's phone has to last a shift.
enum FixAccuracy {
  /// Good enough to know which district a courier is in.
  ///
  /// Cheapest: usually answered from cell towers or wifi without waking the
  /// GPS at all. Used for the periodic position pings that keep a dispatcher's
  /// map warm.
  coarse,

  /// Good enough for route progress.
  balanced,

  /// Good enough to stand behind a geofenced proof of delivery.
  ///
  /// The expensive one, and the reason it exists as its own value: a delivery
  /// confirmation that says "within 50 metres of the address" is a claim the
  /// company may have to defend, so it is worth the battery for the seconds it
  /// takes.
  fine,
}
