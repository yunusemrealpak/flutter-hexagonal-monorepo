import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';

import '../payments_strings.dart';
import 'collection_bloc.dart';
import 'collection_event.dart';
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
/// **The bloc arrives through the widget tree, not the constructor**, and that
/// is a deliberate reading of invariant 1.2.7 rather than an exception to it.
/// The rule forbids a service locator inside a package — `GetIt`, a global,
/// anything a reader cannot see from the call site. `BlocProvider` is an
/// `InheritedWidget`: it is scoped to a subtree, it is visible in the tree that
/// mounts the screen, and a test supplies it the same way an app does. This
/// package already reaches for one that way — `PeykStrings.of(context)` on the
/// line below — so the mechanism is not new here, only the payload.
final class CollectionScreen extends StatefulWidget {
  /// Creates the screen for [shipment].
  ///
  /// The bloc is not a parameter. Whoever mounts this screen puts a
  /// [CollectionBloc] above it with `BlocProvider`.
  const CollectionScreen({
    required this.shipment,
    this.onFinished,
    super.key,
  });

  /// Which parcel the money is owed against.
  final ShipmentId shipment;

  /// Reports that the courier is done at this door.
  ///
  /// **Offered as a button rather than fired on a transition**, and the
  /// difference from `ProofCaptureScreen.onSettled` is deliberate. Proof is
  /// the middle of a visit, so continuing is what the courier already asked
  /// for. Money is the end of it, and `NothingOwed` arrives the instant the
  /// screen loads — reporting that automatically would take a prepaid parcel
  /// off the screen before anybody read the word "prepaid".
  ///
  /// The app decides what "done" leads to. This package does not know that a
  /// manifest exists.
  final VoidCallback? onFinished;

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
    // Asking is the screen's job, not the app's. An app that had to remember
    // to dispatch this would be an app that forgets it on the second route
    // that mounts the screen. `read` rather than `watch`, because initState
    // must not subscribe.
    context.read<CollectionBloc>().add(CollectionRequested(widget.shipment));
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(PaymentsStrings.title),
      // **`buildWhen` is what makes the selectors inside `_Door` worth
      // writing.** Without it this builder runs on every emission — including
      // a change of payment method — and rebuilds the whole subtree, so a
      // `BlocSelector` underneath would be re-created rather than skipped.
      // Narrowing the outer rebuild to *the kind of state* is the half of the
      // pattern people leave out, and leaving it out is why "BlocSelector did
      // not help" is a common complaint.
      body: BlocBuilder<CollectionBloc, CollectionState>(
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType,
        builder: (context, state) => switch (state) {
          CollectionIdle() || CollectionLoading() => const PeykLoadingView(),
          // Where this screen spends most of its life. Most parcels are
          // prepaid, and that is not a failure.
          NothingOwed() => _Finished(
            message: strings.resolve(PaymentsStrings.nothingOwed),
            onFinished: widget.onFinished,
          ),
          Owed() => _Door(shipment: widget.shipment),
          Collected(:final attempt) => _Finished(
            message: strings.resolve(
              PaymentsStrings.taken,
              arguments: CollectionScreen.amountArguments(attempt.amount),
            ),
            onFinished: widget.onFinished,
          ),
          CollectionFailed(:final failure) => PeykFailureView(
            message: strings.resolve(
              CollectionScreen.describe(failure),
              arguments: CollectionScreen.argumentsFor(failure),
            ),
            onRetry: CollectionScreen.canRetry(failure)
                ? () => context.read<CollectionBloc>().add(
                    CollectionRequested(widget.shipment),
                  )
                : null,
          ),
        },
      ),
    );
  }
}

/// A door the courier is finished with, and the way off it.
///
/// The button is drawn only when the app supplied somewhere to go. An app
/// that mounts this screen as a leaf — a dispatcher looking at what a courier
/// collected — gets the sentence and no button, which is the correct screen
/// for somebody who is not standing at the door.
final class _Finished extends StatelessWidget {
  const _Finished({required this.message, this.onFinished});

