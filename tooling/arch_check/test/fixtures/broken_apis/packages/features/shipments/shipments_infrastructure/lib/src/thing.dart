import 'dart:math';

import 'package:core_kernel/core_kernel.dart';

/// Every rule in section 5, in one class.
///
/// The doc comment is part of the fixture: it mentions `DateTime.now()` and
/// `Random()` in prose, and neither mention may be reported. Only the calls in
/// the body below are violations.
final class AmbientAdapter {
  /// Reads the clock, the random generator and an identifier from thin air.
  Future<Result<String, Object>> load(String id) async {
    final at = DateTime.now();
    final noise = Random().nextInt(10);
    final generated = Uuid().v4();
    print('loading $id at $at with $noise as $generated');
    debugPrint('the Flutter spelling of the same mistake');
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    return Success('$id');
  }
}

/// Stands in for Flutter's debugPrint so the fixture needs no Flutter SDK.
void debugPrint(String message) {}

/// Stands in for the uuid package so the fixture needs no dependency.
class Uuid {
  /// Creates one.
  const Uuid();

  /// Produces an identifier.
  String v4() => 'generated';
}
