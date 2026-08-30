/// Route contracts shared by presentation packages and assembled by an app.
///
/// This package describes destinations; it does not render them. It carries no
/// dependency on Flutter and none on a router library, which is what lets a
/// feature's presentation package declare where it can be reached without
/// knowing which of the three apps it ended up in, or what that app routes
/// with.
library;

export 'src/route_definition.dart';
export 'src/route_location.dart';
export 'src/route_module.dart';
