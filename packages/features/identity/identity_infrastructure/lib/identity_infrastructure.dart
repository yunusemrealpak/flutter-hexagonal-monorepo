/// The identity adapters: what answers its driven ports, the DTOs that cross
/// the wire, and the mapper between them.
///
/// | Type | Answers | Over |
/// |---|---|---|
/// | `DeviceBoundCredentialGateway` | `CredentialGateway` | Peyk's directory |
/// | `SsoCredentialGateway` | `CredentialGateway` | a corporate provider |
/// | `SecureSessionStore` | `SessionStore` | the `SecureStore` port |
/// | `InstallationDeviceRegistry` | `DeviceRegistry` | `KeyValueStore` |
/// | `BearerAuthorization` | `AuthorizationProvider` | `SessionTokens` |
///
/// The last row runs the other way from the other three and is the reason this
/// package can exist at all in that direction: it answers a contract declared
/// in `platform/http_dio` rather than one declared in `identity_api`. A
/// platform package may not depend on a feature, so the credential every
/// outbound request carries has to arrive through a contract the transport
/// declares and somebody else fills in — and §1.1 gives exactly one package
/// type sight of both a technology contract and a session.
///
/// The two gateways are scenario 5 made concrete: one port, two adapters,
/// bound by different apps. `app_courier` takes the first — a handset signs in
/// with a password once and a device token afterwards — and `app_dispatcher`
/// takes the second, because an operations desk signs in through the company's
/// own login and never types a Peyk password. `identity_application` does not
/// change a line between them.
///
/// The two stores are chosen apart on purpose. A session carries a live bearer
/// token and belongs behind a keychain; an installation identifier names a
/// handset and authorises nothing, and putting it in the keychain would make
/// it disappear on a passcode change — turning every such change into a device
/// the operation no longer recognises.
library;

export 'src/bearer_authorization.dart';
export 'src/device_bound_credential_gateway.dart';
export 'src/installation_device_registry.dart';
export 'src/secure_session_store.dart';
export 'src/session_dto.dart';
export 'src/session_mapper.dart';
export 'src/sso_credential_gateway.dart';
