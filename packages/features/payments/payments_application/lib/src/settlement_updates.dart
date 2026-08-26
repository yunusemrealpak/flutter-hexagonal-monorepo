import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';

/// Adds a settled attempt to the courier's day.
///
/// Shared by `CollectOnDelivery`, `RefundCollection` and
/// `CollectionReconciler`, because all three settle money and all three have
/// to reach the same day. A copy in each of them would drift the first time
/// the identifier's shape changed.
///
/// It is a function rather than a use case: it has no intention of its own,
/// nothing calls it from outside this package, and giving it a `UseCase`
/// signature would put it in the barrel as if an app might bind it.
///
/// A day that is already closed is left alone and reported. Money that arrives
/// after a hand-in belongs to the next day's reconciliation, and silently
/// changing a number somebody has already counted is worse than saying so.
abstract final class SettlementUpdates {
  /// Includes [attempt] in the day it was settled on.
  static Future<Result<Settlement, PaymentsFailure>> include(
    PaymentAttempt attempt, {
    required SettlementStore store,
    required DateTime at,
  }) async {
    final courier = attempt.request.courier;

    final String id;
    switch (SettlementId.forDay(courier.value, at)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        id = value.value;
    }

    final Settlement? stored;
    switch (await store.read(id)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        stored = value;
    }

    // A missing day is opened rather than reported. The first collection of
    // every morning arrives before anything has been written, and making that
    // an error would start every shift with one.
    final Settlement day;
    if (stored != null) {
      day = stored;
    } else {
      switch (Settlement.openFor(
        courier: courier,
        day: at,
        zero: Money.zero(attempt.amount.currency),
      )) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          day = value;
      }
    }

    return day.including(attempt).flatMapAsync(store.save);
  }
}

/// Chains an asynchronous step onto a `Result`.
///
/// Small enough to live beside its one caller rather than in `core_kernel`,
/// which takes no type it does not strictly need — rule 15 of the forbidden
/// list.
extension on Result<Settlement, PaymentsFailure> {
  Future<Result<Settlement, PaymentsFailure>> flatMapAsync(
    Future<Result<Settlement, PaymentsFailure>> Function(Settlement) next,
  ) async => switch (this) {
    Failed(:final failure) => Failed(failure),
    Success(:final value) => next(value),
  };
}
