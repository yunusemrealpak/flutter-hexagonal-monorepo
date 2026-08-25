import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';

import 'session_dto.dart';
import 'session_mapper.dart';

/// Keeps the session in the platform's secure storage.
///
/// `SecureStore` rather than `KeyValueStore`, and the distinction is the whole
/// reason `core_ports` declares both. A session carries a live bearer token;
/// preferences carry a theme. The first belongs behind whatever the device
/// calls a keychain and the second does not need to be, and a store that
/// treated them alike would either encrypt a theme or leave a token in plain
/// text — and it would be the second.
final class SecureSessionStore implements SessionStore {
  /// Creates the store over [store].
  const SecureSessionStore({required this.store});

  /// Where the session is kept.
  final SecureStore store;

  /// The key the session is kept under.
  static const String key = 'identity/session';

  @override
  Future<Result<Session?, IdentityFailure>> read() async {
    final read = await store.read(key);

    return switch (read) {
      Failed(:final failure) => _readFailure(failure),
      Success(value: null) => const Success(null),
      Success(value: final raw?) => _decode(raw),
    };
  }

  @override
  Future<Result<void, IdentityFailure>> write(Session session) async {
    final written = await store.write(
      key,
      jsonEncode(SessionMapper.toDto(session).toJson()),
    );

    return written.mapFailure(_translate);
  }

  @override
  Future<Result<void, IdentityFailure>> clear() async {
    final deleted = await store.delete(key);
    return deleted.mapFailure(_translate);
  }

  /// A key the OS invalidated reads as "no session", not as a failure.
  ///
  /// `SecureStoreKeyInvalidated` is what a keychain says after the user
  /// changed their passcode or restored the phone from a backup: the bytes are
  /// gone for good. That is exactly a signed-out device, and reporting it as a
  /// failure would leave the app stuck on an error screen it can never clear —
  /// the user would have to reinstall to sign in again.
  Result<Session?, IdentityFailure> _readFailure(SecureStoreFailure failure) =>
      switch (failure) {
        SecureStoreKeyInvalidated() => const Success(null),
        _ => Failed(_translate(failure)),
      };

  Result<Session?, IdentityFailure> _decode(String raw) {
    final decoded = _tryDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      // A stored session we cannot read is a signed-out device rather than a
      // broken one: there is nothing a user can do about a corrupt keychain
      // entry except sign in again, which is what returning null lets them do.
      return const Success(null);
    }
    return SessionMapper.toDomain(
      SessionDto.fromJson(decoded),
    ).map<Session?>((session) => session);
  }

  static Object? _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static IdentityFailure _translate(SecureStoreFailure failure) =>
      switch (failure) {
        SecureStoreUnavailable() => const IdentityUnavailable(
          detail: 'secure store unavailable',
        ),
        SecureStoreAuthenticationFailed() => const IdentityUnavailable(
          detail: 'the device refused to unlock the store',
        ),
        SecureStoreKeyInvalidated() => const IdentityUnavailable(
          detail: 'stored key was invalidated',
        ),
      };
}
