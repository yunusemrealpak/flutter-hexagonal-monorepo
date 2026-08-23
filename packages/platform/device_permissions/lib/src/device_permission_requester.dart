import 'package:core_ports/core_ports.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart'
    as handler;
import 'permission_mapping.dart';

/// The namespace the ask log occupies in the key-value store.
const _askLogNamespace = 'device_permissions';

/// The [PermissionRequester] the shipped applications run on.
///
/// ## The gap this adapter fills
///
/// The port declares five states; `permission_handler` reports four that map
/// onto them and has no equivalent of [PermissionState.notDetermined]. On iOS
/// a permission that has never been asked for reports as `denied`, which is
/// the same answer the platform gives for one the user actively refused.
///
/// The difference matters to the product. "Never asked" is a moment to explain
/// why the camera is needed and then prompt; "refused" is a moment to offer a
/// way around it. Collapsing them produces the rationale screen a courier sees
/// every single day after saying no once.
///
/// So the adapter earns the state the platform will not give it: it records
/// every permission it has asked for, and reports
/// [PermissionState.notDetermined] when the platform says `denied` for one it
/// has no record of asking. The
/// record is durable — it lives in the injected [KeyValueStore] — because a
/// memory of what the user was asked has to survive a restart to be worth
/// anything.
///
/// ## When the record cannot be read
///
/// A failing store makes the adapter report the platform's own answer,
/// `denied`. That is the conservative direction: claiming `notDetermined` would
/// make the app prompt again for something the user has already refused, and
/// on iOS a second prompt is not shown at all — so the courier would see a
/// rationale screen leading to a button that does nothing.
final class DevicePermissionRequester implements PermissionRequester {
  /// Asks through the given platform implementation, remembering what has
  /// been asked in the given store.
  const DevicePermissionRequester(this._platform, this._askLog);

  final handler.PermissionHandlerPlatform _platform;
  final KeyValueStore _askLog;

  @override
  Future<PermissionState> status(DevicePermission permission) async {
    final status = await _platform.checkPermissionStatus(
      toHandlerPermission(permission),
    );
    final state = toPermissionState(status);
    if (state != PermissionState.denied) {
      return state;
    }
    return await _hasBeenAsked(permission)
        ? PermissionState.denied
        : PermissionState.notDetermined;
  }

  @override
  Future<PermissionState> request(DevicePermission permission) async {
    final handlerPermission = toHandlerPermission(permission);
    final results = await _platform.requestPermissions([handlerPermission]);
    await _recordAsked(permission);
    final status = results[handlerPermission];
    if (status == null) {
      // The plugin answered about a permission nobody asked about. Nothing
      // useful can be said, and the port has no failure branch to say it in,
      // so the honest answer is the one that makes the caller ask again.
      return PermissionState.notDetermined;
    }
    return toPermissionState(status);
  }

  Future<bool> _hasBeenAsked(DevicePermission permission) async {
    final result = await _askLog.read(_keyFor(permission));
    // A store that cannot be read is treated as "already asked": see the class
    // documentation for why that is the safe direction.
    return result.fold((value) => value != null, (_) => true);
  }

  Future<void> _recordAsked(DevicePermission permission) async {
    // The write's failure is deliberately ignored. Losing the record costs one
    // extra rationale screen; failing the request because a preference could
    // not be written costs the courier the capability itself.
    await _askLog.write(_keyFor(permission), 'asked');
  }

  String _keyFor(DevicePermission permission) =>
      '$_askLogNamespace.${permission.name}';
}
