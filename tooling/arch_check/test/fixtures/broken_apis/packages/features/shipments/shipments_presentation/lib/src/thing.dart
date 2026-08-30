/// A screen that navigates, which is the app's decision and not its own.
///
/// The doc comment names `context.goNamed` and `Navigator.of` in prose, and
/// neither mention may be reported: the rule is matched against the AST for
/// the same reason `ambient_clock` is.
final class StopTile {
  /// Sends whoever tapped the row to the door.
  void onTap(Object context) {
    context.goNamed('delivery.proof');
    Navigator.of(context).push(Object());
  }
}

/// Stands in for Flutter's Navigator so the fixture needs no Flutter SDK.
class Navigator {
  /// Answers the nearest one.
  static Navigator of(Object context) => Navigator();

  /// Pushes a route.
  void push(Object route) {}
}

/// Stands in for go_router's extension so the fixture parses.
extension on Object {
  void goNamed(String name) {}
}
