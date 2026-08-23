/// Records product events for analysis.
///
/// Nothing here returns a [Future] or a `Result`, and that is the contract
/// rather than an omission: analytics must never fail a use case, never slow
/// one down, and never give a caller something to await. An adapter that
/// cannot deliver buffers or drops the event; the decision belongs to the
/// adapter, and the caller must not be able to observe it.
///
/// Never pass anything here that identifies a person beyond the opaque actor
/// identifier — no names, no addresses, no consignee details. A courier
/// platform handles other people's data all day, and an analytics pipeline is
/// the easiest place for it to leak out of the system.
abstract interface class AnalyticsSink {
  /// Records that [event] happened, with optional structured [properties].
  void track(String event, {Map<String, Object?> properties});

  /// Associates subsequent events with [actorId].
  ///
  /// [traits] carries non-identifying attributes — role, region, app flavour.
  void identify(String actorId, {Map<String, Object?> traits});

  /// Drops the association made by [identify].
  ///
  /// Called on sign-out, so that the next actor's events are not attributed to
  /// the previous one.
  void reset();
}
