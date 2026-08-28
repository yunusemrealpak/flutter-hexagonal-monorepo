import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'collection_controller.dart';
import 'collection_state.dart';
import 'payments_strings.dart';

/// Where a courier takes money at a door.
///
/// **The collect action is behind a permission**, asked of `identity_api`'s
/// `PermissionChecker` and answered without this package learning anything
/// about roles or grants. Scenario 6, in the third feature that needs it.
///
/// **The amount is drawn, not typed.** It comes from `PaymentStatus`, so a
/// courier cannot collect a different number from the one the operation is
/// owed.
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

  /// The arguments an amount contributes to whichever key draws it.
  ///
  /// Three of them, and no formatting. Turning minor units into money needs a
  /// locale — where the separator goes, which side the symbol is on, whether
  /// there is a space before it — and only the app has one. What crosses is
  /// the number, the code, and the currency's own minor-unit digit count: a
  /// currency with three of those or none would break any formatter that
  /// assumed a hundred, which is the same reason `Currency` carries the scale
  /// rather than a bare code.
  @visibleForTesting
  static Map<String, Object?> amountArguments(Money amount) => {
    'minorUnits': amount.minorUnits,
    'currency': amount.currency.code,
    'scale': amount.currency.minorUnitDigits,
  };

  /// Which string a failure should be shown as.
  ///
  /// Exhaustive over `PaymentsFailure`, which is the point of it being sealed:
  /// the day payments learns a new way to fail, this stops compiling instead
  /// of quietly showing a courier the wrong sentence.
  @visibleForTesting
  static String describe(PaymentsFailure failure) => switch (failure) {
    CollectionRefused() => PaymentsStrings.failureRefused,
    CashDrawerUnavailable() => PaymentsStrings.failureCashDrawerUnavailable,
    PaymentsUnavailable() => PaymentsStrings.failureUnavailable,
    AlreadySettled() => PaymentsStrings.failureAlreadySettled,
    NoCollectionFor() => PaymentsStrings.failureNothingToCollect,
    RefundNotPossible() => PaymentsStrings.failureRefundNotPossible,
    SettlementUnavailable() => PaymentsStrings.failureSettlementUnavailable,
    SettlementClosed() => PaymentsStrings.failureSettlementClosed,
    CurrencyMismatch() => PaymentsStrings.failureCurrencyMismatch,
    MalformedPaymentValue() => PaymentsStrings.failureMalformed,
  };

  /// The arguments [failure] contributes to its own message.
  @visibleForTesting
  static Map<String, Object?> argumentsFor(PaymentsFailure failure) =>
      switch (failure) {
        CollectionRefused(:final reason) ||
        RefundNotPossible(:final reason) => {'reason': reason},
        CurrencyMismatch(:final expected, :final actual) => {
          'expected': expected,
          'actual': actual,
        },
        MalformedPaymentValue(:final field) => {'field': field},
        CashDrawerUnavailable() ||
        PaymentsUnavailable() ||
        AlreadySettled() ||
        NoCollectionFor() ||
        SettlementUnavailable() ||
        SettlementClosed() => const {},
      };

  /// Whether trying again is the answer to [failure].
  ///
  /// Money is where a wrong retry costs the most. A payment that has already
  /// been taken must not offer a button that would take it twice, and a
  /// refusal is the operation's decision rather than a hiccup.
  @visibleForTesting
  static bool canRetry(PaymentsFailure failure) => switch (failure) {
    AlreadySettled() ||
    CollectionRefused() ||
    NoCollectionFor() ||
    SettlementClosed() ||
    CurrencyMismatch() => false,
    CashDrawerUnavailable() ||
    PaymentsUnavailable() ||
    RefundNotPossible() ||
    SettlementUnavailable() ||
    MalformedPaymentValue() => true,
  };
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
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(PaymentsStrings.title),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          CollectionIdle() || CollectionLoading() => const PeykLoadingView(),
          // Where this screen spends most of its life. Most parcels are
          // prepaid, and that is not a failure.
          NothingOwed() => PeykEmptyView(
            message: strings.resolve(PaymentsStrings.nothingOwed),
          ),
          final Owed state => _Door(
            state: state,
            canCollect: widget.controller.canCollect,
            onMethod: widget.controller.takeBy,
            onCollect: () =>
                unawaited(widget.controller.collect(widget.shipment)),
          ),
          Collected(:final attempt) => PeykEmptyView(
            message: strings.resolve(
              PaymentsStrings.taken,
              arguments: CollectionScreen.amountArguments(attempt.amount),
            ),
          ),
          CollectionFailed(:final failure) => PeykFailureView(
            message: strings.resolve(
              CollectionScreen.describe(failure),
              arguments: CollectionScreen.argumentsFor(failure),
            ),
            onRetry: CollectionScreen.canRetry(failure)
                ? () => unawaited(widget.controller.load(widget.shipment))
                : null,
          ),
        },
      ),
    );
  }
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
    final strings = PeykStrings.of(context);
    final isCash = state.method.isCash;

    return ListView(
      children: [
        PeykText.display(
          strings.resolve(
            PaymentsStrings.owed,
            arguments: CollectionScreen.amountArguments(state.amount),
          ),
        ),
        const PeykGap.vertical(PeykGapSize.betweenGroups),
        PeykSection(
          title: strings.resolve(
            PaymentsStrings.takingBy,
            arguments: {
              'method': strings.resolve(
                isCash
                    ? PaymentsStrings.methodCash
                    : PaymentsStrings.methodCard,
              ),
            },
          ),
          children: [
            PeykOptionRow(
              label: strings.resolve(PaymentsStrings.methodCash),
              selected: isCash,
              onTap: () => onMethod(const PaymentMethod.cash()),
            ),
            PeykOptionRow(
              label: strings.resolve(PaymentsStrings.methodCard),
              selected: !isCash,
              onTap: () => onMethod(const PaymentMethod.card(last4: '0000')),
            ),
          ],
        ),
        const PeykGap.vertical(PeykGapSize.betweenGroups),
        // Scenario 6: the action a courier without the grant never sees. The
        // use case does not check permissions, so this is the last thing
        // between them and a recorded payment.
        if (canCollect)
          PeykButton(
            label: strings.resolve(PaymentsStrings.collect),
            onPressed: onCollect,
            tone: PeykButtonTone.primary,
          ),
        // An advisory rather than a failure page: the amount is still on the
        // screen and the courier can change the method and try again. A
        // refusal that replaced the screen would take the number with it.
        if (refusal != null) ...[
          const PeykGap.vertical(PeykGapSize.betweenRows),
          PeykChip(
            label: strings.resolve(
              CollectionScreen.describe(refusal),
              arguments: CollectionScreen.argumentsFor(refusal),
            ),
            intent: PeykIntent.danger,
          ),
        ],
      ],
    );
  }
}
