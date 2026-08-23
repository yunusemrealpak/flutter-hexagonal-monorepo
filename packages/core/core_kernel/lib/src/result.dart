// The three types below form one sealed hierarchy, so the language requires
// them to live in the same library. This is the one place in the workspace
// where the "one public type per file" convention yields to that requirement.
//
// `avoid_equals_and_hash_code_on_mutable_classes` wants an `@immutable`
// annotation as proof of immutability, and that annotation lives in
// `package:meta`. core_kernel takes no third-party dependency, so the proof is
// structural instead: every field is final and every constructor is const.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'failure.dart';

/// The outcome of an operation that can fail.
///
/// Every port method whose operation can fail returns a `Result` rather than
/// throwing. That is what keeps failure part of a method's signature instead
/// of a fact the caller has to discover at runtime: the compiler will not let
/// a caller read the success value without saying what happens when there
/// isn't one.
///
/// `S` is the success value, `F` the failure. `F` is unconstrained so that
/// tooling and tests can use a plain `String`, but in product code it is
/// always a [Failure] subtype declared by the package that owns the port.
///
/// Consume it either by pattern matching, which the compiler checks for
/// exhaustiveness:
///
/// ```dart
/// final message = switch (result) {
///   Success(:final value) => 'signed in as ${value.name}',
///   Failed(:final failure) => 'could not sign in: $failure',
/// };
/// ```
///
/// or with [fold], [map], [flatMap] and [mapFailure] when the branches are
/// small enough that naming them costs more than it explains.
sealed class Result<S, F> {
  /// Const so that a `Result` can be built in a const context.
  const Result();

  /// Whether this is a [Success].
  ///
  /// Prefer pattern matching where the value itself is needed; this is for the
  /// cases where only the branch matters.
  bool get isSuccess => this is Success<S, F>;

  /// Whether this is a [Failed].
  bool get isFailure => this is Failed<S, F>;

  /// Collapses both branches into a single value of type `T`.
  ///
  /// The only way to leave a `Result` without deciding what a failure means.
  T fold<T>(
    T Function(S value) onSuccess,
    T Function(F failure) onFailure,
  );

  /// Transforms the success value, leaving a failure untouched.
  ///
  /// Use it when the transformation cannot itself fail; reach for [flatMap]
  /// when it can.
  Result<T, F> map<T>(T Function(S value) transform);

  /// Chains an operation that can itself fail, without nesting the results.
  ///
  /// This is what lets a use case read as a sequence of steps where the first
  /// failure short-circuits the rest.
  Result<T, F> flatMap<T>(Result<T, F> Function(S value) transform);

  /// Transforms the failure, leaving a success untouched.
  ///
  /// This is how an adapter translates a technology-specific failure into the
  /// `sealed` failure type its port declares, so that nothing about the
  /// transport reaches the caller.
  Result<S, T> mapFailure<T>(T Function(F failure) transform);
}

/// A [Result] that carries a value.
final class Success<S, F> extends Result<S, F> {
  /// Wraps [value] as the successful outcome.
  const Success(this.value);

  /// The value the operation produced.
  final S value;

  @override
  T fold<T>(
    T Function(S value) onSuccess,
    T Function(F failure) onFailure,
  ) => onSuccess(value);

  @override
  Result<T, F> map<T>(T Function(S value) transform) =>
      Success<T, F>(transform(value));

  @override
  Result<T, F> flatMap<T>(Result<T, F> Function(S value) transform) =>
      transform(value);

  @override
  Result<S, T> mapFailure<T>(T Function(F failure) transform) =>
      Success<S, T>(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<S, F> && other.value == value;

  @override
  int get hashCode => Object.hash(Success<S, F>, value);

  @override
  String toString() => 'Success($value)';
}

/// A [Result] that carries a failure.
///
/// Named `Failed` rather than `Failure` because [Failure] is the base class
/// this one usually carries, and a `Result` whose two cases were `Success` and
/// `Failure` would make `Failure` mean two different things one line apart.
final class Failed<S, F> extends Result<S, F> {
  /// Wraps [failure] as the unsuccessful outcome.
  const Failed(this.failure);

  /// What went wrong.
  final F failure;

  @override
  T fold<T>(
    T Function(S value) onSuccess,
    T Function(F failure) onFailure,
  ) => onFailure(failure);

  @override
  Result<T, F> map<T>(T Function(S value) transform) => Failed<T, F>(failure);

  @override
  Result<T, F> flatMap<T>(Result<T, F> Function(S value) transform) =>
      Failed<T, F>(failure);

  @override
  Result<S, T> mapFailure<T>(T Function(F failure) transform) =>
      Failed<S, T>(transform(failure));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failed<S, F> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Failed<S, F>, failure);

  @override
  String toString() => 'Failed($failure)';
}
