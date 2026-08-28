import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_presentation/delivery_presentation.dart';
import 'package:design_system/design_system.dart';
import 'package:documents_api/documents_api.dart';
import 'package:documents_presentation/documents_presentation.dart';
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
import 'package:payments_api/payments_api.dart';
import 'package:payments_presentation/payments_presentation.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:reporting_presentation/reporting_presentation.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_presentation/routing_presentation.dart';
import 'package:settings_api/settings_api.dart';
import 'package:settings_presentation/settings_presentation.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_presentation_courier/shipments_presentation_courier.dart';
import 'package:shipments_presentation_dispatcher/shipments_presentation_dispatcher.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_presentation/sync_presentation.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';
import 'package:vehicle_inventory_presentation/vehicle_inventory_presentation.dart';

import '../harness_app.dart';
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
PeykRouter buildHarnessRouter(GetIt container) {
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
    modules: harnessModules,
    sessions: sessions,
    permissions: permissions,
    signInRoute: 'identity.signIn',
    homeRoute: 'shipments.courier.manifest',
    screens: {
      'identity.signIn': (context, _) => SignInScreen(
        controller: SignInController(identity: container<IdentityFacade>()),
      ),
      'shipments.courier.manifest': (context, _) => CourierManifestScreen(
        controller: CourierManifestController(
          shipments: container<ShipmentsFacade>(),
          session: sessions,
        ),
      ),
      // The same screen, reached at the URL a barcode scanner deep-links to.
      // `/stops/scan` is a mode of the manifest rather than a second screen,
      // and mounting it to the same builder is how an app says so — the
      // alternative is a route that resolves to a blank page.
      'shipments.courier.scan': (context, _) => CourierManifestScreen(
        controller: CourierManifestController(
          shipments: container<ShipmentsFacade>(),
          session: sessions,
        ),
      ),
      'shipments.dispatcher.board': (context, _) => DispatcherBoardScreen(
        controller: DispatcherBoardController(
          shipments: container<ShipmentsFacade>(),
          permissions: permissions,
          session: sessions,
        ),
      ),
      // Also the same screen. `/board/assign` differs by carrying a wider
      // permission, which the guard checks before this builder runs — so the
      // board a dispatcher reaches through it is the board with the bulk
      // action on it, and the screen needs no flag to know that.
      'shipments.dispatcher.bulkAssign': (context, _) => DispatcherBoardScreen(
        controller: DispatcherBoardController(
          shipments: container<ShipmentsFacade>(),
          permissions: permissions,
          session: sessions,
        ),
      ),
      'routing.myRoute': (context, _) => RouteScreen(
        controller: FollowedRouteController(
          planning: container<RoutePlanning>(),
          following: container<RouteFollowing>(),
          courier: actor(),
        ),
      ),
      'routing.courierRoute': (context, parameters) => _parsed(
        ActorId.parse(parameters['courierId'] ?? ''),
        (courier) => RouteScreen(
          // The dispatcher's view of the same screen, and the only difference
          // between the two: which controller the app can build. This one is
          // the only app that can build both, which is what makes it the place
          // the split is legible.
          controller: SupervisedRouteController(
            planning: container<RoutePlanning>(),
            supervision: container<RouteSupervision>(),
            courier: courier,
          ),
        ),
      ),
      'delivery.proof': (context, parameters) => _parsed(
        ShipmentId.parse(parameters['shipmentId'] ?? ''),
        (shipment) => ProofCaptureScreen(
          shipment: shipment,
          controller: ProofCaptureController(
            execution: container<DeliveryExecution>(),
            settlement: container<DeliverySettlement>(),
            permissions: permissions,
            session: sessions,
          ),
        ),
      ),
      'payments.collect': (context, parameters) => _parsed(
        ShipmentId.parse(parameters['shipmentId'] ?? ''),
        (shipment) => CollectionScreen(
          shipment: shipment,
          controller: CollectionController(
            payments: container<PaymentsFacade>(),
            permissions: permissions,
            session: sessions,
          ),
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
      'inventory.count': (context, _) => CountScreen(
        controller: CountController(
          inventory: container<VehicleInventoryFacade>(),
          courier: actor(),
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
      'documents.view': (context, parameters) => _parsed(
        ShipmentId.parse(parameters['shipmentId'] ?? ''),
        (shipment) => _parsed(
          DocumentKind.parse(parameters['kind'] ?? ''),
          (kind) => DocumentScreen(
            controller: DocumentController(
              documents: container<DocumentsFacade>(),
              kind: kind,
              shipment: shipment,
            ),
          ),
        ),
      ),
      'reports.board': (context, _) => ReportScreen(
        controller: ReportController(
          reporting: container<ReportingFacade>(),
          permissions: permissions,
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
