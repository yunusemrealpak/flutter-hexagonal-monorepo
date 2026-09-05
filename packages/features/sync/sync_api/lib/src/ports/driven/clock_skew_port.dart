import 'package:core_kernel/core_kernel.dart';

import '../../failures/sync_failure.dart';

/// Reports how far this device's clock is from the server's.
///
/// A port of its own rather than a subtraction inside the transport adapter,
/// because it answers a question the domain asks: an entry queued offline
/// carries the moment it happened, and "the moment it happened" is only
/// comparable to other devices' work if it is expressed in a shared frame of
/// reference.
///
/// This is not a theoretical concern in field operations. A device that has
/// been in a dead zone since morning may have drifted, or a courier may have
/// changed the time zone by hand; last-write-wins between two such devices is
/// decided by whichever clock is further ahead, which is not a rule anybody
/// designed.
///
/// The value is a *difference*, not a time: positive when the server is ahead
/// of the device. It is added to a queued instant to express it in server
/// time, which is why `Clock` is still the only source of "now" — this port
/// corrects an instant, it does not produce one.
abstract interface class ClockSkewPort {
  /// The difference between the server's clock and this device's.
  ///
  /// Returns a `Result` because obtaining it requires reaching the server, and
  /// a caller has to be able to proceed without it: an offline drain uses
  /// `Duration.zero` and sends the device's own reading, which is better than
  /// not sending the work.
  Future<Result<Duration, SyncFailure>> skew();
}
