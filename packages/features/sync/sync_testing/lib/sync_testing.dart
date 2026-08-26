/// Fakes, a builder and contract kits for sync.
///
/// **Fakes.** `InMemoryOutboxStore`, `FakeCommandTransport`, `FakeClockSkew`.
/// Behavioural rather than scripted: the store really orders and really
/// remembers a cursor, and the transport really de-duplicates by envelope
/// identifier — which is what lets a test assert that a retried entry produced
/// one piece of work rather than two.
///
/// Two of them are also *product* adapters. Scenario 5's table binds
/// `InMemoryOutboxStore` in `app_dispatcher`, where the operator is at a desk
/// and durability across a crash buys nothing, and `FakeCommandTransport` in
/// `app_harness`. That is why they live here instead of being written twice,
/// and why the contract kits below are what keep both uses honest.
///
/// **A builder.** `OutboxEntryBuilder` reaches a state by calling the entity's
/// own methods, so a fixture can never be an entry the queue could not have
/// produced — three attempts with no `nextAttemptAt` is a shape no drain
/// creates, and a test asserting against one is asserting about a situation
/// that never happens.
///
/// **A command from no feature.** `TestSyncCommand` is what these tests queue.
/// Reaching for a real one would mean importing `delivery_application`, which
/// `sync_testing` may not do and would not want to — and the fact that a queue
/// test never needs a real command is the demonstration, not a limitation of
/// the fixture.
///
/// **`FakeSyncFacade`** is the queue every feature that writes offline talks
/// to in its own tests. It lives here rather than in each feature, for the
/// reason a fake always belongs beside its contract: `delivery_application`
/// and `payments_application` both enqueue, and two hand-written stubs would
/// drift apart the first time `SyncFacade` grew a method. It records a routing
/// key and a string, never decodes a payload, and does not drain on enqueue —
/// the same three constraints the real queue lives under.
///
/// **Contract kits.** `runOutboxStoreContract` and
/// `runCommandTransportContract`, one suite each, run against every
/// implementation of the port.
///
/// `test` is a runtime dependency of this package rather than a dev
/// dependency, because a contract kit *is* tests — it calls `group` and `test`
/// from `lib/`.
library;

export 'src/command_transport_contract.dart';
export 'src/fake_clock_skew.dart';
export 'src/fake_command_transport.dart';
export 'src/fake_sync_facade.dart';
export 'src/in_memory_outbox_store.dart';
export 'src/outbox_entry_builder.dart';
export 'src/outbox_store_contract.dart';
export 'src/test_sync_command.dart';
