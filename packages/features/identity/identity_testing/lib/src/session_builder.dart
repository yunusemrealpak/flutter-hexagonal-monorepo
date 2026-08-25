import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

/// Builds a session in whatever shape a test needs.
///
/// Every default is a valid, unremarkable session: one courier, one device, a
/// token with an hour left and a refresh window of a week. A test names only
/// the thing it is about — an expired token, a broken binding — and the rest
/// stays out of the way.
///
/// Every step returns a new builder, so a shared base can be branched twice
/// without one branch leaking into the other.
final class SessionBuilder {
  /// Starts from a valid session.
  SessionBuilder()
    : _actorId = 'courier-1',
      _displayName = 'Ali Veli',
      _roles = const {Role.courier},
      _grants = PermissionSet.none,
      _tokenValue = 'jwt.abc',
      _tokenLife = const Duration(hours: 1),
      _refreshWindow = const Duration(days: 7),
      _deviceId = 'handset-1',
      _fingerprint = 'sha256:aaa';

  SessionBuilder._(
    this._actorId,
    this._displayName,
    this._roles,
    this._grants,
    this._tokenValue,
    this._tokenLife,
    this._refreshWindow,
    this._deviceId,
    this._fingerprint,
  );

  /// The instant every session is measured from.
  ///
  /// A constant rather than a clock: rule A1, and a fixture whose timestamps
  /// move is a fixture that makes an equality assertion flake once a day.
  static final DateTime now = DateTime.utc(2026, 3, 14, 12);

  final String _actorId;
  final String _displayName;
  final Set<Role> _roles;
  final PermissionSet _grants;
  final String _tokenValue;
  final Duration _tokenLife;
  final Duration _refreshWindow;
  final String _deviceId;
  final String _fingerprint;

  /// Sets who is signed in.
  SessionBuilder actor(String id, {String? displayName}) =>
      _with(actorId: id, displayName: displayName);

  /// Sets the roles the actor holds.
  SessionBuilder withRoles(Set<Role> roles) => _with(roles: roles);

  /// Grants a permission to this actor personally.
  SessionBuilder granting(Permission permission) => _with(
    grants: _grants.union(PermissionSet.of([permission])),
  );

  /// Sets how long the access token has left, relative to [now].
  ///
  /// A negative duration produces an already expired token, which is the point
  /// of taking a `Duration` rather than a `DateTime`.
  SessionBuilder tokenLife(Duration life) => _with(tokenLife: life);

  /// Sets how long the session can still be refreshed for.
  SessionBuilder refreshWindow(Duration window) => _with(refreshWindow: window);

  /// Sets the device this session is tied to.
  SessionBuilder onDevice(String deviceId, {String? fingerprint}) =>
      _with(deviceId: deviceId, fingerprint: fingerprint);

  /// Sets the token text, for a test that cares which token it is.
  SessionBuilder withToken(String value) => _with(tokenValue: value);

  /// The actor this builder produces, on its own.
  Actor buildActor() => Actor(
    id: _unwrap(ActorId.parse(_actorId)),
    displayName: _displayName,
    roles: _roles,
    directGrants: _grants,
  );

  /// The device binding this builder produces, on its own.
  DeviceBinding buildBinding() => DeviceBinding(
    deviceId: _deviceId,
    fingerprint: _fingerprint,
    boundAt: now.subtract(const Duration(days: 30)),
  );

  /// The session.
  Session build() => Session(
    actor: buildActor(),
    accessToken: _unwrap(
      AccessToken.issue(
        value: _tokenValue,
        expiresAt: now.add(_tokenLife),
      ),
    ),
    deviceBinding: buildBinding(),
    refreshableUntil: now.add(_refreshWindow),
  );

  SessionBuilder _with({
    String? actorId,
    String? displayName,
    Set<Role>? roles,
    PermissionSet? grants,
    String? tokenValue,
    Duration? tokenLife,
    Duration? refreshWindow,
    String? deviceId,
    String? fingerprint,
  }) => SessionBuilder._(
    actorId ?? _actorId,
    displayName ?? _displayName,
    roles ?? _roles,
    grants ?? _grants,
    tokenValue ?? _tokenValue,
    tokenLife ?? _tokenLife,
    refreshWindow ?? _refreshWindow,
    deviceId ?? _deviceId,
    fingerprint ?? _fingerprint,
  );

  static T _unwrap<T, F>(Result<T, F> result) => result.fold(
    (value) => value,
    (failure) => throw StateError('SessionBuilder: $failure'),
  );
}
