import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:http_dio/http_dio.dart';
import 'package:identity_api/identity_api.dart';

import 'device_bound_credential_gateway.dart';
import 'session_dto.dart';
import 'session_mapper.dart';

/// Authenticates a dispatcher against the corporate identity provider.
///
/// The adapter `app_dispatcher` binds, and the other half of scenario 5. It
/// speaks one credential kind — an assertion the provider issued — and refuses
/// the two a handset uses, because an operations desk signs in through the
/// company's own login and never types a Peyk password.
///
/// Everything above it is unchanged: `identity_application` calls the same
/// `CredentialGateway`, the same `Session` comes back, and the same two
/// business rules apply to it. The only difference is which composition root
/// wires which class.
final class SsoCredentialGateway implements CredentialGateway {
  /// Creates the adapter over [transport], against [realm].
  const SsoCredentialGateway({
    required this.transport,
    required this.realm,
  });

  /// The transport requests are sent on.
  final HttpTransport transport;

  /// Which corporate realm the assertion is validated against.
  ///
  /// Configured by the composition root rather than defaulted here. A default
  /// would make the environment something a call site could get wrong.
  final String realm;

  @override
  Future<Result<Session, IdentityFailure>> authenticate({
    required Credentials credentials,
    required DeviceBinding binding,
  }) async {
    if (credentials is! SsoAssertionCredentials) {
      return const Failed(InvalidCredentials());
    }

    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.post,
        path: '/sso/sessions',
        body: jsonEncode({
          'realm': realm,
          'assertion': credentials.assertion,
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
        path: '/sso/sessions/refresh',
        headers: {'Authorization': 'Bearer ${session.accessToken.value}'},
        body: jsonEncode({'realm': realm}),
      ),
    );

    return _decode(response);
  }

  @override
  Future<Result<void, IdentityFailure>> revoke(Session session) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.delete,
        path: '/sso/sessions',
        headers: {'Authorization': 'Bearer ${session.accessToken.value}'},
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(
        DeviceBoundCredentialGateway.translate(failure),
      ),
      Success() => const Success(null),
    };
  }

  Result<Session, IdentityFailure> _decode(
    Result<HttpResponse, TransportFailure> response,
  ) => switch (response) {
    Failed(:final failure) => Failed(
      DeviceBoundCredentialGateway.translate(failure),
    ),
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
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }
}
