import 'dart:convert';
import 'dart:io';

/// What a command left behind.
final class CommandResult {
  /// Creates a result.
  const CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  /// The process's exit code.
  final int exitCode;

  /// Captured standard output, empty when the command inherited the console.
  final String stdout;

  /// Captured standard error, empty when the command inherited the console.
  final String stderr;

  /// Whether the command succeeded.
  bool get ok => exitCode == 0;
}

/// Runs an external command.
///
/// An interface because every interesting decision this tool makes — which
/// packages changed, which runner to use, whether a suite passed — is decided
/// by what a subprocess said, and a test that has to launch `git` and
/// `flutter` to check the decision is not a test of the decision.
abstract interface class CommandRunner {
  /// Runs [executable] with [arguments].
  ///
  /// When [inheritStdio] is true the child writes straight to this process's
  /// console and [CommandResult.stdout] comes back empty. That is what a test
  /// suite wants: a runner that buffered a ten-minute `flutter test` and
  /// printed it at the end would look hung.
  Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool inheritStdio = false,
  });
}

/// The real one.
final class SystemCommandRunner implements CommandRunner {
  /// Creates the runner.
  const SystemCommandRunner();

  @override
  Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool inheritStdio = false,
  }) async {
    if (inheritStdio) {
      final process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        mode: ProcessStartMode.inheritStdio,
      );
      return CommandResult(
        exitCode: await process.exitCode,
        stdout: '',
        stderr: '',
      );
    }

    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return CommandResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }
}
