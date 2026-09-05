import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import '../failures/delivery_failure.dart';

/// A barcode read at the door.
///
/// The symbol is a plain string, not shipments' `Barcode`. That type validates
/// against the operation's own symbologies and returns a `ShipmentFailure`,
/// and it answers a question delivery is not asking: shipments wants to know
/// *which parcel this is*, delivery wants to record *what the courier scanned
/// while standing there*. A scan that turns out to name the wrong parcel is
/// still evidence of what happened, and a type that refused it would throw
/// away the most interesting case.
@immutable
final class ScanEvidence {
  const ScanEvidence._({required this.symbol, required this.scannedAt});

  /// Reads a scan, refusing an empty symbol.
  static Result<ScanEvidence, DeliveryFailure> of({
    required String symbol,
    required DateTime scannedAt,
  }) {
    final trimmed = symbol.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedDeliveryValue(field: 'scan.symbol', reason: 'is empty'),
      );
    }
    return Success(
      ScanEvidence._(symbol: trimmed, scannedAt: scannedAt.toUtc()),
    );
  }

  /// What the scanner read.
  final String symbol;

  /// When, in UTC.
  final DateTime scannedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanEvidence &&
          other.symbol == symbol &&
          other.scannedAt == scannedAt;

  @override
  int get hashCode => Object.hash(symbol, scannedAt);

  @override
  String toString() => 'ScanEvidence($symbol)';
}
