// See the note in result.dart: `@immutable` lives in package:meta, and
// core_kernel takes no third-party dependency. Subclasses are immutable by
// convention and evolve through `copyWith`.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'value_object.dart';

/// Base class for a domain object that is defined by its identifier rather
/// than by its contents.
///
/// A shipment that moves from `assigned` to `loaded` is still the same
/// shipment. That is what separates an entity from a [ValueObject], and it is
/// why equality here is identity-based: two instances with the same [id] are
/// the same entity even when every other field differs. Comparing entities
/// field by field would make "has this shipment changed?" and "is this the
/// same shipment?" the same question, and they are not.
///
/// Subclasses are immutable and evolve through `copyWith`; behaviour lives on
/// the entity rather than in a use case, so that an invalid state cannot be
/// produced no matter which adapter drives the change.
///
/// `runtimeType` participates in equality, so a `Shipment` and a `Consignee`
/// that happen to share an identifier value are not equal.
abstract class Entity<TId> {
  /// Binds this entity to the identifier that defines it.
  ///
  /// Named rather than positional so that subclasses — which usually carry
  /// several fields — can forward it as `required super.id` and keep every
  /// argument at their own call sites labelled.
  const Entity({required this.id});

  /// The identifier that defines this entity.
  ///
  /// Usually a [ValueObject] such as `ShipmentId` rather than a bare `String`,
  /// so that one kind of identifier cannot be passed where another is meant.
  final TId id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entity<TId> &&
          other.runtimeType == runtimeType &&
          other.id == id;

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  String toString() => '$runtimeType($id)';
}
