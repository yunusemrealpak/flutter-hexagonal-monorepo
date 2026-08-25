import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:http_dio/http_dio.dart';
import 'package:identity_api/identity_api.dart';

import 'session_dto.dart';
import 'session_mapper.dart';

/// Authenticates a courier against the operation's own account directory.
///
/// The adapter `app_courier` binds. It speaks the two credential kinds a
/// handset uses — a password the first time, a device token afterwards — and
/// refuses an SSO assertion, because a courier's handset has no corporate
/// identity provider behind it.
///
/// This is one half of scenario 5. `SsoCredentialGateway` is the other, both
/// satisfy `CredentialGateway`, and `identity_application` does not change a
/// line between them: which one is bound is decided in an app's composition
/// root.
final class DeviceBoundCredentialGateway implements CredentialGateway {
  /// Creates the adapter over [transport].
  const DeviceBoundCredentialGateway({required this.transport});

  /// The transport requests are sent on.
  final HttpTransport transport;

  @override
  Future<Result<Session, IdentityFailure>> authenticate({
    required Credentials credentials,
    required DeviceBinding binding,
  }) async {
    final body = switch (credentials) {
      PasswordCredentials(:final actorId, :final secret) => {
        'grant': 'password',
        'actor': actorId.value,
        'secret': secret,
      },
      DeviceTokenCredentials(:final actorId, :final token) => {
        'grant': 'device_token',
        'actor': actorId.value,
        'token': token,
      },
      // Refused here rather than sent and rejected by the server. An adapter
      // that forwarded credentials it cannot serve would turn a configuration
      // mistake into a network round trip and a message nobody can act on.
      SsoAssertionCredentials() => null,
    };
    if (body == null) return const Failed(InvalidCredentials());

    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.post,
        path: '/sessions',
        body: jsonEncode({
          ...body,
          'device': {
            'deviceId': binding.deviceId,
            'fingerprint': binding.fingerprint,
          },
        }),
      ),
    );

    return _decode(response);
  }

  @override
  Future<Result<Session, IdentityFailure>> refresh(Session session) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.post,
        path: '/sessions/refresh',
        headers: {'Authorization': 'Bearer ${session.accessToken.value}'},
      ),
    );

    return _decode(response);
  }

  @override
  Future<Result<void, IdentityFailure>> revoke(Session session) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.delete,
        path: '/sessions',
        headers: {'Authorization': 'Bearer ${session.accessToken.value}'},
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(translate(failure)),
      Success() => const Success(null),
    };
  }

  Result<Session, IdentityFailure> _decode(
    Result<HttpResponse, TransportFailure> response,
  ) => switch (response) {
    Failed(:final failure) => Failed(translate(failure)),
    Success(value: final ok) => _body(ok.body),
  };

  static Result<Session, IdentityFailure> _body(Object? body) {
    final decoded = body is String ? _tryDecode(body) : body;
    if (decoded is! Map<String, dynamic>) {
      return const Failed(
        IdentityUnavailable(detail: 'response is not a JSON object'),
      );
    }
    return SessionMapper.toDomain(SessionDto.fromJson(decoded));
  }

  static Object? _tryDecode(String raw) {
    // The boundary. Letting a FormatException out would put an exception
    // across a port, which invariant 1.2.9 forbids.
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  /// Turns a transport failure into the vocabulary the port promises.
  ///
  /// Shared with `SsoCredentialGateway`, because the mapping is a property of
  /// the port rather than of either adapter: a 401 means the credentials were
  /// refused however they were presented.
  static IdentityFailure translate(TransportFailure failure) =>
      switch (failure) {
        TransportRejected(statusCode: 401) => const InvalidCredentials(),
        TransportRejected(statusCode: 403) => const SessionExpired(),
        TransportRejected(:final statusCode) => IdentityUnavailable(
          detail: 'rejected with $statusCode',
        ),
        TransportOffline(:final detail) => IdentityUnavailable(detail: detail),
        TransportTimeout(:final phase) => IdentityUnavailable(
          detail: 'timed out while ${phase.name}ing',
        ),
        TransportCancelled() => const IdentityUnavailable(detail: 'cancelled'),
        TransportCertificateRejected() => const IdentityUnavailable(
          detail: 'certificate rejected',
        ),
        TransportUnexpected(:final detail) => IdentityUnavailable(
          detail: detail,
        ),
      };
}
