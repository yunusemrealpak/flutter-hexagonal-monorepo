import 'package:core_navigation/core_navigation.dart';
import 'package:design_system/design_system.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:identity_presentation/identity_presentation.dart';
import 'package:incidents_presentation/incidents_presentation.dart';
import 'package:messaging_presentation/messaging_presentation.dart';
import 'package:notifications_presentation/notifications_presentation.dart';
import 'package:payments_presentation/payments_presentation.dart';
import 'package:reporting_presentation/reporting_presentation.dart';
import 'package:routing_presentation/routing_presentation.dart';
import 'package:settings_presentation/settings_presentation.dart';
import 'package:shipments_presentation_dispatcher/shipments_presentation_dispatcher.dart';
import 'package:sync_presentation/sync_presentation.dart';

import 'catalogue/dispatcher_catalogue.dart';
import 'l10n/peyk_dispatcher_localizations.dart';

/// The features a dispatcher's desk mounts.
///
/// Ten, where `app_courier` mounts twelve — and only six of them overlap.
/// `vehicle_inventory` and `documents` are a courier's (a van is counted by
/// whoever stands next to it; a waybill belongs to whoever carries the
/// parcel), `reporting` and the dispatcher board are a desk's, and neither app
/// compiles in what it does not mount.
///
/// `delivery` is the interesting absence: this app *composes* the feature —
/// `DeliveryFacade` resolves, and `RemoteProofStore` is row 4 of the adapter
/// table — and mounts none of its routes. A dispatcher reads a delivery
/// attempt and never stands at a door. A feature is a set of use cases and a
/// set of destinations, and an app can want one without the other.
const List<RouteModule> dispatcherModules = [
  IdentityRoutes(),
  ShipmentsDispatcherRoutes(),
  RoutingRoutes(),
  PaymentsRoutes(),
  SyncRoutes(),
  SettingsRoutes(),
  NotificationsRoutes(),
  IncidentsRoutes(),
  MessagingRoutes(),
  ReportingRoutes(),
];

/// Every string key the mounted features ask this app to answer.
///
/// The input to the catalogue coverage test, which this app *can* fail —
/// unlike `app_harness`, whose `KeyEchoCatalogue` answers everything by
/// definition. That is the whole reason the test exists in three apps: here it
/// is checking a translation, there it was checking a manifest.
final Map<String, List<String>> dispatcherStringKeys = {
  'identity': IdentityStrings.all,
  'shipments.dispatcher': ShipmentsDispatcherStrings.all,
  'routing': RoutingStrings.all,
  'payments': PaymentsStrings.all,
  'sync': SyncStrings.all,
  'settings': SettingsStrings.all,
  'notifications': NotificationsStrings.all,
  'incidents': IncidentsStrings.all,
  'messaging': MessagingStrings.all,
  'reporting': ReportingStrings.all,
};

/// Destinations this app deliberately does not draw.
///
/// Destinations this app deliberately does not draw.
///
/// **The mirror image of `app_courier`'s set.** `routing.myRoute` is unmounted
/// here and mounted there; `routing.courierRoute` is mounted here and
/// unmounted there. One presentation package, two destinations, and each app
/// draws the one its audience has a use for — which is the thing scenario 7
/// shows with two packages and this shows with one.
///
/// `payments.collect` is here because a dispatcher does not take cash at a
/// door; `payments` is composed all the same, for the status a board reads and
/// for the refunds a desk is the only place to make. `payments.refund` needs a
/// form nobody has written, which is why it is here for a different reason
/// from the one above it.
///
/// `incidents.report` needs a form too. `shipments.dispatcher.bulkAssign` is
/// *not* here: it is the board reached through a wider permission, and a mode
/// is not a second screen.
const Set<String> dispatcherUnmountedRoutes = {
  'routing.myRoute',
  'payments.collect',
  'payments.refund',
  'incidents.report',
};

/// The shell.
///
/// It installs the palette, the catalogue and the router, and draws nothing.
/// Everything a dispatcher sees comes from a presentation package.
final class DispatcherApp extends StatelessWidget {
  /// Creates the shell over [router].
  const DispatcherApp({required this.router, super.key});

  /// The router this app assembled.
  final RouterConfig<Object> router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Peyk Operations',
    theme: PeykTheme.themeData(PeykPalette.light),
    darkTheme: PeykTheme.themeData(PeykPalette.dark),
    // Two sets of delegates: this app's product strings and the design
    // system's component strings. §4.1's split, at the point where the two
    // meet — and the reason a component can say "3 unread" in the right plural
    // form without every app spelling it out.
    localizationsDelegates: const [
      ...PeykDispatcherLocalizations.localizationsDelegates,
      ...PeykSystemLocalizations.localizationsDelegates,
    ],
    supportedLocales: PeykDispatcherLocalizations.supportedLocales,
    routerConfig: router,
    builder: (context, child) => PeykStrings(
      // Built from the context so that it follows the locale: a person who
      // changes the language in settings gets new sentences without the app
      // being rebuilt, because `PeykDispatcherLocalizations.of` is an inherited
      // lookup and this builder runs again.
      catalogue: DispatcherCatalogue(context),
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
