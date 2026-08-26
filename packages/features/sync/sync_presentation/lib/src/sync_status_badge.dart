import 'package:flutter/widgets.dart';
import 'package:sync_api/sync_api.dart';

import 'review_queue_controller.dart';

/// The queue indicator every screen in a courier app carries.
///
/// Deliberately plain: no colours, no typography, no spacing scale. Those come
/// from `design_system`, which arrives in phase 7, and inventing them here
/// would mean deleting them then. What this widget demonstrates now is the
/// part that will not change — a screen renders a sealed state exhaustively
/// and reaches nothing but ports.
///
/// The five cases are five *different sentences*, which is the whole reason
/// `SyncStatus` is a union rather than a count plus a boolean. "You are in a
/// basement" and "the server said no, we are trying again shortly" send a
/// courier to different places, and a badge that collapsed them into "not
/// synced" is what makes somebody restart an app that is working correctly.
final class SyncStatusBadge extends StatelessWidget {
  /// Creates the badge over [controller].
  const SyncStatusBadge({required this.controller, super.key});

  /// What drives it.
  final ReviewQueueController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Text(describe(controller.status)),
  );

  /// Turns a queue status into something a courier can act on.
  ///
  /// Static and public so that a test can assert on the sentence without
  /// pumping a widget tree, and so that an app that renders the same status in
  /// a different shape — a tile, a banner — does not reimplement the wording.
  ///
  /// The translation happens here rather than in `SyncStatus`, because this is
  /// where the locale is known. A status carrying a formatted English string
  /// would be untranslatable a phase later.
  static String describe(SyncStatus status) => switch (status) {
    SyncIdle() => 'Everything is sent',
    SyncDraining(:final pending) => 'Sending $pending',
    SyncWaitingForNetwork(:final pending) => '$pending waiting for signal',
    SyncWaitingToRetry(:final pending) => '$pending will be retried',
    SyncBlocked(:final needingReview) => '$needingReview need you',
  };
}
