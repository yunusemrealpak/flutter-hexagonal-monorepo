/// The scheduling contract, its WorkManager adapter, and its fake.
///
/// `BackgroundScheduler` is a technology contract and lives here for the same
/// reason `LocationSource` lives in `location_service`: nothing in the product
/// asks for "a periodic task". `sync` asks for its outbox to be drained, and
/// *when a device is willing to wake up* is a question only WorkManager and
/// BGTaskScheduler can answer.
///
/// **Everything here schedules; nothing here runs.** The operating system
/// starts a second isolate long after these calls returned, with a fresh Dart
/// heap and no container in it, so what is scheduled is a *name* rather than a
/// function. Registering the entry point that name arrives at belongs to an
/// app, and so does deciding what the name means. The README says what that
/// costs and which half of it this repository can exercise.
library;

export 'src/background_scheduler.dart';
export 'src/fake_background_scheduler.dart';
export 'src/scheduling_failure.dart';
export 'src/task_constraints.dart';
export 'src/work_manager_scheduler.dart';
