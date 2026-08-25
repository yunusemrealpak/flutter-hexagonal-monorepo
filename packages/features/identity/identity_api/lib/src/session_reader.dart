import 'session.dart';

/// Reads the session another feature needs in order to do its own work.
///
/// One of the two ports identity opens to the rest of the product. It is
/// narrow on purpose: `shipments` needs to know who is asking, and giving it
/// `IdentityFacade` instead would also give it the ability to sign the user
/// out. A port is the smallest thing that answers the question.
///
/// Neither method returns a `Result`. This port reads state identity is
/// already holding, so there is nothing to fail; a `Result` here would put an
/// unreachable failure branch at every call site, which CLAUDE.md section 3
/// rules out.
abstract interface class SessionReader {
  /// The session in force right now, or `null` when nobody is signed in.
  Session? get current;

  /// Emits the session whenever it changes, and `null` after sign-out.
  Stream<Session?> changes();
}
