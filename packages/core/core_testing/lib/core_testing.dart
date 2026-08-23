/// Behavioural fakes for the `core_ports` capabilities.
///
/// Fakes, not mocks. Every one of these really does the thing: the store
/// stores, the bus delivers, the navigation keeps a history that `back`
/// actually pops. A test written against them exercises the caller's logic
/// rather than a script of expected calls, which is why it keeps passing when
/// the caller is refactored and starts failing when the caller is broken.
///
/// Three of them exist to remove ambient state from the suite —
/// `FakeClock`, `FakeIdGenerator` and `FakeRandomSource`. Between them they
/// are why no test in this workspace needs to sleep, retry, or match an
/// identifier with a wildcard.
///
/// The fakes that stand in for fallible ports can be told to fail
/// (`InMemoryKeyValueStore.failNextWith` and its secure-store counterpart).
/// Failure is part of a port's contract, so the fake that stands in for that
/// contract has to be able to produce it — otherwise the failure branches of
/// every caller stay untested.
library;

export 'src/analytics_record.dart';
export 'src/fake_clock.dart';
export 'src/fake_feature_flag_reader.dart';
export 'src/fake_id_generator.dart';
export 'src/fake_network_status.dart';
export 'src/fake_permission_requester.dart';
export 'src/fake_random_source.dart';
export 'src/in_memory_key_value_store.dart';
export 'src/in_memory_secure_store.dart';
export 'src/log_record.dart';
export 'src/navigation_record.dart';
export 'src/recording_analytics_sink.dart';
export 'src/recording_event_bus.dart';
export 'src/recording_logger.dart';
export 'src/recording_navigation.dart';
