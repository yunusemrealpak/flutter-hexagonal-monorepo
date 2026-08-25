import 'package:core_kernel/core_kernel.dart';

import 'billing_failure.dart';
import 'billing_repository.dart';

/// "It is only a stub, and it lives next to the port it implements."
///
/// A contract package that carries an implementation stops being a contract:
/// every package that depends on it now depends on this too.
final class HttpBillingRepository implements BillingRepository {
  /// Creates it.
  const HttpBillingRepository();

  @override
  Future<Result<String, BillingFailure>> invoiceById(String id) async =>
      const Failed<String, BillingFailure>(BillingUnavailable());
}
