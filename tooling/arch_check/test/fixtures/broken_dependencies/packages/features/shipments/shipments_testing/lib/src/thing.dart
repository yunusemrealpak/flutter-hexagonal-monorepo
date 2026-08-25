import 'package:payments_application/payments_application.dart';

/// A fake that reached into another feature's use cases.
final class FakeThing {
  /// What it borrowed: a use case, not a contract.
  final CollectPayment borrowed = const CollectPayment();
}
