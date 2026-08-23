import 'package:core_navigation/core_navigation.dart';
import 'package:core_testing/src/recording_navigation.dart';

/// One call captured by a [RecordingNavigation].
sealed class NavigationRecord {
  const NavigationRecord();
}

/// A captured `goTo` call.
final class WentTo extends NavigationRecord {
  /// Captures the destination pushed onto the history.
  const WentTo(this.location);

  /// Where the caller went.
  final RouteLocation location;

  @override
  String toString() => 'WentTo(${location.value})';
}

/// A captured `replaceWith` call.
final class ReplacedWith extends NavigationRecord {
  /// Captures the destination that replaced the current entry.
  const ReplacedWith(this.location);

  /// Where the caller went.
  final RouteLocation location;

  @override
  String toString() => 'ReplacedWith(${location.value})';
}

/// A captured `back` call.
final class WentBack extends NavigationRecord {
  /// Captures a pop, and whether there was anything to pop.
  const WentBack({required this.succeeded});

  /// Whether there was an entry to go back to.
  final bool succeeded;

  @override
  String toString() => 'WentBack(succeeded: $succeeded)';
}
