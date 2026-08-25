/// S4, twice: a barrel that declares a type of its own, and republishes
/// another package's surface as if it were this package's.
library;

export 'package:core_kernel/core_kernel.dart';
export 'src/thing.dart';

/// Declared in the barrel, so it lives outside lib/src/.
const String leaked = 'leaked';
