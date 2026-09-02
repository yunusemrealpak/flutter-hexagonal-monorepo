import 'package:delivery_api/delivery_api.dart';

/// What the proof screen can be showing.
///
/// Sealed and hand-written, in a package with no code generation at all. Five
/// cases rather than one class with `isLoading`, `attempt` and `failure` on
/// it: the flat shape lets a widget be handed a state that is arriving *and*
/// settled, and the day two of those are set at once nobody can say what
/// should be on screen.
sealed class ProofCaptureState {
  const ProofCaptureState();
}

/// The courier is on their way; nothing has been asked for yet.
final class AwaitingArrival extends ProofCaptureState {
  /// Creates the state.
  const AwaitingArrival();
}

/// The geofence is being asked whether they are there.
final class Arriving extends ProofCaptureState {
  /// Creates the state.
  const Arriving();
}

/// The attempt is open and evidence is being collected.
final class AtTheDoor extends ProofCaptureState {
  /// Creates the state.
  const AtTheDoor(
    this.attempt, {
    this.recipientName = '',
    this.signature,
    this.photo,
    this.scan,
    this.refusal,
    this.notice,
  });

  /// The open attempt.
  final DeliveryAttempt attempt;

  /// What the person at the door gave as their name.
  final String recipientName;

  /// The signature, once one is taken.
  final SignatureCapture? signature;

  /// The photograph, once one is taken.
  final PhotoEvidence? photo;

  /// The scan, once one is made.
  final ScanEvidence? scan;

  /// A completion the domain refused, or `null`.
  ///
  /// Carried beside the attempt rather than replacing it. The attempt is still
  /// open and still correct — the domain declined to close it — so dropping to
  /// a failure state would send a courier back to the start of a hand-over
  /// they are halfway through.
  final DeliveryFailure? refusal;

  /// What the last capture came back with instead of evidence, or `null`.
  ///
  /// Beside the attempt for the same reason [refusal] is: a camera that would
  /// not open has not invalidated a signature already on the glass. It is a
  /// `CaptureRefusal` rather than a sentence because one of its cases carries
  /// an affordance — a blocked permission is drawn with the settings action
  /// beside it — and a screen handed a string could not know which.
  ///
  /// [CaptureDeclined] never reaches here. A courier who changed their mind is
  /// behaving normally, and the notice is what draws a chip.
  final CaptureRefusal? notice;

  /// Which kinds of evidence have been captured so far.
  Set<EvidenceKind> get carries => {
    if (signature != null) EvidenceKind.signature,
    if (photo != null) EvidenceKind.photo,
    if (scan != null) EvidenceKind.scan,
  };

  /// What this parcel's grade still insists on.
  ///
  /// Read from `ProofPolicy`, which lives in `delivery_api`. The screen shows
  /// the rule rather than owning it: a second copy here would tell a courier
  /// they were finished on the day the policy changed and the use case
  /// disagreed.
  Set<EvidenceKind> get missing =>
      ProofPolicy.forGrade(attempt.grade).insistsOn.difference(carries);

  /// Whether there is enough here to try.
  ///
  /// The floor of at least one piece applies to every grade, which is why it
  /// is checked beside [missing] rather than folded into it.
  bool get isComplete => missing.isEmpty && carries.isNotEmpty;

  /// Returns a copy with the given fields replaced.
  AtTheDoor copyWith({
    String? recipientName,
    SignatureCapture? signature,
    PhotoEvidence? photo,
    ScanEvidence? scan,
    DeliveryFailure? refusal,
    CaptureRefusal? notice,
  }) => AtTheDoor(
    attempt,
    recipientName: recipientName ?? this.recipientName,
    signature: signature ?? this.signature,
    photo: photo ?? this.photo,
    scan: scan ?? this.scan,
    refusal: refusal,
    notice: notice,
  );
}

/// The visit is recorded, one way or the other.
final class Settled extends ProofCaptureState {
  /// Creates the state.
  const Settled(this.attempt);

  /// What was recorded.
  final DeliveryAttempt attempt;
}

/// The visit could not be opened or recorded.
final class CaptureFailed extends ProofCaptureState {
  /// Creates the state.
  const CaptureFailed(this.failure);

  /// What went wrong, in delivery's own words.
  ///
  /// A `DeliveryFailure`, not a `String`. Turning it into a message is this
  /// layer's job and it happens at the widget, where the locale is known.
  final DeliveryFailure failure;
}
