/// Fakes, fixtures and the contract kits for payments.
///
/// **The kit that matters is `runPaymentsGatewayContract`**, and the three
/// assertions at the top of it are the specification's "idempotency
/// (critical)". A courier taps *collect*, the request times out, the phone
/// retries — and the far side has to recognise the second copy as the same
/// intention and answer with the first one's result. The retry carries a
/// different instant, so an implementation that recorded again is visible in
/// the answer.
///
/// It also asserts the half people forget: *two* intentions are two movements.
/// A gateway that deduplicated on the shipment rather than the key would pass
/// the first three tests and refuse a customer who legitimately pays twice for
/// one parcel, after a return.
///
/// **Fakes.** `FakePaymentsGateway` really takes money once and is the adapter
/// `app_harness` binds. `InMemorySettlementStore` is also a product adapter —
/// `app_dispatcher` binds it. `FakeCashDrawer` refuses to release more than it
/// holds, through `Money.minus`, so a caller giving back money it never took
/// fails here rather than at a hand-in. `FakeReceiptPrinter` exists mostly for
/// its failing path: a receipt that would not print must never undo a
/// collection.
///
/// **`FakePaymentStatusReader` is what `shipments_application` uses**, and its
/// size is the demonstration of scenario 1. A shipments test that had to build
/// a `PaymentAttempt`, a drawer and a settlement in order to ask "is anything
/// owed" would mean the port was too wide.
///
/// `test` is a runtime dependency of this package rather than a dev one,
/// because a contract kit *is* tests — it calls `group` and `test` from
/// `lib/`.
library;

export 'src/fake_cash_drawer.dart';
export 'src/fake_payment_status_reader.dart';
export 'src/fake_payments_gateway.dart';
export 'src/fake_receipt_printer.dart';
export 'src/in_memory_settlement_store.dart';
export 'src/payments_fixtures.dart';
export 'src/payments_gateway_contract.dart';
export 'src/settlement_store_contract.dart';
