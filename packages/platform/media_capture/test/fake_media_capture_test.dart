@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_capture/media_capture.dart';

CapturedMedia _media() => CapturedMedia(
  path: '/tmp/proof.jpg',
  mimeType: 'image/jpeg',
  byteSize: 2048,
  capturedAt: DateTime.utc(2026, 1, 1, 9),
);

void main() {
  group('FakeMediaCapture', () {
    test('answers queued results in order', () async {
      final capture = FakeMediaCapture()
        ..queue(const Failed(CaptureCancelled()))
        ..queue(Success(_media()));

      expect((await capture.capturePhoto()).isFailure, isTrue);
      expect((await capture.capturePhoto()).isSuccess, isTrue);
    });

    test('records the settings each call asked for', () async {
      final capture = FakeMediaCapture()..queue(Success(_media()));

      await capture.capturePhoto(maxWidthPixels: 640, quality: 50);

      expect(capture.requestedSettings, [(640, 50)]);
    });

    test('fails rather than throws when nothing is queued', () async {
      final result = await FakeMediaCapture().capturePhoto();

      final failure = (result as Failed<CapturedMedia, CaptureFailure>).failure;
      expect(failure, isA<CaptureUnavailable>());
      expect(
        (failure as CaptureUnavailable).detail,
        contains('nothing queued'),
      );
    });
  });
}
