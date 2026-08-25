/// The shipments UI as courier sees it.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:shipments_presentation_courier/src/...`
/// is reaching across a boundary, and arch_check reports it as one.
library;

export 'src/shipments_courier_routes.dart';
export 'src/shipments_courier_screen.dart';
