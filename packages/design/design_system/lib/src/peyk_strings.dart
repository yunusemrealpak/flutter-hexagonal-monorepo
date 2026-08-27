import 'package:flutter/widgets.dart';

import 'key_echo_catalogue.dart';
import 'string_catalogue.dart';

/// Carries a [StringCatalogue] down the widget tree.
///
/// An app installs one above its router; every screen below reads it. The
/// catalogue is not passed through constructors because a label is needed at
/// every depth of a screen and threading it would mean every private widget in
/// every presentation package taking a parameter it only forwards.
final class PeykStrings extends InheritedWidget {
  /// Puts [catalogue] in scope for [child].
  const PeykStrings({
    required this.catalogue,
    required super.child,
    super.key,
  });

  /// What resolves keys below this point.
  final StringCatalogue catalogue;

  /// The catalogue in force at [context].
  ///
  /// Falls back to [KeyEchoCatalogue] when there is none, for the same reason
  /// `PeykTheme.of` falls back to the light palette: an app that forgot to
  /// install one has a wiring bug, and a screen showing `shipments.scan` is a
  /// far better report of that bug than a crash in a van.
  static StringCatalogue of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PeykStrings>();
    assert(
      scope != null,
      'No PeykStrings in this tree. An app installs one above its router; a '
      'widget test can pass one to PeykTheme.wrap().',
    );
    return scope?.catalogue ?? const KeyEchoCatalogue();
  }

  @override
  bool updateShouldNotify(PeykStrings oldWidget) =>
      oldWidget.catalogue != catalogue;
}
