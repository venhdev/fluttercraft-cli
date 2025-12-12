import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'console.dart';

/// Result of running an external process
class ProcessResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final bool success;

  ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  }) : success = exitCode == 0;

  @override
  String toString() => 'ProcessResult(exitCode: $exitCode, success: $success)';
}

/// Utility class for running external processes (flutter, fvm, shorebird, etc.)
class ProcessRunner {
  final Console _console;
  final bool verbose;

  ProcessRunner({
    Console? console,
    this.verbose = false,
  }) : _console = console ?? Console();

  /// Run a command and wait for completion
  /// 
  /// [command] - The command to run (e.g., 'flutter', 'fvm')
  /// [args] - Arguments for the command
  /// [workingDirectory] - Working directory for the command
  /// [streamOutput] - Whether to stream stdout/stderr in real-time
  Future<ProcessResult> run(
    String command,
    List<String> args, {
    String? workingDirectory,
    bool streamOutput = true,
    Map<String, String>? environment,
  }) async {
    final fullCommand = '$command ${args.join(' ')}';
    
    if (verbose) {
      _console.info('Running: $fullCommand');
    }

    try {
      final process = await Process.start(
        command,
        args,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: Platform.isWindows,
      );

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      // Stream stdout
      final stdoutCompleter = Completer<void>();
      process.stdout.transform(utf8.decoder).listen(
        (data) {
          stdoutBuffer.write(data);
          if (streamOutput) {
            stdout.write(data);
          }
        },
        onDone: () => stdoutCompleter.complete(),
        onError: (e) => stdoutCompleter.completeError(e),
      );

      // Stream stderr
      final stderrCompleter = Completer<void>();
      process.stderr.transform(utf8.decoder).listen(
        (data) {
          stderrBuffer.write(data);
          if (streamOutput) {
            stderr.write(data);
          }
        },
        onDone: () => stderrCompleter.complete(),
        onError: (e) => stderrCompleter.completeError(e),
      );

      // Wait for process to complete
      final exitCode = await process.exitCode;
      await Future.wait([stdoutCompleter.future, stderrCompleter.future]);

      final result = ProcessResult(
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
      );

      if (verbose) {
        if (result.success) {
          _console.success('Command completed with exit code: $exitCode');
        } else {
          _console.error('Command failed with exit code: $exitCode');
        }
      }

      return result;
    } catch (e) {
      _console.error('Failed to execute: $fullCommand');
      _console.error('Error: $e');
      return ProcessResult(
        exitCode: -1,
        stdout: '',
        stderr: e.toString(),
      );
    }
  }

  /// Run a command and capture output without streaming
  Future<ProcessResult> runSilent(
    String command,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    return run(
      command,
      args,
      workingDirectory: workingDirectory,
      streamOutput: false,
      environment: environment,
    );
  }

  /// Run flutter command (with FVM support)
  Future<ProcessResult> flutter(
    List<String> args, {
    String? workingDirectory,
    bool useFvm = false,
    bool streamOutput = true,
  }) async {
    if (useFvm) {
      return run('fvm', ['flutter', ...args],
          workingDirectory: workingDirectory, streamOutput: streamOutput);
    }
    return run('flutter', args,
        workingDirectory: workingDirectory, streamOutput: streamOutput);
  }

  /// Run dart command (with FVM support)
  Future<ProcessResult> dart(
    List<String> args, {
    String? workingDirectory,
    bool useFvm = false,
    bool streamOutput = true,
  }) async {
    if (useFvm) {
      return run('fvm', ['dart', ...args],
          workingDirectory: workingDirectory, streamOutput: streamOutput);
    }
    return run('dart', args,
        workingDirectory: workingDirectory, streamOutput: streamOutput);
  }

  /// Run shorebird command
  Future<ProcessResult> shorebird(
    List<String> args, {
    String? workingDirectory,
    bool streamOutput = true,
  }) async {
    return run('shorebird', args,
        workingDirectory: workingDirectory, streamOutput: streamOutput);
  }

  /// Check if a command exists on the system
  Future<bool> commandExists(String command) async {
    try {
      final result = await runSilent(
        Platform.isWindows ? 'where.exe' : 'which',
        [command],
      );
      return result.success;
    } catch (e) {
      return false;
    }
  }
}
