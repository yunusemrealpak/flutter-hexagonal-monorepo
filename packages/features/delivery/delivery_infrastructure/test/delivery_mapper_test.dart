@Tags(['unit'])
library;

import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_infrastructure/delivery_infrastructure.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:flutter_test/flutter_test.dart';

DeliveryAttempt _roundTrip(DeliveryAttempt attempt) =>
    DeliveryMapper.attemptToDomain(
      DeliveryAttemptDto.fromJson(
        DeliveryMapper.attemptToDto(attempt).toJson(),
      ),
    ).fold((value) => value, (failure) => throw StateError('$failure'));

void main() {
  group('DeliveryMapper', () {
    test('an attempt in progress survives the round trip', () {
      final read = _roundTrip(DeliveryFixtures.attempt());

      expect(read.id.value, 'attempt-1');
      expect(read.shipment.value, 'SHP-1');
      expect(read.courier.value, 'courier-1');
      expect(read.isSettled, isFalse);
    });

    test('a completed attempt comes back with its evidence and handle', () {
      final read = _roundTrip(
        DeliveryFixtures.completed(proof: DeliveryFixtures.fullProof()),
      );

      final outcome = read.outcome as AttemptCompleted;
      expect(outcome.reference.value, 'proof-1');
      expect(outcome.proof.carries, {
        EvidenceKind.signature,
        EvidenceKind.photo,
      });
    });

    test('the bytes survive, not just the fact that there were some', () {
      // Months later, that difference is the whole value of the record.
      final proof = DeliveryFixtures.proof(
        signature: DeliveryFixtures.signature(bytes: const [9, 8, 7]),
      );

      final read = _roundTrip(DeliveryFixtures.completed(proof: proof));

      final outcome = read.outcome as AttemptCompleted;
      expect(outcome.proof.signature!.bytes, [9, 8, 7]);
    });

    test('a failed attempt keeps its reason and its note', () {
      final read = _roundTrip(
        DeliveryFixtures.failed(
          reason: const NonDeliveryReason.damagedInTransit(note: 'crushed'),
        ),
      );

      final outcome = read.outcome as AttemptFailed;
      expect(outcome.reason, isA<DamagedInTransit>());
      expect((outcome.reason as DamagedInTransit).note, 'crushed');
    });

    test('a reschedule keeps the day that was asked for', () {
      final requested = DeliveryFixtures.noon.add(const Duration(days: 1));

      final read = _roundTrip(
        DeliveryFixtures.failed(
          reason: NonDeliveryReason.rescheduled(requestedFor: requested),
        ),
      );

      final reason = (read.outcome as AttemptFailed).reason as Rescheduled;
      expect(reason.requestedFor, requested);
    });

    test('reading back runs the proof policy, so a stripped record fails', () {
      // The payoff of replaying the domain's own transitions instead of
      // hydrating fields. A high-value proof that has lost its photograph on
      // the way back does not quietly become a valid delivery.
      final attempt = DeliveryFixtures.attempt(grade: DeliveryGrade.highValue);
      final completed = attempt
          .completeWith(
            proof: DeliveryFixtures.fullProof(),
            reference: DeliveryFixtures.reference(),
            at: DeliveryFixtures.noon,
          )
          .fold((value) => value, (failure) => throw StateError('$failure'));

      final json = DeliveryMapper.attemptToDto(completed).toJson();
      (json['proof']! as Map<String, dynamic>)['photoBase64'] = null;

      final read = DeliveryMapper.attemptToDomain(
        DeliveryAttemptDto.fromJson(json),
      );

      expect(read.fold((_) => null, (f) => f), isA<ProofInsufficient>());
    });

    test('a completed attempt with no evidence at all is refused', () {
      final json = DeliveryMapper.attemptToDto(
        DeliveryFixtures.completed(),
      ).toJson()..['proof'] = null;

      final read = DeliveryMapper.attemptToDomain(
        DeliveryAttemptDto.fromJson(json),
      );

      expect(read.fold((_) => null, (f) => f), isA<MalformedDeliveryValue>());
    });

    test('damage recorded without a note does not load', () {
      // The domain says the note is required. A mapper that invented one would
      // be overruling it.
      final json = DeliveryMapper.attemptToDto(
        DeliveryFixtures.failed(
          reason: const NonDeliveryReason.damagedInTransit(note: 'crushed'),
        ),
      ).toJson()..['reasonNote'] = null;

      final read = DeliveryMapper.attemptToDomain(
        DeliveryAttemptDto.fromJson(json),
      );

      expect(read.fold((_) => null, (f) => f), isA<MalformedDeliveryValue>());
    });

    test('an unreadable grade loads as standard rather than failing', () {
      // Getting a grade wrong loosens a proof requirement; refusing to load
      // the record loses the delivery. The first is recoverable.
      final json = DeliveryMapper.attemptToDto(
        DeliveryFixtures.attempt(),
      ).toJson()..['grade'] = 'platinum';

      final read = DeliveryMapper.attemptToDomain(
        DeliveryAttemptDto.fromJson(json),
      );

      expect(
        read.fold((a) => a.grade, (f) => throw StateError('$f')),
        DeliveryGrade.standard,
      );
    });

    test('an unreadable foreign identifier is a delivery failure', () {
      // ShipmentReference and CourierReference are what let this file rebuild
      // the identifiers delivery's contract is expressed in without seeing
      // shipments_api or identity_api.
      final json = DeliveryMapper.attemptToDto(
        DeliveryFixtures.attempt(),
      ).toJson()..['shipmentId'] = '';

      final read = DeliveryMapper.attemptToDomain(
        DeliveryAttemptDto.fromJson(json),
      );

      expect(read.fold((_) => null, (f) => f), isA<MalformedDeliveryValue>());
    });

    test('bytes that are not base64 are a named failure, not a crash', () {
      final json = DeliveryMapper.attemptToDto(
        DeliveryFixtures.completed(),
      ).toJson();
      (json['proof']! as Map<String, dynamic>)['signatureBase64'] = 'not!b64';

      final read = DeliveryMapper.attemptToDomain(
        DeliveryAttemptDto.fromJson(json),
      );

      expect(read.fold((_) => null, (f) => f), isA<MalformedDeliveryValue>());
    });

    test('instants go out in UTC', () {
      // The line that is easy to omit and hard to notice missing. A device set
      // to Istanbul time would otherwise write local instants that read back
      // as UTC.
      final dto = DeliveryMapper.attemptToDto(DeliveryFixtures.attempt());

      expect(dto.startedAt, endsWith('Z'));
    });
  });
}
