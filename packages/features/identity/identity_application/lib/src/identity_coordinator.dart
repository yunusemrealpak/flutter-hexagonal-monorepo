import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';

/// The driving port's implementation, and the one thing in the feature that
/// knows which session is currently in force.
///
/// It implements three ports at once, and that is deliberate: all three are
/// views of the same fact. `IdentityFacade` is what a screen calls to change
/// the session; `SessionReader` and `PermissionChecker` are what *other
/// features* ask about it. Splitting them across three objects would mean
/// three copies of "the session right now", and the first time they disagreed
/// a dispatcher would see a button their permissions no longer allow.
///
/// The two rules the specification names are not here. They live on `Session`
/// in `identity_api` — refresh before the token expires, refuse a session
/// whose device tie has broken — and this class calls them. A coordinator
/// orchestrates; an entity decides.
final class IdentityCoordinator
    implements IdentityFacade, SessionReader, PermissionChecker {
  /// Creates the coordinator over its ports.
  IdentityCoordinator({
    required this._gateway,
    required this._store,
    required this._devices,
    required this._clock,
    required this._logger,
  });

  final CredentialGateway _gateway;
  final SessionStore _store;
  final DeviceRegistry _devices;
  final Clock _clock;
  final Logger _logger;

  final StreamController<Session?> _sessions =
      StreamController<Session?>.broadcast();

  Session? _current;

  @override
  Session? get current => _current;

  @override
  Stream<Session?> changes() => _sessions.stream;

  @override
  Stream<Session?> sessionChanges() => _sessions.stream;

  @override
  bool can(Permission permission) => _current?.actor.can(permission) ?? false;

  /// Reads whatever session survived the last run and validates it.
  ///
  /// Called by the composition root at start-up rather than by a screen, which
  /// is why it is not part of `IdentityFacade`: a screen wants to know whether
  /// anybody is signed in, and `sessionChanges` answers that.
  ///
  /// A stored session that no longer holds is discarded rather than kept
  /// around to fail on the next request. Keeping it would make the app look
  /// signed in until the first call, which is the worst possible moment to
  /// find out otherwise.
  Future<Result<Session?, IdentityFailure>> restore() async {
    final stored = await _store.read();
    switch (stored) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(value: null):
        return const Success(null);
      case Success(value: final session?):
        final binding = await _devices.currentBinding();
        switch (binding) {
          case Failed(:final failure):
            return Failed(failure);
          case Success(value: final device):
            final validated = session.validateAgainst(device, _clock.now());
            switch (validated) {
              case Failed(:final failure):
                await _discard();
                return Failed(failure);
              case Success(value: final live):
                _adopt(live);
                return Success(live);
            }
        }
    }
  }

  @override
  Future<Result<Session, IdentityFailure>> signIn(
    Credentials credentials,
  ) async {
    final binding = await _devices.currentBinding();
    switch (binding) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(value: final device):
        // The binding is passed in rather than read by the adapter, so the
        // decision about which device a session is issued for belongs to this
        // use case and an adapter cannot quietly issue one for another.
        final authenticated = await _gateway.authenticate(
          credentials: credentials,
          binding: device,
        );
        switch (authenticated) {
          case Failed(:final failure):
            return Failed(failure);
          case Success(value: final session):
            await _persist(session);
            _adopt(session);
            return Success(session);
        }
    }
  }

  @override
  Future<Result<void, IdentityFailure>> signOut() async {
    final session = _current;

    if (session != null) {
      final revoked = await _gateway.revoke(session);
      if (revoked case Failed(:final failure)) {
        // Sign-out is what a user reaches for when something is already wrong.
        // Refusing to sign them out locally because the server could not be
        // told would strand them on the screen they are trying to leave.
        _logger.warning(
          'signed out locally without revoking remotely',
          context: {'failure': '$failure'},
        );
      }
    }

    final cleared = await _store.clear();
    _adopt(null);
    return cleared;
  }

  @override
  Future<Result<Session, IdentityFailure>> refreshSession() async {
    final session = _current;
    if (session == null) return const Failed(NoSession());

    if (!session.canRefreshAt(_clock.now())) {
      await _discard();
      return const Failed(SessionExpired());
    }

    final refreshed = await _gateway.refresh(session);
    switch (refreshed) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(value: final live):
        await _persist(live);
        _adopt(live);
        return Success(live);
    }
  }

  /// Refreshes only when the token is close enough to expiry to need it.
  ///
  /// This is the specification's first rule at the place it is acted on. The
  /// decision itself is `Session.needsRefreshAt`, in `identity_api`; what
  /// belongs here is only *when to ask*. Called before an outbound request by
  /// whatever composes the app, so that a courier on a bad connection is never
  /// stalled by a request that fails once and is retried.
  Future<Result<Session, IdentityFailure>> refreshIfDue() async {
    final session = _current;
    if (session == null) return const Failed(NoSession());
    if (!session.needsRefreshAt(_clock.now())) return Success(session);
    return refreshSession();
  }

  /// Releases the change stream. Called when the container is torn down.
  Future<void> dispose() => _sessions.close();

  /// Writes the session down, and does not fail the sign-in if it cannot.
  ///
  /// A session that was issued is usable for this run whether or not it
  /// survives a restart. Failing here instead would turn a full keychain into
  /// a courier who cannot sign in at all.
  Future<void> _persist(Session session) async {
    final written = await _store.write(session);
    if (written case Failed(:final failure)) {
      _logger.warning(
        'session obtained but not stored; it will not survive a restart',
        context: {'failure': '$failure'},
      );
    }
  }

  void _adopt(Session? session) {
    _current = session;
    _sessions.add(session);
  }

  Future<void> _discard() async {
    await _store.clear();
    _adopt(null);
  }
}
