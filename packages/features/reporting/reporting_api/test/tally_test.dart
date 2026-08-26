import 'package:core_kernel/core_kernel.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

ShipmentId parcel(String raw) =>
    (ShipmentId.parse(raw) as Success<ShipmentId, ShipmentFailure>).value;

ReportingDay get today => ReportingDay.of(DateTime.utc(2026, 3, 4, 9));

void main() {
  group('an empty day', () {
    test('counts nothing and reads as zero rather than as nothing', () {
      final tally = OperationTally.empty(today);

      expect(tally.total, 0);
      expect(tally.delivered, 0);
      expect(tally.successRate, 0);
    });
  });

  group('recording outcomes', () {
    test('counts each parcel once', () {
      final tally = OperationTally.empty(today)
          .recording(
            shipment: parcel('SHP-1'),
            outcome: ShipmentOutcome.delivered,
          )
          .recording(
            shipment: parcel('SHP-2'),
            outcome: ShipmentOutcome.failed,
          );

      expect(tally.delivered, 1);
      expect(tally.failed, 1);
      expect(tally.total, 2);
    });

    test('the same parcel twice changes nothing', () {
      final once = OperationTally.empty(today).recording(
        shipment: parcel('SHP-1'),
        outcome: ShipmentOutcome.delivered,
      );

      final twice = once.recording(
        shipment: parcel('SHP-1'),
        outcome: ShipmentOutcome.delivered,
      );

      expect(twice.total, 1);
      expect(twice.delivered, 1);
    });

    test('a parcel that failed and then arrived counts once, as delivered', () {
      final tally = OperationTally.empty(today)
          .recording(
            shipment: parcel('SHP-1'),
            outcome: ShipmentOutcome.failed,
          )
          .recording(
            shipment: parcel('SHP-1'),
            outcome: ShipmentOutcome.delivered,
          );

      expect(tally.total, 1);
      expect(tally.failed, 0);
      expect(tally.delivered, 1);
    });

    test('the success rate is over finished parcels only', () {
      final tally = OperationTally.empty(today)
          .recording(
            shipment: parcel('SHP-1'),
            outcome: ShipmentOutcome.delivered,
          )
          .recording(
            shipment: parcel('SHP-2'),
            outcome: ShipmentOutcome.delivered,
          )
          .recording(
            shipment: parcel('SHP-3'),
            outcome: ShipmentOutcome.returned,
          );

      expect(tally.successRate, closeTo(2 / 3, 0.0001));
    });

    test('a recorded outcome cannot be changed from outside', () {
      final tally = OperationTally.empty(today).recording(
        shipment: parcel('SHP-1'),
        outcome: ShipmentOutcome.delivered,
      );

      expect(
        () => tally.outcomes[parcel('SHP-2')] = ShipmentOutcome.failed,
        throwsUnsupportedError,
      );
    });
  });

  group('ReportingDay', () {
    test('is the UTC day of the instant', () {
      expect(
        ReportingDay.of(DateTime.utc(2026, 3, 4, 23, 59)).value,
        '2026-03-04',
      );
      expect(
        ReportingDay.of(DateTime.utc(2026, 3, 5, 0, 1)).value,
        '2026-03-05',
      );
    });

    test('pads a single-digit month and day', () {
      expect(ReportingDay.of(DateTime.utc(2026, 1, 2)).value, '2026-01-02');
    });

    test('round-trips through parse', () {
      final day = ReportingDay.of(DateTime.utc(2026, 3, 4));

      expect(
        (ReportingDay.parse(day.value)
                as Success<ReportingDay, ReportingFailure>)
            .value,
        day,
      );
    });

    test('refuses something that is not a calendar day', () {
      for (final raw in ['2026-03', 'yesterday', '2026-13-01']) {
        expect(
          ReportingDay.parse(raw),
          isA<Failed<ReportingDay, ReportingFailure>>(),
          reason: raw,
        );
      }
    });

    test('orders by spelling, because the spelling is fixed-width', () {
      final earlier = ReportingDay.of(DateTime.utc(2026, 3, 4));
      final later = ReportingDay.of(DateTime.utc(2026, 12, 31));

      expect(earlier.isBefore(later), isTrue);
      expect(later.isBefore(earlier), isFalse);
      expect(earlier.isBefore(earlier), isFalse);
    });
  });

  group('ShipmentOutcome', () {
    test('round-trips through its stored spelling', () {
      for (final outcome in ShipmentOutcome.values) {
        expect(
          (ShipmentOutcome.parse(outcome.name)
                  as Success<ShipmentOutcome, ReportingFailure>)
              .value,
          outcome,
        );
      }
    });

    test('has no in-progress member', () {
      expect(ShipmentOutcome.values, hasLength(3));
    });
  });
}
