/// The permission_handler-backed adapter for the `PermissionRequester` port.
///
/// A ninth platform package where the specification lists eight, and the
/// reason is that `PermissionRequester` has no natural owner among the other
/// eight. Camera permission is needed by `media_capture`, location permission
/// by `location_service`, notification permission by `push_messaging`, and one
/// plugin covers all three. Hosting the adapter in any one of those packages
/// would mean the other two reach for a dependency they have no business
/// having — and the constitution forbids `platform/*` depending on
/// `platform/*` precisely so that cannot happen quietly.
///
/// So the three consumers depend on the *port*, which arrives through their
/// constructors, and an application's composition root is where this adapter
/// meets them. That is the same shape every other port in the workspace takes;
/// the only unusual thing here is that the port lives in `core_ports` while
/// its adapter needed a package of its own.
library;

export 'src/device_permission_requester.dart';
export 'src/permission_mapping.dart';
