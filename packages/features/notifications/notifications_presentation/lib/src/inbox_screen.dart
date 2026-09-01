import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications_api/notifications_api.dart';

import 'inbox_controller.dart';
import 'inbox_state.dart';
import 'notifications_strings.dart';

/// Where a courier reads what the operation has told them.
final class InboxScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const InboxScreen({required this.controller, super.key});

  /// What drives it.
  final InboxController controller;

  @override
  State<InboxScreen> createState() => _InboxScreenState();

  /// Which string a failure should be shown as.
  ///
  /// Exhaustive over `NotificationsFailure`, which is the point of it being
  /// sealed: the day notifications learns a new way to fail, this stops
  /// compiling instead of showing a courier the wrong sentence.
  ///
  /// It returns a key rather than a sentence. The mapping — *which* message a
  /// failure gets — stays here, where the compiler checks it covers the union;
  /// the wording is the app's, which is why `app_courier` can say "No signal"
  /// to somebody in a van while `app_dispatcher` says "The service did not
  /// answer" to somebody at a desk on ethernet.
  @visibleForTesting
  static String describe(NotificationsFailure failure) => switch (failure) {
    InboxUnavailable() => NotificationsStrings.failureUnavailable,
    NotificationMissing() => NotificationsStrings.failureMissing,
    AlertsRefused() => NotificationsStrings.failureRefused,
    AlertsBlocked() => NotificationsStrings.failureBlocked,
    AlertsUnreachable() => NotificationsStrings.failureUnreachable,
    // The inbox screen never asks for the alert state, so this case cannot
    // reach it — but the union is one hierarchy on purpose and a screen that
    // opted out of a case would be a screen with a hole the day it does.
    AlertStateUnavailable() => NotificationsStrings.failureUnavailable,
    MalformedNotification() => NotificationsStrings.failureMalformed,
  };

  /// Whether reading again is the answer to [failure].
  ///
  /// `PeykFailureView` draws no button when this is false, because an action
  /// that cannot help is worse than no action: somebody taps it, nothing
  /// changes, and they conclude the app is broken rather than that alerts are
  /// switched off in the operating system.
  @visibleForTesting
  static bool canRetry(NotificationsFailure failure) => switch (failure) {
    AlertsRefused() || AlertsBlocked() => false,
    InboxUnavailable() ||
    NotificationMissing() ||
    AlertsUnreachable() ||
    AlertStateUnavailable() ||
    MalformedNotification() => true,
  };
}

class _InboxScreenState extends State<InboxScreen> {
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
      title: strings.resolve(NotificationsStrings.inboxTitle),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          InboxIdle() || InboxLoading() => const PeykLoadingView(),
          // An empty inbox is its own view rather than an empty list, because
          // a screen with nothing on it reads as a screen that failed to load
          // — and a courier who thinks it failed will pull over and reload it.
          InboxReady(:final entries) when entries.isEmpty => PeykEmptyView(
            message: strings.resolve(NotificationsStrings.inboxEmpty),
          ),
          InboxReady(:final entries) => ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) =>
                _Alert(entry: entries[index], controller: widget.controller),
          ),
          InboxFailed(:final failure) => PeykFailureView(
            message: strings.resolve(InboxScreen.describe(failure)),
            onRetry: InboxScreen.canRetry(failure)
                ? () => unawaited(widget.controller.load())
                : null,
          ),
        },
      ),
    );
  }
}

/// One alert in the list.
///
/// The subject is a key carried by the entry itself, with the arguments that
/// go into it — the alert was raised somewhere that had no idea which language
/// would read it. That is the same catalogue call every label makes, and it is
/// the reason `StringCatalogue.resolve` takes arguments at all.
class _Alert extends StatelessWidget {
  const _Alert({required this.entry, required this.controller});

  final InboxEntry entry;
  final InboxController controller;

  @override
  Widget build(BuildContext context) => PeykListRow(
    title: PeykStrings.of(
      context,
    ).resolve(entry.subject, arguments: entry.arguments),
    trailing: entry.isUnread ? const PeykBadge(count: 1) : null,
    onTap: entry.isUnread ? () => controller.markRead(entry.id) : null,
  );
}
