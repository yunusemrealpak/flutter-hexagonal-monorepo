import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';

/// The one place a container's settled attempts are announced.
///
/// Delivery's driving surface is three interfaces and its change stream is one
/// fact. `DeliveryExecution` opens an attempt and `DeliverySettlement` closes
/// one, while `DeliveryHistory.changes` is what a screen watches — so the
/// stream cannot belong to whichever coordinator an app happened to bind.
///
/// A composition root binds one of these and hands it to every delivery
/// coordinator it builds.
final class DeliveryChannel {
  /// Creates an open channel.
  DeliveryChannel();

  final StreamController<DeliveryAttempt> _attempts =
      StreamController<DeliveryAttempt>.broadcast();

  /// What a screen watches.
  ///
  /// A broadcast stream, so a stop list and a proof screen can both listen.
  Stream<DeliveryAttempt> get attempts => _attempts.stream;

  /// Runs [work] and announces the attempt it produced.
  ///
  /// **Nothing is emitted for a refused call.** The record did not change, and
  /// a screen that redrew on it would flicker for no reason.
  Future<Result<DeliveryAttempt, DeliveryFailure>> announce(
    Future<Result<DeliveryAttempt, DeliveryFailure>> work,
  ) async {
    final result = await work;
    if (result case Success(value: final attempt)) _attempts.add(attempt);
    return result;
  }

  /// Releases the stream.
  ///
  /// Called by the composition root when the container is torn down. The
  /// channel owns the controller, so it is the only thing that can.
  Future<void> dispose() => _attempts.close();
}
