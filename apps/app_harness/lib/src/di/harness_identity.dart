import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_application/identity_application.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:injectable/injectable.dart';

/// identity, on fakes.
///
/// One module per feature, and each one is short enough to read in a sitting.
/// That is the shape the constitution forces and it is worth noticing why: an
/// app is the only package allowed to see an `_application` and an
/// `_infrastructure` at once, so this file is the only place in the workspace
/// where `IdentityCoordinator` and a `CredentialGateway` implementation are
/// both in scope. Everything else sees one side or the other.
@module
abstract class HarnessIdentity {
  /// Scenario 5, first row: the harness binds the fake where `app_courier`
  /// binds `DeviceBoundCredentialGateway` and `app_dispatcher` binds
  /// `SsoCredentialGateway`. `identity_application` is the same package in all
  /// three, and it never learns which.
  @lazySingleton
  FakeCredentialGateway get fakeGateway => FakeCredentialGateway();

  /// The same instance, as the port the use cases take.
  @lazySingleton
  CredentialGateway gateway(FakeCredentialGateway fake) => fake;

  /// Sessions in a map rather than in the keychain.
  @lazySingleton
  SessionStore get sessionStore => InMemorySessionStore();

  /// A registry that accepts whatever device asks.
  @lazySingleton
  DeviceRegistry get devices => FakeDeviceRegistry();

  /// The coordinator, registered once under its own type.
  ///
  /// It implements four interfaces — `IdentityFacade`, `SessionReader`,
  /// `PermissionChecker` and `SessionTokens` — and the registrations below are
  /// *views* of this one object rather than several objects. That matters:
  /// `PermissionChecker` answering from a session `SessionReader` does not
  /// have would be a screen showing actions for somebody who is not signed in.
  ///
  /// The fourth is deliberately not registered here. `SessionTokens` exists to
  /// authorise outbound requests, and this app's transport is
  /// `FakeHttpTransport` — nothing leaves the process, so there is nothing to
  /// authorise. A binding whose only purpose was completeness would be a
  /// binding no test ever resolves.
  ///
  /// It is also the shape scenario 6 needs. `payments_presentation` and
  /// `shipments_presentation_dispatcher` each hold a `PermissionChecker` and
  /// have never heard of identity's use cases; what they are holding is this.
  @lazySingleton
  IdentityCoordinator coordinator(
    CredentialGateway gateway,
    SessionStore store,
    DeviceRegistry devices,
    Clock clock,
    Logger logger,
  ) => IdentityCoordinator(
    gateway: gateway,
    store: store,
    devices: devices,
    clock: clock,
    logger: logger,
  );

  /// Signing in and out.
  @lazySingleton
  IdentityFacade identity(IdentityCoordinator it) => it;

  /// Who is signed in. The narrowest port a screen can ask for.
  @lazySingleton
  SessionReader sessionReader(IdentityCoordinator it) => it;

  /// What they may do. Scenario 6's port.
  @lazySingleton
  PermissionChecker permissionChecker(IdentityCoordinator it) => it;
}
