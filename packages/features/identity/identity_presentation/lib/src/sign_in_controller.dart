import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';

import 'sign_in_state.dart';

/// Drives the sign-in screen.
///
/// It holds `IdentityFacade` and nothing else — no gateway, no store, no
/// knowledge of whether this app signs in with a password or through a
/// corporate provider. `app_courier` binds a coordinator over
/// `DeviceBoundCredentialGateway` and `app_dispatcher` one over
/// `SsoCredentialGateway`, and this file is identical in both.
///
/// The credential kind is chosen by the caller, which is what keeps that true.
/// A controller that built `PasswordCredentials` itself would be a controller
/// the dispatcher app cannot use.
final class SignInController extends ChangeNotifier {
  /// Creates the controller over the identity facade the app composed.
  SignInController({required this._identity});

  final IdentityFacade _identity;

  SignInState _state = const SignInIdle();

  /// What the screen should be showing.
  SignInState get state => _state;

  /// Sends [credentials].
  ///
  /// Ignores a second call while one is in flight. Without that, a double tap
  /// on a slow connection sends two sign-ins and the second one's session
  /// replaces the first's — including its device binding, which the two
  /// requests may not agree about.
  Future<void> submit(Credentials credentials) async {
    if (_state is SignInPending) return;

    _emit(const SignInPending());

    final result = await _identity.signIn(credentials);
    _emit(
      switch (result) {
        Success(value: final session) => SignedIn(session),
        Failed(:final failure) => SignInRejected(failure),
      },
    );
  }

  void _emit(SignInState next) {
    _state = next;
    notifyListeners();
  }
}
