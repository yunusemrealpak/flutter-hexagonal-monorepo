import 'package:core_kernel/core_kernel.dart';

import 'delivery_failure.dart';
import 'photo_evidence.dart';

/// Makes a photograph small enough to carry.
///
/// A driven port that speaks in delivery's words — a `PhotoEvidence` in, a
/// `PhotoEvidence` out — rather than in a codec's. There is no quality
/// setting, no sampling mode and no format in this interface, because none of
/// those is a delivery concern; what delivery knows is that a queue on a
/// device and a mobile connection both have limits, and that a photograph
/// which cannot be made to fit is a photograph that will sit in an outbox for
/// ever.
///
/// `limitBytes` is a parameter rather than a constant. What fits depends on
/// what will carry it, the composition root is what knows which transport was
/// bound, and a limit compiled into this package would be wrong for one of the
/// three apps.
///
/// Failing with `MediaTooLarge` when it cannot get under the limit is the
/// honest answer. An adapter that returned the original anyway would move the
/// failure to the transport, hours later, on a device with no signal.
abstract interface class MediaCompressorPort {
  /// Returns [photo] at [limitBytes] or smaller.
  ///
  /// A photograph already under the limit is returned untouched: re-encoding
  /// it would cost quality for nothing.
  Future<Result<PhotoEvidence, DeliveryFailure>> compress(
    PhotoEvidence photo, {
    required int limitBytes,
  });
}
