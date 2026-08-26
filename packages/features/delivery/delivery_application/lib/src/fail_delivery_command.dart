import 'dart:convert';

import 'package:delivery_api/delivery_api.dart';
import 'package:sync_api/sync_api.dart';

/// A visit that did not end in a hand-over, on its way to the server.
///
/// The companion of `CompleteDeliveryCommand`, and a separate routing key
/// rather than one command with an outcome field. The composition root maps
/// keys to transport handlers, and a failed delivery and a completed one reach
/// different endpoints, carry different payloads and are retried under
/// different rules; folding them together would put a `switch` inside the
/// handler and hide the difference from the person reading a stuck queue.
///
/// The reason is flattened into a tag and an optional note. `sync` stores a
/// string, so the union has to become data somewhere, and here is the only
/// place that knows what the cases mean.
final class FailDeliveryCommand implements SyncCommand {
  /// Describes [attempt], which must be a failed one.
  const FailDeliveryCommand(this.attempt);

  /// The settled attempt this command is about.
  final DeliveryAttempt attempt;

  @override
  String get type => 'delivery.failAttempt';

  @override
  String get payload => jsonEncode({
    'attemptId': attempt.id.value,
    'shipmentId': attempt.shipment.value,
    'courierId': attempt.courier.value,
    'startedAt': attempt.startedAt.toIso8601String(),
    'settledAt': attempt.settledAt?.toIso8601String(),
    if (attempt.outcome case AttemptFailed(:final reason)) ...{
      'reason': _tagOf(reason),
      'retryable': reason.isRetryable,
      ..._detailOf(reason),
    },
  });

  static String _tagOf(NonDeliveryReason reason) => switch (reason) {
    RecipientAbsent() => 'recipientAbsent',
    AddressNotFound() => 'addressNotFound',
    RefusedByRecipient() => 'refusedByRecipient',
    DamagedInTransit() => 'damagedInTransit',
    AccessDenied() => 'accessDenied',
    Rescheduled() => 'rescheduled',
  };

  static Map<String, Object?> _detailOf(NonDeliveryReason reason) =>
      switch (reason) {
        RecipientAbsent() => const {},
        AddressNotFound(:final found) => {'found': found},
        RefusedByRecipient(:final note) => {'note': note},
        DamagedInTransit(:final note) => {'note': note},
        AccessDenied(:final note) => {'note': note},
        Rescheduled(:final requestedFor) => {
          'requestedFor': requestedFor.toIso8601String(),
        },
      };

  @override
  String toString() => 'FailDeliveryCommand(${attempt.id.value})';
}
