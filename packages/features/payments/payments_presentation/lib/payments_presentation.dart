/// The payments UI.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:payments_presentation/src/...` is
/// reaching across a boundary, and arch_check reports it as one.
library;

export 'src/payments_routes.dart';
export 'src/payments_screen.dart';
