import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// Builds a shipment in whatever state a test needs, by walking the real
/// state machine to it.
///
/// The walking is the point. `Shipment`'s public constructor can put a
/// shipment into any state — mappers in `shipments_infrastructure` need that
/// to rebuild one from a row — and a builder that used it could hand a test a
/// shipment the machine cannot actually produce. Every assertion made against
/// such a fixture is an assertion about a situation that never happens.
///
/// So each step calls the transition it is named after and throws if the
/// machine refuses. A misconfigured builder fails loudly in setup rather than
/// quietly in an assertion.
///
/// ```dart
/// final shipment = ShipmentBuilder()
///     .withId('ship-42')
///     .assignedTo(courier)
///     .loaded()
///     .outForDelivery()
///     .build();
/// ```
///
/// Every step returns a *new* builder rather than `this`. Two reasons, and
/// only the second is about lints: a shared prefix can be reused — `final
/// onTheVan = base.assignedTo(courier).loaded();` and then two tests branch
/// off it without one leaking into the other — and `avoid_returning_this`
/// exists precisely because a mutable fluent object surprises whoever assumes
/// otherwise.
final class ShipmentBuilder {
  /// Starts from a newly accepted shipment.
  ShipmentBuilder()
    : _id = 'ship-1',
      _barcodeBody = '10000000000',
      _consigneeName = 'Ayse Yilmaz',
      _address = 'Bagdat Cd. 100, Kadikoy, Istanbul',
      _at = defaultMoment,
      _moves = const [];

  // Positional, because a named parameter cannot start with an underscore
  // and an initializing formal is what keeps this constructor from being six
  // lines of assignment. Private and called from exactly one place, `_with`,
  // which is named-parameter shaped and is what every step actually uses.
  ShipmentBuilder._(
    this._id,
    this._barcodeBody,
    this._consigneeName,
    this._address,
    this._at,
    this._moves,
  );

  /// The instant every move is stamped with unless [at] changes it.
  ///
  /// A constant, not a clock. Rule A1 forbids `DateTime.now()` here as
  /// anywhere else, and a fixture whose timestamps move is a fixture that
  /// makes an equality assertion flake once a day.
  static final DateTime defaultMoment = DateTime.utc(2026, 3, 14, 12);

  final String _id;
  final String _barcodeBody;
  final String _consigneeName;
  final String _address;
  final DateTime _at;
  final List<Shipment Function(Shipment)> _moves;

  /// Sets the identifier.
  ShipmentBuilder withId(String id) => _with(id: id);

  /// Sets the barcode's eleven-digit body; the check digit is computed.
  ShipmentBuilder withBarcodeBody(String body) => _with(barcodeBody: body);

  /// Sets who receives it and where.
  ShipmentBuilder to(String name, {String? address}) =>
      _with(consigneeName: name, address: address);

  /// Stamps every move from here on with [moment].
  ShipmentBuilder at(DateTime moment) => _with(at: moment);

  /// Puts it on [courier]'s manifest.
  ShipmentBuilder assignedTo(ActorId courier) =>
      _move((shipment) => shipment.assignTo(courier, at: _at));

  /// Scans it into the vehicle of whoever it is assigned to.
  ///
  /// Takes no courier: the assigned one is the only courier that may load it,
  /// and letting a builder pass a different one would let a test set up a
  /// situation the machine refuses.
  ShipmentBuilder loaded() =>
      _move((shipment) => shipment.loadOnto(_courierOf(shipment), at: _at));

  /// Sends it out with whoever it is assigned to.
  ShipmentBuilder outForDelivery() => _move(
    (shipment) => shipment.startDelivery(_courierOf(shipment), at: _at),
  );

  /// Hands it over against [proofReference].
  ShipmentBuilder delivered({String proofReference = 'proof-1'}) => _move(
    (shipment) => shipment.completeDelivery(
      proofReference: proofReference,
      at: _at,
    ),
  );

  /// Records a failed attempt.
  ShipmentBuilder undeliverable({String reason = 'nobody home'}) =>
      _move((shipment) => shipment.failDelivery(reason: reason, at: _at));

  /// Sends it back to the depot.
  ShipmentBuilder returnedToDepot({ActorId? by}) =>
      _move((shipment) => shipment.returnToDepot(at: _at, by: by));

  /// Produces the shipment.
  Shipment build() {
    var shipment = Shipment.accepted(
      id: _unwrap(ShipmentId.parse(_id)),
      barcode: _unwrap(
        Barcode.parse('$_barcodeBody${Barcode.checkDigitFor(_barcodeBody)}'),
      ),
      consignee: _unwrap(
        Consignee.create(
          name: _consigneeName,
          address: _unwrap(AddressPoint.create(formatted: _address)),
        ),
      ),
    );
    for (final move in _moves) {
      shipment = move(shipment);
    }
    return shipment;
  }

  ShipmentBuilder _with({
    String? id,
    String? barcodeBody,
    String? consigneeName,
    String? address,
    DateTime? at,
    List<Shipment Function(Shipment)>? moves,
  }) => ShipmentBuilder._(
    id ?? _id,
    barcodeBody ?? _barcodeBody,
    consigneeName ?? _consigneeName,
    address ?? _address,
    at ?? _at,
    moves ?? _moves,
  );

  ShipmentBuilder _move(
    Result<Shipment, ShipmentFailure> Function(Shipment) transition,
  ) => _with(
    moves: [
      ..._moves,
      (shipment) => _unwrap(transition(shipment)),
    ],
  );

  ActorId _courierOf(Shipment shipment) {
    final courier = shipment.status.courier;
    if (courier == null) {
      throw StateError(
        'ShipmentBuilder: ${shipment.status.label} has no courier. Call '
        'assignedTo() before loaded() or outForDelivery().',
      );
    }
    return courier;
  }

  static T _unwrap<T, F>(Result<T, F> result) => result.fold(
    (value) => value,
    (failure) => throw StateError('ShipmentBuilder: $failure'),
  );
}
