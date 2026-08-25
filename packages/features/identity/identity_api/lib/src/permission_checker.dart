import 'permission.dart';

/// Answers whether the current actor may do one thing.
///
/// The other port identity opens, and the one scenario 6 of the architecture
/// is about: `shipments_presentation_dispatcher` asks this before it renders
/// the bulk-assign button, and never learns how the answer was reached. It
/// does not know about roles, about direct grants, or that `Actor` exists.
///
/// Deliberately not a getter over `PermissionSet`. Handing out the set would
/// let a caller reason about permissions it was not asking about — "they have
/// three of the four, close enough" — and would make widening the model
/// (time-bounded grants, a permission that depends on the shipment) a
/// breaking change for everyone. One question, one answer.
abstract interface class PermissionChecker {
  /// Whether the actor currently signed in may do [permission].
  ///
  /// `false` when nobody is signed in. That is the safe direction, and it
  /// means a caller never has to check for a session before checking for a
  /// permission.
  bool can(Permission permission);
}
