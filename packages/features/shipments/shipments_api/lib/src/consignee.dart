import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import 'address_point.dart';
import 'shipment_failure.dart';

/// Who receives the shipment, and where.
///
/// Hand-written for the same reason as `AddressPoint`: there is something to
/// check, and a generated public constructor would let a caller skip it.
@immutable
final class Consignee {
  const Consignee._({
    required this.name,
    required this.address,
    required this.phone,
  });

  /// Reads a consignee.
  ///
  /// The phone number is optional and deliberately not validated beyond being
  /// non-blank when present. Peyk delivers across borders, number formats
  /// differ by country, and a contract package that decided what a phone
  /// number looks like would be wrong in whichever country it was not written
  /// in. Reachability is answered by trying, not by a regular expression.
  static Result<Consignee, ShipmentFailure> create({
    required String name,
    required AddressPoint address,
    String? phone,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Failed(
        MalformedValue(field: 'consignee.name', reason: 'is empty'),
      );
    }
    final trimmedPhone = phone?.trim();
    if (trimmedPhone != null && trimmedPhone.isEmpty) {
      return const Failed(
        MalformedValue(
          field: 'consignee.phone',
          reason: 'is present but blank; omit it instead',
        ),
      );
    }
    return Success(
      Consignee._(
        name: trimmedName,
        address: address,
        phone: trimmedPhone,
      ),
    );
  }

  /// The name on the label.
  final String name;

  /// Where the shipment is going.
  final AddressPoint address;

  /// A number to call on arrival, when there is one.
  final String? phone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Consignee &&
          other.name == name &&
          other.address == address &&
          other.phone == phone;

  @override
  int get hashCode => Object.hash(name, address, phone);

  @override
  String toString() => 'Consignee($name, ${address.formatted})';
}
