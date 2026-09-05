/// The identity contract: who is acting, on which device, and what they may do.
///
/// Everything another package is allowed to know about identity is in this
/// library, and nothing in it is an implementation. Three groups:
///
/// **The domain.** `Actor`, `Session`, `AccessToken`, `DeviceBinding`,
/// `Credentials`, `Role`, `Permission`, `PermissionSet` — and the two business
/// rules the product actually has, which live on `Session` rather than in a
/// use case: refresh before the token expires, and refuse a session whose
/// device tie has broken.
///
/// **The driving port.** `IdentityFacade`, implemented by
/// `identity_application`, called by presentation packages and composition
/// roots.
///
/// **The driven ports.** `CredentialGateway`, `SessionStore`,
/// `DeviceRegistry`, answered by `identity_infrastructure`.
///
/// Plus the two ports identity opens to *other features*: `SessionReader` and
/// `PermissionChecker`. They are the reason `shipments` can ask who is signed
/// in and what they may do while depending on nothing but this package.
///
/// And one more driving port with an audience of its own: `SessionTokens`, for
/// whatever authorises outbound requests. It is separate from `IdentityFacade`
/// for the reason §2.3 gives — a port is one audience's conversation, and the
/// network layer's conversation with identity is two sentences long.
library;

export 'src/entities/actor.dart';
export 'src/failures/identity_failure.dart';
export 'src/ports/driven/credential_gateway.dart';
export 'src/ports/driven/device_registry.dart';
export 'src/ports/driven/session_store.dart';
export 'src/ports/driving/identity_facade.dart';
export 'src/ports/driving/permission_checker.dart';
export 'src/ports/driving/session_reader.dart';
export 'src/ports/driving/session_tokens.dart';
export 'src/values/access_token.dart';
export 'src/values/actor_id.dart';
export 'src/values/credentials.dart';
export 'src/values/device_binding.dart';
export 'src/values/permission.dart';
export 'src/values/permission_set.dart';
export 'src/values/role.dart';
export 'src/values/session.dart';
