import 'package:core_kernel/core_kernel.dart';
import 'push_failure.dart';
import 'push_message.dart';

/// Registers the device for push and delivers what arrives.
///
/// A technology contract, declared here for the same reason `HttpTransport`
/// and `LocationSource` are declared in their own platform packages: nothing
/// in the product asks for "a push token". `notifications` asks to alert a
/// courier; `shipments` asks to know when an assignment lands. Those are ports
/// in those features' `_api` packages, answered using this.
abstract interface class PushMessagingClient {
  /// The device's registration token.
  ///
  /// Requesting it is what prompts for notification permission on iOS, so a
  /// caller decides *when* the courier is asked — usually after the screen
  /// that explains why, never on first launch.
  Future<Result<String, PushFailure>> currentToken();

  /// Emits a new token whenever the provider rotates it.
  ///
  /// Rotation happens on reinstall, restore from backup, and at the provider's
  /// discretion. A backend that is not told stops being able to reach the
  /// device, and nothing about the device looks wrong when it does.
  Stream<String> tokenChanges();

  /// Messages that arrive while the application is running.
  ///
  /// No `Result`, and that is the contract: a malformed payload becomes a
  /// [PushMessage] of an unrecognised kind with its raw data intact, never an
  /// error and never a dropped message. A fleet updates over weeks, so a
  /// server sending a shape this version has not seen is normal traffic rather
  /// than a fault.
  Stream<PushMessage> messages();

  /// Subscribes the device to [topic], so it receives that topic's broadcasts.
  Future<Result<void, PushFailure>> subscribeTo(String topic);

  /// Undoes [subscribeTo].
  ///
  /// Called on sign-out. A device left subscribed to a former courier's region
  /// keeps receiving that region's dispatches.
  Future<Result<void, PushFailure>> unsubscribeFrom(String topic);
}
