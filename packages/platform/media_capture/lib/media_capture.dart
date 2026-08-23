/// The photo-evidence contract, its image_picker adapter, and its fake.
///
/// One method, `capturePhoto`, and the narrowness is the design. Every extra
/// capture mode — video, gallery selection, multiple images — carries its own
/// permission, size and compression story, and the product needs exactly one
/// of them today. A contract offering five would be five things to fake, five
/// to test, and four that nothing calls.
///
/// `CapturedMedia` carries a path rather than bytes. Proof-of-delivery photos
/// are megabytes each, a courier takes dozens in a shift, and holding them in
/// memory while an outbox drains is how an offline-first app gets killed by
/// the operating system.
///
/// The case worth noticing in `CaptureFailure` is `CaptureCancelled`. It is a
/// failure only in the sense that there is no media to return: a courier who
/// opens the camera and changes their mind is behaving normally, and an
/// interface that shows them a red banner for it is wrong. It exists so that a
/// caller can tell "nothing happened" from "something broke" — the kind of
/// distinction a `sealed` failure type is for.
library;

export 'src/capture_failure.dart';
export 'src/captured_media.dart';
export 'src/fake_media_capture.dart';
export 'src/image_picker_media_capture.dart';
export 'src/media_capture.dart';
