import 'package:core_ports/core_ports.dart';
import 'package:flutter/widgets.dart';
import 'package:sync_api/sync_api.dart';

import 'src/di/injection.dart';
import 'src/harness_app.dart';
import 'src/router/harness_routes.dart';
import 'src/sync/sync_orchestrator.dart';

/// Re-exported so a test can build the same app the entry point does.
///
/// A test that assembled its own would be a test of a second app.
export 'src/di/injection.dart' show configureHarness, harnessContainer;
export 'src/harness_app.dart';
export 'src/router/harness_routes.dart';
export 'src/router/peyk_router.dart';
export 'src/router/session_refresh.dart';
export 'src/sync/sync_orchestrator.dart';

/// Stands every feature up on fakes.
///
/// Four lines, and that is the measure of whether the architecture worked: a
/// composition root that had to reach inside a feature to start it would be a
/// feature that did not compose.
void main() {
  final container = configureHarness();
  // Nothing enqueues through this and nothing waits for it: it decides when
  // a queue that already holds the work is worth attempting. Started before
  // the first frame so that an app reopened on the street sends what was
  // written in a basement.
  SyncOrchestrator(
    sync: container<SyncFacade>(),
    network: container<NetworkStatus>(),
    logger: container<Logger>(),
  ).start();

  runApp(HarnessApp(router: buildHarnessRouter(container).build()));
}
