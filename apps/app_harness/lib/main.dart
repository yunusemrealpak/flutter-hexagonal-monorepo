import 'package:flutter/widgets.dart';

import 'src/di/injection.dart';
import 'src/harness_app.dart';
import 'src/router/harness_routes.dart';

/// Re-exported so a test can build the same app the entry point does.
///
/// A test that assembled its own would be a test of a second app.
export 'src/di/injection.dart' show configureHarness, harnessContainer;
export 'src/harness_app.dart';
export 'src/router/harness_routes.dart';
export 'src/router/peyk_router.dart';
export 'src/router/session_refresh.dart';

/// Stands every feature up on fakes.
///
/// Four lines, and that is the measure of whether the architecture worked: a
/// composition root that had to reach inside a feature to start it would be a
/// feature that did not compose.
void main() {
  final container = configureHarness();
  runApp(HarnessApp(router: buildHarnessRouter(container).build()));
}
