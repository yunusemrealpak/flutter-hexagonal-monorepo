import 'package:billing_api/billing_api.dart';
import 'package:core_kernel/src/result.dart';
import 'package:shipments_api/shipments_api.dart';

import 'invoice_payload.dart';

/// The adapter.
///
/// Two habits from a codebase without ports: the type it needed was not
/// exported from core_kernel's barrel so the import reached into src/, and the
/// method that promised a Result throws when the input is wrong.
final class DioBillingRepository implements BillingRepository {
  /// Creates it.
  const DioBillingRepository();

  @override
  Future<Result<String, BillingFailure>> invoiceById(String id) async {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    return const Failed<String, BillingFailure>(BillingUnavailable());
  }

  /// Decides whether an invoice may be settled, using another feature's
  /// concept — a crossing that belongs to a use case, not to an adapter.
  bool canSettle(ShipmentSummary shipment) => shipment.isDelivered;

  /// Maps a payload to what the port promised.
  String fromPayload(Map<String, Object?> payload) =>
      InvoicePayload.fromJson(payload).id;
}
