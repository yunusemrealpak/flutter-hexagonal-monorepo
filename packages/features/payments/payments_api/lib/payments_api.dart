/// The payments contract: money, what is owed on a parcel, and the key that
/// stops a retry becoming a second charge.
///
/// **`IdempotencyKey` is the type this package is built around**, and the
/// design decision worth reading is that `PaymentAttempt` uses it as its
/// *identifier*. Two attempts with the same key are the same attempt — that is
/// what `Entity` equality already means — so a double charge is not a bug to
/// guard against but a state the type system cannot express. An attempt with
/// an identity of its own beside the key would have made "two attempts, one
/// key" and "one attempt, two keys" both constructible, and one of those is
/// somebody's money.
///
/// **Money is minor units in an `int`.** 0.1 + 0.2 is not 0.3 in binary
/// floating point, and a settlement that adds four hundred cash collections in
/// doubles is off by an amount somebody has to explain. Arithmetic across
/// currencies returns a failure rather than a plausible number.
///
/// **`PaymentStatusReader` is payments' half of scenario 1.**
/// `shipments_application` consults it before letting a delivery close against
/// an outstanding cash collection, while `payments_application` consults
/// `shipments_api` for its own reasons. Neither `_application` package sees
/// the other: each depends on the other feature's contract, and a contract
/// package depends on no implementation, so the graph stays acyclic.
///
/// It is narrow on purpose — one question, one answer — like `SessionReader`
/// beside `IdentityFacade`. Handing `shipments` the whole facade would hand it
/// the ability to take money.
///
/// **What crosses to another feature, and what does not.** This package names
/// `ActorId` and `ShipmentId`, and nothing else of theirs. Section 2.1 of
/// docs/DEPENDENCY_RULES.md: an identifier crosses, a model does not. Payments
/// never learns what is in a parcel or where it is going, only that money is
/// owed against one. `ShipmentReference` and `CourierReference` are the other
/// half — readers that report a bad foreign identifier as a *payments*
/// failure, so `payments_infrastructure` can rebuild the identifiers this
/// contract is expressed in without depending on a foreign `_api`.
///
/// **The driving ports.** `PaymentsFacade` and `PaymentStatusReader`,
/// implemented by `payments_application`.
///
/// **The driven ports.** `PaymentsGateway`, `CashDrawerPort`,
/// `ReceiptPrinterPort`, `SettlementStore`, answered by
/// `payments_infrastructure`.
library;

export 'src/cash_drawer_port.dart';
export 'src/collection_request.dart';
export 'src/courier_reference.dart';
export 'src/currency.dart';
export 'src/idempotency_key.dart';
export 'src/money.dart';
export 'src/payment_attempt.dart';
export 'src/payment_method.dart';
export 'src/payment_outcome.dart';
export 'src/payment_status.dart';
export 'src/payment_status_reader.dart';
export 'src/payments_facade.dart';
export 'src/payments_failure.dart';
export 'src/payments_gateway.dart';
export 'src/receipt_printer_port.dart';
export 'src/settlement.dart';
export 'src/settlement_id.dart';
export 'src/settlement_store.dart';
export 'src/shipment_reference.dart';
