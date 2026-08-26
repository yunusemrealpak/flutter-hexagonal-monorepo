import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// The stored shape of one incident.
///
/// A DTO, and it stays on this side of the port. Instants are ISO 8601 in UTC
/// for the reason `InboxEntryDto` gives: epoch milliseconds would be smaller
/// and would make a stored row unreadable by whoever is debugging a courier's
/// phone at seven in the morning.
///
/// **This file is the one place in the feature where a foreign identifier is
/// rebuilt.** `ActorId.parse` and `ShipmentId.parse` are called here, and both
/// return *their own* feature's failure type — so the mapping ends with a
/// `mapFailure` that translates into `IncidentsFailure`. An `_infrastructure`
/// package could not do this at all, and would have to go through a reader
/// published by its own `_api`; a `_core` package may, and the difference is
/// worth knowing about before this feature is ever split.
final class IncidentDto {
  /// Creates the DTO.
  const IncidentDto({
    required this.id,
    required this.category,
    required this.severity,
    required this.openedAt,
    required this.escalatedAt,
    required this.resolvedAt,
    required this.reportedBy,
    required this.shipmentId,
    required this.note,
    required this.resolution,
  });

  /// Builds the DTO that carries [incident].
  factory IncidentDto.fromDomain(Incident incident) => IncidentDto(
    id: incident.id.value,
    category: incident.category.name,
    severity: incident.severity.name,
    openedAt: incident.openedAt.toIso8601String(),
    escalatedAt: incident.escalatedAt?.toIso8601String(),
    resolvedAt: incident.resolvedAt?.toIso8601String(),
    reportedBy: incident.reportedBy?.value,
    shipmentId: incident.shipmentId?.value,
    note: incident.note,
    resolution: incident.resolution,
  );

  /// Reads one from a decoded JSON object, or `null` when the shape is wrong.
  static IncidentDto? fromJson(Map<String, Object?> json) {
    Object? at(String key) => json[key];
    bool stringOrNull(Object? value) => value == null || value is String;

    final id = at('id');
    final category = at('category');
    final severity = at('severity');
    final openedAt = at('openedAt');
    if (id is! String ||
        category is! String ||
        severity is! String ||
        openedAt is! String ||
        !stringOrNull(at('escalatedAt')) ||
        !stringOrNull(at('resolvedAt')) ||
        !stringOrNull(at('reportedBy')) ||
        !stringOrNull(at('shipmentId')) ||
        !stringOrNull(at('note')) ||
        !stringOrNull(at('resolution'))) {
      return null;
    }

    return IncidentDto(
      id: id,
      category: category,
      severity: severity,
      openedAt: openedAt,
      escalatedAt: at('escalatedAt') as String?,
      resolvedAt: at('resolvedAt') as String?,
      reportedBy: at('reportedBy') as String?,
      shipmentId: at('shipmentId') as String?,
      note: at('note') as String?,
      resolution: at('resolution') as String?,
    );
  }

  /// Reads a whole log from the text a key-value store gave back.
  static List<IncidentDto>? decodeAll(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return null;
      }
      final rows = <IncidentDto>[];
      for (final element in decoded) {
        if (element is! Map<String, Object?>) {
          return null;
        }
        final dto = fromJson(element);
        if (dto == null) {
          return null;
        }
        rows.add(dto);
      }
      return rows;
    } on FormatException {
      return null;
    }
  }

  /// The text to store for [rows].
  static String encodeAll(List<IncidentDto> rows) =>
      jsonEncode([for (final row in rows) row._toJson()]);

  /// The identifier, as stored.
  final String id;

  /// The category, as stored.
  final String category;

  /// The severity, as stored.
  final String severity;

  /// When it was opened, ISO 8601 in UTC.
  final String openedAt;

  /// When it was last escalated, or `null`.
  final String? escalatedAt;

  /// When it was closed, or `null`.
  final String? resolvedAt;

  /// Who reported it, or `null` when the product did.
  final String? reportedBy;

  /// Which parcel it concerns, or `null`.
  final String? shipmentId;

  /// What the reporter wrote.
  final String? note;

  /// What was done about it.
  final String? resolution;

  /// The incident this DTO carries, or the first failure that stopped it.
  Result<Incident, IncidentsFailure> toDomain() {
    final opened = DateTime.tryParse(openedAt);
    if (opened == null) {
      return Failed(
        MalformedIncident(
          field: 'openedAt',
          reason: '"$openedAt" is not an instant',
        ),
      );
    }

    for (final later in {
      'escalatedAt': escalatedAt,
      'resolvedAt': resolvedAt,
    }.entries) {
      final raw = later.value;
      if (raw != null && DateTime.tryParse(raw) == null) {
        return Failed(
          MalformedIncident(
            field: later.key,
            reason: '"$raw" is not an instant',
          ),
        );
      }
    }

    final actor = _actor();
    if (actor case Failed(:final failure)) {
      return Failed(failure);
    }
    final parcel = _parcel();
    if (parcel case Failed(:final failure)) {
      return Failed(failure);
    }

    return IncidentId.parse(id).flatMap(
      (identifier) => IncidentCategory.parse(category).flatMap(
        (kind) => _severity().flatMap(
          (level) => Incident.stored(
            id: identifier,
            category: kind,
            severity: level,
            openedAt: opened,
            escalatedAt: _instant(escalatedAt),
            resolvedAt: _instant(resolvedAt),
            reportedBy: (actor as Success<ActorId?, IncidentsFailure>).value,
            shipmentId:
                (parcel as Success<ShipmentId?, IncidentsFailure>).value,
            note: note,
            resolution: resolution,
          ),
        ),
      ),
    );
  }

  /// Rebuilds the actor identifier, translating identity's failure into ours.
  ///
  /// `mapFailure` rather than a `switch`: the only thing this layer has to say
  /// about a malformed foreign identifier is which field it was in.
  Result<ActorId?, IncidentsFailure> _actor() {
    final raw = reportedBy;
    if (raw == null) {
      return const Success(null);
    }
    return ActorId.parse(raw)
        .map<ActorId?>((actor) => actor)
        .mapFailure(
          (_) => const MalformedIncident(
            field: 'reportedBy',
            reason: 'it is not an actor identifier',
          ),
        );
  }

  Result<ShipmentId?, IncidentsFailure> _parcel() {
    final raw = shipmentId;
    if (raw == null) {
      return const Success(null);
    }
    return ShipmentId.parse(raw)
        .map<ShipmentId?>((shipment) => shipment)
        .mapFailure(
          (_) => const MalformedIncident(
            field: 'shipmentId',
            reason: 'it is not a shipment identifier',
          ),
        );
  }

  Result<IncidentSeverity, IncidentsFailure> _severity() {
    for (final value in IncidentSeverity.values) {
      if (value.name == severity) {
        return Success(value);
      }
    }
    return Failed(
      MalformedIncident(
        field: 'severity',
        reason: '"$severity" is not a severity',
      ),
    );
  }

  /// Reads an optional instant that [toDomain] has already validated.
  static DateTime? _instant(String? raw) =>
      raw == null ? null : DateTime.parse(raw);

  Map<String, Object?> _toJson() => {
    'id': id,
    'category': category,
    'severity': severity,
    'openedAt': openedAt,
    'escalatedAt': escalatedAt,
    'resolvedAt': resolvedAt,
    'reportedBy': reportedBy,
    'shipmentId': shipmentId,
    'note': note,
    'resolution': resolution,
  };
}
