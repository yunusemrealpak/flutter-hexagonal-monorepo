/// The shipments UI as dispatcher sees it.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing
/// `package:shipments_presentation_dispatcher/src/...` is reaching across a
/// boundary, and arch_check reports it as one.
library;

export 'src/shipments_dispatcher_routes.dart';
export 'src/shipments_dispatcher_screen.dart';
