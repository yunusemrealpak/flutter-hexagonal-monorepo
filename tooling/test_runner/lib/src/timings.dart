import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// How long each package's suite took, last time anybody measured.
///
/// Used for one thing: dividing packages into buckets that finish at roughly
/// the same time. Splitting seventy packages evenly *by count* puts
/// `design_system`'s golden-adjacent widget suite next to nine `_api` packages
/// and leaves nine other machines idle.
final class Timings {
  /// Creates timings from [seconds].
  Timings(this.file, Map<String, double> seconds) : _seconds = seconds;

  /// Reads the file at [path], or empty timings when it is missing.
  factory Timings.load(String path) {
    final file = File(path);
    if (!file.existsSync()) return Timings(file, {});
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) return Timings(file, {});
      return Timings(file, {
        for (final entry in decoded.entries)
          entry.key.toString():
              double.tryParse(entry.value.toString()) ?? _unknownCost,
      });
    } on FormatException {
      return Timings(file, {});
    }
  }

  /// Where the timings are written.
  final File file;

  final Map<String, double> _seconds;

  /// What a package with no recorded time is assumed to cost.
  ///
  /// Deliberately above the median rather than at it. A package nobody has
  /// timed is usually a package somebody just added, and putting the unknown
  /// in the emptiest bucket is the cheapest way to be wrong.
  static const double _unknownCost = 20;

  /// The recorded cost of [package], or the assumed one.
  double costOf(String package) => _seconds[package] ?? _unknownCost;

  /// Records that [package] took [seconds].
  void record(String package, double seconds) =>
      _seconds[package] = double.parse(seconds.toStringAsFixed(2));

  /// Writes the file back.
  void save() {
    file.parent.createSync(recursive: true);
    final sorted = Map.fromEntries(
      _seconds.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(
        sorted,
      )}\n',
    );
  }

  /// The default location, relative to a workspace root.
  static String pathFor(String rootPath) =>
      p.join(rootPath, '.cache', 'timings.json');
}
