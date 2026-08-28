import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// The fingerprints of the suites that last passed.
///
/// A JSON file rather than a directory of marker files, because the whole
/// point is that CI can restore it as one cache entry. It lives under
/// `.cache/`, which is gitignored: a skip decision is a fact about one
/// machine's history, not about the repository.
final class TestHashCache {
  /// Creates a cache backed by [file].
  TestHashCache(this.file, Map<String, String> entries) : _entries = entries;

  /// Reads the cache at [path], or an empty one when it is missing or
  /// unreadable.
  ///
  /// A corrupt cache re-runs everything. It never fails the command: the worst
  /// a bad cache may cost is time, and a runner that refused to start because
  /// of one would be worse than no cache at all.
  factory TestHashCache.load(String path) {
    final file = File(path);
    if (!file.existsSync()) return TestHashCache(file, {});
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) return TestHashCache(file, {});
      return TestHashCache(file, {
        for (final entry in decoded.entries)
          entry.key.toString(): entry.value.toString(),
      });
    } on FormatException {
      return TestHashCache(file, {});
    }
  }

  /// Where the cache is written.
  final File file;

  final Map<String, String> _entries;

  /// Whether [package] last passed under [hash].
  bool isFresh(String package, String hash) => _entries[package] == hash;

  /// Records that [package] passed under [hash].
  void record(String package, String hash) => _entries[package] = hash;

  /// Forgets [package], so its next run is not skipped.
  void forget(String package) => _entries.remove(package);

  /// Writes the cache back, creating `.cache/` if it is not there.
  void save() {
    file.parent.createSync(recursive: true);
    final sorted = Map.fromEntries(
      _entries.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(
        sorted,
      )}\n',
    );
  }

  /// The default location, relative to a workspace root.
  static String pathFor(String rootPath) =>
      p.join(rootPath, '.cache', 'test_hashes.json');
}
