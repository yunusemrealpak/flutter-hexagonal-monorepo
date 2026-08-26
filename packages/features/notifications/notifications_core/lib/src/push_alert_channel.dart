import 'package:core_kernel/core_kernel.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:push_messaging/push_messaging.dart';

/// Answers the alert contract using the push provider.
///
/// **This is the edge the reduced split is for.** `feature_application` may
/// not depend on `platform/*`; `feature_core` may. So this file — a use case's
/// neighbour in the same package — is allowed to import
/// `platform/push_messaging`, and the use cases beside it still cannot see it,
/// because they hold `AlertChannel` and nothing else.
///
/// The translation it performs is the whole reason `AlertChannel` exists as a
/// separate interface from `PushMessagingClient`:
///
/// - a *topic* becomes "alerts for this person";
/// - a `PushMessage` becomes an `ArrivingAlert`, losing the provider's
///   envelope and gaining the product's vocabulary;
/// - a `PushFailure` becomes a `NotificationsFailure`, so that a screen can
///   tell "ask again" from "send them to the system settings" without knowing
///   what Firebase calls either.
///
/// Nothing it does can throw across the port: every failure the client reports
/// is mapped, and the message stream is `Result`-free by contract.
final class PushAlertChannel implements AlertChannel {
  /// Creates the adapter over the push client.
  const PushAlertChannel({required this._client});

  final PushMessagingClient _client;

  /// The topic prefix that carries one person's alerts.
  static const topicPrefix = 'actor.';

  /// The topic [actorId]'s alerts are broadcast on.
  static String topicFor(String actorId) => '$topicPrefix$actorId';

  @override
  Future<Result<void, NotificationsFailure>> openFor(String actorId) async {
    // The token is requested first because that is what prompts for
    // permission. Subscribing a device that has not been granted permission
    // succeeds at the provider and delivers nothing, which is the worst of
    // both: no alerts, and no failure to report.
    final token = await _client.currentToken();
    if (token case Failed(:final failure)) {
      return Failed(_translate(failure));
    }

    final subscribed = await _client.subscribeTo(topicFor(actorId));
    return switch (subscribed) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success() => const Success(null),
    };
  }

  @override
  Future<Result<void, NotificationsFailure>> closeFor(String actorId) async {
    final unsubscribed = await _client.unsubscribeFrom(topicFor(actorId));
    return switch (unsubscribed) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success() => const Success(null),
    };
  }

  @override
  Stream<ArrivingAlert> arriving() => _client.messages().map(toAlert);

  /// Turns a provider message into the product's idea of an alert.
  ///
  /// Static and public so that it can be tested without a client — most of
  /// what is worth testing in an adapter is its mapping.
  ///
  /// An unrecognised kind keeps its payload and gets a subject a screen can
  /// still render. Dropping it would be the one behaviour this feature must
  /// not have: a fleet updates over weeks, and the courier who has not
  /// updated is the one being told something.
  static ArrivingAlert toAlert(PushMessage message) {
    final kind = switch (message.kind) {
      PushMessageKind.shipmentAssigned => NotificationKind.assignment,
      PushMessageKind.dispatchMessage => NotificationKind.message,
      PushMessageKind.routeUpdated => NotificationKind.routeChange,
      PushMessageKind.unknown => NotificationKind.unrecognised,
    };

    return ArrivingAlert(
      // An empty identifier is the provider saying it sent none, and it is not
      // the same as an identifier that happens to be blank. Turning it into
      // null here is what lets the use case decide to mint one.
      externalId: message.id.isEmpty ? null : message.id,
      kind: kind,
      subject: 'inbox.${kind.name}',
      arguments: message.data,
    );
  }

  NotificationsFailure _translate(PushFailure failure) => switch (failure) {
    PushPermissionDenied() => const AlertsRefused(),
    PushPermissionBlocked() => const AlertsBlocked(),
    PushRegistrationFailed(:final detail) => AlertsUnreachable(detail: detail),
    PushUnavailable(:final detail) => AlertsUnreachable(detail: detail),
  };
}
