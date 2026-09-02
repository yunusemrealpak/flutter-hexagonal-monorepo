@Tags(['unit'])
library;

import 'dart:io';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:media_capture/media_capture.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// An image picker platform the test drives directly.
final class FakeImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  XFile? nextFile;
  Object? throwOnCapture;
  ImagePickerOptions? lastOptions;
  ImageSource? lastSource;

  /// What `getLostData` answers, or null for a launch that lost nothing.
  LostDataResponse? lostData;

  /// What `getLostData` throws, for the platforms that do not implement it.
  Object? throwOnLostData;

  /// How many times the lost data was asked for.
  int lostDataReads = 0;

  @override
  Future<LostDataResponse> getLostData() async {
    lostDataReads++;
    final error = throwOnLostData;
    if (error != null) {
      // Typed as Object so the fake can reproduce anything a platform channel
      // is capable of throwing, including the UnimplementedError every
      // non-Android implementation of this method raises.
      // ignore: only_throw_errors
      throw error;
    }
    return lostData ?? LostDataResponse.empty();
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    lastSource = source;
    lastOptions = options;
    final error = throwOnCapture;
    if (error != null) {
      // Typed as Object so the fake can reproduce anything a platform channel
      // is capable of throwing.
      // ignore: only_throw_errors
      throw error;
    }
    return nextFile;
  }
}

XFile _file({
  String path = '/tmp/proof.jpg',
  String? mimeType = 'image/jpeg',
}) => XFile.fromData(
  Uint8List.fromList(List<int>.filled(2048, 7)),
  path: path,
  mimeType: mimeType,
);

