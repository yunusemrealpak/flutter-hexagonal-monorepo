@Tags(['widget'])
library;

import 'package:app_courier/main.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:notifications_api/notifications_api.dart';

import 'support/test_platform.dart';

/// What this app does with the two notifications calls that had no caller.
///
/// The audit's finding was that `openAlertsFor` and `closeAlertsFor` were
/// never invoked anywhere, so push was inert from end to end. Both halves are
/// this app's job: the screen offers the first, and signing out has to perform
/// the second whether anybody looked at the screen or not.
void main() {
  late GetIt container;

  setUp(() async {
    container = await configureCourier(testPlatform());
    // The guard refuses `/settings` without a session, so the two tests below
    // would both be about the sign-in screen otherwise. Two registrations
    // replaced rather than a second container built, as `courier_shell_test`
    // does: the graph underneath stays the one this app composes.
    await container.unregister<SessionReader>();
    await container.unregister<PermissionChecker>();
    container
      ..registerSingleton<SessionReader>(
        _StaticSession(SessionBuilder().build()),
      )
      ..registerSingleton<PermissionChecker>(
        const _Permissions({Permission.viewAssignedShipments}),
      );
  });

  tearDown(() => container.reset());

  testWidgets('the settings screen offers to turn alerts on', (tester) async {
    final router = buildCourierRouter(container).build();
    await tester.pumpWidget(CourierApp(router: router));
    await tester.pumpAndSettle();

    router.go('/settings');
    await tester.pumpAndSettle();

    // A courier's phone composes a real alert channel, so the section is
    // drawn. `app_dispatcher` composes `DeskAlertChannel` and passes no
    // controller, which is what makes that an app decision rather than a
    // feature's.
    expect(find.byType(PeykSwitchRow), findsOneWidget);
  });

  testWidgets('signing out closes alerts before it ends the session', (
    tester,
  ) async {
    final order = <String>[];
    final notifications = _RecordingNotifications(order);
    final identity = _RecordingIdentity(order);
    await container.unregister<NotificationsFacade>();
    await container.unregister<IdentityFacade>();
    container
      ..registerSingleton<NotificationsFacade>(notifications)
      ..registerSingleton<IdentityFacade>(identity);

    final router = buildCourierRouter(container).build();
    await tester.pumpWidget(CourierApp(router: router));
    await tester.pumpAndSettle();

    router.go('/settings');
    await tester.pumpAndSettle();

    // Found by tone rather than by wording: the sentence behind
    // `settings.signOut` is this app's, and a test that spelled it out would
    // fail the day somebody edited an .arb file.
    final signOut = find.byWidgetPredicate(
      (widget) =>
          widget is PeykButton && widget.tone == PeykButtonTone.destructive,
    );
    await tester.ensureVisible(signOut);
    await tester.pumpAndSettle();
    await tester.tap(signOut);
    await tester.pumpAndSettle();

    // The order is forced rather than tidy: closing needs the actor, and
    // signing out is what takes the actor away. A handset left subscribed to
    // a former courier's topic keeps buzzing with somebody else's work.
    expect(order, ['closeAlertsFor', 'signOut']);
  });
}

/// A facade that records which call happened and does nothing else.
final class _RecordingNotifications implements NotificationsFacade {
  _RecordingNotifications(this._order);

  final List<String> _order;

  @override
  Future<Result<void, NotificationsFailure>> closeAlertsFor(
    ActorId actor,
  ) async {
    _order.add('closeAlertsFor');
    return const Success(null);
  }

  @override
  Future<Result<void, NotificationsFailure>> openAlertsFor(
    ActorId actor,
  ) async => const Success(null);

  @override
  Future<Result<AlertState, NotificationsFailure>> alertStateFor(
    ActorId actor,
  ) async => const Success(AlertsClosed());

  @override
  Future<Result<List<InboxEntry>, NotificationsFailure>> inboxOf(
    ActorId actor,
  ) async => const Success([]);

  @override
  Future<Result<InboxEntry, NotificationsFailure>> markRead(
    ActorId actor,
    NotificationId id,
  ) async => Failed(NotificationMissing(id.value));

  @override
  Stream<int> unreadCount() => const Stream.empty();
}

/// An identity that records the sign-out and keeps the session alive.
///
/// Alive on purpose: ending it would take the screen away mid-tap and the
/// order under test would be observed through a rebuild rather than directly.
final class _RecordingIdentity implements IdentityFacade {
  _RecordingIdentity(this._order);

  final List<String> _order;

  @override
  Future<Result<void, IdentityFailure>> signOut() async {
    _order.add('signOut');
    return const Success(null);
  }

  @override
  Future<Result<Session, IdentityFailure>> signIn(Credentials credentials) =>
      throw UnimplementedError();

  @override
  Future<Result<Session, IdentityFailure>> refreshSession() =>
      throw UnimplementedError();

  @override
  Stream<Session?> sessionChanges() => const Stream.empty();
}

/// A session that is simply there, for a test about something else.
final class _StaticSession implements SessionReader {
  const _StaticSession(this.current);

  @override
  final Session current;

  @override
  Stream<Session?> changes() => const Stream.empty();
}

final class _Permissions implements PermissionChecker {
  const _Permissions(this._granted);

  final Set<Permission> _granted;

  @override
  bool can(Permission permission) => _granted.contains(permission);
}
