import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sync_api/sync_api.dart';

import 'review_queue_controller.dart';
import 'review_queue_state.dart';

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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state) {
      ReviewIdle() || ReviewLoading() => const Center(
        child: Text('Checking the queue'),
      ),
      ReviewReady(:final entries) when entries.isEmpty => const Center(
        // Not an error. This is the state the screen is in most of the time.
        child: Text('Nothing needs you'),
      ),
      ReviewReady(:final entries) => ListView(
        children: [
          for (final entry in entries)
            _BlockedTile(
              entry: entry,
              onRetry: () => unawaited(widget.controller.retry(entry.id)),
            ),
        ],
      ),
      ReviewFailed(:final failure) => Center(child: Text(_describe(failure))),
    },
  );

  /// Turns a failure into something a person can act on.
  static String _describe(SyncFailure failure) => switch (failure) {
    SyncOffline() => 'No signal. This list is from this device.',
    OutboxUnavailable() => 'The queue on this device could not be read.',
    _ => 'Something went wrong. Try again.',
  };
}

final class _BlockedTile extends StatelessWidget {
  const _BlockedTile({required this.entry, required this.onRetry});

  final OutboxEntry entry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.type),
        Text(entry.blockedReason ?? ''),
        Text('${entry.attempts} attempts'),
        GestureDetector(
          onTap: onRetry,
          child: const Text('Try again'),
        ),
      ],
    ),
  );
}
