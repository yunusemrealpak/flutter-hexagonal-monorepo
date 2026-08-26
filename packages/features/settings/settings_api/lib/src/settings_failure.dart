import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the settings ports.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them. Declared here rather than
/// in an adapter, because a failure is part of a contract: the package that
/// owns the port owns what failing it means.
sealed class SettingsFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const SettingsFailure();
}

/// The preference store could not be reached, so nothing is known either way.
///
/// Distinct from a successful read of nothing. "This actor has never changed a
/// preference" is an ordinary state with an obvious answer — the defaults —
/// while "the disk did not answer" is a state where writing the defaults over
/// the top would destroy the choices somebody made.
final class PreferencesUnavailable extends SettingsFailure {
  /// Records that the store was unreachable, with an optional [detail] for the
  /// log.
  const PreferencesUnavailable({this.detail});

  /// Adapter-supplied context. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'PreferencesUnavailable(${detail ?? 'no detail'})';
}

/// Something was stored for the actor, and it could not be read back.
///
/// Usually a preference the product used to write and no longer understands.
/// A separate case from [PreferencesUnavailable] because the recovery differs:
/// a corrupt record can be replaced with the defaults, an unreachable store
/// cannot.
final class PreferencesCorrupted extends SettingsFailure {
  /// Records that the record stored for [actorId] could not be decoded.
  const PreferencesCorrupted(this.actorId);

  /// Whose record could not be decoded.
  final String actorId;

  @override
  String toString() => 'PreferencesCorrupted($actorId)';
}

/// A preference value was refused at construction.
///
/// [field] names the preference and [reason] says what was wrong with the
/// value. Both are for the log and for a developer; neither is a message to
/// show anybody.
final class MalformedPreference extends SettingsFailure {
  /// Records that [field] was given a value described by [reason].
  const MalformedPreference({required this.field, required this.reason});

  /// Which preference refused its value.
  final String field;

  /// Why the value was refused.
  final String reason;

  @override
  String toString() => 'MalformedPreference($field: $reason)';
}
