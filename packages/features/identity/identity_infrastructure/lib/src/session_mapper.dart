import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'session_dto.dart';

/// Translates a session between the outside world and the domain.
///
/// Hand-written for the reason every mapper in this workspace is: what makes
/// it worth writing is the deciding, not the copying. An unknown role name is
/// the case worth reading — it is *dropped*, not refused, and that is the
/// opposite of what `ShipmentMapper` does with an unknown shipment state.
///
/// The difference is which way each one fails safe. A shipment state this
/// build does not understand cannot be guessed at without risking a delivered
/// parcel going back on a manifest. A role this build does not understand can
/// only ever grant permissions this build also does not understand, so
/// dropping it removes access rather than inventing it — and refusing the
/// whole session instead would lock every courier out of an old app version
/// the day a new role is added on the server.
abstract final class SessionMapper {
  /// Builds a domain session from what arrived.
  static Result<Session, IdentityFailure> toDomain(SessionDto dto) {
    final actorDto = dto.actor;
    if (actorDto == null) {
      return const Failed(IdentityUnavailable(detail: 'actor is absent'));
    }
    final tokenValue = dto.accessToken;
    if (tokenValue == null) {
      return const Failed(MalformedAccessToken('absent'));
    }
    final deviceDto = dto.device;
    if (deviceDto == null) {
      return const Failed(
        IdentityUnavailable(detail: 'device binding is absent'),
      );
    }

    return _moment(dto.expiresAt, 'expiresAt').flatMap(
      (expiresAt) =>
          AccessToken.issue(
            value: tokenValue,
            expiresAt: expiresAt,
          ).flatMap(
            (token) =>
                _moment(dto.refreshableUntil, 'refreshableUntil').flatMap(
                  (refreshableUntil) => _actor(actorDto).flatMap(
                    (actor) => _binding(deviceDto).map(
                      (binding) => Session(
                        actor: actor,
                        accessToken: token,
                        deviceBinding: binding,
                        refreshableUntil: refreshableUntil,
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  /// Writes a domain session back out.
  ///
  /// Total, unlike [toDomain]: a `Session` cannot be invalid, because the only
  /// way to obtain one is through types whose factories refuse bad input.
  static SessionDto toDto(Session session) => SessionDto(
    actor: ActorDto(
      id: session.actor.id.value,
      displayName: session.actor.displayName,
      roles: session.actor.roles.map((role) => role.name).toList(),
      grants: session.actor.directGrants.values
          .map((permission) => permission.name)
          .toList(),
    ),
    accessToken: session.accessToken.value,
    expiresAt: session.accessToken.expiresAt.toIso8601String(),
    refreshableUntil: session.refreshableUntil.toIso8601String(),
    device: DeviceBindingDto(
      deviceId: session.deviceBinding.deviceId,
      fingerprint: session.deviceBinding.fingerprint,
      boundAt: session.deviceBinding.boundAt.toIso8601String(),
    ),
  );

  static Result<Actor, IdentityFailure> _actor(ActorDto dto) {
    final id = dto.id;
    if (id == null) return const Failed(MalformedActorId(''));

    return ActorId.parse(id).map(
      (actorId) => Actor(
        id: actorId,
        displayName: dto.displayName ?? actorId.value,
        roles: _roles(dto.roles ?? const []),
        directGrants: PermissionSet.of(_permissions(dto.grants ?? const [])),
      ),
    );
  }

  /// Reads role names, dropping any this build does not know.
  ///
  /// See the note on the class: dropping removes access rather than inventing
  /// it, and refusing outright would lock every courier out of an older app
  /// the day a new role appears on the server.
  static Set<Role> _roles(List<String> names) => {
    for (final name in names) ?_roleByName(name),
  };

  static Role? _roleByName(String name) {
    for (final role in Role.values) {
      if (role.name == name) return role;
    }
    return null;
  }

  static Iterable<Permission> _permissions(List<String> names) sync* {
    for (final name in names) {
      for (final permission in Permission.values) {
        if (permission.name == name) yield permission;
      }
    }
  }

  static Result<DeviceBinding, IdentityFailure> _binding(
    DeviceBindingDto dto,
  ) {
    final deviceId = dto.deviceId;
    final fingerprint = dto.fingerprint;
    if (deviceId == null || fingerprint == null) {
      return Failed(DeviceNotRegistered(deviceId ?? 'unknown'));
    }
    return _moment(dto.boundAt, 'boundAt').map(
      (boundAt) => DeviceBinding(
        deviceId: deviceId,
        fingerprint: fingerprint,
        boundAt: boundAt,
      ),
    );
  }

  static Result<DateTime, IdentityFailure> _moment(String? raw, String field) {
    if (raw == null) {
      return Failed(IdentityUnavailable(detail: '$field is absent'));
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return Failed(
        IdentityUnavailable(detail: '$field is not an ISO-8601 instant'),
      );
    }
    // UTC, always: AccessToken.issue refuses a local expiry, and the Clock
    // port promises UTC. Converting here rather than at the comparison keeps
    // the promise where it can be seen.
    return Success(parsed.toUtc());
  }
}
