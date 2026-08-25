import 'package:flutter/widgets.dart';

/// The one button every screen uses.
final class PeykButton extends StatelessWidget {
  /// Creates it.
  const PeykButton({required this.label, super.key});

  /// What the button says.
  final String label;

  @override
  Widget build(BuildContext context) => Text(label);
}
