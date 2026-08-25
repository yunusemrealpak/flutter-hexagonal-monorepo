import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

/// The wire shape of an invoice, declared in the contract package because
/// that is where the entity was and it felt like the same thing.
@JsonSerializable()
@immutable
class InvoiceDto {
  /// Creates it.
  const InvoiceDto({required this.id, required this.amountMinor});

  /// The identifier as the billing system spells it.
  final String id;

  /// The amount, in minor units.
  final int amountMinor;
}
