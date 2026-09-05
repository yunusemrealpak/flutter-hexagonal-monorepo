import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';
import 'package:payments_api/payments_api.dart';

/// Whose day is being handed in.
typedef SettlementRequest = ({ActorId courier, DateTime day});

/// Hands in a courier's money for one day.
///
/// Reads the day, closes it and writes it back. What it deliberately does
/// *not* do is recompute the totals from the attempts: `CollectOnDelivery` and
/// `RefundCollection` have been adding to this settlement all afternoon, and a
/// closing step that recounted would be a second source of truth for the same
/// number — the one that disagrees at six o'clock with a day nobody can
/// reopen.
///
/// A day nobody collected on is opened and closed empty rather than reported
/// as missing. A courier who took no cash still hands in a day, and an
/// operation that could not tell "no collections" from "no record" would have
/// to chase both.
final class CloseDailySettlement
    implements UseCase<SettlementRequest, Result<Settlement, PaymentsFailure>> {
  /// Creates the use case.
  const CloseDailySettlement({
    required this._settlements,
    required this._clock,
    this.currency = Currency.tryLira,
  });

  final SettlementStore _settlements;
  final Clock _clock;

  /// The currency an empty day is opened in.
  ///
  /// A parameter with a default rather than a constant, because the operation
  /// a composition root is wiring knows which country it is in and this
  /// package does not.
  final Currency currency;

  @override
  Future<Result<Settlement, PaymentsFailure>> call(
    SettlementRequest request,
  ) async {
    final String id;
    switch (SettlementId.forDay(request.courier.value, request.day)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        id = value.value;
    }

    final Settlement? stored;
    switch (await _settlements.read(id)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        stored = value;
    }

    final Settlement day;
    if (stored != null) {
      day = stored;
    } else {
      switch (Settlement.openFor(
        courier: request.courier,
        day: request.day,
        zero: Money.zero(currency),
      )) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          day = value;
      }
    }

    return switch (day.close(at: _clock.now())) {
      Failed(:final failure) => Failed(failure),
      Success(:final value) => _settlements.save(value),
    };
  }
}
