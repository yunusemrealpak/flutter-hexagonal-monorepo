import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:notifications_api/notifications_api.dart';

/// Says whether alerts reach this device, reconciling two facts that can
/// disagree.
///
/// The operating system owns whether this application may show a notification.
/// The registry owns whether this device ever asked to be sent one for this
/// person. Neither is sufficient:
///
/// - the permission alone cannot tell a courier who turned alerts on from one
///   who granted the permission for something else and never did;
/// - the registry alone cannot tell either of them from a courier who turned
///   notifications off in the phone's own settings afterwards, which the
///   application is never told about.
///
/// **The permission is read first, and `AlertsUnavailable` short-circuits.** A
/// device that may not be asked again has no use for the stored fact, so that
/// answer cannot fail on a store read — which matters, because it is the one
/// answer whose screen has something to offer.
///
/// A use case rather than a method on the coordinator, for the reason
/// `OpenAlerts` gives: the ports belong to a use case and the coordinator
/// composes use cases. It holds `PermissionRequester` from `core_ports`, which
/// is what makes the whole matrix testable against a fake instead of a device.
final class ReadAlertState
    implements UseCase<String, Result<AlertState, NotificationsFailure>> {
  /// Creates the use case.
  const ReadAlertState({required this._registry, required this._permissions});

  final AlertRegistry _registry;
  final PermissionRequester _permissions;

  @override
  Future<Result<AlertState, NotificationsFailure>> call(String actorId) async {
    final permission = await _permissions.status(
      DevicePermission.notifications,
    );

    switch (permission) {
      case PermissionState.permanentlyDenied:
      case PermissionState.restricted:
        return const Success(AlertsUnavailable());
      case PermissionState.notDetermined:
      case PermissionState.denied:
        // Asking is still allowed, so the offer is the same one a device that
        // never opened alerts gets. Reading the registry here would let a
        // stale "open" contradict the operating system.
        return const Success(AlertsClosed());
      case PermissionState.granted:
        final open = await _registry.isOpenFor(actorId);
        return open.map(
          (isOpen) => isOpen ? const AlertsOpen() : const AlertsClosed(),
        );
    }
  }
}
