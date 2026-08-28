import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:http_dio/http_dio.dart';
import 'package:injectable/injectable.dart';

/// The cross-cutting ports, answered by fakes.
///
/// A `@module` is how `injectable` registers something it did not annotate,
/// and it is the only shape available here: rule I6 forbids an annotation
/// inside a package, so every adapter in the workspace is a plain class and an
/// app is where the annotations live. That constraint turns out to be the
/// feature — the registration list *is* the composition, written down in one
/// file per concern rather than scattered across seventy packages as metadata.
///
/// Every registration here is a `@lazySingleton`. These fakes hold state a
/// test wants to inspect between calls, and a factory would hand each caller
/// its own empty one.
@module
abstract class HarnessPorts {
  /// A clock that does not move unless a test moves it.
  ///
  /// Fixed rather than fast: hermeticity (§7.4) is not about speed, it is
  /// about a test asking the same question twice and getting the same answer.
  @lazySingleton
  Clock get clock => FakeClock(DateTime.utc(2026, 3, 14, 9));

  /// Identifiers that count rather than randomise.
  @lazySingleton
  IdGenerator get ids => FakeIdGenerator();

  /// A scripted sequence, so a shuffle is reproducible.
  @lazySingleton
  RandomSource get random => FakeRandomSource();

  /// Everything logged, kept for a test to read.
  @lazySingleton
  Logger get logger => RecordingLogger();

  /// Every event published, kept in order.
  @lazySingleton
  DomainEventBus get events => RecordingEventBus();

  /// Every analytics record, kept.
  @lazySingleton
  AnalyticsSink get analytics => RecordingAnalyticsSink();

  /// A network that is up until a test says otherwise.
  @lazySingleton
  NetworkStatus get network => FakeNetworkStatus();

  /// Permissions granted without a device asking anybody.
  @lazySingleton
  PermissionRequester get permissions => FakePermissionRequester();

  /// Flags off by default.
  @lazySingleton
  FeatureFlagReader get flags => FakeFeatureFlagReader();

  /// A key-value store in a map.
  @lazySingleton
  KeyValueStore get keyValues => InMemoryKeyValueStore();

  /// A secure store in a map.
  ///
  /// `InMemorySecureStore` rather than `KeychainSecureStore`, and it comes
  /// from `core_testing` rather than from `platform/secure_store` because
  /// `SecureStore` is declared in `core_ports` — §2.2's rule that a fake lives
  /// beside the contract it imitates, applied in the direction people forget.
  @lazySingleton
  SecureStore get secureStore => InMemorySecureStore();

  /// A transport that answers from a queue and never opens a socket.
  ///
  /// Registered as the concrete type as well as the interface: the harness's
  /// own tests enqueue responses on it, and a caller holding `HttpTransport`
  /// has no way to. Both registrations resolve to the same instance, which is
  /// what makes that safe.
  @lazySingleton
  FakeHttpTransport get fakeTransport => FakeHttpTransport();

  /// The same instance, seen as the contract adapters take.
  @lazySingleton
  HttpTransport transport(FakeHttpTransport fake) => fake;
}
