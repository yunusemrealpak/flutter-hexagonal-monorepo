import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late ReportingHarness harness;

  setUp(() {
    harness = ReportingHarness()..listen();
  });
  tearDown(() => harness.dispose());

  Future<void> delivered(String id, {DateTime? at}) async {
    harness.events.publish(
      ShipmentDelivered(
        shipmentId: ReportingHarness.parcel(id),
        proofReference: 'proof-$id',
        occurredAt: at ?? DateTime.utc(2026, 3, 4, 9),
      ),
    );
    await pumpEventQueue();
  }

  Future<void> failed(String id, {DateTime? at}) async {
    harness.events.publish(
      ShipmentFailed(
        shipmentId: ReportingHarness.parcel(id),
        reason: 'recipient absent',
        occurredAt: at ?? DateTime.utc(2026, 3, 4, 11),
      ),
    );
    await pumpEventQueue();
  }

  Future<void> returned(String id, {DateTime? at}) async {
    harness.events.publish(
      ShipmentReturned(
        shipmentId: ReportingHarness.parcel(id),
        occurredAt: at ?? DateTime.utc(2026, 3, 4, 18),
      ),
    );
    await pumpEventQueue();
  }

  group('building the totals from events', () {
    test('a day nobody has finished a parcel on reads as zero', () async {
      final tally = ReportingHarness.valueOf(
        await harness.facade.tallyFor(ReportingHarness.today),
      );

      expect(tally.total, 0);
      expect(tally.successRate, 0);
    });

    test('counts each of the three outcomes', () async {
      await delivered('SHP-1');
      await failed('SHP-2');
      await returned('SHP-3');

      final tally = ReportingHarness.valueOf(
        await harness.facade.tallyFor(ReportingHarness.today),
      );

      expect(tally.delivered, 1);
      expect(tally.failed, 1);
      expect(tally.returned, 1);
      expect(tally.successRate, closeTo(1 / 3, 0.0001));
    });

    test('a parcel that failed and then arrived counts once', () async {
      await failed('SHP-1');
      await delivered('SHP-1', at: DateTime.utc(2026, 3, 4, 16));

      final tally = ReportingHarness.valueOf(
        await harness.facade.tallyFor(ReportingHarness.today),
      );

      expect(tally.total, 1);
      expect(tally.delivered, 1);
      expect(tally.failed, 0);
    });

    test('the same event twice changes nothing', () async {
      await delivered('SHP-1');
      await delivered('SHP-1');

      final tally = ReportingHarness.valueOf(
        await harness.facade.tallyFor(ReportingHarness.today),
      );

      expect(tally.total, 1);
    });

    test('the day is the event day, not the day it was processed', () async {
      await delivered('SHP-1', at: DateTime.utc(2026, 3, 3, 22));

      final yesterday = ReportingHarness.valueOf(
        await harness.facade.tallyFor(
          ReportingDay.of(DateTime.utc(2026, 3, 3)),
        ),
      );
      final today = ReportingHarness.valueOf(
        await harness.facade.tallyFor(ReportingHarness.today),
      );

      expect(yesterday.delivered, 1);
      expect(today.total, 0);
    });

    test('a write failure is logged and the watcher stays alive', () async {
      harness.keyValue.failNextWith(const StoreUnavailable(detail: 'locked'));

      await delivered('SHP-1');
      await delivered('SHP-2');

      expect(harness.logger.recordsAt(LogLevel.warning), isNotEmpty);
      expect(
        ReportingHarness.valueOf(
          await harness.facade.tallyFor(ReportingHarness.today),
        ).total,
        1,
      );
    });

    test('shipments never learns that reporting exists', () async {
      await delivered('SHP-1');

      expect(harness.events.publishedOf<ShipmentDelivered>(), hasLength(1));
    });
  });

  group('reading a range', () {
    test('includes the days with nothing on them', () async {
      await delivered('SHP-1', at: DateTime.utc(2026, 3, 2, 9));
      await delivered('SHP-2', at: DateTime.utc(2026, 3, 4, 9));

      final week = await harness.facade.range(
        from: ReportingDay.of(DateTime.utc(2026, 3, 2)),
        to: ReportingDay.of(DateTime.utc(2026, 3, 4)),
      );

      final days =
          (week as Success<List<OperationTally>, ReportingFailure>).value;
      expect(days.map((tally) => tally.total), [1, 0, 1]);
    });

    test('a single day is a range of one', () async {
      final week = await harness.facade.range(
        from: ReportingHarness.today,
        to: ReportingHarness.today,
      );

      expect(
        (week as Success<List<OperationTally>, ReportingFailure>).value,
        hasLength(1),
      );
    });

    test('walks a month boundary without skipping a day', () async {
      final range = await harness.facade.range(
        from: ReportingDay.of(DateTime.utc(2026, 2, 27)),
        to: ReportingDay.of(DateTime.utc(2026, 3, 2)),
      );

      expect(
        (range as Success<List<OperationTally>, ReportingFailure>).value.map(
          (tally) => tally.day.value,
        ),
        ['2026-02-27', '2026-02-28', '2026-03-01', '2026-03-02'],
      );
    });

    test('an inverted range is refused, not answered with nothing', () async {
      final range = await harness.facade.range(
        from: ReportingDay.of(DateTime.utc(2026, 3, 6)),
        to: ReportingDay.of(DateTime.utc(2026, 3, 2)),
      );

      expect(ReportingHarness.failureOf(range), isA<RangeInverted>());
    });
  });
}
