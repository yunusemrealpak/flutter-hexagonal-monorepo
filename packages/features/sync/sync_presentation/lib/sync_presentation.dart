/// The sync UI: a queue badge, and the screen a depot opens when it says
/// something needs a person.
///
/// The interesting constraint here is what the review screen *cannot* do. It
/// shows a routing key, a reason and an attempt count — and never the payload,
/// because this package depends on `sync_api`, which cannot decode one.
/// Rendering "the delivery for shipment SHP-9" would mean reaching into
/// `delivery_api`, and at that point sync would have learned a feature's name.
///
/// That turns out to be the honest shape anyway: the person resolving a stuck
/// queue needs to know what stopped and why, and the app that composed the
/// feature is the only thing entitled to turn a routing key into a link to the
/// feature that owns it.
///
/// This package holds no adapter and no use case. It depends on contracts
/// only, so what actually answers `SyncFacade` is decided by whichever app
/// composed it: the real coordinator in `app_courier`, a fake in
/// `app_harness`.
library;

export 'src/review_queue_controller.dart';
export 'src/review_queue_screen.dart';
export 'src/review_queue_state.dart';
export 'src/sync_routes.dart';
export 'src/sync_status_badge.dart';
