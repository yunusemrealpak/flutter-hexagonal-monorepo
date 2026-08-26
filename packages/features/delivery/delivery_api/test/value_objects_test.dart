@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('identifiers', () {
    test('refuse an empty or blank value', () {
      for (final raw in ['', '   ']) {
        expect(
          DeliveryAttemptId.parse(raw),
          isA<Failed<DeliveryAttemptId, DeliveryFailure>>(),
        );
        expect(
          ProofReference.parse(raw),
          isA<Failed<ProofReference, DeliveryFailure>>(),
        );
      }
    });

    test('trim what a header or a form field brought with it', () {
      expect(
        Fixtures.unwrap(ProofReference.parse('  proof-9 ')).value,
        'proof-9',
      );
    });
  });

  group('references', () {
    test('report a foreign identifier as a delivery failure', () {
      // The rule this exists for: a failure belongs to the package that owns
      // the port. A DeliveryGateway promising DeliveryFailure may not hand
      // back one of shipments' or identity's.
      final shipment = ShipmentReference.parse('');
      final courier = CourierReference.parse('');

      expect(shipment, isA<Failed<Object, DeliveryFailure>>());
      expect(courier, isA<Failed<Object, DeliveryFailure>>());
      expect(
        (shipment as Failed<Object, DeliveryFailure>).failure,
        isA<MalformedDeliveryValue>(),
      );
    });

    test('read a good one straight through', () {
      expect(
        Fixtures.unwrap(ShipmentReference.parse('SHP-9')).value,
        'SHP-9',
      );
      expect(
        Fixtures.unwrap(CourierReference.parse('courier-9')).value,
        'courier-9',
      );
    });
  });

  group('evidence', () {
    test('an empty capture proves nothing and is refused', () {
      // What a screen produces when somebody taps done without drawing.
      expect(
        SignatureCapture.of(bytes: const [], capturedAt: Fixtures.noon),
        isA<Failed<SignatureCapture, DeliveryFailure>>(),
      );
      expect(
        PhotoEvidence.of(bytes: const [], capturedAt: Fixtures.noon),
        isA<Failed<PhotoEvidence, DeliveryFailure>>(),
      );
      expect(
        ScanEvidence.of(symbol: '  ', scannedAt: Fixtures.noon),
        isA<Failed<ScanEvidence, DeliveryFailure>>(),
      );
    });

    test('a photograph that is not an image is refused', () {
      expect(
        PhotoEvidence.of(
          bytes: const [1],
          capturedAt: Fixtures.noon,
          mimeType: 'application/pdf',
        ),
        isA<Failed<PhotoEvidence, DeliveryFailure>>(),
      );
    });

    test('captured instants are normalised to UTC', () {
      // Every timestamp in this package is UTC, so that two devices in two
      // timezones produce comparable evidence.
      final local = DateTime(2026, 3, 14, 12);
      final photo = Fixtures.unwrap(
        PhotoEvidence.of(bytes: const [1], capturedAt: local),
      );

      expect(photo.capturedAt.isUtc, isTrue);
    });
  });

  group('Recipient', () {
    test('needs a name', () {
      // A hand-over with nobody's name on it is not evidence of anything.
      expect(
        Recipient.named('  '),
        isA<Failed<Recipient, DeliveryFailure>>(),
      );
    });

    test('defaults the relationship to the person it was addressed to', () {
      expect(Fixtures.recipient().relationship, 'self');
    });

    test('is equal by what it holds', () {
      expect(Fixtures.recipient(), Fixtures.recipient());
    });
  });

  group('ProofOfDelivery', () {
    test('says which kinds of evidence it carries', () {
      final proof = Fixtures.proof(
        signature: Fixtures.signature(),
        scan: Fixtures.scan(),
      );

      expect(proof.carries, {EvidenceKind.signature, EvidenceKind.scan});
    });

    test('replaces only the photograph', () {
      // Narrow on purpose: the one thing that legitimately rewrites a captured
      // proof is compression — the same photograph, fewer bytes.
      final proof = Fixtures.proof(
        signature: Fixtures.signature(),
        photo: Fixtures.photo(bytes: const [1, 2, 3, 4, 5, 6, 7, 8]),
      );

      final smaller = proof.withPhoto(Fixtures.photo(bytes: const [1]));

      expect(smaller.photo!.byteCount, 1);
      expect(smaller.signature, same(proof.signature));
      expect(smaller.recipient, proof.recipient);
    });
  });
}
