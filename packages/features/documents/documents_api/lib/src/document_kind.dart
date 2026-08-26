import 'package:core_kernel/core_kernel.dart';

import 'documents_failure.dart';

/// Which piece of paperwork.
///
/// A closed set, because every one of them is a template somebody maintains
/// and a legal obligation somebody signed off. An open `String` kind would
/// make "which documents does this product produce" a question nobody can
/// answer without grepping.
enum DocumentKind {
  /// The consignment note that travels with the parcel.
  waybill,

  /// Proof that the parcel was handed over.
  deliveryReceipt,

  /// The record of damage found at a door.
  damageReport;

  /// Reads a kind from its stored spelling.
  static Result<DocumentKind, DocumentsFailure> parse(String raw) {
    for (final value in values) {
      if (value.name == raw) {
        return Success(value);
      }
    }
    return Failed(
      MalformedDocument(
        field: 'kind',
        reason: '"$raw" is not one of ${values.map((v) => v.name).join(', ')}',
      ),
    );
  }
}
