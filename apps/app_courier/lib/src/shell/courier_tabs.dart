import 'package:design_system/design_system.dart';

/// One tab of the courier's shell: a word, a picture, and the routes that live
/// behind it.
///
/// The first entry of [routes] is the tab's root — where tapping the tab
/// lands, and where re-tapping it returns to. The rest are the screens that
/// belong inside that tab's stack, which is what lets a courier three screens
/// deep into a delivery look at the map and come back to exactly where they
/// were.
final class CourierTab {
  /// Describes a tab.
  const CourierTab({
    required this.label,
    required this.icon,
    required this.routes,
  });

  /// The string key for the word under the picture.
  ///
  /// Answered by `CourierCatalogue`, like every other key in this app. The
  /// tab's word is the app's to choose: `app_dispatcher` mounts several of the
  /// same features and would call none of these tabs the same thing.
  final String label;

  /// The picture, from the design system's vocabulary.
  final PeykIcon icon;

  /// Every route inside this tab, the root first.
  final List<String> routes;

  /// Where the tab lands.
  String get root => routes.first;
}

/// The courier's four tabs, left to right.
///
/// **The set is this app's answer, not a feature's.** Twelve presentation
/// packages declare where they can be reached; none of them knows whether it
/// ended up behind a tab, and `routing_presentation` is mounted by
/// `app_dispatcher` too, where there is no bar at all. That is §2.3's rule —
/// a driving surface belongs to the audience — one level above where it was
/// written: not which operations an audience performs, but which of them are
/// one tap away.
///
/// **What a feature can say is in its `RouteDefinition` already.** A tab root
/// has to be openable with no argument, and `path` is where that is stated:
/// `/stops` can be a tab and `/stops/:shipmentId/proof` cannot. Nothing had to
/// be added to `core_navigation` to express a branch — the test below reads
/// `path` and says so, which is why that core contract did not move for this
/// change.
///
/// Everything the app mounts is behind exactly one tab except `identity.signIn`
/// — a screen that exists to end, and the one place a bar would be an offer to
/// go somewhere nobody is allowed yet. `courier_shell_test.dart` asserts that
/// partition exactly, so a route added to a feature has to be given a home
/// rather than quietly becoming unreachable.
const List<CourierTab> courierTabs = [
  CourierTab(
    label: 'courier.tab.stops',
    icon: PeykIcon.list,
    routes: [
      'shipments.courier.manifest',
      'shipments.courier.scan',
      'delivery.proof',
      'payments.collect',
      'documents.view',
    ],
  ),
  CourierTab(
    label: 'courier.tab.route',
    icon: PeykIcon.map,
    routes: ['routing.myRoute'],
  ),
  CourierTab(
    label: 'courier.tab.inbox',
    icon: PeykIcon.inbox,
    routes: ['notifications.inbox', 'messaging.thread'],
  ),
  // The tab that admits what it is. A courier's day is the first three; this
  // is the drawer, and calling it "Settings" would hide the vehicle count and
  // the stuck-work queue behind a word that does not describe them.
  CourierTab(
    label: 'courier.tab.more',
    icon: PeykIcon.more,
    routes: [
      'settings.home',
      'sync.review',
      'incidents.board',
      'inventory.count',
    ],
  ),
];

/// The routes this app mounts outside the shell.
///
/// One, and it is the interesting one. Sign-in is not a tab and must not be
/// reachable from a bar: a bar drawn there would offer four destinations the
/// guard would refuse. Being outside the shell is also what makes signing out
/// leave the shell entirely, which is the behaviour the shell test pins down.
const Set<String> courierRoutesOutsideShell = {'identity.signIn'};

/// Every string key the shell itself asks this app to answer.
///
/// The feature manifests in `courier_routes.dart` cover what the *screens*
/// ask for. The tab words are the app's own, so they are listed here and the
/// catalogue coverage test checks them the same way — otherwise a tab label
/// would be the one string in the product with nothing asserting it has a
/// translation.
final List<String> courierShellStringKeys = [
  for (final tab in courierTabs) tab.label,
];
