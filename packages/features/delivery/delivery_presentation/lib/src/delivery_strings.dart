import 'package:delivery_api/delivery_api.dart';

/// Every string key this package asks an app to answer.
///
/// The evidence-kind keys are derived from the enum they label, so a new
/// `EvidenceKind` adds a key to [all] and an app's coverage test fails until
/// somebody writes the sentence. A courier told "this parcel needs
/// evidenceKind.fingerprint" is a courier who has been shown a bug.
abstract final class DeliveryStrings {
  /// The screen's title.
  static const String title = 'delivery.title';

  /// The parcel being delivered. Takes a `shipment` argument.
  static const String delivering = 'delivery.delivering';

  /// What the field for the recipient's name is called.
  static const String recipientLabel = 'delivery.recipient.label';

  /// The placeholder in that field.
  static const String recipientHint = 'delivery.recipient.hint';

  /// What is still needed before this visit can be completed.
  ///
  /// Takes a `kinds` argument: the already-resolved names, joined by the app.
  static const String stillNeeded = 'delivery.stillNeeded';

  /// Something that has been captured. Takes a `kind` argument.
  static const String captured = 'delivery.captured';

  /// The action that opens the signature capture.
  static const String addSignature = 'delivery.addSignature';

  /// The action that opens the camera.
  static const String addPhoto = 'delivery.addPhoto';

  /// The action that records a successful delivery.
  static const String delivered = 'delivery.delivered';

  /// The action that records a visit that ended without a hand-over.
  static const String couldNotDeliver = 'delivery.couldNotDeliver';

  /// Shown once the visit has been recorded.
  static const String recorded = 'delivery.recorded';

  /// The courier is not close enough. Takes a `metres` argument.
  static const String failureOutsideArea = 'delivery.failure.outsideArea';

  /// There is no position fix.
  static const String failurePositionUnavailable =
      'delivery.failure.positionUnavailable';

  /// The device will not report its position and only its settings can change
  /// that.
  static const String failurePositionBlocked =
      'delivery.failure.positionBlocked';

  /// The action that opens this app's page in the device settings.
  ///
  /// A product sentence rather than a system one, which is why it is here
  /// instead of in `design_system` beside *try again*: every feature that
  /// sends somebody to the settings page says why in its own words.
  static const String openSettings = 'delivery.openSettings';

  /// The capture was refused, and can be asked for again.
  static const String captureNotAllowed = 'delivery.capture.notAllowed';

  /// The capture is blocked in the device settings.
  static const String captureBlocked = 'delivery.capture.blocked';

  /// The proof gathered is not enough. Takes a `kinds` argument.
  static const String failureProofInsufficient =
      'delivery.failure.proofInsufficient';

  /// This visit has already been recorded.
  static const String failureAlreadySettled = 'delivery.failure.alreadySettled';

  /// The evidence could not be saved.
  static const String failureProofStoreUnavailable =
      'delivery.failure.proofStoreUnavailable';

  /// The evidence is not on this device.
  static const String failureProofNotFound = 'delivery.failure.proofNotFound';

  /// The photograph is too large.
  static const String failureMediaTooLarge = 'delivery.failure.mediaTooLarge';

  /// The visit could not be queued.
  static const String failureUnavailable = 'delivery.failure.unavailable';

  /// A stored value could not be read. Takes a `field` argument.
  static const String failureMalformed = 'delivery.failure.malformed';

  /// The key for one kind of evidence.
  static String evidenceKind(EvidenceKind kind) =>
      'delivery.evidenceKind.${kind.name}';

  /// The key for one kind of evidence, named by the string a failure carries.
  ///
  /// `ProofInsufficient.missing` is a list of `EvidenceKind.name` strings —
  /// the failure crosses the port as data, so it cannot carry the enum. This
  /// rebuilds the key from the name rather than matching on it, which keeps
  /// the two spellings in one place.
  static String evidenceKindNamed(String name) => 'delivery.evidenceKind.$name';

  /// Every key above, for an app's coverage test.
  static final List<String> all = [
    title,
    delivering,
    recipientLabel,
    recipientHint,
    stillNeeded,
    captured,
    addSignature,
    addPhoto,
    delivered,
    couldNotDeliver,
    recorded,
    openSettings,
    captureNotAllowed,
    captureBlocked,
    failureOutsideArea,
    failurePositionUnavailable,
    failurePositionBlocked,
    failureProofInsufficient,
    failureAlreadySettled,
    failureProofStoreUnavailable,
    failureProofNotFound,
    failureMediaTooLarge,
    failureUnavailable,
    failureMalformed,
    for (final kind in EvidenceKind.values) evidenceKind(kind),
  ];
}
