import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:messaging_api/messaging_api.dart';

import 'thread_controller.dart';
import 'thread_state.dart';

/// Where a courier and the operation talk.
///
/// Deliberately plain: no colours, no typography, no spacing scale. Those come
/// from `design_system` in phase 7 — and the queued state is the first thing
/// that will want them, because "written but not sent" is a distinction people
/// read as a shade rather than as a word.
final class ThreadScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const ThreadScreen({required this.controller, super.key});

  /// What drives it.
  final ThreadController controller;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();

  /// Turns a failure into something a person can act on.
  ///
  /// Exhaustive over `MessagingFailure`. Two of the six cases never reach a
  /// screen in practice — a deferral is invisible by design and a refusal is
  /// logged — and they are answered here anyway, because a sealed type the
  /// compiler checks is worth more than a shorter switch.
  static String describe(MessagingFailure failure) => switch (failure) {
    ThreadUnavailable() => 'This conversation could not be opened.',
    DeliveryDeferred() => 'Waiting for a connection.',
    DeliveryRefused() => 'The operation would not take that message.',
    MessageMissing() => 'That message is no longer here.',
    MalformedMessage() => 'That message cannot be sent.',
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state) {
      ThreadIdle() || ThreadLoading() => const Text('thread.loading'),
      ThreadReady(:final messages) when messages.isEmpty => const Text(
        'thread.empty',
      ),
      ThreadReady(:final messages, :final queued) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final message in messages) _Line(message: message),
          if (queued > 0) Text('thread.queued $queued'),
        ],
      ),
      ThreadFailed(:final failure) => Text(ThreadScreen.describe(failure)),
    },
  );
}

/// One message.
///
/// The body is shown as written — it is the one string in this workspace that
/// is not a localisation key, because a person typed it. Its *status* is a
/// key, because that is the product speaking.
class _Line extends StatelessWidget {
  const _Line({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) => Semantics(
    label: message.isQueued
        ? 'thread.status.queued'
        : message.isRead
        ? 'thread.status.read'
        : 'thread.status.sent',
    child: Text(message.body),
  );
}
