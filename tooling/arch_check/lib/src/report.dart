import 'dart:convert';

import 'runner.dart';

/// How a run is rendered.
enum ReportFormat {
  /// A report meant to be read in a terminal or a CI log.
  text('text'),

  /// The same four fields per violation, for a machine.
  json('json');

  const ReportFormat(this.id);

  /// The identifier accepted by `--format`.
  final String id;

  /// The format with this identifier, or `null` if there is none.
  static ReportFormat? byId(String id) {
    for (final format in ReportFormat.values) {
      if (format.id == id) return format;
    }
    return null;
  }
}

/// Renders a [CheckRun].
///
/// Both formats carry the same four fields per violation — code, location,
/// what, remedy — because a rule that does not say how to fix it gets worked
/// around instead of obeyed, and that is as true of a machine-readable report
/// as of a human one.
String render(CheckRun run, ReportFormat format) => switch (format) {
  ReportFormat.text => _text(run),
  ReportFormat.json => _json(run),
};

String _text(CheckRun run) {
  final buffer = StringBuffer();
  for (final violation in run.violations) {
    buffer
      ..writeln('${violation.code}  ${violation.location}')
      ..writeln('  ${violation.what}')
      ..writeln(_wrap(violation.remedy, indent: '  '))
      ..writeln();
  }

  final packages = run.packagesChecked;
  final noun = packages == 1 ? 'package' : 'packages';
  if (run.isClean) {
    buffer.write('arch_check: clean — $packages $noun, no violations.');
    return buffer.toString();
  }

  final total = run.violations.length;
  buffer.writeln(
    'arch_check: $total violation${total == 1 ? '' : 's'} in $packages $noun.',
  );
  for (final entry in run.countsByCode.entries) {
    buffer.writeln('  ${entry.value.toString().padLeft(4)}  ${entry.key}');
  }
  return buffer.toString().trimRight();
}

String _json(CheckRun run) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert({
    'violations': run.violations.map((v) => v.toJson()).toList(),
    'summary': {
      'packagesChecked': run.packagesChecked,
      'violationCount': run.violations.length,
      'countsByCode': run.countsByCode,
      'clean': run.isClean,
    },
  });
}

/// Wraps a remedy to 78 columns so that a four-line violation stays readable
/// in a terminal and in a CI log, which is the only place anyone reads it.
String _wrap(String text, {required String indent, int width = 78}) {
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final lines = <String>[];
  var current = StringBuffer(indent);
  var empty = true;
  for (final word in words) {
    if (!empty && current.length + 1 + word.length > width) {
      lines.add(current.toString());
      current = StringBuffer(indent);
      empty = true;
    }
    if (!empty) current.write(' ');
    current.write(word);
    empty = false;
  }
  if (!empty) lines.add(current.toString());
  return lines.join('\n');
}