void main() {
  late FakeImagePickerPlatform platform;
  late FakePermissionRequester permissions;
  late FakeClock clock;
  late ImagePickerMediaCapture capture;

  setUp(() {
    platform = FakeImagePickerPlatform();
    permissions = FakePermissionRequester({
      DevicePermission.camera: PermissionState.granted,
    });
    clock = FakeClock();
    capture = ImagePickerMediaCapture(platform, permissions, clock);
  });

  group('capturePhoto', () {
    test('describes what the camera produced', () async {
      platform.nextFile = _file();

      final result = await capture.capturePhoto();

      final media = (result as Success<CapturedMedia, CaptureFailure>).value;
      expect(media.path, '/tmp/proof.jpg');
      expect(media.mimeType, 'image/jpeg');
      expect(media.byteSize, 2048);
    });

    test('stamps the capture from the injected clock', () async {
      platform.nextFile = _file();
      clock.advance(const Duration(hours: 5));

      final result = await capture.capturePhoto();

      // The platform does not timestamp a capture and something has to.
      // Injected, it is a value this test states rather than measures.
      expect(
        (result as Success<CapturedMedia, CaptureFailure>).value.capturedAt,
        clock.now(),
      );
    });

    test(
      'falls back to a mime type when the platform does not report one',
      () async {
        platform.nextFile = _file(mimeType: null);

        final result = await capture.capturePhoto();

        expect(
          (result as Success<CapturedMedia, CaptureFailure>).value.mimeType,
          'image/jpeg',
        );
      },
    );

    test('asks the camera rather than the gallery', () async {
      platform.nextFile = _file();

      await capture.capturePhoto();

      // Evidence is something the courier takes now, at the door. A gallery
      // pick would let any photo on the device stand as proof of delivery.
      expect(platform.lastSource, ImageSource.camera);
    });

    test('passes the downscaling instructions to the platform', () async {
      platform.nextFile = _file();

      await capture.capturePhoto(maxWidthPixels: 800, quality: 60);

      // Downscaling happens in the platform, not afterwards in Dart: the
      // difference is what a shift of uploads costs on a metered link.
      expect(platform.lastOptions?.maxWidth, 800);
      expect(platform.lastOptions?.imageQuality, 60);
    });

    test('reports a dismissed camera as its own case', () async {
      platform.nextFile = null;

      final result = await capture.capturePhoto();

      // A courier who changes their mind is behaving normally. The case exists
      // so a caller can tell "nothing happened" from "something broke" and not
      // show a red banner for the first.
      expect(
        (result as Failed<CapturedMedia, CaptureFailure>).failure,
        isA<CaptureCancelled>(),
      );
    });

    test('prompts when camera access has never been asked for', () async {
      capture = ImagePickerMediaCapture(
        platform,
        permissions = FakePermissionRequester(),
        clock,
      );
      platform.nextFile = _file();

      final result = await capture.capturePhoto();

      expect(permissions.requested, [DevicePermission.camera]);
      expect(result.isSuccess, isTrue);
    });

    test(
      'keeps a refusal that can be asked again distinct from one that cannot',
      () async {
        permissions.setState(DevicePermission.camera, PermissionState.denied);
        expect(
          ((await capture.capturePhoto())
                  as Failed<CapturedMedia, CaptureFailure>)
              .failure,
          isA<CapturePermissionDenied>(),
        );

        permissions.setState(
          DevicePermission.camera,
          PermissionState.permanentlyDenied,
        );
        expect(
          ((await capture.capturePhoto())
                  as Failed<CapturedMedia, CaptureFailure>)
              .failure,
          isA<CapturePermissionBlocked>(),
        );
      },
    );

    test('does not open the camera when access is refused', () async {
      permissions.setState(DevicePermission.camera, PermissionState.denied);

      await capture.capturePhoto();

      expect(platform.lastSource, isNull);
    });

    test('lets no exception escape', () async {
      platform.throwOnCapture = StateError('camera in use');

      final result = await capture.capturePhoto();

      expect(result.isFailure, isTrue);
      expect(
        (result as Failed<CapturedMedia, CaptureFailure>).failure,
        isA<CaptureUnavailable>(),
      );
    });
  });

  group('recoverLostCapture', () {
    test('describes the file the platform kept for us', () async {
      platform.lostData = LostDataResponse(
        file: _file(path: '/tmp/lost.jpg'),
        type: RetrieveType.image,
      );

      final media = await capture.recoverLostCapture();

      // Android can kill the app while the camera activity is in front. The
      // photograph exists; this call is the only way back to it, and this
      // product's payload is proof-of-delivery photographs.
      expect(media?.path, '/tmp/lost.jpg');
      expect(media?.byteSize, 2048);
      expect(media?.capturedAt, clock.now());
    });

    test('answers null when nothing was lost', () async {
      expect(await capture.recoverLostCapture(), isNull);
    });

    test('answers null when the lost capture is itself an error', () async {
      platform.lostData = LostDataResponse(
        exception: PlatformException(code: 'camera_error'),
        type: RetrieveType.image,
      );

      // There is nothing to hand back either way, and a caller cannot act on
      // the difference: it opens the camera again.
      expect(await capture.recoverLostCapture(), isNull);
    });

    test('answers null on a platform that does not implement it', () async {
      platform.throwOnLostData = UnimplementedError();

      // getLostData is Android's. Everywhere else "nothing was lost" is the
      // truth, and a failure here would be one every caller had to handle and
      // none could act on.
      expect(await capture.recoverLostCapture(), isNull);
    });
  });

  group('bytesOf', () {
    test('reads the file the capture named', () async {
      final directory = await Directory.systemTemp.createTemp('media_capture');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/proof.jpg');
      await file.writeAsBytes(List<int>.filled(64, 3));

      final result = await capture.bytesOf(
        CapturedMedia(
          path: file.path,
          mimeType: 'image/jpeg',
          byteSize: 64,
          capturedAt: clock.now(),
        ),
      );

      expect(
        (result as Success<List<int>, CaptureFailure>).value,
        hasLength(64),
      );
    });

    test('reports a file the operating system has already reclaimed', () async {
      final result = await capture.bytesOf(
        CapturedMedia(
          path: '/tmp/gone-${clock.now().microsecondsSinceEpoch}.jpg',
          mimeType: 'image/jpeg',
          byteSize: 64,
          capturedAt: clock.now(),
        ),
      );

      // CapturedMedia's own doc says the path is temporary. A caller that got
      // an exception here would be one that crashed at a door.
      expect(result, isA<Failed<List<int>, CaptureFailure>>());
    });
  });
}
