import 'dart:collection';

import 'package:meta/meta.dart';

import 'permission.dart';

/// An immutable, unordered set of [Permission]s.
///
/// This is a value — two sets holding the same permissions are the same set —
/// but it does not extend `ValueObject<Set<Permission>>`, and the reason is
/// worth stating rather than working around. `ValueObject` compares with `==`,
/// and `Set.==` in Dart is identity-based: two separately built sets holding
/// the same three permissions would compare unequal, so every test that
/// constructed an expectation would fail for a reason that has nothing to do
/// with permissions. Membership equality has to be written out, and a subclass
/// that overrode both of its base class's only two behaviours would be
/// inheriting nothing but the name.
@immutable
final class PermissionSet {
  const PermissionSet._(this._values);

  /// Builds a set from [permissions], discarding duplicates.
  factory PermissionSet.of(Iterable<Permission> permissions) =>
      PermissionSet._(Set<Permission>.unmodifiable(permissions));

  /// The set that grants nothing.
  static const PermissionSet none = PermissionSet._(<Permission>{});

  final Set<Permission> _values;

  /// The permissions in this set, as an unmodifiable view.
  ///
  /// A view rather than a copy: callers that only read pay nothing, and a
  /// caller that tries to write gets an error instead of silently mutating a
  /// value object.
  Set<Permission> get values => UnmodifiableSetView<Permission>(_values);

  /// Whether [permission] is granted.
  bool contains(Permission permission) => _values.contains(permission);

  /// The permissions granted by this set or by [other].
  PermissionSet union(PermissionSet other) =>
      PermissionSet.of(<Permission>{..._values, ...other._values});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionSet &&
          other._values.length == _values.length &&
          other._values.containsAll(_values);

  /// Order-independent, because the value this class carries is a set.
  ///
  /// Exclusive-or is sound here for the same reason it is unsound in general:
  /// it cancels a value out when it appears twice, and a set cannot hold the
  /// same permission twice.
  @override
  int get hashCode =>
      _values.fold<int>(0, (hash, permission) => hash ^ permission.hashCode);

  @override
  String toString() =>
      'PermissionSet(${_values.map((p) => p.name).toList()..sort()})';
}
