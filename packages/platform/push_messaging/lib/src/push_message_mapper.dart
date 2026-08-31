import 'package:core_ports/core_ports.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'push_message.dart';
import 'push_message_dto.dart';
import 'push_message_kind.dart';

// The wire spellings, in one place. A server that renames one of these breaks
// exactly this map and nothing else.
const _kindsByWireName = <String, PushMessageKind>{
  'shipment_assigned': PushMessageKind.shipmentAssigned,
  'dispatch_message': PushMessageKind.dispatchMessage,
  'route_updated': PushMessageKind.routeUpdated,
};

/// Turns a provider envelope into something the product can act on.
///
/// Hand-written, and that is the convention rather than an oversight: decoding
/// is generated in [PushMessageDto], and every judgement about what the decoded
/// values *mean* lives here where it can be read. Three judgements are made:
///
/// - **A payload that will not decode is still a message.** It becomes
///   [PushMessageKind.unknown] with its raw data intact rather than an
///   exception inside a stream handler. A fleet updates over weeks, so a
///   server sending a shape this version has never seen is normal traffic.
/// - **`data` is kept whole**, even after `kind` has been read out of it, so a
///   message of an unrecognised kind still carries everything a later app
///   version would have needed.
/// - **`sentAt` prefers the provider's send time** and falls back to the
///   [Clock] only when there is none. Push can arrive long after it was sent —
///   a phone that was off, a network that was down — and collapsing the two
///   would make every delayed message look fresh.
PushMessage toPushMessage(RemoteMessage message, {required Clock clock}) {
  final dto = _decode(message.data);
  return PushMessage(
    // Push delivery is at-least-once. Carrying the provider's identifier is
    // what lets a caller notice the same message arriving twice.
    id: message.messageId ?? '',
    kind: _kindsByWireName[dto?.kind] ?? PushMessageKind.unknown,
    data: Map.unmodifiable(<String, String>{
      for (final entry in message.data.entries) entry.key: '${entry.value}',
    }),
    sentAt: message.sentTime?.toUtc() ?? clock.now(),
    // Decoded rather than left for a caller to fish out of `data`: the wire
    // spelling belongs to the DTO, and a caller reading `data['thread_id']`
    // would be a second place a server rename breaks.
    shipmentId: dto?.shipmentId,
    threadId: dto?.threadId,
    title: dto?.title ?? message.notification?.title,
    body: dto?.body ?? message.notification?.body,
  );
}

PushMessageDto? _decode(Map<String, dynamic> data) {
  try {
    return PushMessageDto.fromJson(data);
  } on Object {
    // A missing or mistyped field. The message survives as `unknown`; see the
    // first judgement above.
    return null;
  }
}
