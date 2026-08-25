import 'package:collection/collection.dart';

/// Any package import under lib/ breaks the innermost ring.
final List<int> sorted = [3, 1, 2]
  ..sort(compareNatural as int Function(int, int));
