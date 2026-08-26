import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:settings_api/settings_api.dart';

import 'preferences_dto.dart';

/// Answers the preferences contract out of a key-value store.
///
/// The adapter half of this package. It sits on the far side of
/// `PreferencesStore` from the use cases beside it, and the only reason it can
/// see them at all is that a reduced-split feature puts both in one package.
/// Nothing in the use cases imports this file, and nothing here imports them —
/// in a full split that would be a compiler error, and here it is a rule the
/// package keeps for itself so that the day it splits is a move rather than a
/// rewrite.
///
/// `KeyValueStore` is a port from `core_ports`, not a device API. Which store
/// it is — encrypted preferences on a phone, an in-memory map in a test — is
/// an app's decision, and this class cannot tell the difference.
///
/// **It does not import `identity_api`.** It takes the actor as a `String`,
/// because that is what `PreferencesStore` promises. The rule that a driven
/// port speaks in raw identifiers is enforced by the compiler in an
/// `_infrastructure` package and kept by hand here.
final class KeyValuePreferencesStore implements PreferencesStore {
  /// Creates the adapter over the store it keeps the record in.
  const KeyValuePreferencesStore({required this._store});

  final KeyValueStore _store;

  /// The prefix every key this adapter writes carries.
  ///
  /// A namespace rather than a bare actor identifier, because the store is
  /// shared with every other feature that keeps a scalar and two features
  /// choosing the same key would silently overwrite each other.
  static const keyPrefix = 'settings.preferences.';

  @override
  Future<Result<UserPreferences?, SettingsFailure>> read(String actorId) async {
    final stored = await _store.read(_keyFor(actorId));

    return switch (stored) {
      Failed(:final failure) => Failed(_translate(failure, actorId)),
      // A key that holds nothing is a successful read of nothing. Only the
      // caller knows whether that means defaults or a first-run flow, so the
      // decision is not taken here.
      Success(value: null) => const Success(null),
      Success(value: final raw?) => switch (PreferencesDto.decode(raw)) {
        null => Failed(PreferencesCorrupted(actorId)),
        final dto => dto.toDomain().map<UserPreferences?>((value) => value),
      },
    };
  }

  @override
  Future<Result<void, SettingsFailure>> write(
    String actorId,
    UserPreferences preferences,
  ) async {
    final written = await _store.write(
      _keyFor(actorId),
      PreferencesDto.fromDomain(preferences).encode(),
    );

    return switch (written) {
      Failed(:final failure) => Failed(_translate(failure, actorId)),
      Success() => const Success(null),
    };
  }

  String _keyFor(String actorId) => '$keyPrefix$actorId';

  /// Turns a storage failure into a settings failure.
  ///
  /// The translation is not cosmetic. `StoreCorrupted` and `StoreUnavailable`
  /// call for different behaviour upstream — one can be recovered from by
  /// writing the defaults over the top and the other cannot — so they are kept
  /// apart, while `StoreOutOfSpace` joins the unavailable case because a
  /// caller can do nothing different about it.
  SettingsFailure _translate(StoreFailure failure, String actorId) =>
      switch (failure) {
        StoreCorrupted() => PreferencesCorrupted(actorId),
        StoreUnavailable(:final detail) => PreferencesUnavailable(
          detail: detail,
        ),
        StoreOutOfSpace() => const PreferencesUnavailable(
          detail: 'no room to store preferences',
        ),
      };
}
