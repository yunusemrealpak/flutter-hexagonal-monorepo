/// Fakes, fixtures and the contract kit for messaging.
///
/// **Why this feature has a `_testing` package and the other six do not.**
/// Section 7 of CLAUDE.md says to create one only when another package
/// consumes its fakes, and `runMessageStoreContract` is consumed by
/// `messaging_core`: the same kit runs against `InMemoryMessageStore` here and
/// against `KeyValueMessageStore` there, so the fake and the real adapter
/// cannot drift. `settings`, `notifications`, `incidents`, `vehicle_inventory`,
/// `documents` and `reporting` keep their stand-ins in their own test folders,
/// because nothing outside those features consumes them.
///
/// Fakes, not mocks. `InMemoryMessageStore` really stores and really orders;
/// `FakeMessagingFacade` really keeps threads and really leaves a message
/// queued when it is told the device is offline. A test written against them
/// exercises the caller's logic rather than a script of expected calls.
library;

export 'src/fake_message_transport.dart';
export 'src/fake_messaging_facade.dart';
export 'src/in_memory_message_store.dart';
export 'src/message_store_contract.dart';
export 'src/messaging_fixtures.dart';
