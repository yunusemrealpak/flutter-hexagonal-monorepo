import 'package:core_navigation/core_navigation.dart';

/// The destination this package offers to an app.
///
/// Parameterised by both the parcel and the kind, because a route that only
/// named the parcel would need somewhere else to say which document — and
/// "somewhere else" is a piece of state that survives a deep link badly.
///
/// No `requiredPermission`: a courier carrying a parcel is entitled to its
/// paperwork, and a permission here would stop them showing it to the person
/// asking.
final class DocumentsRoutes implements RouteModule {
  /// Creates the module.
  const DocumentsRoutes();

  @override
  String get moduleName => 'documents';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'documents.view',
      path: '/shipments/:shipmentId/documents/:kind',
    ),
  ];
}
