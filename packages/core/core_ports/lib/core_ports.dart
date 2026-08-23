/// The capabilities a feature is allowed to ask the outside world for.
///
/// Everything in this library is an interface with no implementation. That is
/// the point of the package: `_application` code depends on the shape of a
/// capability, and an app's composition root decides which adapter provides
/// it. The same use case runs against a device keychain in `app_courier` and
/// against an in-memory fake in `app_harness` without changing a line.
///
/// Two rules govern what belongs here. A port is in `core_ports` only when
/// more than one feature needs it and none of them owns it — anything a single
/// feature needs belongs in that feature's `_api`. And a port method returns
/// `Result` when the operation can fail, a plain value when it cannot;
/// `Clock`, `IdGenerator` and `RandomSource` have no failure mode, and giving
/// them one would put an unreachable branch at every call site.
library;

export 'src/analytics_sink.dart';
export 'src/clock.dart';
export 'src/device_permission.dart';
export 'src/domain_event_bus.dart';
export 'src/feature_flag_reader.dart';
export 'src/id_generator.dart';
export 'src/key_value_store.dart';
export 'src/log_level.dart';
export 'src/logger.dart';
export 'src/network_condition.dart';
export 'src/network_status.dart';
export 'src/permission_requester.dart';
export 'src/permission_state.dart';
export 'src/random_source.dart';
export 'src/secure_store.dart';
export 'src/secure_store_failure.dart';
export 'src/store_failure.dart';