  final String message;
  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    final done = onFinished;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PeykEmptyView(message: message),
        if (done != null) ...[
          const PeykGap.vertical(PeykGapSize.betweenGroups),
          PeykButton(
            label: PeykStrings.of(context).resolve(PaymentsStrings.done),
            onPressed: done,
            tone: PeykButtonTone.primary,
          ),
        ],
      ],
    );
  }
}

/// The door itself: an amount, a way of paying, and the button.
///
/// **Three `BlocSelector`s rather than one `BlocBuilder`.** Each one names the
/// slice of the state its subtree draws, and rebuilds only when that slice
/// changes. Tapping *card* after *cash* rebuilds two option rows and nothing
/// else — not the amount, not the collect button, not the refusal chip. Under
/// the `ListenableBuilder` this replaced, one `notifyListeners` rebuilt the
/// whole list.
///
/// The selectors are safe against a state that is no longer [Owed]: an
/// emission can land between the outer rebuild and this one, and a selector
/// that assumed the case would throw on the frame in between.
final class _Door extends StatelessWidget {
  const _Door({required this.shipment});

  final ShipmentId shipment;

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return ListView(
      children: [
        BlocSelector<CollectionBloc, CollectionState, Money?>(
          selector: (state) => state is Owed ? state.amount : null,
          builder: (context, amount) => amount == null
              ? const PeykGap.vertical(PeykGapSize.betweenRows)
              : PeykText.display(
                  strings.resolve(
                    PaymentsStrings.owed,
                    arguments: CollectionScreen.amountArguments(amount),
                  ),
                ),
        ),
        const PeykGap.vertical(PeykGapSize.betweenGroups),
        BlocSelector<CollectionBloc, CollectionState, PaymentMethod?>(
          selector: (state) => state is Owed ? state.method : null,
          builder: (context, method) {
            if (method == null) {
              return const PeykGap.vertical(PeykGapSize.betweenRows);
            }
            final isCash = method.isCash;

            return PeykSection(
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
                  onTap: () => context.read<CollectionBloc>().add(
                    const MethodChosen(PaymentMethod.cash()),
                  ),
                ),
                PeykOptionRow(
                  label: strings.resolve(PaymentsStrings.methodCard),
                  selected: !isCash,
                  onTap: () => context.read<CollectionBloc>().add(
                    const MethodChosen(PaymentMethod.card(last4: '0000')),
                  ),
                ),
              ],
            );
          },
        ),
        const PeykGap.vertical(PeykGapSize.betweenGroups),
        // Scenario 6: the action a courier without the grant never sees. The
        // use case does not check permissions, so this is the last thing
        // between them and a recorded payment.
        //
        // `canCollect` is read from the bloc rather than selected from the
        // state, because it is not in the state — a permission the operation
        // revokes mid-shift must not be answered from a value the screen
        // captured when it opened.
        if (context.read<CollectionBloc>().canCollect)
          PeykButton(
            label: strings.resolve(PaymentsStrings.collect),
            onPressed: () => context.read<CollectionBloc>().add(
              CollectionSubmitted(shipment),
            ),
            tone: PeykButtonTone.primary,
          ),
        // An advisory rather than a failure page: the amount is still on the
        // screen and the courier can change the method and try again. A
        // refusal that replaced the screen would take the number with it.
        BlocSelector<CollectionBloc, CollectionState, PaymentsFailure?>(
          selector: (state) => state is Owed ? state.refusal : null,
          builder: (context, refusal) => refusal == null
              ? const PeykGap.vertical(PeykGapSize.betweenRows)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PeykGap.vertical(PeykGapSize.betweenRows),
                    PeykChip(
                      label: strings.resolve(
                        CollectionScreen.describe(refusal),
                        arguments: CollectionScreen.argumentsFor(refusal),
                      ),
                      intent: PeykIntent.danger,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
