@Tags(['widget'])
library;

import 'dart:async';

import 'package:app_courier/main.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_presentation/delivery_presentation.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_testing/identity_testing.dart';

import 'support/test_platform.dart';

/// Whether a courier can take a signature at all.
///
/// The other half of `photo_evidence_test.dart`, and the interesting half:
/// there is no adapter under it. A photograph travels app → `CameraProofSource`
/// → `platform/media_capture`; a signature travels app → `PeykSignaturePanel`,
/// because ink needs no device. What this asserts is the one seam that leaves:
/// the app is the only place that can see a component, a `Clock` and a domain
/// factory at once, and the panel is pushed and popped by the app because §2.4
/// gives it nothing else.
void main() {
  late GetIt container;
  final clock = FakeClock(DateTime.utc(2026, 3, 14, 12, 30));

  setUp(() async {
    container = await configureCourier(testPlatform());

    // The real clock is replaced rather than the signature path being
    // stubbed. Rule 1.2.8's whole payoff is that an instant a screen records
    // is assertable, and it is only assertable because nothing on this path
    // calls `DateTime.now()`.
    await container.unregister<Clock>();
    container.registerSingleton<Clock>(clock);

    await container.unregister<SessionReader>();
    await container.unregister<PermissionChecker>();
    container
      ..registerSingleton<SessionReader>(
        _StaticSession(SessionBuilder().build()),
      )
      ..registerSingleton<PermissionChecker>(
        const _Permissions({
          Permission.viewAssignedShipments,
          Permission.completeDelivery,
        }),
      );
  });

  tearDown(() => container.reset());

  Future<ProofCaptureScreen> openProof(WidgetTester tester) async {
    final router = buildCourierRouter(container).build();
    await tester.pumpWidget(CourierApp(router: router));
    await tester.pumpAndSettle();
    router.go('/stops/SHP-1/proof');
    await tester.pumpAndSettle();
    return tester.widget<ProofCaptureScreen>(find.byType(ProofCaptureScreen));
  }

  /// Draws a line across the pad.
  Future<void> scribble(WidgetTester tester) async {
    final pad = find.byType(PeykSignaturePad);
    final origin = tester.getTopLeft(pad) + const Offset(20, 20);
    final gesture = await tester.startGesture(origin);
    for (var step = 1; step <= 5; step++) {
      await gesture.moveTo(origin + Offset(step * 20.0, step * 8.0));
    }
    await gesture.up();
    await tester.pump();
  }

  /// Lets the engine finish rasterising, pumping between attempts.
  ///
  /// The same alternation `design_system`'s own tests need, and for the same
  /// reason: `Picture.toImage` completes on the engine, which fake async never
  /// gives a turn — and no widget advances inside a `runAsync` window, so the
  /// route cannot pop while it is open.
  Future<void> settleEngine(
    WidgetTester tester, {
    required bool Function() until,
  }) async {
    for (var round = 0; !until() && round < 100; round++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
  }

  testWidgets('the proof screen is given somewhere to sign', (tester) async {
    final screen = await openProof(tester);

    // The wiring rather than a rendered button, for the reason the photo test
    // gives: the button appears once `arrive` has succeeded, and an app that
    // supplies nothing is how `app_dispatcher` draws no pad.
    expect(screen.onCaptureSignature, isNotNull);
  });

  testWidgets('a signature comes back stamped with the app clock', (
    tester,
  ) async {
    final screen = await openProof(tester);

    Result<SignatureCapture, CaptureRefusal>? capture;
    unawaited(screen.onCaptureSignature!().then((r) => capture = r));
    await tester.pumpAndSettle();

    // The panel this app pushed, over the screen that asked for it.
    expect(find.byType(PeykSignaturePanel), findsOneWidget);
    expect(find.text('Please sign here'), findsOneWidget);

    await scribble(tester);
    await tester.tap(find.text('Done'));
    await settleEngine(tester, until: () => capture != null);

    final signature = capture!.fold((s) => s, (_) => null);
    expect(signature, isNotNull);
    expect(signature!.bytes, isNotEmpty);
    // The line the panel could not write, asserted rather than assumed.
    expect(signature.capturedAt, DateTime.utc(2026, 3, 14, 12, 30));
    // And the app popped what the app pushed: the panel may not close itself.
    expect(find.byType(PeykSignaturePanel), findsNothing);
  });

  testWidgets('backing out is a decline and not a failure', (tester) async {
    final screen = await openProof(tester);

    Result<SignatureCapture, CaptureRefusal>? capture;
    unawaited(screen.onCaptureSignature!().then((r) => capture = r));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Nothing in the domain went wrong, so it is not a `DeliveryFailure`. The
    // screen draws nothing for this one, which is what makes it different from
    // every other case of `CaptureRefusal`.
    expect(capture!.fold((_) => null, (r) => r), isA<CaptureDeclined>());
    expect(find.byType(PeykSignaturePanel), findsNothing);
  });

  testWidgets('an empty panel cannot be finished', (tester) async {
    final screen = await openProof(tester);

    unawaited(screen.onCaptureSignature!());
    await tester.pumpAndSettle();

    // `SignatureCapture.of` would refuse the empty bytes — after telling a
    // courier they had a signature. The panel refuses before.
    final done = tester.widget<PeykButton>(
      find.ancestor(of: find.text('Done'), matching: find.byType(PeykButton)),
    );
    expect(done.onPressed, isNull);
  });
}

/// A session that is simply there, for a test about something else.
final class _StaticSession implements SessionReader {
  const _StaticSession(this.current);

  @override
  final Session current;

  @override
  Stream<Session?> changes() => const Stream.empty();
}

/// The grants this test needs, and nothing else.
final class _Permissions implements PermissionChecker {
  const _Permissions(this._granted);

  final Set<Permission> _granted;

  @override
  bool can(Permission permission) => _granted.contains(permission);
}
