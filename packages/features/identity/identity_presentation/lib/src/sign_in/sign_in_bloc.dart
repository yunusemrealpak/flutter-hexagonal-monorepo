import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';

import 'sign_in_event.dart';
import 'sign_in_state.dart';

/// Drives the sign-in screen.
///
/// It holds `IdentityFacade` and nothing else — no gateway, no store, no
/// knowledge of whether this app signs in with a password or through a
/// corporate provider. `app_courier` binds a coordinator over
/// `DeviceBoundCredentialGateway` and `app_dispatcher` one over
/// `SsoCredentialGateway`, and this file is identical in both.
///
/// **`droppable()` replaces a hand-written in-flight guard**, and that is the
/// whole migration here. The `ChangeNotifier` this file used to be opened with
/// `if (_state is SignInPending) return;`, which is the same policy written as
/// a condition on a mutable field: correct, invisible to a reader scanning the
/// class, and impossible to change without editing the method it guards. As a
/// transformer it is one word at the registration and it is named.
///
/// What it prevents is real. A double tap on a slow connection sends two
/// sign-ins, and the second one's session replaces the first's — including its
/// device binding, which the two requests may not agree about.
final class SignInBloc extends Bloc<SignInEvent, SignInState> {
  /// Creates the bloc over the identity facade the app composed.
  SignInBloc({required this._identity}) : super(const SignInIdle()) {
    on<CredentialsSubmitted>(_onSubmitted, transformer: droppable());
    on<SignInCleared>(_onCleared);
  }

  final IdentityFacade _identity;

  Future<void> _onSubmitted(
    CredentialsSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInPending());

    final result = await _identity.signIn(event.credentials);
    emit(
      switch (result) {
        Success(value: final session) => SignedIn(session),
        Failed(:final failure) => SignInRejected(failure),
      },
    );
  }

  /// Clearing is refused while an attempt is in flight.
  ///
  /// `droppable()` covers a second *submit*; it says nothing about a different
  /// event arriving mid-flight, and returning to idle under a request that is
  /// still running would put the screen back on the form and then move it off
  /// again when the answer lands.
  void _onCleared(SignInCleared event, Emitter<SignInState> emit) {
    if (state is SignInPending) return;
    emit(const SignInIdle());
  }
}
