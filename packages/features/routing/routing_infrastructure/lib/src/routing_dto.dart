/// The wire shape of a routing record.
///
/// A DTO, and it stays here. It never appears in a signature the domain can
/// see: the adapter maps it to whatever the port promised, so a change to the
/// server's field names is a change to this file and its mapper, and to
/// nothing else.
final class RoutingDto {
  /// Creates the DTO.
  const RoutingDto({required this.id});

  /// Reads one from a decoded JSON object.
  ///
  /// Hand-written while this package has no generator wired up. Add
  /// `json_serializable` and a `build.yaml` when the shape grows past what is
  /// pleasant to write by hand — never in the `_api` package.
  factory RoutingDto.fromJson(Map<String, Object?> json) =>
      RoutingDto(id: json['id']! as String);

  /// The identifier as the remote system spells it.
  final String id;

  /// The domain value this DTO carries.
  ///
  /// The mapper lives beside the DTO rather than beside the entity, because
  /// mapping is an infrastructure concern and the domain must not learn the
  /// wire format to do it.
  String toDomain() => id;
}
