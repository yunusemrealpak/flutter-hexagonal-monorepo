@Tags(['widget'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_presentation/delivery_presentation.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:shipments_api/shipments_api.dart';

/// A `PermissionChecker` a test can set, standing in for identity.
///
/// Four lines, and it is the entire coupling between this package and
/// identity's decision-making. That is what scenario 6 is for: the screen asks
/// a question and gets a bool, and everything identity actually does to arrive
/// at the answer is invisible here — including in the test, which is the
/// proof.
final class _Permissions implements PermissionChecker {
  _Permissions(this._granted);

  final Set<Permission> _granted;

  @override
  bool can(Permission permission) => _granted.contains(permission);
}

/// A `SessionReader` over one fixed session, or none.
final class _Session implements SessionReader {
  _Session(this.current);

  @override
  final Session? current;

  @override
  Stream<Session?> changes() => Stream.value(current);
}

/// A `DeliveryFacade` this test steers.
///
/// A stand-in rather than the real coordinator, and it has to be: this package
/// may not depend on `delivery_application`. What it can name is the port,
/// which is exactly the point.
final class _Facade implements DeliveryFacade {
  Result<DeliveryAttempt, DeliveryFailure>? startAnswer;
  Result<DeliveryAttempt, DeliveryFailure>? completeAnswer;

  /// The proofs `completeWithProof` was handed, in order.
  final List<ProofOfDelivery> proofs = [];

  /// The reasons `failWithReason` was handed, in order.
  final List<NonDeliveryReason> reasons = [];

  /// The grades `startAttempt` was asked for, in order.
  final List<DeliveryGrade> grades = [];

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> startAttempt({
    required ShipmentId shipment,
    required ActorId courier,
    DeliveryGrade grade = DeliveryGrade.standard,
  }) async {
    grades.add(grade);
    return startAnswer ?? Success(DeliveryFixtures.attempt(grade: grade));
  }

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> completeWithProof({
    required DeliveryAttempt attempt,
    required ProofOfDelivery proof,
  }) async {
    proofs.add(proof);
    return completeAnswer ?? Success(DeliveryFixtures.completed());
  }

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> failWithReason({
    required DeliveryAttempt attempt,
    required NonDeliveryReason reason,
  }) async {
    reasons.add(reason);
    return Success(DeliveryFixtures.failed(reason: reason));
  }

  /// Every other method of the port, which this test does not use.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProofCaptureController _controller(
  _Facade facade, {
  Set<Permission> granted = const {Permission.completeDelivery},
  bool signedIn = true,
}) => ProofCaptureController(
  delivery: facade,
  session: _Session(
    signedIn ? SessionBuilder().actor('courier-1').build() : null,
  ),
  permissions: _Permissions(granted),
);

void main() {
  late _Facade facade;
  late ProofCaptureController controller;

  setUp(() {
    facade = _Facade();
    controller = _controller(facade);
    addTearDown(controller.dispose);
  });

  Future<void> arrive({DeliveryGrade grade = DeliveryGrade.standard}) =>
      controller.arrive(shipment: DeliveryFixtures.shipment(), grade: grade);

  group('ProofCaptureController', () {
    test('starts before the door', () {
      expect(controller.state, isA<AwaitingArrival>());
    });

    test('opens an attempt and waits at the door', () async {
      await arrive();

      expect(controller.state, isA<AtTheDoor>());
    });

    test('asks for nothing when nobody is signed in', () async {
      final anonymous = _controller(facade, signedIn: false);
      addTearDown(anonymous.dispose);

      await anonymous.arrive(shipment: DeliveryFixtures.shipment());

      expect(anonymous.state, isA<AwaitingArrival>());
      expect(facade.grades, isEmpty);
    });

    test('reports a courier who is not at the address', () async {
      facade.startAnswer = const Failed(
        OutsideDeliveryArea(metresAway: 450, allowedMetres: 100),
      );

      await arrive();

      expect(controller.state, isA<CaptureFailed>());
    });

    test('reads the policy rather than restating it', () async {
      // A second copy of the rule here would tell a courier they were finished
      // on the day the policy changed and the use case disagreed.
      await arrive(grade: DeliveryGrade.highValue);
      final atTheDoor = controller.state as AtTheDoor;

      expect(atTheDoor.missing, {EvidenceKind.signature, EvidenceKind.photo});
      expect(atTheDoor.isComplete, isFalse);
    });

    test('a standard parcel is complete on one piece of evidence', () async {
      await arrive();
      controller.addPhoto(DeliveryFixtures.photo());

      expect((controller.state as AtTheDoor).isComplete, isTrue);
    });

    test('builds the proof from the evidence, with no clock', () async {
      // Section 2 does not allow this package core_ports, so the instant comes
      // from the evidence through ProofOfDelivery.from.
      await arrive();
      controller
        ..recipientIs('A. Yilmaz')
        ..addSignature(DeliveryFixtures.signature());

      await controller.complete();

      expect(facade.proofs.single.capturedAt, DeliveryFixtures.noon);
      expect(facade.proofs.single.recipient.name, 'A. Yilmaz');
    });

    test('refuses to record a hand-over without the grant', () async {
      // Scenario 6 where it bites. The use case does not check permissions —
      // identity is not one of its collaborators — so this is the last thing
      // between an actor without the grant and a recorded delivery.
      final ungranted = _controller(facade, granted: const {});
      addTearDown(ungranted.dispose);
      await ungranted.arrive(shipment: DeliveryFixtures.shipment());
      ungranted
        ..recipientIs('A. Yilmaz')
        ..addSignature(DeliveryFixtures.signature());

      await ungranted.complete();

      expect(ungranted.canComplete, isFalse);
      expect(facade.proofs, isEmpty);
    });

    test('reads the permission every time rather than caching it', () async {
      // A grant can be revoked mid-shift, and a screen answering from a value
      // it captured when it opened would keep offering an action the operation
      // has taken away.
      expect(controller.canComplete, isTrue);
      expect(_controller(facade, granted: const {}).canComplete, isFalse);
    });

    test('a hand-over with nobody s name is refused before the port', () async {
      await arrive();
      controller.addSignature(DeliveryFixtures.signature());

      await controller.complete();

      expect((controller.state as AtTheDoor).refusal, isNotNull);
      expect(facade.proofs, isEmpty);
    });

    test('a refused completion keeps the courier at the door', () async {
      // The attempt is still open and still correct. Dropping to a failure
      // state would send a courier back to the start of a hand-over they are
      // halfway through.
      facade.completeAnswer = const Failed(ProofStoreUnavailable());
      await arrive();
      controller
        ..recipientIs('A. Yilmaz')
        ..addSignature(DeliveryFixtures.signature());

      await controller.complete();

      final state = controller.state as AtTheDoor;
      expect(state.refusal, isA<ProofStoreUnavailable>());
      expect(state.signature, isNotNull);
    });

    test('recording a failed visit needs no permission', () async {
      // Every courier standing at a door may say what happened. Gating it
      // would leave the visit unrecorded rather than leaving it undone.
      final ungranted = _controller(facade, granted: const {});
      addTearDown(ungranted.dispose);
      await ungranted.arrive(shipment: DeliveryFixtures.shipment());

      await ungranted.couldNotDeliver(
        const NonDeliveryReason.recipientAbsent(),
      );

      expect(ungranted.state, isA<Settled>());
      expect(facade.reasons.single, isA<RecipientAbsent>());
    });
  });

  group('ProofCaptureScreen', () {
    Widget screen({
      Set<Permission> granted = const {Permission.completeDelivery},
      DeliveryGrade grade = DeliveryGrade.standard,
      Future<PhotoEvidence?> Function()? onCapturePhoto,
    }) {
      final built = _controller(facade, granted: granted);
      addTearDown(built.dispose);
      return Directionality(
        textDirection: TextDirection.ltr,
        child: ProofCaptureScreen(
          controller: built,
          shipment: DeliveryFixtures.shipment(),
          grade: grade,
          onCapturePhoto: onCapturePhoto,
        ),
      );
    }

    testWidgets('says what the grade still insists on', (tester) async {
      await tester.pumpWidget(screen(grade: DeliveryGrade.highValue));
      await tester.pump();

      expect(find.textContaining('Still needed'), findsOneWidget);
    });

    testWidgets('hides the delivered action without the grant', (tester) async {
      await tester.pumpWidget(screen(granted: const {}));
      await tester.pump();

      expect(find.text('Delivered'), findsNothing);
      expect(find.text('Could not deliver'), findsOneWidget);
    });

    testWidgets('offers no camera when the app supplied none', (tester) async {
      // A presentation package may not depend on platform/*, so capture
      // arrives as a callback. An app with no camera passes nothing and the
      // button is not drawn.
      await tester.pumpWidget(screen());
      await tester.pump();

      expect(find.text('Add photo'), findsNothing);
    });

    testWidgets('takes the evidence the app captured', (tester) async {
      await tester.pumpWidget(
        screen(onCapturePhoto: () async => DeliveryFixtures.photo()),
      );
      await tester.pump();

      await tester.tap(find.text('Add photo'));
      await tester.pump();

      expect(find.text('Captured: photo'), findsOneWidget);
    });

    test('says something different for every failure', () {
      // Nine cases, nine sentences — the reason DeliveryFailure is sealed.
      // "You are 450m from the address" and "the evidence could not be saved"
      // send a courier to different places.
      final sentences = <DeliveryFailure>[
        const OutsideDeliveryArea(metresAway: 450, allowedMetres: 100),
        const DeliveryPositionUnavailable(),
        const ProofInsufficient(grade: 'highValue', missing: ['photo']),
        const AttemptAlreadySettled('attempt-1'),
        const ProofStoreUnavailable(),
        const ProofNotFound('proof-1'),
        const MediaTooLarge(bytes: 10, limit: 2),
        const DeliveryUnavailable(),
        const MalformedDeliveryValue(field: 'recipient', reason: 'is empty'),
      ].map(ProofCaptureScreen.describe).toList();

      expect(sentences.toSet(), hasLength(9));
    });
  });

  group('DeliveryRoutes', () {
    test('guards the proof screen behind the same permission', () {
      // The route guard and the button guard are both scenario 6 and they are
      // not the same check: one keeps the wrong person off the screen, the
      // other keeps them from recording a hand-over once they are on it.
      const module = DeliveryRoutes();

      expect(module.moduleName, 'delivery');
      expect(module.routes.single.requiredPermission, 'completeDelivery');
    });
  });
}
