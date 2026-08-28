import 'dart:io';

import 'package:test_runner/test_runner.dart';

/// The entrypoint, and the only place that calls `exit()`.
Future<void> main(List<String> arguments) async {
  exitCode = await runCli(arguments, out: stdout, err: stderr);
}
