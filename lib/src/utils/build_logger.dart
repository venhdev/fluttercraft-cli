import 'dart:io';

import 'package:path/path.dart' as p;

/// Logger utility for writing build logs to .fluttercraft/ directory
/// 
/// Log structure:
/// - `.fluttercraft/build_latest.log`  - Overwritten each run
/// - `.fluttercraft/logs/{uuid}.log`   - Per-build log file
class BuildLogger {
  final String projectRoot;
  final String buildId;
  
  IOSink? _latestSink;
  IOSink? _buildSink;
  
  static const String _fluttercraftDir = '.fluttercraft';
  static const String _logsDir = 'logs';
  static const String _latestLogName = 'build_latest.log';

  BuildLogger({
    required this.projectRoot,
    required this.buildId,
  });

  /// Get .fluttercraft directory path
  String get fluttercraftPath => p.join(projectRoot, _fluttercraftDir);
  
  /// Get logs directory path
  String get logsPath => p.join(fluttercraftPath, _logsDir);
  
  /// Get path to latest log
  String get latestLogPath => p.join(fluttercraftPath, _latestLogName);
  
  /// Get path to this build's log
  String get buildLogPath => p.join(logsPath, '$buildId.log');

  /// Initialize logger and create directories
  Future<void> init() async {
    // Create .fluttercraft directory
    final fluttercraftDir = Directory(fluttercraftPath);
    if (!await fluttercraftDir.exists()) {
      await fluttercraftDir.create(recursive: true);
    }
    
    // Create logs subdirectory
    final logsDir = Directory(logsPath);
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
  }

  /// Start a new log session
  Future<void> startSession({String? version}) async {
    await init();
    
    // Open both sinks
    _latestSink = File(latestLogPath).openWrite();
    _buildSink = File(buildLogPath).openWrite();
    
    // Write header to both
    _writeHeader(version);
  }

  void _writeHeader(String? version) {
    final header = '''
════════════════════════════════════════════════════════════════
  fluttercraft CLI - Build Log
  Build ID: $buildId
  Started: ${DateTime.now()}
  Version: ${version ?? 'N/A'}
════════════════════════════════════════════════════════════════

''';
    _latestSink?.write(header);
    _buildSink?.write(header);
  }

  /// Log a message to both files
  void log(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    final line = '[$timestamp] $message\n';
    _latestSink?.write(line);
    _buildSink?.write(line);
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
    _latestSink?.write(content);
    _buildSink?.write(content);
  }

  /// End the log session
  Future<void> endSession({
    bool success = true,
    Duration? duration,
    String? outputPath,
  }) async {
    final footer = '''

════════════════════════════════════════════════════════════════
  Build ${success ? 'COMPLETED' : 'FAILED'}
  Build ID: $buildId
  Ended: ${DateTime.now()}
  Duration: ${duration?.inSeconds ?? 0}s
  Output: ${outputPath ?? 'N/A'}
════════════════════════════════════════════════════════════════
''';
    _latestSink?.write(footer);
    _buildSink?.write(footer);
    
    // Close both sinks
    await _latestSink?.flush();
    await _latestSink?.close();
    await _buildSink?.flush();
    await _buildSink?.close();
    
    _latestSink = null;
    _buildSink = null;
  }
}

