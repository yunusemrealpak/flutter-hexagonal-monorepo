import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:sync_api/sync_api.dart';

import 'review_queue_controller.dart';
import 'sync_strings.dart';

/// The queue indicator every screen in a courier app carries.
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
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final status = controller.status;
        return PeykChip(
          label: strings.resolve(
            describe(status),
            arguments: argumentsFor(status),
          ),
          intent: intentOf(status),
        );
      },
    );
  }

  /// Which string a queue status should be shown as.
  ///
  /// Static and public so a test can assert on the key without pumping a
  /// widget tree, and so an app rendering the same status in another shape — a
  /// tile, a banner — does not reimplement the mapping.
  @visibleForTesting
  static String describe(SyncStatus status) => switch (status) {
    SyncIdle() => SyncStrings.statusIdle,
    SyncDraining() => SyncStrings.statusDraining,
    SyncWaitingForNetwork() => SyncStrings.statusWaitingForNetwork,
    SyncWaitingToRetry() => SyncStrings.statusWaitingToRetry,
    SyncBlocked() => SyncStrings.statusBlocked,
  };

  /// The count [status] contributes to its own sentence.
  ///
  /// `SyncIdle` contributes nothing, which is why this is a separate function
  /// rather than a field on the key: a status with no number is not a status
  /// with a zero in it.
  @visibleForTesting
  static Map<String, Object?> argumentsFor(SyncStatus status) =>
      switch (status) {
        SyncIdle() => const {},
        SyncDraining(:final pending) ||
        SyncWaitingForNetwork(:final pending) ||
        SyncWaitingToRetry(:final pending) => {'count': pending},
        SyncBlocked(:final needingReview) => {'count': needingReview},
      };

  /// How loudly [status] should be drawn.
  ///
  /// This is the mapping the design system deliberately cannot make: a
  /// component knows what `danger` looks like, and only `sync` knows that
  /// "given up on" is one. Being blocked is the single case that needs a
  /// person, so it is the single case that is not neutral or informational.
  @visibleForTesting
  static PeykIntent intentOf(SyncStatus status) => switch (status) {
    SyncIdle() => PeykIntent.success,
    SyncDraining() || SyncWaitingForNetwork() => PeykIntent.neutral,
    SyncWaitingToRetry() => PeykIntent.warning,
    SyncBlocked() => PeykIntent.danger,
  };
}
