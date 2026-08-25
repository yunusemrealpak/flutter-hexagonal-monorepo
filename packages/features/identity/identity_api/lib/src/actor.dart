import 'package:core_kernel/core_kernel.dart';

import 'actor_id.dart';
import 'permission.dart';
import 'permission_set.dart';
import 'role.dart';

/// Who is acting: a courier, a dispatcher, a supervisor, an auditor.
///
/// An [Entity], so equality is by [id]: the same courier whose display name
/// was corrected and whose roles were widened is still the same courier. That
/// is the whole reason this type is hand-written rather than generated.
/// `freezed` produces structural equality, which would make "is this the same
/// actor?" and "has this actor changed?" the same question — and the second
/// question is one an entity is defined by being able to answer separately.
///
/// Behaviour lives here rather than in a use case. [can] is the single
/// definition of what an actor may do, so a screen, a use case and an adapter
/// that all need the answer cannot each arrive at a different one.
final class Actor extends Entity<ActorId> {
  /// Creates an actor with the roles and grants it holds.
  ///
  /// Not private and not validated, because there is nothing to validate:
  /// every field is already a type whose invalid values cannot be
  /// constructed. A factory returning a `Result` here would put an unreachable
  /// failure branch at every call site.
  Actor({
    required super.id,
    required this.displayName,
    required Set<Role> roles,
    this.directGrants = PermissionSet.none,
  }) : roles = Set<Role>.unmodifiable(roles);

  /// How this actor is named in the interface.
  final String displayName;

  /// The roles the actor holds, as an unmodifiable set.
  final Set<Role> roles;

  /// Permissions granted to this actor personally, on top of their roles.
  ///
  /// The escape hatch every real operation eventually needs: one courier who
  /// may also refund, without inventing a role for one person. Kept separate
  /// from [roles] so that revoking the exception does not touch the role.
  final PermissionSet directGrants;

  /// Everything this actor may do: the union of their roles' permissions and
  /// their personal grants.
  PermissionSet get permissions => roles.fold<PermissionSet>(
    directGrants,
    (granted, role) => granted.union(role.permissions),
  );

  /// Whether this actor may do [permission].
  ///
  /// This is the question `PermissionChecker` answers for other features. They
  /// ask through that port and never see this class, which is what keeps
  /// `shipments_presentation_dispatcher` free of any knowledge of how identity
  /// decides.
  bool can(Permission permission) => permissions.contains(permission);

  /// Returns a copy with the given fields replaced.
  ///
  /// Hand-written for the same reason equality is: the entity is small, and
  /// generating it would drag structural equality in with it.
  Actor copyWith({
    String? displayName,
    Set<Role>? roles,
    PermissionSet? directGrants,
  }) => Actor(
    id: id,
    displayName: displayName ?? this.displayName,
    roles: roles ?? this.roles,
    directGrants: directGrants ?? this.directGrants,
  );

  @override
  String toString() => 'Actor(${id.value}, $displayName, roles: $roles)';
}
