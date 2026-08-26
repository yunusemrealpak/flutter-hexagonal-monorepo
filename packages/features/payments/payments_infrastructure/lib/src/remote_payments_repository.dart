import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';

import 'payments_dto.dart';

/// Answers the payments contract from a remote system.
///
/// A scaffolded stub: it reports [PaymentsUnavailable] until a transport is
/// given to it. Take that transport through the constructor as a technology
/// contract from a `platform/*` package — never a client library directly, and
/// never a service locator.
///
/// Whatever that technology throws is caught here and returned as a failure.
/// No exception crosses this boundary.
final class RemotePaymentsRepository implements PaymentsRepository {
  /// Creates the adapter.
  const RemotePaymentsRepository();

  @override
  Future<Result<String, PaymentsFailure>> byId(String id) async {
    return const Failed<String, PaymentsFailure>(PaymentsUnavailable());
  }

  /// Maps a decoded payload to the value the port promised.
  ///
  /// Kept separate from the call above so that the mapping can be tested
  /// without a transport, which is most of what is worth testing here.
  String fromPayload(Map<String, Object?> payload) =>
      PaymentsDto.fromJson(payload).toDomain();
}
