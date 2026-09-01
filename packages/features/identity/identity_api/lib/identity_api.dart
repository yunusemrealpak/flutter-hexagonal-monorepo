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

export 'src/access_token.dart';
export 'src/actor.dart';
export 'src/actor_id.dart';
export 'src/credential_gateway.dart';
export 'src/credentials.dart';
export 'src/device_binding.dart';
export 'src/device_registry.dart';
export 'src/identity_facade.dart';
export 'src/identity_failure.dart';
export 'src/permission.dart';
export 'src/permission_checker.dart';
export 'src/permission_set.dart';
export 'src/role.dart';
export 'src/session.dart';
export 'src/session_reader.dart';
export 'src/session_store.dart';
export 'src/session_tokens.dart';
