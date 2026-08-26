import 'package:flutter/widgets.dart';

/// The Payments screen.
///
/// Presentation depends on its feature's `_api` and never on its
/// `_application` or `_infrastructure`: it knows the vocabulary, not the use
/// cases and not the adapters. An app's composition root supplies whatever
/// this screen needs to call.
final class PaymentsScreen extends StatelessWidget {
  /// Creates the screen.
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
