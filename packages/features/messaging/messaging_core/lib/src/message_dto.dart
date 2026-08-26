import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:messaging_api/messaging_api.dart';

/// The stored shape of one message.
final class MessageDto {
  /// Creates the DTO.
  const MessageDto({
    required this.id,
    required this.thread,
    required this.author,
    required this.body,
    required this.writtenAt,
    required this.sentAt,
    required this.readAt,
  });

  /// Builds the DTO that carries [message].
  factory MessageDto.fromDomain(Message message) => MessageDto(
    id: message.id.value,
    thread: message.thread.value,
    author: message.author.value,
    body: message.body,
    writtenAt: message.writtenAt.toIso8601String(),
    sentAt: message.sentAt?.toIso8601String(),
    readAt: message.readAt?.toIso8601String(),
  );

  /// Reads one from a decoded JSON object, or `null` when the shape is wrong.
  static MessageDto? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final thread = json['thread'];
    final author = json['author'];
    final body = json['body'];
    final writtenAt = json['writtenAt'];
    final sentAt = json['sentAt'];
    final readAt = json['readAt'];
    if (id is! String ||
        thread is! String ||
        author is! String ||
        body is! String ||
        writtenAt is! String ||
        (sentAt != null && sentAt is! String) ||
        (readAt != null && readAt is! String)) {
      return null;
    }

    return MessageDto(
      id: id,
      thread: thread,
      author: author,
      body: body,
      writtenAt: writtenAt,
      sentAt: sentAt as String?,
      readAt: readAt as String?,
    );
  }

  /// Reads every stored message from the text a key-value store gave back.
  static List<MessageDto>? decodeAll(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return null;
      }
      final rows = <MessageDto>[];
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
  static String encodeAll(List<MessageDto> rows) =>
      jsonEncode([for (final row in rows) row._toJson()]);

  /// The identifier, as stored.
  final String id;

  /// Which thread, as stored.
  final String thread;

  /// Who wrote it, as stored.
  final String author;

  /// What it says.
  final String body;

  /// When it was written, ISO 8601 in UTC.
  final String writtenAt;

  /// When the server took it, or `null`.
  final String? sentAt;

  /// When it was read, or `null`.
  final String? readAt;

  /// The message this DTO carries, or the first failure that stopped it.
  Result<Message, MessagingFailure> toDomain() {
    final written = DateTime.tryParse(writtenAt);
    if (written == null) {
      return Failed(
        MalformedMessage(
          field: 'writtenAt',
          reason: '"$writtenAt" is not an instant',
        ),
      );
    }
    for (final later in {'sentAt': sentAt, 'readAt': readAt}.entries) {
      final raw = later.value;
      if (raw != null && DateTime.tryParse(raw) == null) {
        return Failed(
          MalformedMessage(
            field: later.key,
            reason: '"$raw" is not an instant',
          ),
        );
      }
    }

    return MessageId.parse(id).flatMap(
      (identifier) => ThreadId.parse(thread).flatMap(
        (conversation) => _author().flatMap(
          (writer) => Message.stored(
            id: identifier,
            thread: conversation,
            author: writer,
            body: body,
            writtenAt: written,
            sentAt: sentAt == null ? null : DateTime.parse(sentAt!),
            readAt: readAt == null ? null : DateTime.parse(readAt!),
          ),
        ),
      ),
    );
  }

  Result<ActorId, MessagingFailure> _author() =>
      ActorId.parse(author).mapFailure(
        (_) => const MalformedMessage(
          field: 'author',
          reason: 'it is not an actor identifier',
        ),
      );

  Map<String, Object?> _toJson() => {
    'id': id,
    'thread': thread,
    'author': author,
    'body': body,
    'writtenAt': writtenAt,
    'sentAt': sentAt,
    'readAt': readAt,
  };
}
