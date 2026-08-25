import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'session_builder.dart';

/// A `DeviceRegistry` whose answer a test can change mid-run.
///
/// Changing [binding] between calls is how the rule the specification asks for
/// becomes testable: a session issued against one fingerprint, presented after
/// the device reports another, has to be refused. Without a registry that can
/// change its mind, that branch has no way to be reached.
final class FakeDeviceRegistry implements DeviceRegistry {
  /// Starts out reporting the same device `SessionBuilder` binds to.
  FakeDeviceRegistry({DeviceBinding? binding})
    : binding = binding ?? SessionBuilder().buildBinding();

  /// What this registry currently reports.
  DeviceBinding binding;

  /// Actors that have been bound to this device, in order.
  final List<ActorId> bound = [];

  final List<IdentityFailure> _queuedFailures = [];

  /// Makes the next call return [failure].
  void failNextWith(IdentityFailure failure) => _queuedFailures.add(failure);

  @override
  Future<Result<DeviceBinding, IdentityFailure>> currentBinding() async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);
    return Success(binding);
  }

  @override
  Future<Result<DeviceBinding, IdentityFailure>> bind(ActorId actorId) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    bound.add(actorId);
    return Success(binding);
  }

  IdentityFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
