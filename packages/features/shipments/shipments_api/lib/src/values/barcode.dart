import 'package:core_kernel/core_kernel.dart';

import '../failures/shipment_failure.dart';

/// The number printed on the label, as the scanner reads it.
///
/// Twelve digits, the last of which is a modulo-10 check digit over the first
/// eleven — the same scheme GS1 uses, and the reason a mis-scan is usually
/// caught before it becomes a lookup for somebody else's parcel.
///
/// The check lives here rather than in an adapter on purpose. A scanner
/// adapter, a manual-entry screen and a REST payload all produce barcodes, and
/// a validation that lived in one of them would be absent from the other two
/// — which is exactly how a hand-typed digit ends up querying a real shipment
/// that happens to exist.
final class Barcode extends ValueObject<String> {
  const Barcode._(super.value);

  /// How many digits a Peyk barcode has, check digit included.
  static const int length = 12;

  /// Reads a barcode from [raw], rejecting anything a scanner should not have
  /// produced.
  ///
  /// Whitespace is stripped anywhere in the string, not only at the ends:
  /// labels are routinely printed in groups of four and read back with the
  /// gaps in them.
  static Result<Barcode, ShipmentFailure> parse(String raw) {
    final digits = raw.replaceAll(RegExp(r'\s'), '');

    if (digits.length != length) {
      return Failed(
        MalformedBarcode(
          raw: raw,
          reason: 'expected $length digits, got ${digits.length}',
        ),
      );
    }
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      return Failed(
        MalformedBarcode(raw: raw, reason: 'contains a non-digit'),
      );
    }
    if (!_checkDigitHolds(digits)) {
      return Failed(
        MalformedBarcode(raw: raw, reason: 'check digit does not match'),
      );
    }
    return Success(Barcode._(digits));
  }

  /// The check digit that makes [body] — eleven digits — a valid barcode.
  ///
  /// Exposed so that tests and fixtures can build barcodes that pass rather
  /// than hard-coding numbers whose provenance nobody remembers, and so that
  /// `shipments_testing` can generate a manifest without importing the
  /// algorithm twice.
  static int checkDigitFor(String body) {
    var weighted = 0;
    for (var index = 0; index < body.length; index++) {
      final digit = int.parse(body[index]);
      // GS1 weights alternate 3 and 1 from the right; with eleven body digits
      // the leftmost is weighted 3.
      weighted += index.isEven ? digit * 3 : digit;
    }
    return (10 - weighted % 10) % 10;
  }

  static bool _checkDigitHolds(String digits) {
    final body = digits.substring(0, length - 1);
    final stated = int.parse(digits[length - 1]);
    return checkDigitFor(body) == stated;
  }
}
