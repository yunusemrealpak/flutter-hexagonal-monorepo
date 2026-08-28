import 'dart:io';

import 'package:dep_graph/dep_graph.dart';

/// The entrypoint, and the only place that calls `exit()`.
void main(List<String> arguments) {
  final code = runCli(arguments, out: stdout, err: stderr);
  exitCode = code;
}
