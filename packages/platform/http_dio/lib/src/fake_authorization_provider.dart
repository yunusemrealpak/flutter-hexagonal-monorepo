import 'authorization_provider.dart';

/// A programmable [AuthorizationProvider] that holds a credential and nothing
/// else.
///
/// Ships from this package for the reason `FakeHttpTransport` does: a fake
/// belongs with the contract it imitates, and this contract is declared here.
///
/// It counts calls rather than only recording them, because the property most
/// worth asserting about an authorising transport is a *number* — that a
/// hundred requests behind one expired token produced one renewal and not a
/// hundred.
final class FakeAuthorizationProvider implements AuthorizationProvider {
  /// Starts out presenting the credential given, or nothing when it is `null`.
  FakeAuthorizationProvider({this._credential});

  String? _credential;

  /// What the next [renewedCredential] will switch to.
  ///
  /// `null` — the default — makes renewal fail, which is what a closed refresh
  /// window looks like to the transport.
  String? renewal;

  int _credentialCalls = 0;
  int _renewalCalls = 0;

  /// How many times a credential has been asked for.
  int get credentialCalls => _credentialCalls;

  /// How many times a renewal has been asked for.
  int get renewalCalls => _renewalCalls;

  @override
  Future<String?> credential() async {
    _credentialCalls++;
    return _credential;
  }

  @override
  Future<String?> renewedCredential() async {
    _renewalCalls++;
    return _credential = renewal;
  }
}
