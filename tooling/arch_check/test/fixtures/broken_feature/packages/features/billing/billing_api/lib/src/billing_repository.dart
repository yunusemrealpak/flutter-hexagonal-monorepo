import 'package:core_kernel/core_kernel.dart';

import 'billing_failure.dart';

/// The port. This part is correct too.
abstract interface class BillingRepository {
  /// Loads one invoice.
  Future<Result<String, BillingFailure>> invoiceById(String id);
}
