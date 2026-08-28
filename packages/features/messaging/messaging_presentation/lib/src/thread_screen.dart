import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:messaging_api/messaging_api.dart';

import 'messaging_strings.dart';
import 'thread_controller.dart';
import 'thread_state.dart';

/// Where a courier and the operation talk.
final class ThreadScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const ThreadScreen({required this.controller, super.key});

  /// What drives it.
  final ThreadController controller;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();

  /// Which string a failure should be shown as.
  ///
  /// Exhaustive over `MessagingFailure`. Two of the five cases never reach a
  /// screen in practice — a deferral is invisible by design and a refusal is
  /// logged — and they are answered here anyway, because a sealed type the
  /// compiler checks is worth more than a shorter switch.
  @visibleForTesting
  static String describe(MessagingFailure failure) => switch (failure) {
    ThreadUnavailable() => MessagingStrings.failureThreadUnavailable,
    DeliveryDeferred() => MessagingStrings.failureDeferred,
    DeliveryRefused() => MessagingStrings.failureRefused,
    MessageMissing() => MessagingStrings.failureMissing,
    MalformedMessage() => MessagingStrings.failureMalformed,
  };
}

class _ThreadScreenState extends State<ThreadScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.watch();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(MessagingStrings.threadTitle),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          ThreadIdle() || ThreadLoading() => const PeykLoadingView(),
          ThreadReady(:final messages) when messages.isEmpty => PeykEmptyView(
            message: strings.resolve(MessagingStrings.threadEmpty),
          ),
          ThreadReady(:final messages, :final queued) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _Line(message: messages[index]),
                ),
              ),
              // The queue is shown as a count rather than per message,
              // because what a person needs to know is whether anything is
              // still on this device — not which line it was.
              if (queued > 0)
                PeykChip(
                  label: strings.resolve(
                    MessagingStrings.threadQueued,
                    arguments: {'count': queued},
                  ),
                  intent: PeykIntent.warning,
                ),
            ],
          ),
          ThreadFailed(:final failure) => PeykFailureView(
            message: strings.resolve(ThreadScreen.describe(failure)),
            onRetry: () => unawaited(widget.controller.load()),
          ),
        },
      ),
    );
  }
}

/// One message.
///
/// The body is shown as written — it is the one string in this workspace that
/// is not a localisation key, because a person typed it. Its *status* is a
/// key, because that is the product speaking.
///
/// The status is a chip beside the line rather than only a semantics label.
/// "Written but not sent" was a distinction a screen reader could hear and a
/// person looking at the screen could not, which is the wrong way round: the
/// courier who needs it most is the one glancing at a phone in a van.
class _Line extends StatelessWidget {
  const _Line({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final (key, intent) = switch (message) {
      Message(isQueued: true) => (
        MessagingStrings.statusQueued,
        PeykIntent.warning,
      ),
      Message(isRead: true) => (
        MessagingStrings.statusRead,
        PeykIntent.success,
      ),
      _ => (MessagingStrings.statusSent, PeykIntent.neutral),
    };
    final label = PeykStrings.of(context).resolve(key);

    return PeykListRow(
      title: message.body,
      trailing: PeykChip(label: label, intent: intent),
    );
  }
}
