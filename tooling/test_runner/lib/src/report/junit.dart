import '../model/package_result.dart';

/// Renders results as JUnit XML.
///
/// **One test case per package, not per test.** The runner launches `dart
/// test` and `flutter test` and reads their exit codes; parsing their machine
/// reporters into per-test cases would make this tool a second, worse copy of
/// two test reporters that already exist. What CI needs from an XML file is
/// "which package failed, and how long did each one take" — the per-test
/// detail is in the run log, printed live, where somebody debugging is
/// already looking.
///
/// A skipped package is a `<skipped/>` case rather than an absent one. A
/// report that quietly omitted them would show a full suite shrinking every
/// time the cache warmed up.
abstract final class JUnitReport {
  /// The XML document for [results].
  static String render(List<PackageResult> results) {
    final failures = results.where((result) => result.failed).length;
    final skipped = results
        .where((result) => result.status == RunStatus.skipped)
        .length;
    final seconds = results
        .fold<int>(0, (total, result) => total + result.duration.inMilliseconds)
        .toDouble();

    final head =
        '<testsuites name="peyk" tests="${results.length}" '
        'failures="$failures" skipped="$skipped" '
        'time="${(seconds / 1000).toStringAsFixed(3)}">';

    return [
      '<?xml version="1.0" encoding="UTF-8"?>',
      head,
      for (final result in results) ..._suite(result),
      '</testsuites>',
      '',
    ].join('\n');
  }

  static List<String> _suite(PackageResult result) {
    final time = (result.duration.inMilliseconds / 1000).toStringAsFixed(3);
    final body = switch (result.status) {
      RunStatus.passed => <String>[],
      RunStatus.skipped => [
        '      <skipped message="unchanged since it last passed"/>',
      ],
      RunStatus.failed => [_failure(result)],
    };

    final name = _escape(result.package);
    final open =
        '  <testsuite name="$name" tests="1" '
        'failures="${result.failed ? 1 : 0}" time="$time">';
    final testcase =
        '    <testcase classname="$name" name="suite" '
        'time="$time"${body.isEmpty ? '/>' : '>'}';

    return [
      open,
      testcase,
      ...body,
      if (body.isNotEmpty) '    </testcase>',
      '  </testsuite>',
    ];
  }

  static String _failure(PackageResult result) {
    final command = _escape(result.command.join(' '));
    return '      <failure message="suite failed">$command</failure>';
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
