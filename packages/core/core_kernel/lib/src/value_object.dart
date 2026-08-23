// See the note in result.dart: `@immutable` lives in package:meta, and
// core_kernel takes no third-party dependency. Immutability is structural here
// — the single field is final and the constructor is const.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'entity.dart';

/// Base class for a value that is defined entirely by what it holds.
///
/// A value object has no identity of its own: two `Barcode`s with the same
/// digits are the same barcode. That is the whole difference from [Entity],
/// which is defined by its identifier and stays the same thing as its contents
/// change.
///
/// This class supplies the equality, hashing and printing that follow from
/// that definition. It deliberately does not supply validation: subclasses use
/// a private constructor plus a factory that returns a `Result`, so that an
/// invalid instance cannot be constructed at all.
///
/// ```dart
/// final class Barcode extends ValueObject<String> {
///   const Barcode._(super.value);
///
///   static Result<Barcode, BarcodeFailure> parse(String raw) {
///     final trimmed = raw.trim();
///     if (trimmed.length != 12) {
///       return const Failed(BarcodeFailure.wrongLength());
///     }
///     return Success(Barcode._(trimmed));
///   }
/// }
/// ```
///
/// `runtimeType` participates in equality, so a `Barcode` and a `TrackingCode`
/// wrapping the same string are not equal. Wrapping a primitive is only worth
/// the ceremony if the wrapper actually distinguishes it from every other
/// string in the system.
abstract class ValueObject<T> {
  /// Stores [value] as this object's entire identity.
  const ValueObject(this.value);

  /// The underlying value.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueObject<T> &&
          other.runtimeType == runtimeType &&
          other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => '$runtimeType($value)';
}
