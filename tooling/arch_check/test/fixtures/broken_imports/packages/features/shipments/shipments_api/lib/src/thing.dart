import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

/// Both imports above belong outside a contract package.
@JsonSerializable()
@immutable
class ShipmentDto {
  /// Creates it.
  const ShipmentDto();
}
