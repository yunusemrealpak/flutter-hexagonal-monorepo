import 'dart:io';

import 'package:arch_check/arch_check.dart';

void main(List<String> arguments) {
  final code = runCli(arguments, out: stdout, err: stderr);
  exitCode = code;
}
