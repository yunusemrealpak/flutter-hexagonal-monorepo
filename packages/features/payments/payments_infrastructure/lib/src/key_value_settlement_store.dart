import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:payments_api/payments_api.dart';

import 'payments_dto.dart';
import 'payments_mapper.dart';

/// Keeps a courier's day on the device.
///
/// The adapter `app_courier` binds. A settlement is written on every
/// collection and read at the end of a shift, and both have to work in a
/// basement — the money is in the courier's pocket whether or not a server can
/// be reached.
///
/// **`KeyValueStore` rather than a repository of its own.** That port's
/// documentation warns against persisting domain data through it, and the
/// warning is about features that skip designing a repository. This *is* the
/// repository: `SettlementStore` is payments' own outbound port, typed and
/// versioned, and the key-value store is the byte bucket underneath.
/// `routing`'s cache and delivery's proof store are built the same way.
final class KeyValueSettlementStore implements SettlementStore {
  /// Creates the adapter over [store].
  const KeyValueSettlementStore({
    required this.store,
    this.namespace = 'payments.settlement',
  });

  /// Where the days go.
  final KeyValueStore store;

  /// The key prefix this adapter owns.
  ///
  /// Everything it writes starts with this, so that signing out can clear
  /// payments' days without touching another feature's cursors.
  final String namespace;

  @override
  Future<Result<Settlement?, PaymentsFailure>> read(String settlementId) async {
    final String? body;
    switch (await store.read(_keyFor(settlementId))) {
      case Failed(:final failure):
        return Failed(SettlementUnavailable(detail: '$failure'));
      case Success(:final value):
        body = value;
    }

    // A missing day is a successful read of nothing, which is the port's
    // contract: the first collection of every morning arrives before anything
    // has been written.
    if (body == null) return const Success(null);

    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error) {
      return Failed(
        MalformedPaymentValue(field: 'settlement', reason: error.message),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return const Failed(
        MalformedPaymentValue(
          field: 'settlement',
          reason: 'the stored record is not a JSON object',
        ),
      );
    }

    return PaymentsMapper.settlementToDomain(
      SettlementDto.fromJson(decoded),
    ).map((settlement) => settlement);
  }

  @override
  Future<Result<Settlement, PaymentsFailure>> save(
    Settlement settlement,
  ) async {
    final body = jsonEncode(
      PaymentsMapper.settlementToDto(settlement).toJson(),
    );

    return switch (await store.write(_keyFor(settlement.id.value), body)) {
      Failed(:final failure) => Failed(
        SettlementUnavailable(detail: '$failure'),
      ),
      Success() => Success(settlement),
    };
  }

  String _keyFor(String settlementId) => '$namespace.$settlementId';
}
