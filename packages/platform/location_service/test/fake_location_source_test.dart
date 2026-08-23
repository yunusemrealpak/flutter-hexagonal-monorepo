@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_service/location_service.dart';

GeoFix _fix({double latitude = 41.0082}) => GeoFix(
  latitude: latitude,
  longitude: 28.9784,
  accuracyMetres: 10,
  capturedAt: DateTime.utc(2026, 1, 1, 9),
);

void main() {
  late FakeLocationSource source;

  setUp(() => source = FakeLocationSource());
  tearDown(() async => source.dispose());

  group('FakeLocationSource', () {
    test('answers queued results in order', () async {
      source
        ..queue(const Failed(LocationTimeout(Duration(seconds: 15))))
        ..queue(Success(_fix()));

      final first = await source.currentFix();
      final second = await source.currentFix();

      // A queue rather than a single canned answer is what lets a test drive a
      // retry: fail once, succeed once, assert the caller tried twice.
      expect(first.isFailure, isTrue);
      expect(second.isSuccess, isTrue);
    });

    test('records the accuracy each call asked for', () async {
      source
        ..queue(Success(_fix()))
        ..queue(Success(_fix()));

      await source.currentFix(accuracy: FixAccuracy.coarse);
      await source.currentFix(accuracy: FixAccuracy.fine);

      // The assertion for "a proof of delivery asks for a fine fix and a
      // routine ping does not".
      expect(source.requestedAccuracies, [
        FixAccuracy.coarse,
        FixAccuracy.fine,
      ]);
    });

    test('fails rather than throws when nothing is queued', () async {
      final result = await source.currentFix();

      final failure = (result as Failed<GeoFix, LocationFailure>).failure;
      expect(failure, isA<LocationUnavailable>());
      expect(
        (failure as LocationUnavailable).detail,
        contains('nothing queued'),
      );
    });

    test('walks a courier along a route one position at a time', () async {
      final seen = <Result<GeoFix, LocationFailure>>[];
      final subscription = source.track().listen(seen.add);
      addTearDown(subscription.cancel);

      source
        ..emit(Success(_fix(latitude: 41.01)))
        ..emit(Success(_fix(latitude: 41.02)));
      await pumpEventQueue();

      expect(seen, hasLength(2));
    });

    test('records whether tracking asked for background access', () async {
      final subscription = source.track(inBackground: true).listen((_) {});
      addTearDown(subscription.cancel);

      expect(source.trackedInBackground, isTrue);
    });
  });
}
