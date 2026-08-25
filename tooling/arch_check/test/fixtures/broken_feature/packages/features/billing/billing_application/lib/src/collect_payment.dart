import 'package:billing_api/billing_api.dart';
import 'package:billing_infrastructure/billing_infrastructure.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

/// Collects a payment.
///
/// Every shortcut in this class is one somebody has taken in a real codebase:
/// the adapter is constructed here instead of injected, the clock is read from
/// the ambient one, the transport is configured in the use case, the locator
/// resolves what the constructor should have taken, and the diagnostic goes
/// straight to the console.
final class CollectPayment
    implements UseCase<String, Result<String, BillingFailure>> {
  /// Creates it.
  const CollectPayment();

  @override
  Future<Result<String, BillingFailure>> call(String input) async {
    final startedAt = DateTime.now();
    final transport = Dio(
      BaseOptions(receiveTimeout: const Duration(seconds: 5)),
    );
    final repository = GetIt.I<BillingRepository>();
    final fallback = const DioBillingRepository();

    debugPrint('collecting $input at $startedAt via ${transport.options}');

    final result = await repository.invoiceById(input);
    return result is Failed<String, BillingFailure>
        ? fallback.invoiceById(input)
        : result;
  }
}
