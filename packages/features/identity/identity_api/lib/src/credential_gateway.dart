import 'package:core_kernel/core_kernel.dart';

import 'credentials.dart';
import 'device_binding.dart';
import 'identity_failure.dart';
import 'session.dart';

/// Turns credentials into a session, wherever that actually happens.
///
/// A driven port: `identity_application` calls it, `identity_infrastructure`
/// answers it. The word "gateway" is the whole point — the use case knows
/// there is something on the other side of this method and knows nothing about
/// what. `DeviceBoundCredentialGateway` and `SsoCredentialGateway` both
/// satisfy it, and the app that binds one instead of the other changes no line
/// of the use case (scenario 5).
///
/// Speaks in the product's words. There is no `HttpRequest` in this file and
/// there cannot be: `identity_application`, which consumes this port, may not
/// depend on `platform/*` at all.
abstract interface class CredentialGateway {
  /// Authenticates [credentials] for the device described by [binding].
  ///
  /// The binding is a parameter rather than something the adapter reads, so
  /// that the use case decides which device a session is issued for and the
  /// adapter cannot quietly issue one for a different device.
  Future<Result<Session, IdentityFailure>> authenticate({
    required Credentials credentials,
    required DeviceBinding binding,
  });

  /// Exchanges [session]'s refresh window for a session with a fresh token.
  Future<Result<Session, IdentityFailure>> refresh(Session session);

  /// Invalidates [session] on the far side.
  Future<Result<void, IdentityFailure>> revoke(Session session);
}
