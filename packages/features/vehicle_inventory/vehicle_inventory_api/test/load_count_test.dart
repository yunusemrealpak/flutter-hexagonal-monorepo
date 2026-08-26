import 'package:test/test.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

import 'support/fixtures.dart';

void main() {
  group('opening a count', () {
    test('starts open with everything missing and nothing unexpected', () {
      final count = open();

      expect(count.isOpen, isTrue);
      expect(count.missing, hasLength(3));
      expect(count.unexpected, isEmpty);
      expect(count.isReconciled, isFalse);
    });

    test('refuses a manifest with nothing on it', () {
      final refused = LoadCount.opened(
        id: countId('CNT-2'),
        courier: courier,
        direction: LoadDirection.loading,
        manifest: const {},
        startedAt: started,
      );

      expect(failureOf(refused), isA<MalformedCount>());
    });

    test('the manifest cannot be changed from outside', () {
      final count = open();

      expect(
        () => count.manifest.add(parcel('SHP-9')),
        throwsUnsupportedError,
      );
    });
  });

  group('scanning', () {
    test('moves a parcel out of missing', () {
      final count = valueOf(open().scan(parcel('SHP-1')));

      expect(count.missing, {parcel('SHP-2'), parcel('SHP-3')});
    });

    test('the same parcel twice is one parcel', () {
      final once = valueOf(open().scan(parcel('SHP-1')));

      final twice = valueOf(once.scan(parcel('SHP-1')));

      expect(twice.scanned, hasLength(1));
      expect(twice, same(once));
    });

    test('a parcel nobody expected is recorded, not refused', () {
      final count = valueOf(open().scan(parcel('SHP-9')));

      expect(count.unexpected, {parcel('SHP-9')});
      expect(count.missing, hasLength(3));
    });

    test('a closed count refuses a scan', () {
      final closed = valueOf(open().closedAtInstant(started));

      expect(failureOf(closed.scan(parcel('SHP-1'))), isA<CountClosed>());
    });

    test('a van that matches the paperwork reconciles', () {
      var count = open();
      for (final id in ['SHP-1', 'SHP-2', 'SHP-3']) {
        count = valueOf(count.scan(parcel(id)));
      }

      expect(count.isReconciled, isTrue);
    });
  });

  group('closing', () {
    test('is allowed while the count disagrees', () {
      final closed = valueOf(
        valueOf(open().scan(parcel('SHP-1'))).closedAtInstant(started),
      );

      expect(closed.isOpen, isFalse);
      expect(closed.missing, hasLength(2));
    });

    test('twice is refused', () {
      final closed = valueOf(open().closedAtInstant(started));

      expect(failureOf(closed.closedAtInstant(started)), isA<CountClosed>());
    });
  });

  group('a stored count', () {
    test('cannot have closed before it started', () {
      final refused = LoadCount.stored(
        id: countId('CNT-1'),
        courier: courier,
        direction: LoadDirection.unloading,
        manifest: {parcel('SHP-1')},
        scanned: const {},
        startedAt: started,
        closedAt: started.subtract(const Duration(minutes: 1)),
      );

      expect(failureOf(refused), isA<MalformedCount>());
    });

    test('keeps the direction it was counted in', () {
      final stored = valueOf(
        LoadCount.stored(
          id: countId('CNT-1'),
          courier: courier,
          direction: LoadDirection.unloading,
          manifest: {parcel('SHP-1')},
          scanned: {parcel('SHP-1')},
          startedAt: started,
          closedAt: null,
        ),
      );

      expect(stored.direction, LoadDirection.unloading);
      expect(stored.isReconciled, isTrue);
    });
  });
}
