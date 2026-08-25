import 'package:billing_application/billing_application.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// The screen.
///
/// It constructs the use case itself, which is why the package had to depend
/// on `_application` — the dependency and the habit arrive together.
final class BillingScreen extends StatelessWidget {
  /// Creates it.
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const useCase = CollectPayment();
    return PeykButton(label: 'collect ${useCase.runtimeType}');
  }
}
