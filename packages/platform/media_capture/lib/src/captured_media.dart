/// A file the device produced, and enough about it to decide what to do next.
///
/// A path rather than the bytes, on purpose. Proof-of-delivery photos are
/// megabytes each, a courier takes dozens in a shift, and holding them in
/// memory while an outbox drains is how an offline-first app gets killed by
/// the operating system. The bytes are read when something is ready to consume
/// them.
///
/// Not a domain type. `delivery` will declare its own proof-of-delivery
/// entity, with its own rules about what counts as evidence, and map this into
/// it.
final class CapturedMedia {
  /// Records a file at [path] of [byteSize] bytes, captured at [capturedAt].
  const CapturedMedia({
    required this.path,
    required this.mimeType,
    required this.byteSize,
    required this.capturedAt,
  });

  /// Where the file is on the device.
  ///
  /// Temporary. The operating system may reclaim it, so anything that has to
  /// survive a restart copies it somewhere durable first.
  final String path;

  /// What the file is, as reported by the platform, or a sensible default when
  /// it did not say.
  final String mimeType;

  /// How large the file is.
  ///
  /// Present so that `sync` can decide whether this waits for an unmetered
  /// link without opening the file to find out.
  final int byteSize;

  /// When the capture happened, in UTC.
  ///
  /// Read from the injected `Clock`, because the platform does not report it
  /// and a timestamp taken from the system clock would be unassertable.
  final DateTime capturedAt;

  @override
  String toString() => 'CapturedMedia($path, $mimeType, $byteSize bytes)';
}
