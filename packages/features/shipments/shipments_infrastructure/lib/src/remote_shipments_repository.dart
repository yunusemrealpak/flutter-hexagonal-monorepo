import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import 'shipments_dto.dart';

/// Answers the shipments contract from a remote system.
///
/// A scaffolded stub: it reports [ShipmentsUnavailable] until a transport is
/// given to it. Take that transport through the constructor as a technology
/// contract from a `platform/*` package — never a client library directly, and
/// never a service locator.
///
/// Whatever that technology throws is caught here and returned as a failure.
/// No exception crosses this boundary.
final class RemoteShipmentsRepository implements ShipmentsRepository {
  /// Creates the adapter.
  const RemoteShipmentsRepository();

  @override
  Future<Result<String, ShipmentsFailure>> byId(String id) async {
    return const Failed<String, ShipmentsFailure>(ShipmentsUnavailable());
  }

  /// Maps a decoded payload to the value the port promised.
  ///
  /// Kept separate from the call above so that the mapping can be tested
  /// without a transport, which is most of what is worth testing here.
  String fromPayload(Map<String, Object?> payload) =>
      ShipmentsDto.fromJson(payload).toDomain();
}
