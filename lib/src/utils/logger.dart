import 'dart:io';

import 'package:path/path.dart' as p;

/// Logger utility for writing build logs to files
class Logger {
  final String logDirectory;
  final String appName;

  IOSink? _currentLogSink;
  String? _currentLogPath;
  final List<String> _logBuffer = [];

  Logger({required this.logDirectory, this.appName = 'build'});

  /// Initialize logger and create log directory if needed
  Future<void> init() async {
    final logDir = Directory(logDirectory);
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
  }

  /// Start a new log session
  Future<String> startSession({String? version}) async {
    await init();

    // Latest log (always overwritten)
    final latestLogPath = p.join(logDirectory, '$appName-latest.log');

    // Create archive log with timestamp and version
    final timestamp =
        DateTime.now()
            .toIso8601String()
            .replaceAll(':', '-')
            .replaceAll('T', '_')
            .split('.')[0];

    final versionSuffix = version != null ? '-$version' : '';
    final archiveLogPath = p.join(
      logDirectory,
      '$appName$versionSuffix-$timestamp.log',
    );

    // Open latest log for writing
    _currentLogPath = latestLogPath;
    _currentLogSink = File(latestLogPath).openWrite();

    // Write header
    _writeHeader(version);

    // Store archive path for later
    _logBuffer.clear();
    _logBuffer.add('Archive: $archiveLogPath');

    return archiveLogPath;
  }

  void _writeHeader(String? version) {
    final header = '''
════════════════════════════════════════════════════════════════
  Mobile Build CLI - Build Log
  Started: ${DateTime.now()}
  Version: ${version ?? 'N/A'}
════════════════════════════════════════════════════════════════

''';
    _currentLogSink?.write(header);
  }

  /// Log a message
  void log(String message) {
    final timestamp =
        DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    final line = '[$timestamp] $message';
    _currentLogSink?.writeln(line);
    _logBuffer.add(line);
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
    _currentLogSink?.writeln('\n$separator');
    _currentLogSink?.writeln('  $title');
    _currentLogSink?.writeln('$separator\n');
  }

  /// End the log session and create archive
  Future<void> endSession({
    bool success = true,
    Duration? duration,
    String? outputPath,
  }) async {
    // Write footer
    final footer = '''

════════════════════════════════════════════════════════════════
  Build ${success ? 'COMPLETED' : 'FAILED'}
  Ended: ${DateTime.now()}
  Duration: ${duration?.inSeconds ?? 0}s
  Output: ${outputPath ?? 'N/A'}
════════════════════════════════════════════════════════════════
''';
    _currentLogSink?.write(footer);

    // Close the sink
    await _currentLogSink?.flush();
    await _currentLogSink?.close();
    _currentLogSink = null;

    // Copy to archive if we have an archive path
    if (_logBuffer.isNotEmpty && _currentLogPath != null) {
      final archivePath = _logBuffer.first.replaceFirst('Archive: ', '');
      if (archivePath.isNotEmpty) {
        try {
          await File(_currentLogPath!).copy(archivePath);
        } catch (e) {
          // Ignore copy errors
        }
      }
    }
  }

  /// Get the path to the latest log
  String get latestLogPath => p.join(logDirectory, '$appName-latest.log');

  /// Get the log directory path
  String get logsPath => logDirectory;
}
