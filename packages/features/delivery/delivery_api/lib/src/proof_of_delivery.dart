import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import 'delivery_failure.dart';
import 'evidence_kind.dart';
import 'photo_evidence.dart';
import 'recipient.dart';
import 'scan_evidence.dart';
import 'signature_capture.dart';

/// Everything a courier came back with from one hand-over.
///
/// Three optional pieces of evidence and one required recipient. Which
/// combination is *enough* is not decided here — that is `ProofPolicy`, and
/// the separation is the point: what was captured is a fact about the visit,
/// what is sufficient is a rule about the parcel, and an operation changes the
/// second far more often than the first.
///
/// The recipient is required even when every piece of evidence is absent,
/// because a proof with nobody's name on it is not a proof. The policy will
/// refuse such a thing anyway; requiring the name here means the refusal can
/// say *which evidence* is missing instead of "everything".
@immutable
final class ProofOfDelivery {
  const ProofOfDelivery._({
    required this.recipient,
    required this.capturedAt,
    this.signature,
    this.photo,
    this.scan,
  });

  /// Assembles a proof from whatever the courier captured.
  ///
  /// It cannot fail: every argument is already a validated value, and whether
  /// the combination is acceptable is `ProofPolicy`'s question rather than
  /// this constructor's. A `Result` here would put an unreachable failure
  /// branch at every call site, which CLAUDE.md section 3 rules out.
  factory ProofOfDelivery.captured({
    required Recipient recipient,
    required DateTime capturedAt,
    SignatureCapture? signature,
    PhotoEvidence? photo,
    ScanEvidence? scan,
  }) => ProofOfDelivery._(
    recipient: recipient,
    capturedAt: capturedAt.toUtc(),
    signature: signature,
    photo: photo,
    scan: scan,
  );

  /// Assembles a proof and takes its instant from the evidence itself.
  ///
  /// **For callers that have no clock.** A presentation package may depend on
  /// `core_kernel`, `core_navigation` and contracts, and on nothing else —
  /// section 2 — so it cannot hold a `Clock`, and rule A1 forbids it reaching
  /// for `DateTime.now()`. Without this it would have to be handed a time
  /// source that is a `Clock` under another name.
  ///
  /// Deriving the instant is also the more honest answer. A hand-over happened
  /// when the courier captured the evidence, not when they got round to
  /// pressing a button; the two differ by however long the recipient spent
  /// looking for a pen.
  ///
  /// The latest of the pieces rather than the earliest: the proof is complete
  /// at the moment the last of it was taken.
  ///
  /// Fails when there is nothing to take an instant from. That is the same
  /// case `ProofPolicy` refuses at every grade, caught here one step earlier
  /// because there is genuinely nothing to build.
  static Result<ProofOfDelivery, DeliveryFailure> from({
    required Recipient recipient,
    SignatureCapture? signature,
    PhotoEvidence? photo,
    ScanEvidence? scan,
  }) {
    final instants = [
      if (signature != null) signature.capturedAt,
      if (photo != null) photo.capturedAt,
      if (scan != null) scan.scannedAt,
    ]..sort();

    if (instants.isEmpty) {
      return const Failed(
        ProofInsufficient(grade: 'any', missing: ['any evidence']),
      );
    }

    return Success(
      ProofOfDelivery._(
        recipient: recipient,
        capturedAt: instants.last,
        signature: signature,
        photo: photo,
        scan: scan,
      ),
    );
  }

  /// Who took it.
  final Recipient recipient;

  /// When the hand-over was recorded, in UTC.
  final DateTime capturedAt;

  /// The signature, if one was taken.
  final SignatureCapture? signature;

  /// The photograph, if one was taken.
  final PhotoEvidence? photo;

  /// The scan, if one was made.
  final ScanEvidence? scan;

  /// Which kinds of evidence this proof actually carries.
  ///
  /// The one thing `ProofPolicy` reads. Exposing the set rather than three
  /// nullable getters means a new kind of evidence is a change in two files
  /// instead of in every rule that inspects a proof.
  Set<EvidenceKind> get carries => {
    if (signature != null) EvidenceKind.signature,
    if (photo != null) EvidenceKind.photo,
    if (scan != null) EvidenceKind.scan,
  };

  /// Returns a copy with [photo] replaced.
  ///
  /// Narrow on purpose. The only thing that legitimately rewrites a captured
  /// proof is compression — the same photograph, fewer bytes — and a general
  /// `copyWith` would let a use case quietly swap a signature for another one
  /// after the fact.
  ProofOfDelivery withPhoto(PhotoEvidence replacement) => ProofOfDelivery._(
    recipient: recipient,
    capturedAt: capturedAt,
    signature: signature,
    photo: replacement,
    scan: scan,
  );

  @override
  String toString() =>
      'ProofOfDelivery(${recipient.name}, '
      '${carries.map((kind) => kind.name).join('+')})';
}
