import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// A `PaymentStatusReader` a test can set, standing in for payments.
///
/// **This is the fake `shipments_application` uses**, which is the whole of
/// what shipments needs in order to test scenario 1: a question, an answer,
/// and no knowledge of how payments arrives at it. That the stand-in is this
/// small is the demonstration — a shipments test that had to build a
/// `PaymentAttempt`, a drawer and a settlement to ask "is anything owed" would
/// mean the port was too wide.
///
/// It answers `nothingToCollect` by default, because most parcels are prepaid
/// and a fixture that has to be told the ordinary case before it can be used
/// is a fixture nobody uses.
final class FakePaymentStatusReader implements PaymentStatusReader {
  final Map<String, PaymentStatus> _byShipment = {};
  final List<PaymentsFailure> _queuedFailures = [];

  /// Every shipment this reader was asked about, oldest first.
  final List<String> asked = [];

  /// Says that [amount] is owed on [shipmentId].
  void owes(String shipmentId, Money amount) =>
      _byShipment[shipmentId] = PaymentStatus.outstanding(amount);

  /// Says that [shipmentId] has been paid for.
  void settled(String shipmentId, Money amount, DateTime at) =>
      _byShipment[shipmentId] = PaymentStatus.settled(amount: amount, at: at);

  /// Makes the next call return [failure].
  void failNextWith(PaymentsFailure failure) => _queuedFailures.add(failure);

  @override
  Future<Result<PaymentStatus, PaymentsFailure>> statusFor(
    ShipmentId shipment,
  ) async {
    asked.add(shipment.value);

    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    return Success(
      _byShipment[shipment.value] ?? const PaymentStatus.nothingToCollect(),
    );
  }

  PaymentsFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
