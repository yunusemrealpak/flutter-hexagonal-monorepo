import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_presentation/identity_presentation.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:incidents_presentation/incidents_presentation.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:messaging_presentation/messaging_presentation.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:notifications_presentation/notifications_presentation.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:reporting_presentation/reporting_presentation.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_presentation/routing_presentation.dart';
import 'package:settings_api/settings_api.dart';
import 'package:settings_presentation/settings_presentation.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_presentation_dispatcher/shipments_presentation_dispatcher.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_presentation/sync_presentation.dart';

import '../dispatcher_app.dart';
import 'peyk_router.dart';

/// Builds this app's router from [container].
///
/// **This function is where a controller is constructed, and it is the only
/// place in the workspace that could be.** A controller takes a facade; a
/// facade is built from use cases; use cases are built over adapters. Three
/// layers that no package may see at once, joined here.
///
/// The controllers are built per navigation rather than held, because most of
/// them subscribe to something and a held one would keep listening after
/// somebody left the screen. `SettingsController` and the two that watch a
/// stream are the reason `dispose` exists on them at all.
///
/// **Half of them need a value out of the URL** — which thread, which parcel,
/// which kind of document — and that is why a `ScreenBuilder` takes the path
/// parameters. The parsing happens here and returns a `Result`, so a URL
/// somebody typed wrong produces a message rather than an exception: these are
/// the same `parse` factories an adapter uses, and they were never allowed to
/// throw.
PeykRouter buildDispatcherRouter(GetIt container) {
  final sessions = container<SessionReader>();
  final permissions = container<PermissionChecker>();

  /// Whoever is signed in.
  ///
  /// Every screen below the guard has one: `requiresSession` defaults to true
  /// and the redirect sends anybody without a session to sign-in. The bang is
  /// that guarantee written down — if it ever fires, the guard is wrong and a
  /// null actor would have hidden it behind an empty screen.
  ActorId actor() => sessions.current!.actor.id;

  return PeykRouter(
    modules: dispatcherModules,
    sessions: sessions,
    permissions: permissions,
    signInRoute: 'identity.signIn',
    homeRoute: 'shipments.dispatcher.board',
    screens: {
      'identity.signIn': (context, _) => SignInScreen(
        controller: SignInController(identity: container<IdentityFacade>()),
      ),
      'shipments.dispatcher.board': (context, _) => DispatcherBoardScreen(
        controller: DispatcherBoardController(
          shipments: container<ShipmentsFacade>(),
          permissions: permissions,
          session: sessions,
        ),
      ),
      // The same screen. `/board/assign` differs by carrying a wider
      // permission, which the guard checks before this builder runs — so the
      // board reached through it is the board with the bulk action on it, and
      // the screen needs no flag to know that.
      'shipments.dispatcher.bulkAssign': (context, _) => DispatcherBoardScreen(
        controller: DispatcherBoardController(
          shipments: container<ShipmentsFacade>(),
          permissions: permissions,
          session: sessions,
        ),
      ),
      // Somebody else's route, and the only screen in the workspace whose
      // behaviour differs between the two apps: `reorderable` is true here.
      // The flag is the app's to decide — the guard has already let this
      // person in, and reordering a courier's afternoon is a separate grant
      // that only a desk holds.
      'routing.courierRoute': (context, parameters) => _parsed(
        ActorId.parse(parameters['courierId'] ?? ''),
        (courier) => RouteScreen(
          reorderable: true,
          controller: RouteController(
            routing: container<RoutingFacade>(),
            courier: courier,
          ),
        ),
      ),
      'reports.board': (context, _) => ReportScreen(
        controller: ReportController(
          reporting: container<ReportingFacade>(),
          permissions: permissions,
        ),
      ),
      'sync.review': (context, _) => ReviewQueueScreen(
        controller: ReviewQueueController(sync: container<SyncFacade>()),
      ),
      'settings.home': (context, _) => SettingsScreen(
        controller: SettingsController(
          settings: container<SettingsFacade>(),
          actor: actor(),
        ),
      ),
      'notifications.inbox': (context, _) => InboxScreen(
        controller: InboxController(
          notifications: container<NotificationsFacade>(),
          actor: actor(),
        ),
      ),
      'incidents.board': (context, _) => IncidentBoardScreen(
        controller: IncidentBoardController(
          incidents: container<IncidentsFacade>(),
          permissions: permissions,
          actor: actor(),
        ),
      ),
      'messaging.thread': (context, parameters) => _parsed(
        ThreadId.parse(parameters['threadId'] ?? ''),
        (thread) => ThreadScreen(
          controller: ThreadController(
            messaging: container<MessagingFacade>(),
            thread: thread,
            reader: actor(),
          ),
        ),
      ),
    },
  );
}

/// Draws [onValue] when a path segment parsed, and says so when it did not.
///
/// The `parse` factories in every `_api` return a `Result` and never throw —
/// rule 1.2.9 — so a URL with a malformed identifier in it arrives here as a
/// value rather than as an exception. This is where a composition root turns
/// that into something on a screen.
///
/// It draws a `PeykFailureView` with a key rather than the failure's own text,
/// because the failure is a developer-facing description of a bad identifier
/// and the person looking at it typed a URL.
Widget _parsed<T, F>(Result<T, F> parsed, Widget Function(T) onValue) =>
    switch (parsed) {
      Success(:final value) => onValue(value),
      Failed() => const PeykFailureView(message: 'peyk.route.badParameter'),
    };
