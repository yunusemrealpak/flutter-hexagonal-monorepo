import 'route_location.dart';

/// Moves the user between destinations.
///
/// Presentation packages depend on this rather than on a router library, so a
/// bloc can express "go to the shipment detail" without importing anything
/// that knows about widgets. The app supplies the adapter.
///
/// Nothing here returns a `Result`. Navigating to a destination that does not
/// exist is a programming error, not a runtime failure — the fix is a code
/// change, not a branch the caller writes. Adapters assert on it in debug and
/// no-op in release.
abstract interface class Navigation {
  /// Goes to [location], adding it to the history.
  void goTo(RouteLocation location);

  /// Goes to [location], replacing the current entry in the history.
  ///
  /// For transitions the user should not be able to go back through — landing
  /// on the route list after signing in, for instance.
  void replaceWith(RouteLocation location);

  /// Goes back one entry.
  ///
  /// Returns whether there was anything to go back to, so a caller can decide
  /// what to do at the root of the stack.
  bool back();
}
