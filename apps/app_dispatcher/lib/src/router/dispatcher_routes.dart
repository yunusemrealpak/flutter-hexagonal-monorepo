import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
/// The blocs are built per navigation rather than held, because most of them
/// subscribe to something and a held one would keep listening after somebody
/// left the screen. `BlocProvider` closes what it created when the route
/// leaves the tree, which is the disposal this router used to have no place to
/// do.
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
      'identity.signIn': (context, _) => BlocProvider(
        create: (_) => SignInBloc(identity: container<IdentityFacade>()),
        child: const SignInScreen(),
      ),
      'shipments.dispatcher.board': (context, _) => BlocProvider(
        create: (_) => DispatcherBoardBloc(
          shipments: container<ShipmentsFacade>(),
          permissions: permissions,
          session: sessions,
        ),
        child: const DispatcherBoardScreen(),
      ),
      // The same screen. `/board/assign` differs by carrying a wider
      // permission, which the guard checks before this builder runs — so the
      // board reached through it is the board with the bulk action on it, and
      // the screen needs no flag to know that.
      'shipments.dispatcher.bulkAssign': (context, _) => BlocProvider(
        create: (_) => DispatcherBoardBloc(
          shipments: container<ShipmentsFacade>(),
          permissions: permissions,
          session: sessions,
        ),
        child: const DispatcherBoardScreen(),
      ),
      // Somebody else's route, and the only screen in the workspace whose
      // behaviour differs between the two apps. The difference is the bloc's
      // *type*: a `SupervisedRouteBloc` holds `RouteSupervision` and no
      // `RouteFollowing`, so this screen can reorder a courier's afternoon and
      // cannot ask where that courier is. The guard has already let this
      // person in; reordering is a separate grant that only a desk holds.
      'routing.courierRoute': (context, parameters) => _parsed(
        ActorId.parse(parameters['courierId'] ?? ''),
        (courier) => BlocProvider<RouteBloc>(
          create: (_) => SupervisedRouteBloc(
            planning: container<RoutePlanning>(),
            supervision: container<RouteSupervision>(),
            courier: courier,
          ),
          child: const RouteScreen(),
        ),
      ),
      'reports.board': (context, _) => BlocProvider(
        create: (_) => ReportBloc(
          reporting: container<ReportingFacade>(),
          permissions: permissions,
        ),
        child: const ReportScreen(),
      ),
      'sync.review': (context, _) => BlocProvider(
        create: (_) => ReviewQueueBloc(sync: container<SyncFacade>()),
        child: const ReviewQueueScreen(),
      ),
      // No `AlertsBloc` here, and that absence is the composition speaking:
      // `DeskAlertChannel` refuses every open, so the screen's
      // `context.read<AlertsBloc?>()` is null and no switch is drawn. A
      // control that cannot work is worse than an absent one.
      'settings.home': (context, _) => BlocProvider(
        create: (_) => SettingsBloc(
          settings: container<SettingsFacade>(),
          actor: actor(),
        ),
        child: SettingsScreen(
          // The one call site `IdentityFacade.signOut` had been waiting for.
          // Nothing here says where to go afterwards, and nothing has to: the
          // session ends, the router's SessionRefresh fires, and the guard
          // that was always right about a sessionless actor finally gets
          // asked.
          //
          // Alerts are closed first, and the order is forced rather than
          // tidy: closing needs the actor, and signing out is what takes the
          // actor away. A handset left subscribed to a former courier's topic
          // keeps buzzing with somebody else's work.
          onSignOut: () => unawaited(_signOut(container, actor())),
        ),
      ),
      'notifications.inbox': (context, _) => BlocProvider(
        create: (_) => InboxBloc(
          notifications: container<NotificationsFacade>(),
          actor: actor(),
        ),
        child: const InboxScreen(),
      ),
      'incidents.board': (context, _) => BlocProvider(
        create: (_) => IncidentBoardBloc(
          incidents: container<IncidentsFacade>(),
          permissions: permissions,
          actor: actor(),
        ),
        child: const IncidentBoardScreen(),
      ),
      'messaging.thread': (context, parameters) => _parsed(
        ThreadId.parse(parameters['threadId'] ?? ''),
        (thread) => BlocProvider(
          create: (_) => ThreadBloc(
            messaging: container<MessagingFacade>(),
            thread: thread,
            reader: actor(),
          ),
          child: const ThreadScreen(),
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

/// Ends the session, after making sure this device stops being alerted.
///
/// Two facades, one gesture, and the order matters: `closeAlertsFor` needs the
/// actor and `signOut` is what takes the actor away. Closing is not made
/// conditional on succeeding — a device that could not unsubscribe still has a
/// person who asked to be signed out, and refusing that would trap somebody on
/// a handset because the network was down. The registry keeps the record, so
/// the next read still knows the device is subscribed.
Future<void> _signOut(GetIt container, ActorId actor) async {
  await container<NotificationsFacade>().closeAlertsFor(actor);
  await container<IdentityFacade>().signOut();
}
