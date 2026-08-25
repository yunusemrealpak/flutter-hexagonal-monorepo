import 'dart:math';

import 'package:billing_api/billing_api.dart';
import 'package:core_kernel/core_kernel.dart';

/// A fake that invents its own identifiers.
///
/// The point of a fake is that a test can assert on what comes out of it. This
/// one draws from the ambient random generator, so the assertion has to be a
/// wildcard — and a wildcard assertion is one that passes when the code is
/// wrong.
final class FakeBillingRepository implements BillingRepository {
  final Random _random = Random();

  @override
  Future<Result<String, BillingFailure>> invoiceById(String id) async =>
      Success<String, BillingFailure>('invoice-${_random.nextInt(1000)}');
}
