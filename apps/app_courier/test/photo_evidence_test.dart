@Tags(['widget'])
library;

import 'package:app_courier/main.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_infrastructure/delivery_infrastructure.dart';
import 'package:delivery_presentation/delivery_presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:media_capture/media_capture.dart';

import 'support/test_platform.dart';

/// Whether a courier can photograph a parcel at all.
///
/// `ProofCaptureScreen` has taken an `onCapturePhoto` callback since phase 7
/// and no app supplied one, so the button was never drawn and
/// `ImagePickerMediaCapture` was never constructed outside its own tests. This
/// is the app half of closing that.
void main() {
  late GetIt container;
  late FakeMediaCapture camera;

  setUp(() async {
    container = await configureCourier(testPlatform());
    camera = FakeMediaCapture();
    // The one registration replaced: everything above it — CameraProofSource,
    // the compressor, the screen — is what this app composes. A hand-built
    // stand-in for the whole chain would be a test of a different app.
    await container.unregister<MediaCapture>();
    container.registerSingleton<MediaCapture>(camera);

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

  Future<void> openProof(WidgetTester tester) async {
    final router = buildCourierRouter(container).build();
    await tester.pumpWidget(CourierApp(router: router));
    await tester.pumpAndSettle();
    router.go('/stops/SHP-1/proof');
    await tester.pumpAndSettle();
  }

  testWidgets('the proof screen is given a camera', (tester) async {
    await openProof(tester);

    // The assertion is on the wiring rather than on a rendered button, and
    // deliberately so: the button appears once `arrive` has succeeded, which
    // needs a geofence and a server. What this app is responsible for is
    // supplying the capability at all — `ProofCaptureScreen` draws no camera
    // when it is handed none, which is how `app_dispatcher` gets no camera.
    final screen = tester.widget<ProofCaptureScreen>(
      find.byType(ProofCaptureScreen),
    );
    expect(screen.onCapturePhoto, isNotNull);
  });

  testWidgets('what it is given produces evidence from the camera', (
    tester,
  ) async {
    camera
      ..queue(
        Success(
          CapturedMedia(
            path: '/tmp/proof.jpg',
            mimeType: 'image/jpeg',
            byteSize: 32,
            capturedAt: DateTime.utc(2026, 3, 14, 12),
          ),
        ),
      )
      ..bytes['/tmp/proof.jpg'] = List<int>.filled(32, 9);

    await openProof(tester);
    final screen = tester.widget<ProofCaptureScreen>(
      find.byType(ProofCaptureScreen),
    );

    final photo = await screen.onCapturePhoto!();

    // End to end through what this app composed: the fake camera, the real
    // CameraProofSource, the real compressor, and the real key-value store
    // the marker is written into.
    expect(photo?.byteCount, 32);
    expect(camera.requestedSettings, hasLength(1));
  });

  testWidgets('a courier who backs out gets no evidence and no error', (
    tester,
  ) async {
    camera.queue(const Failed(CaptureCancelled()));

    await openProof(tester);
    final screen = tester.widget<ProofCaptureScreen>(
      find.byType(ProofCaptureScreen),
    );

    expect(await screen.onCapturePhoto!(), isNull);
  });

  test('the source knows which parcel a lost capture belonged to', () {
    // The app composes the recovery, not just the capture. The behaviour is
    // proved in delivery_infrastructure; what this asserts is that this app
    // builds the thing that has it, rather than calling MediaCapture directly
    // from the router and losing the marker.
    expect(container.isRegistered<CameraProofSource>(), isTrue);
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

final class _Permissions implements PermissionChecker {
  const _Permissions(this._granted);

  final Set<Permission> _granted;

  @override
  bool can(Permission permission) => _granted.contains(permission);
}
