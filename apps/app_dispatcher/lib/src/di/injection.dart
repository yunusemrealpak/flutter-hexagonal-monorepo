import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'dispatcher_platform.dart';
import 'injection.config.dart';

/// This app's container.
///
/// Its own instance rather than `GetIt.instance`, for the reason every
/// composition root in this workspace uses one: a global container is a
/// container two tests share, and the first test's SQLite file then fails the
/// second in a way that looks like an adapter bug.
final GetIt dispatcherContainer = GetIt.asNewInstance();

/// Registers everything this app composes, over [platform].
///
/// The bindings are registered *before* `init()` so that the generated
/// registrations can depend on them. That is what makes `DispatcherPlatform`
/// a parameter of the composition rather than a global somebody reaches for —
/// `main.dart` passes the real plugins and a test passes whatever it likes,
/// and everything between here and a dispatcher's screen is identical.
/// `DispatcherPlatform` is registered by hand above, so the generator is told
/// not to look for a registration it will never find. Missing dependencies
/// throw for everything else: a module that asks for something nobody
/// provides should fail the build rather than the first screen that opens.
@InjectableInit(
  ignoreUnregisteredTypes: [DispatcherPlatform],
  throwOnMissingDependencies: true,
  // Rule S3 reads `package:*/src/` as one thing: somebody reached across a
  // boundary. That is exact only because intra-package imports are relative by
  // convention (CLAUDE.md section 3), and a generator emitting absolute
  // self-imports breaks the premise — which is what arch_check reported the
  // first time this file was generated. Fixing the source rather than the rule
  // is what section 4.2 point 6 asks for.
  preferRelativeImports: true,
)
Future<GetIt> configureDispatcher(DispatcherPlatform platform) async {
  dispatcherContainer.registerSingleton<DispatcherPlatform>(platform);
  return dispatcherContainer.init();
}
