import 'package:core_kernel/core_kernel.dart';

/// The server position this device last saw.
///
/// Opaque on purpose. It is a token the server issues and the device stores
/// and hands back; nothing in this workspace parses it, orders two of them, or
/// derives a time from it. The moment a client starts interpreting a cursor,
/// the server can no longer change what it puts in one.
///
/// It is what makes a conflict detectable at all: a device that has been
/// offline since Tuesday sends Tuesday's cursor, and the server can say "there
/// have been writes since" rather than silently overwriting them.
///
/// There is no `parse` returning a `Result` here, unlike every other value
/// object in the workspace, because there is nothing to validate — any string
/// the server issued is a valid cursor, including an empty one. What the type
/// buys is that a cursor cannot be passed where a payload is meant.
final class SyncCursor extends ValueObject<String> {
  /// Wraps a token the server issued.
  const SyncCursor(super.value);

  /// The position of a device that has never synchronised.
  ///
  /// Sent on the first drain after an install. A server that receives it knows
  /// there is no history to compare against and accepts the write.
  static const SyncCursor beginning = SyncCursor('');

  /// Whether this device has never heard a position from the server.
  bool get isBeginning => value.isEmpty;
}
