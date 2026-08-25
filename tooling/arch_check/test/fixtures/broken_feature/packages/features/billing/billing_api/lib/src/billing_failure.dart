import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the billing ports. This part is correct.
sealed class BillingFailure extends Failure {
  /// Const so a failure can be built in a const context.
  const BillingFailure();
}

/// No invoice is stored under the identifier that was asked for.
final class InvoiceNotFound extends BillingFailure {
  /// Creates it.
  const InvoiceNotFound(this.id);

  /// The identifier that produced nothing.
  final String id;
}

/// The billing system could not be reached.
final class BillingUnavailable extends BillingFailure {
  /// Creates it.
  const BillingUnavailable();
}
