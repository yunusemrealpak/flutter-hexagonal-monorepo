import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messaging_api/messaging_api.dart';

import '../messaging_strings.dart';
import 'thread_bloc.dart';
import 'thread_event.dart';
import 'thread_state.dart';

/// Where a courier and the operation talk.
///
/// The bloc arrives through the widget tree: whoever mounts this screen puts a
/// [ThreadBloc] above it with `BlocProvider`.
final class ThreadScreen extends StatefulWidget {
  /// Creates the screen.
  const ThreadScreen({super.key});

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
    context.read<ThreadBloc>()
      ..add(const ThreadWatched())
      ..add(const ThreadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(MessagingStrings.threadTitle),
      // No `buildWhen` and no `BlocSelector`, and both are deliberate.
      // `ThreadReady` follows `ThreadReady` on every arriving message, so
      // narrowing on the case would suppress the only emission that matters;
      // and without that narrowing a selector underneath would be re-created
      // rather than skipped, which is the half of the pattern people leave
      // out. The queue chip could select its count, but the list beside it
      // redraws for the same emission anyway.
      body: BlocBuilder<ThreadBloc, ThreadState>(
        builder: (context, state) => switch (state) {
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
            onRetry: () =>
                context.read<ThreadBloc>().add(const ThreadRequested()),
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
