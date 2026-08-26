import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'collection_controller.dart';
import 'collection_state.dart';

/// Where a courier takes money at a door.
///
/// **The collect action is behind a permission**, asked of `identity_api`'s
/// `PermissionChecker` and answered without this package learning anything
/// about roles or grants. Scenario 6, in the third feature that needs it.
///
/// **The amount is drawn, not typed.** It comes from `PaymentStatus`, so a
/// courier cannot collect a different number from the one the operation is
/// owed.
///
/// Deliberately plain: no colours, no typography, no spacing scale. Those come
/// from `design_system`, which arrives in phase 7.
final class CollectionScreen extends StatefulWidget {
  /// Creates the screen over [controller], for [shipment].
  const CollectionScreen({
    required this.controller,
    required this.shipment,
    super.key,
  });

  /// What drives it.
  final CollectionController controller;

  /// Which parcel the money is owed against.
  final ShipmentId shipment;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();

  /// Turns an amount into something a person reads.
  ///
  /// Minor units become a decimal here and nowhere else, using the currency's
  /// own scale — a currency with three minor-unit digits or none would break
  /// any code that assumed a hundred. It is the same reason `Currency` carries
  /// the scale rather than a bare code.
  ///
  /// No locale and no symbol placement: `design_system` and the app's
  /// localisation arrive in phase 7, and inventing a half-answer here would
  /// mean deleting it then.
  static String render(Money amount) {
    final digits = amount.currency.minorUnitDigits;
    if (digits == 0) return '${amount.minorUnits} ${amount.currency.code}';

    final scale = _powerOfTen(digits);
    final major = amount.minorUnits ~/ scale;
    final minor = (amount.minorUnits % scale).toString().padLeft(digits, '0');
    return '$major.$minor ${amount.currency.code}';
  }

  /// Turns a failure into something a person can act on.
  ///
  /// Exhaustive over `PaymentsFailure`, which is the point of it being sealed:
  /// the day payments learns a new way to fail, this stops compiling instead
  /// of quietly showing a courier the wrong sentence.
  static String describe(PaymentsFailure failure) => switch (failure) {
    CollectionRefused(:final reason) => 'Refused: $reason',
    CashDrawerUnavailable() => 'The cash record could not be updated.',
    PaymentsUnavailable() => 'This could not be recorded. Try again.',
    AlreadySettled() => 'This payment has already been taken.',
    NoCollectionFor() => 'There is nothing to collect on this parcel.',
    RefundNotPossible(:final reason) => 'Cannot refund: $reason',
    SettlementUnavailable() => "Your day's total could not be read.",
    SettlementClosed() => 'Your day is already handed in.',
    CurrencyMismatch(:final expected, :final actual) =>
      'This is in $actual and the collection is in $expected.',
    MalformedPaymentValue(:final field) => 'Something is wrong with $field.',
  };

  static int _powerOfTen(int digits) {
    var value = 1;
    for (var i = 0; i < digits; i++) {
      value *= 10;
    }
    return value;
  }
}

class _CollectionScreenState extends State<CollectionScreen> {
  @override
  void initState() {
    super.initState();
    // initState cannot be async, and the read is genuinely fire-and-forget:
    // its result reaches the screen through the controller's notification
    // rather than through this call.
    unawaited(widget.controller.load(widget.shipment));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state) {
      CollectionIdle() || CollectionLoading() => const Center(
        child: Text('Checking what is owed'),
      ),
      // Where this screen spends most of its life. Most parcels are prepaid.
      NothingOwed() => const Center(child: Text('Nothing to collect')),
      final Owed state => _Door(
        state: state,
        canCollect: widget.controller.canCollect,
        onMethod: widget.controller.takeBy,
        onCollect: () => unawaited(widget.controller.collect(widget.shipment)),
      ),
      Collected(:final attempt) => Center(
        child: Text('Taken ${CollectionScreen.render(attempt.amount)}'),
      ),
      CollectionFailed(:final failure) => Center(
        child: Text(CollectionScreen.describe(failure)),
      ),
    },
  );
}

final class _Door extends StatelessWidget {
  const _Door({
    required this.state,
    required this.canCollect,
    required this.onMethod,
    required this.onCollect,
  });

  final Owed state;
  final bool canCollect;
  final void Function(PaymentMethod) onMethod;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final refusal = state.refusal;

    return ListView(
      children: [
        Text('Owed ${CollectionScreen.render(state.amount)}'),
        Text('Taking by ${state.method.isCash ? 'cash' : 'card'}'),
        GestureDetector(
          onTap: () => onMethod(const PaymentMethod.cash()),
          child: const Text('Cash'),
        ),
        GestureDetector(
          onTap: () => onMethod(const PaymentMethod.card(last4: '0000')),
          child: const Text('Card'),
        ),
        // Scenario 6: the action a courier without the grant never sees. The
        // use case does not check permissions, so this is the last thing
        // between them and a recorded payment.
        if (canCollect)
          GestureDetector(onTap: onCollect, child: const Text('Take payment')),
        if (refusal != null) Text(CollectionScreen.describe(refusal)),
      ],
    );
  }
}
