import 'dart:io';

import 'package:scaffold/scaffold.dart';

void main(List<String> arguments) {
  exitCode = runCli(arguments, out: stdout, err: stderr);
}
