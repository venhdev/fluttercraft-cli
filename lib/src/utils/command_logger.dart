import 'dart:io';

import 'package:path/path.dart' as p;

/// Unified logger utility for all fluttercraft CLI commands.
///
/// Log structure:
/// - `.fluttercraft/logs/<commandName>/<commandName>-YYYY-MM-DD.log`
class CommandLogger {
  final String projectRoot;
  final String commandName;
  final String? buildId;

  IOSink? _sink;
  late final String _logPath;

  static const String _fluttercraftDir = '.fluttercraft';
  static const String _logsDir = 'logs';

  CommandLogger({
    required this.projectRoot,
    required this.commandName,
    this.buildId,
  }) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _logPath = p.join(
      projectRoot,
      _fluttercraftDir,
      _logsDir,
      commandName,
      '$commandName-$dateStr.log',
    );
  }

  /// Get log directory path
  String get logsPath => p.dirname(_logPath);

  /// Get path to this command's log file
  String get logFilePath => _logPath;

  /// Initialize logger and create directories
  Future<void> init() async {
    final dir = Directory(logsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Start a new log session
  Future<void> startSession({String? version}) async {
    await init();

    // Open sink in append mode
    _sink = File(_logPath).openWrite(mode: FileMode.append);

    // Write session header
    final header = '''
════════════════════════════════════════════════════════════════
  fluttercraft CLI - ${commandName.toUpperCase()} Session
  ${buildId != null ? 'Build ID: $buildId' : ''}
  Started: ${DateTime.now()}
  Version: ${version ?? 'N/A'}
════════════════════════════════════════════════════════════════
''';
    _sink?.write(header);
  }

  /// Log a message
  void log(String message) {
    final timestamp =
        DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    final line = '[$timestamp] $message\n';
    _sink?.write(line);
  }

  /// Log an info message
  void info(String message) {
    log('[INFO] $message');
  }

  /// Log a warning message
  void warning(String message) {
    log('[WARN] $message');
  }

  /// Log an error message
  void error(String message) {
    log('[ERROR] $message');
  }

  /// Log command execution
  void command(String cmd) {
    log('[CMD] $cmd');
  }

  /// Log command output
  void output(String output) {
    for (final line in output.split('\n')) {
      if (line.trim().isNotEmpty) {
        log('[OUT] $line');
      }
    }
  }

  /// Log a section separator
  void section(String title) {
    final separator = '─' * 60;
    final content = '\n$separator\n  $title\n$separator\n\n';
    _sink?.write(content);
  }

  /// End the log session
  Future<void> endSession({
    bool? success,
    Duration? duration,
    String? outputPath,
  }) async {
    final status = success == null
        ? ''
        : (success ? 'COMPLETED' : 'FAILED');
        
    final footer = '''
  ${status.isNotEmpty ? 'Result: $status' : ''}
  Ended: ${DateTime.now()}
  ${duration != null ? 'Duration: ${duration.inSeconds}s' : ''}
  ${outputPath != null ? 'Output: $outputPath' : ''}
════════════════════════════════════════════════════════════════
\n''';
    _sink?.write(footer);

    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }
}
