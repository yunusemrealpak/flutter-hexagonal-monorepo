import 'package:core_navigation/core_navigation.dart';
import 'navigation_record.dart';

/// A [Navigation] that maintains a real history and records every call.
///
/// The history is real rather than a counter, so `back` reports the same thing
/// a router would: false at the root of the stack, true otherwise. A bloc that
/// decides whether to close a screen or show a confirmation is testing against
/// behaviour here, not against a stub that always agrees.
final class RecordingNavigation implements Navigation {
  final List<RouteLocation> _history = [];
  final List<NavigationRecord> _records = [];

  /// Every call so far, oldest first.
  List<NavigationRecord> get records => List.unmodifiable(_records);

  /// The current history, oldest first.
  List<RouteLocation> get history => List.unmodifiable(_history);

  /// Where the user currently is, or `null` at an empty stack.
  RouteLocation? get current => _history.isEmpty ? null : _history.last;

  @override
  void goTo(RouteLocation location) {
    _history.add(location);
    _records.add(WentTo(location));
  }

  @override
  void replaceWith(RouteLocation location) {
    if (_history.isNotEmpty) {
      _history.removeLast();
    }
    _history.add(location);
    _records.add(ReplacedWith(location));
  }

  @override
  bool back() {
    final succeeded = _history.length > 1;
    if (succeeded) {
      _history.removeLast();
    }
    _records.add(WentBack(succeeded: succeeded));
    return succeeded;
  }
}
