/// The payments adapters: the gateway, the device copy that makes it work in a
/// tunnel, the day's store, the drawer, and the mappers between them.
///
/// **`DeviceBackedPaymentsGateway` is the piece that makes offline idempotency
/// real.** `CollectOnDelivery` asks `attemptFor` before it mints a key, so
/// that two taps on one intention produce one key. Against a bare
/// `RestPaymentsGateway` that check is worthless in a tunnel — the read fails,
/// the use case mints again, and the courier's second tap queues a second
/// collection. With this decorator in front, the read is answered from what
/// *this device* recorded, and the second tap finds the first.
///
/// It is a decorator rather than a base class, so it composes with whatever
/// answers the remote side: `app_harness` puts a fake behind it and gets the
/// same offline behaviour with no second implementation to keep in step.
///
/// **`RestPaymentsGateway` carries the idempotency in the URL.** `collect` is
/// a `PUT` to the attempt's own key rather than a `POST` to a collection,
/// which makes a resend after a lost acknowledgement the same request rather
/// than a second charge. An adapter that posted would have to hope the server
/// read a header.
///
/// **`KeyValueReceiptPrinter` does not drive a printer**, and that is the
/// honest shape rather than a gap: there is no printer among the eight
/// platform packages, and a courier platform's receipt is usually a screen or
/// a message. The port exists for something this small because the question
/// "was a receipt produced" is asked by a regulator, the answer needs a seam a
/// test can watch, and the technology behind it is somebody else's decision.
///
/// **`PaymentsMapper` replays an attempt and restores a settlement.** An
/// attempt is rebuilt as an intention and then taken, refused or refunded —
/// exactly as it happened — so a refund that arrived without a taking fails on
/// the way in rather than becoming a hole in a day's numbers. A settlement's
/// totals are an aggregate and cannot be replayed without every attempt, so
/// they are restored as stored, and `runSettlementStoreContract` is the guard.
///
/// **Nothing here brings the Flutter SDK in**, which is why this package's
/// tests run under `dart test` while `delivery_infrastructure`'s run under
/// `flutter test`. Money is an HTTP request and a row; delivery needed a
/// camera and a position, and paid for them.
library;

export 'src/device_backed_payments_gateway.dart';
export 'src/key_value_cash_drawer.dart';
export 'src/key_value_receipt_printer.dart';
export 'src/key_value_settlement_store.dart';
export 'src/payments_dto.dart';
export 'src/payments_mapper.dart';
export 'src/rest_payments_gateway.dart';
