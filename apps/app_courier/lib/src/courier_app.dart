import 'package:core_navigation/core_navigation.dart';
import 'package:delivery_presentation/delivery_presentation.dart';
import 'package:design_system/design_system.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:documents_presentation/documents_presentation.dart';
import 'package:flutter/material.dart';
import 'package:identity_presentation/identity_presentation.dart';
import 'package:incidents_presentation/incidents_presentation.dart';
import 'package:messaging_presentation/messaging_presentation.dart';
import 'package:notifications_presentation/notifications_presentation.dart';
import 'package:payments_presentation/payments_presentation.dart';
import 'package:routing_presentation/routing_presentation.dart';
import 'package:settings_presentation/settings_presentation.dart';
import 'package:shipments_presentation_courier/shipments_presentation_courier.dart';
import 'package:sync_presentation/sync_presentation.dart';
import 'package:vehicle_inventory_presentation/vehicle_inventory_presentation.dart';

import 'catalogue/courier_catalogue.dart';
import 'l10n/peyk_courier_localizations.dart';

/// The features a courier's phone mounts.
///
/// Twelve of the fourteen. `shipments_presentation_dispatcher` and
/// `reporting_presentation` are absent, and their absence costs nothing —
/// neither package is a dependency of this app, so neither is compiled into
/// it. An app is a set of features as much as a set of adapters, and that is
/// the half of scenario 5 the adapter table does not show.
const List<RouteModule> courierModules = [
  IdentityRoutes(),
  ShipmentsCourierRoutes(),
  RoutingRoutes(),
  DeliveryRoutes(),
  PaymentsRoutes(),
  SyncRoutes(),
  SettingsRoutes(),
  NotificationsRoutes(),
  IncidentsRoutes(),
  VehicleInventoryRoutes(),
  MessagingRoutes(),
  DocumentsRoutes(),
];

/// Every string key the mounted features ask this app to answer.
///
/// The input to the catalogue coverage test, which this app *can* fail —
/// unlike `app_harness`, whose `KeyEchoCatalogue` answers everything by
/// definition. That is the whole reason the test exists in three apps: here it
/// is checking a translation, there it was checking a manifest.
final Map<String, List<String>> courierStringKeys = {
  'identity': IdentityStrings.all,
  'shipments.courier': ShipmentsCourierStrings.all,
  'routing': RoutingStrings.all,
  'delivery': DeliveryStrings.all,
  'payments': PaymentsStrings.all,
  'sync': SyncStrings.all,
  'settings': SettingsStrings.all,
  'notifications': NotificationsStrings.all,
  'incidents': IncidentsStrings.all,
  'vehicle_inventory': VehicleInventoryStrings.all,
  'messaging': MessagingStrings.all,
  'documents': DocumentsStrings.all,
};

/// Destinations this app deliberately does not draw.
///
/// Three, and they are three different kinds of decision.
///
/// `routing.courierRoute` is somebody *else's* route, which is a dispatcher's
/// screen. `routing_presentation` declares both destinations and this app
/// draws one of them — a feature is not all-or-nothing, and the route guard
/// would have refused this one anyway because a courier does not hold the
/// permission it names. Mounting it would have been a screen nobody can reach.
///
/// `payments.refund` and `incidents.report` need a form this workspace has not
/// written. Phase 7's acceptance is that the wiring holds, not that every
/// screen exists.
///
/// `shipments.courier.scan` is *not* here: it is the manifest reached from a
/// scanner deep-link, and it is mounted to the same builder. A mode is not a
/// second screen.
///
/// The router test asserts this set exactly, so a screen somebody forgot to
/// mount fails while a gap somebody chose is written down.
const Set<String> courierUnmountedRoutes = {
  'routing.courierRoute',
  'payments.refund',
  'incidents.report',
};

/// The shell.
///
/// It installs the palette, the catalogue and the router, and draws nothing.
/// Everything a courier sees comes from a presentation package.
final class CourierApp extends StatelessWidget {
  /// Creates the shell over [router].
  const CourierApp({required this.router, super.key});

  /// The router this app assembled.
  final RouterConfig<Object> router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Peyk',
    theme: PeykTheme.themeData(PeykPalette.light),
    darkTheme: PeykTheme.themeData(PeykPalette.dark),
    // Two sets of delegates: this app's product strings and the design
    // system's component strings. §4.1's split, at the point where the two
    // meet — and the reason a component can say "3 unread" in the right plural
    // form without every app spelling it out.
    localizationsDelegates: const [
      ...PeykCourierLocalizations.localizationsDelegates,
      ...PeykSystemLocalizations.localizationsDelegates,
    ],
    supportedLocales: PeykCourierLocalizations.supportedLocales,
    routerConfig: router,
    builder: (context, child) => PeykStrings(
      // Built from the context so that it follows the locale: a person who
      // changes the language in settings gets new sentences without the app
      // being rebuilt, because `PeykCourierLocalizations.of` is an inherited
      // lookup and this builder runs again.
      catalogue: CourierCatalogue(context),
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
