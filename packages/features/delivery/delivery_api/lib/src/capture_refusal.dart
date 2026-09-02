import 'package:core_kernel/core_kernel.dart';

import 'delivery_failure.dart';

/// Why an app came back from a capture with no evidence.
///
/// **The failure side of what a capture callback answers.** A proof screen may
/// not depend on `platform/*`, so it is handed a
/// `Future<Result<PhotoEvidence, CaptureRefusal>> Function()` and the app
/// supplies whatever it captures with. Before this type existed the callback
/// answered `PhotoEvidence?`, and a camera switched off in the system settings
/// was indistinguishable from a courier who changed their mind — so the one
/// case with a way out of it was the one nothing could offer a way out of.
///
/// **Four cases, because a courier does four different things.** Nothing at
/// all for [CaptureDeclined]; press the button again for [CaptureNotAllowed],
/// which shows the prompt again; open the settings page for
/// [CaptureBlockedInSettings], which is the only thing that changes it; read a
/// sentence for [EvidenceUnusable]. Collapsing any two of them produces a
/// screen that tells a courier to do something that will not help — the same
/// argument `LocationFailure` makes for its five.
///
/// **It sits on the failure side of a `Result` while [CaptureDeclined] is not
/// a failure**, which is the tension `media_capture`'s `CaptureCancelled`
/// documents one layer down and for the same reason: the method has to answer
/// something and there is no evidence. This case exists precisely so a caller
/// can tell *nothing happened* from *something broke*, and a screen that put a
/// red banner in front of somebody who changed their mind would be wrong.
sealed class CaptureRefusal extends Failure {
  /// Const so that a refusal can be built in a const context.
  const CaptureRefusal();
}

/// The courier opened the capture and backed out of it.
///
/// Not an error, and never something to report. Shown as nothing at all.
final class CaptureDeclined extends CaptureRefusal {
  /// Records that the courier dismissed the capture.
  const CaptureDeclined();

  @override
  String toString() => 'CaptureDeclined()';
}

/// The device refused the capability, and can still be asked for it.
///
/// The button stays where it is: pressing it again shows the prompt again.
final class CaptureNotAllowed extends CaptureRefusal {
  /// Records that the device refused, with asking still possible.
  const CaptureNotAllowed();

  @override
  String toString() => 'CaptureNotAllowed()';
}

/// The device refuses the capability in a way only its settings page can
/// change.
///
/// The one case the whole type exists for. An app that cannot tell this from
/// [CaptureNotAllowed] offers a button that shows no prompt and does nothing.
final class CaptureBlockedInSettings extends CaptureRefusal {
  /// Records that the capability cannot be requested again from inside the
  /// app.
  const CaptureBlockedInSettings();

  @override
  String toString() => 'CaptureBlockedInSettings()';
}

/// Something was captured and it cannot be used as proof.
///
/// Carries delivery's own failure, so the screen renders it through the same
/// `describe` it already exhausts for everything else: a photograph over the
/// size budget is `MediaTooLarge`, an empty one is `MalformedDeliveryValue`,
/// and a platform that broke is `DeliveryUnavailable` with a detail for the
/// log.
final class EvidenceUnusable extends CaptureRefusal {
  /// Records that the capture produced something unusable.
  const EvidenceUnusable(this.failure);

  /// What was wrong with it, in delivery's own words.
  final DeliveryFailure failure;

  @override
  String toString() => 'EvidenceUnusable($failure)';
}
