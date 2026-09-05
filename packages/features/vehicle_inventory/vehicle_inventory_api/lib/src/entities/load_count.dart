import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import '../failures/vehicle_inventory_failure.dart';
import '../values/load_count_id.dart';
import '../values/load_direction.dart';

/// One reconciliation of what should be in a van against what was scanned.
///
/// **The discrepancy is derived, never stored.** [missing] and [unexpected]
/// are set arithmetic over [manifest] and [scanned]. Storing them beside the
/// two sets would make a state where the three disagree representable — and it
/// is the state a bug would produce, silently, in the record somebody uses to
/// argue about a lost parcel.
///
/// **A count is closable while it disagrees.** That is the whole point of it:
/// a courier who cannot find two parcels closes the count with two missing,
/// and the operation now knows. A rule that refused to close an incomplete
/// count would leave couriers at the depot with a screen they cannot dismiss,
/// and the discrepancy would go in a WhatsApp message instead.
final class LoadCount extends Entity<LoadCountId> {
  const LoadCount._({
    required super.id,
    required this.courier,
    required this.direction,
    required this.manifest,
    required this.scanned,
    required this.startedAt,
    required this.closedAt,
  });

  /// Opens a count against the manifest the depot says is right.
  ///
  /// [startedAt] comes from a `Clock` — rule A1.
  ///
  /// An empty manifest is refused. A van with nothing on it is not a round,
  /// and a count against nothing would close immediately with everything
  /// scanned "unexpected" — which reads as a data problem and is one.
  static Result<LoadCount, VehicleInventoryFailure> opened({
    required LoadCountId id,
    required ActorId courier,
    required LoadDirection direction,
    required Set<ShipmentId> manifest,
    required DateTime startedAt,
  }) {
    if (manifest.isEmpty) {
      return const Failed(
        MalformedCount(field: 'manifest', reason: 'there is nothing to count'),
      );
    }

    return Success(
      LoadCount._(
        id: id,
        courier: courier,
        direction: direction,
        manifest: Set.unmodifiable(manifest),
        scanned: Set.unmodifiable(const <ShipmentId>{}),
        startedAt: startedAt.toUtc(),
        closedAt: null,
      ),
    );
  }

  /// Rebuilds a count that was already stored.
  static Result<LoadCount, VehicleInventoryFailure> stored({
    required LoadCountId id,
    required ActorId courier,
    required LoadDirection direction,
    required Set<ShipmentId> manifest,
    required Set<ShipmentId> scanned,
    required DateTime startedAt,
    required DateTime? closedAt,
  }) {
    if (closedAt != null && closedAt.toUtc().isBefore(startedAt.toUtc())) {
      return const Failed(
        MalformedCount(
          field: 'closedAt',
          reason: 'it is before the count was started',
        ),
      );
    }

    return opened(
      id: id,
      courier: courier,
      direction: direction,
      manifest: manifest,
      startedAt: startedAt,
    ).map(
      (count) => LoadCount._(
        id: count.id,
        courier: count.courier,
        direction: count.direction,
        manifest: count.manifest,
        scanned: Set.unmodifiable(scanned),
        startedAt: count.startedAt,
        closedAt: closedAt?.toUtc(),
      ),
    );
  }

  /// Whose van is being counted.
  final ActorId courier;

  /// Which way the parcels are going.
  final LoadDirection direction;

  /// What the depot says should be there.
  final Set<ShipmentId> manifest;

  /// What has actually been scanned.
  final Set<ShipmentId> scanned;

  /// When the count was opened, in UTC.
  final DateTime startedAt;

  /// When it was closed, or `null` while it is open.
  final DateTime? closedAt;

  /// Whether somebody is still scanning.
  bool get isOpen => closedAt == null;

  /// On the manifest and not scanned.
  Set<ShipmentId> get missing => manifest.difference(scanned);

  /// Scanned and not on the manifest.
  ///
  /// Just as interesting as [missing] and easier to forget: a parcel in the
  /// van that nobody expected is somebody else's parcel, and it is a delivery
  /// that will not happen unless the count says so.
  Set<ShipmentId> get unexpected => scanned.difference(manifest);

  /// Whether the van matches the paperwork.
  bool get isReconciled => missing.isEmpty && unexpected.isEmpty;

  /// Records one scan.
  ///
  /// **Idempotent.** A barcode read twice is one parcel — scanners double-fire,
  /// and a courier who cannot tell whether the first beep registered will scan
  /// again. Counting the second read would produce a count that never
  /// reconciles and a courier who stops trusting the screen.
  ///
  /// A parcel that is not on the manifest is *recorded*, not refused. Refusing
  /// it would leave the only evidence of a mis-load in whatever the courier
  /// chose to say about it afterwards.
  Result<LoadCount, VehicleInventoryFailure> scan(ShipmentId shipment) {
    if (!isOpen) {
      return const Failed(CountClosed('scan'));
    }
    if (scanned.contains(shipment)) {
      return Success(this);
    }

    return Success(
      LoadCount._(
        id: id,
        courier: courier,
        direction: direction,
        manifest: manifest,
        scanned: Set.unmodifiable({...scanned, shipment}),
        startedAt: startedAt,
        closedAt: null,
      ),
    );
  }

  /// Closes the count, discrepancy and all.
  Result<LoadCount, VehicleInventoryFailure> closedAtInstant(DateTime instant) {
    if (!isOpen) {
      return const Failed(CountClosed('close'));
    }

    return Success(
      LoadCount._(
        id: id,
        courier: courier,
        direction: direction,
        manifest: manifest,
        scanned: scanned,
        startedAt: startedAt,
        closedAt: instant.toUtc(),
      ),
    );
  }
}
