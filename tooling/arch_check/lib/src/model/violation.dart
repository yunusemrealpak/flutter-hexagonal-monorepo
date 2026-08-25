import 'package:path/path.dart' as p;

/// Where a violation was found.
///
/// A package is always known. A file and a line are known when the violation
/// was found in source rather than in a pubspec edge.
final class ViolationLocation {
  /// Creates a location. [file] and [line] are omitted for a pubspec edge.
  const ViolationLocation({required this.package, this.file, this.line});

  /// The package's path relative to the workspace root, in posix form.
  final String package;

  /// The offending file's path relative to the workspace root, if any.
  final String? file;

  /// The 1-based line the offending construct starts on, if known.
  final int? line;

  @override
  String toString() {
    if (file == null) return package;
    return line == null ? file! : '$file:$line';
  }
}

/// One breach of the constitution.
///
/// Four fields, because a rule that does not say how to fix it gets worked
/// around instead of obeyed. The shape is fixed by section 7 of
/// `docs/DEPENDENCY_RULES.md` and the JSON output carries exactly the same
/// four.
final class Violation implements Comparable<Violation> {
  /// Creates a violation with the four fields section 7 requires.
  const Violation({
    required this.code,
    required this.location,
    required this.what,
    required this.remedy,
  });

  /// One of the violation codes declared in `docs/DEPENDENCY_RULES.md`.
  final String code;

  /// Where the breach is, precise enough to open in an editor.
  final ViolationLocation location;

  /// The offending edge, import or call, quoted.
  final String what;

  /// The concrete move that resolves it.
  final String remedy;

  /// The `--format=json` shape, carrying the same four fields as the text one.
  Map<String, Object?> toJson() => {
    'code': code,
    'location': {
      'package': location.package,
      if (location.file != null) 'file': location.file,
      if (location.line != null) 'line': location.line,
    },
    'what': what,
    'remedy': remedy,
  };

  /// Sorted by package, then file, then line, then code, so that two runs over
  /// an unchanged workspace produce byte-identical output. A report that
  /// reorders itself cannot be diffed, and a diff is how a reviewer sees what
  /// a change did to the architecture.
  @override
  int compareTo(Violation other) {
    final byPackage = location.package.compareTo(other.location.package);
    if (byPackage != 0) return byPackage;
    final byFile = (location.file ?? '').compareTo(other.location.file ?? '');
    if (byFile != 0) return byFile;
    final byLine = (location.line ?? 0).compareTo(other.location.line ?? 0);
    if (byLine != 0) return byLine;
    final byCode = code.compareTo(other.code);
    if (byCode != 0) return byCode;
    return what.compareTo(other.what);
  }

  @override
  String toString() => '$code  $location: $what';
}

/// Builds the posix, workspace-relative path a [ViolationLocation] carries.
///
/// Every path in the report is relative to the workspace root and uses forward
/// slashes on every platform, so that a violation reported on Windows and one
/// reported in CI are the same string.
String relativePosix(String absolute, String root) =>
    p.posix.joinAll(p.split(p.relative(absolute, from: root)));
