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
import 'package:reporting_presentation/reporting_presentation.dart';
import 'package:routing_presentation/routing_presentation.dart';
import 'package:settings_presentation/settings_presentation.dart';
import 'package:shipments_presentation_courier/shipments_presentation_courier.dart';
import 'package:shipments_presentation_dispatcher/shipments_presentation_dispatcher.dart';
import 'package:sync_presentation/sync_presentation.dart';
import 'package:vehicle_inventory_presentation/vehicle_inventory_presentation.dart';

/// Every feature this app mounts, as route modules.
///
/// Fourteen, which is all of them — and that is what makes this app a harness
/// rather than a product. `app_courier` mounts eleven and `app_dispatcher`
/// mounts ten; neither mounts both shipments screens, and this one does,
/// because scenario 7 is easier to look at when the two are side by side.
///
/// The list is the whole of "which features are in this app". Adding one is a
/// line here and a line in a DI module, and nothing in any feature changes.
const List<RouteModule> harnessModules = [
  IdentityRoutes(),
  ShipmentsCourierRoutes(),
  ShipmentsDispatcherRoutes(),
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
  ReportingRoutes(),
];

/// Destinations this app deliberately does not draw.
///
/// The router reports every route with no screen behind it, and the test
/// asserts that set equals this one — so a screen somebody added to a feature
/// and forgot to mount fails, while a gap somebody decided on is written down.
/// A silent difference between the two is how a route ends up resolving to a
/// blank page in production.
///
/// Both of these need a form this workspace has not written: a refund needs an
/// amount and a reason, and reporting an incident needs a category and a note.
/// Phase 7's acceptance is that the wiring holds, not that every screen exists
/// — and a placeholder mounted here would make the router test stop being able
/// to tell the two apart.
const Set<String> harnessUnmountedRoutes = {
  'payments.refund',
  'incidents.report',
};

/// Every string key the mounted features ask an app to answer.
///
/// The union of the fourteen `*Strings.all` manifests, and the input to this
/// app's catalogue coverage test. It is a list of lists rather than a flat one
/// so that a failure names the feature whose key is missing.
final Map<String, List<String>> harnessStringKeys = {
  'identity': IdentityStrings.all,
  'shipments.courier': ShipmentsCourierStrings.all,
  'shipments.dispatcher': ShipmentsDispatcherStrings.all,
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
  'reporting': ReportingStrings.all,
};

/// The shell.
///
/// It installs three things and draws nothing itself: the palette, the string
/// catalogue, and the router. That is the whole job of a composition root's
/// widget — everything a person sees comes from a presentation package, and
/// everything those packages need comes from here.
final class HarnessApp extends StatelessWidget {
  /// Creates the shell over [router].
  const HarnessApp({required this.router, super.key});

  /// The router this app assembled.
  final RouterConfig<Object> router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Peyk harness',
    theme: PeykTheme.themeData(PeykPalette.light),
    darkTheme: PeykTheme.themeData(PeykPalette.dark),
    localizationsDelegates: PeykSystemLocalizations.localizationsDelegates,
    supportedLocales: PeykSystemLocalizations.supportedLocales,
    routerConfig: router,
    builder: (context, child) => PeykStrings(
      // The harness's real catalogue, not a stand-in for one. A harness whose
      // job is to prove every feature can be stood up wants to see *which*
      // string each screen asked for; finished English would hide a label
      // wired to the wrong key behind a sentence that reads fine.
      //
      // It is also why this app runs no gen-l10n at all, and why it is the
      // only app in the workspace with no .arb file.
      catalogue: const KeyEchoCatalogue(),
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
