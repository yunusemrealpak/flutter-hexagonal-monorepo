import 'package:core_kernel/core_kernel.dart';

import 'arriving_alert.dart';
import 'notifications_failure.dart';

/// Whether this device can be reached, and the alerts that reach it.
///
/// A driven port, and the name is the point. Nothing in the product asks for
/// "a push token" or "a topic subscription" — `notifications` asks whether a
/// courier can be alerted, and an adapter answers that *using* the technology
/// contract `PushMessagingClient` in `platform/push_messaging`. That is the
/// distinction `docs/DEPENDENCY_RULES.md` §2.2 draws between a port and a
/// technology contract, and this pair is the clearest example of it in the
/// workspace: the same two interfaces, one in the product's words and one in
/// Firebase's.
abstract interface class AlertChannel {
  /// Makes sure alerts for [actorId] will reach this device.
  ///
  /// Asking for it is what prompts for notification permission on a phone, so
  /// a caller decides *when* somebody is asked — after the screen that
  /// explains why, never on first launch.
  Future<Result<void, NotificationsFailure>> openFor(String actorId);

  /// Stops alerts for [actorId] reaching this device.
  ///
  /// Called on sign-out. A device left open to a former courier's operation
  /// keeps buzzing with somebody else's work.
  Future<Result<void, NotificationsFailure>> closeFor(String actorId);

  /// Alerts arriving while the app is running.
  ///
  /// No `Result`, and that is the contract. An alert whose shape this version
  /// does not recognise arrives as `NotificationKind.unrecognised` with its
  /// arguments intact — never as an error and never dropped. A fleet updates
  /// over weeks, so a server sending something new is normal traffic rather
  /// than a fault.
  Stream<ArrivingAlert> arriving();
}
