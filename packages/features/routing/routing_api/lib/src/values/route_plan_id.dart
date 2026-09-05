import 'package:core_kernel/core_kernel.dart';

import '../failures/routing_failure.dart';

/// Identifies one plan for one courier's shift.
///
/// Plans are replaced rather than edited all day: a courier who deviates gets
/// a new plan, not a mutated one, so that the plan they were following at
/// eleven o'clock is still a thing that can be pointed at when somebody asks
/// why they went that way. The identifier is what makes those distinguishable.
final class RoutePlanId extends ValueObject<String> {
  const RoutePlanId._(super.value);

  /// Reads a plan identifier from [raw].
  static Result<RoutePlanId, RoutingFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedRouteValue(field: 'routePlanId', reason: 'is empty'),
      );
    }
    return Success(RoutePlanId._(trimmed));
  }
}
