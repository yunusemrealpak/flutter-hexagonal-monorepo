import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:notifications_api/notifications_api.dart';

/// The stored shape of one inbox entry.
///
/// A DTO, and it stays on this side of the ports: `InboxEntry` never learns
/// that it is written as JSON, and this type never appears in a signature
/// `notifications_api` declares.
///
/// Instants are stored as ISO 8601 strings in UTC. Storing epoch milliseconds
/// would be smaller and would make every stored row unreadable by a person
/// debugging a courier's phone at seven in the morning.
final class InboxEntryDto {
  /// Creates the DTO.
  const InboxEntryDto({
    required this.id,
    required this.kind,
    required this.subject,
    required this.receivedAt,
    required this.readAt,
    required this.arguments,
  });

  /// Builds the DTO that carries [entry].
  factory InboxEntryDto.fromDomain(InboxEntry entry) => InboxEntryDto(
    id: entry.id.value,
    kind: entry.kind.name,
    subject: entry.subject,
    receivedAt: entry.receivedAt.toIso8601String(),
    readAt: entry.readAt?.toIso8601String(),
    arguments: entry.arguments,
  );

  /// Reads one from a decoded JSON object, or `null` when the shape is wrong.
  ///
  /// Never throws. A row a previous version of the product wrote is a corrupt
  /// row, and the caller turns `null` into a failure — no exception crosses
  /// the port above it.
  static InboxEntryDto? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final kind = json['kind'];
    final subject = json['subject'];
    final receivedAt = json['receivedAt'];
    final readAt = json['readAt'];
    final arguments = json['arguments'];
    if (id is! String ||
        kind is! String ||
        subject is! String ||
        receivedAt is! String ||
        (readAt != null && readAt is! String) ||
        arguments is! Map<String, Object?>) {
      return null;
    }
    final rendered = <String, String>{};
    for (final entry in arguments.entries) {
      final value = entry.value;
      if (value is! String) {
        return null;
      }
      rendered[entry.key] = value;
    }
    return InboxEntryDto(
      id: id,
      kind: kind,
      subject: subject,
      receivedAt: receivedAt,
      readAt: readAt as String?,
      arguments: rendered,
    );
  }

  /// Reads a whole inbox from the string a key-value store gave back.
  ///
  /// A single key holds the list rather than one key per entry. An inbox is
  /// read and written whole — a courier opens it, and every unread count
  /// recomputes from all of it — so splitting it across keys would buy nothing
  /// and cost a `keys()` scan on every read.
  static List<InboxEntryDto>? decodeAll(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return null;
      }
      final entries = <InboxEntryDto>[];
      for (final element in decoded) {
        if (element is! Map<String, Object?>) {
          return null;
        }
        final dto = fromJson(element);
        if (dto == null) {
          return null;
        }
        entries.add(dto);
      }
      return entries;
    } on FormatException {
      return null;
    }
  }

  /// The text to store for [entries].
  static String encodeAll(List<InboxEntryDto> entries) =>
      jsonEncode([for (final entry in entries) entry._toJson()]);

  /// The identifier, as it was stored.
  final String id;

  /// The kind, as it was stored.
  final String kind;

  /// The localisation key, as it was stored.
  final String subject;

  /// When the alert arrived, ISO 8601 in UTC.
  final String receivedAt;

  /// When it was read, or `null`.
  final String? readAt;

  /// What the localisation key needs filling in with.
  final Map<String, String> arguments;

  /// The entry this DTO carries, or the first failure that stopped it.
  Result<InboxEntry, NotificationsFailure> toDomain() {
    final received = DateTime.tryParse(receivedAt);
    if (received == null) {
      return Failed(
        MalformedNotification(
          field: 'receivedAt',
          reason: '"$receivedAt" is not an instant',
        ),
      );
    }
    final stored = readAt;
    final read = stored == null ? null : DateTime.tryParse(stored);
    if (stored != null && read == null) {
      return Failed(
        MalformedNotification(
          field: 'readAt',
          reason: '"$stored" is not an instant',
        ),
      );
    }

    return NotificationId.parse(id).flatMap(
      (identifier) => NotificationKind.parse(kind).flatMap(
        (parsed) => InboxEntry.stored(
          id: identifier,
          kind: parsed,
          subject: subject,
          receivedAt: received,
          readAt: read,
          arguments: arguments,
        ),
      ),
    );
  }

  Map<String, Object?> _toJson() => {
    'id': id,
    'kind': kind,
    'subject': subject,
    'receivedAt': receivedAt,
    'readAt': readAt,
    'arguments': arguments,
  };
}
