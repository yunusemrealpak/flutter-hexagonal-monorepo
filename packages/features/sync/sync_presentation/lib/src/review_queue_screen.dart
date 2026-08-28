import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:sync_api/sync_api.dart';

import 'review_queue_controller.dart';
import 'review_queue_state.dart';
import 'sync_strings.dart';

/// The screen a depot opens when the badge says something needs a person.
///
/// It shows a routing key, a reason and an attempt count per entry — and
/// **never the payload**. That is not a layout choice: this package depends on
/// `sync_api`, which cannot decode a payload, so rendering the contents of a
/// queued command is not something the code here is able to do. A screen that
/// wanted to show "the delivery for shipment SHP-9" would have to reach into
/// `delivery_api`, and at that point sync would have learned a feature's name.
///
/// Which is the honest shape for this screen anyway. The person resolving a
/// stuck queue needs to know *what stopped and why*; the app that composed
/// this feature is the only thing entitled to turn a routing key into a link
/// to the feature that owns it.
final class ReviewQueueScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const ReviewQueueScreen({required this.controller, super.key});

  /// What drives it.
  final ReviewQueueController controller;

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();

  /// Which string a failure should be shown as.
  ///
  /// `SyncFailure` is not sealed over a small set this package can exhaust —
  /// it carries cases only an adapter produces — so the wildcard is real
  /// rather than lazy. The two named cases are the two a person on this screen
  /// can do something about.
  @visibleForTesting
  static String describe(SyncFailure failure) => switch (failure) {
    SyncOffline() => SyncStrings.failureOffline,
    OutboxUnavailable() => SyncStrings.failureOutboxUnavailable,
    _ => SyncStrings.failureOther,
  };
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  @override
  void initState() {
    super.initState();
    // initState cannot be async, and the load is genuinely fire-and-forget:
    // its result reaches the screen through the controller's notification
    // rather than through this call.
    widget.controller.watch();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(SyncStrings.reviewTitle),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          ReviewIdle() || ReviewLoading() => const PeykLoadingView(),
          // Not an error. This is the state the screen is in most of the time,
          // and showing a failure for it would send somebody looking for a
          // problem that does not exist.
          ReviewReady(:final entries) when entries.isEmpty => PeykEmptyView(
            message: strings.resolve(SyncStrings.reviewEmpty),
          ),
          ReviewReady(:final entries) => ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) => _BlockedTile(
              entry: entries[index],
              onRetry: () =>
                  unawaited(widget.controller.retry(entries[index].id)),
            ),
          ),
          ReviewFailed(:final failure) => PeykFailureView(
            message: strings.resolve(ReviewQueueScreen.describe(failure)),
            onRetry: () => unawaited(widget.controller.load()),
          ),
        },
      ),
    );
  }
}

/// One piece of work the queue gave up on.
///
/// `entry.type` is a routing key — `delivery.complete` — and it is shown
/// unresolved on purpose where the other labels are not. It is the one string
/// on this screen that sync did not choose: a feature put it there, and only
/// the app that mounted both features can say what it means in words.
final class _BlockedTile extends StatelessWidget {
  const _BlockedTile({required this.entry, required this.onRetry});

  final OutboxEntry entry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykListRow(
      title: strings.resolve(entry.type),
      subtitle: entry.blockedReason,
      trailing: PeykChip(
        label: strings.resolve(
          SyncStrings.attempts,
          arguments: {'count': entry.attempts},
        ),
        intent: PeykIntent.danger,
      ),
      onTap: onRetry,
    );
  }
}
