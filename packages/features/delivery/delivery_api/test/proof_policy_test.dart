@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('ProofPolicy', () {
    test('a standard parcel is closed by any single piece of evidence', () {
      const policy = ProofPolicy.forGrade(DeliveryGrade.standard);

      for (final proof in [
        Fixtures.proof(signature: Fixtures.signature()),
        Fixtures.proof(photo: Fixtures.photo()),
        Fixtures.proof(scan: Fixtures.scan()),
      ]) {
        expect(
          policy.accept(proof),
          isA<Success<ProofOfDelivery, DeliveryFailure>>(),
        );
      }
    });

    test('no evidence at all is refused at every grade', () {
      // A recipient's name with nothing behind it is not a proof. The floor
      // applies to every grade, which is why it is checked once rather than
      // expressed as three alternative sets per grade.
      for (final grade in DeliveryGrade.values) {
        final refused = ProofPolicy.forGrade(grade).accept(Fixtures.proof());

        expect(refused, isA<Failed<ProofOfDelivery, DeliveryFailure>>());
        expect(
          (refused as Failed<ProofOfDelivery, DeliveryFailure>).failure,
          isA<ProofInsufficient>(),
        );
      }
    });

    test('a high-value parcel needs a signature and a photograph', () {
      const policy = ProofPolicy.forGrade(DeliveryGrade.highValue);

      expect(
        policy.accept(
          Fixtures.proof(
            signature: Fixtures.signature(),
            photo: Fixtures.photo(),
          ),
        ),
        isA<Success<ProofOfDelivery, DeliveryFailure>>(),
      );
    });

    test('a high-value refusal says which piece is missing', () {
      // Carrying the list rather than a sentence is what lets a courier's
      // screen open the camera. "Insufficient proof" turns into a shrug.
      final refused = const ProofPolicy.forGrade(
        DeliveryGrade.highValue,
      ).accept(Fixtures.proof(signature: Fixtures.signature()));

      final failure =
          (refused as Failed<ProofOfDelivery, DeliveryFailure>).failure
              as ProofInsufficient;
      expect(failure.missing, ['photo']);
      expect(failure.grade, 'highValue');
    });

    test('a scan does not stand in for a signature on a high-value parcel', () {
      final refused = const ProofPolicy.forGrade(
        DeliveryGrade.highValue,
      ).accept(Fixtures.proof(scan: Fixtures.scan(), photo: Fixtures.photo()));

      expect(
        ((refused as Failed<ProofOfDelivery, DeliveryFailure>).failure
                as ProofInsufficient)
            .missing,
        ['signature'],
      );
    });

    test('what each grade insists on is readable without a proof', () {
      // The policy is a value with no dependencies, which is what makes the
      // rule reviewable as a table by somebody who does not read Dart.
      expect(
        const ProofPolicy.forGrade(DeliveryGrade.standard).insistsOn,
        isEmpty,
      );
      expect(const ProofPolicy.forGrade(DeliveryGrade.highValue).insistsOn, {
        EvidenceKind.signature,
        EvidenceKind.photo,
      });
    });
  });
}
