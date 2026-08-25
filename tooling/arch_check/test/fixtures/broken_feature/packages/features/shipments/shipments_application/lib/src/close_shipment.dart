import 'package:billing_application/billing_application.dart';
import 'package:core_kernel/core_kernel.dart';

/// Closes a shipment, and settles its invoice by calling billing's use case
/// directly. billing's use case calls back into shipments, and neither team
/// noticed until the build started taking eleven minutes.
final class CloseShipment implements UseCase<String, Result<String, Object>> {
  /// Creates it.
  const CloseShipment();

  @override
  Future<Result<String, Object>> call(String input) async {
    const collect = CollectPayment();
    await collect(input);
    return Success<String, Object>(input);
  }
}
