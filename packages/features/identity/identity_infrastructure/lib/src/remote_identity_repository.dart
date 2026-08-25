import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'identity_dto.dart';

/// Answers the identity contract from a remote system.
///
/// A scaffolded stub: it reports [IdentityUnavailable] until a transport is
/// given to it. Take that transport through the constructor as a technology
/// contract from a `platform/*` package — never a client library directly, and
/// never a service locator.
///
/// Whatever that technology throws is caught here and returned as a failure.
/// No exception crosses this boundary.
final class RemoteIdentityRepository implements IdentityRepository {
  /// Creates the adapter.
  const RemoteIdentityRepository();

  @override
  Future<Result<String, IdentityFailure>> byId(String id) async {
    return const Failed<String, IdentityFailure>(IdentityUnavailable());
  }

  /// Maps a decoded payload to the value the port promised.
  ///
  /// Kept separate from the call above so that the mapping can be tested
  /// without a transport, which is most of what is worth testing here.
  String fromPayload(Map<String, Object?> payload) =>
      IdentityDto.fromJson(payload).toDomain();
}
