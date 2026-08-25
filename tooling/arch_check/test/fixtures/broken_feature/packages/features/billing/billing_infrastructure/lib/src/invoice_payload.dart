part 'invoice_payload.g.dart';

/// The wire shape, with a generated companion and no build.yaml to say which
/// builder produced it.
class InvoicePayload {
  /// Creates it.
  const InvoicePayload({required this.id});

  /// Reads one from JSON.
  factory InvoicePayload.fromJson(Map<String, Object?> json) =>
      _$InvoicePayloadFromJson(json);

  /// The identifier.
  final String id;
}
