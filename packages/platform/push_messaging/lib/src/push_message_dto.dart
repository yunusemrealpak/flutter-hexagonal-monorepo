import 'package:json_annotation/json_annotation.dart';

part 'push_message_dto.g.dart';

/// The payload a Peyk push carries, as it appears on the wire.
///
/// A DTO, and it lives in a `platform/*` package because that is one of the
/// two places §10.1 allows `json_serializable` to run — the other being
/// `_infrastructure`. Declaring this in an `_api` package would be rule G2's
/// violation, and the reason for the rule is visible in every field below:
/// their names and their optionality are shaped by what a push provider sends,
/// not by what the product means.
///
/// `kind` is a `String` here and a `PushMessageKind` one layer up. That split
/// is deliberate. Decoding is generated; deciding what an unrecognised kind
/// means is a product judgement, so it stays in the hand-written mapper where
/// it can be read — which is also the rule §10.2.3 states for `freezed` and
/// domain validation.
///
/// Every field but [kind] is optional, because a payload missing something is
/// a payload from a different app version rather than a broken one. A fleet
/// updates over weeks.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
final class PushMessageDto {
  /// Constructs the DTO. Called by the generated `fromJson`.
  const PushMessageDto({
    required this.kind,
    this.shipmentId,
    this.threadId,
    this.title,
    this.body,
  });

  /// Reads a DTO from the provider's data map.
  factory PushMessageDto.fromJson(Map<String, dynamic> json) =>
      _$PushMessageDtoFromJson(json);

  /// What the push is about, as the server spelled it.
  final String kind;

  /// The shipment the push concerns, when it concerns one.
  final String? shipmentId;

  /// The message thread the push concerns, when it concerns one.
  final String? threadId;

  /// A title the server composed, when it composed one.
  final String? title;

  /// A body the server composed, when it composed one.
  final String? body;
}
