import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Record of a single build attempt for JSONL logging
class BuildRecord {
  final String id;
  final String status; // "success" | "failed"
  final String cmd;
  final double duration; // seconds
  final DateTime timestamp;

  BuildRecord({
    required this.id,
    required this.status,
    required this.cmd,
    required this.duration,
    required this.timestamp,
  });

  /// Create a success record
  factory BuildRecord.success({
    required String id,
    required String cmd,
    required Duration duration,
  }) {
    return BuildRecord(
      id: id,
      status: 'success',
      cmd: cmd,
      duration: duration.inMilliseconds / 1000.0,
      timestamp: DateTime.now().toUtc(),
    );
  }

  /// Create a failed record
  factory BuildRecord.failed({
    required String id,
    required String cmd,
    required Duration duration,
  }) {
    return BuildRecord(
      id: id,
      status: 'failed',
      cmd: cmd,
      duration: duration.inMilliseconds / 1000.0,
      timestamp: DateTime.now().toUtc(),
    );
  }

  /// Parse from JSON
  factory BuildRecord.fromJson(Map<String, dynamic> json) {
    return BuildRecord(
      id: json['id'] as String,
      status: json['status'] as String,
      cmd: json['cmd'] as String,
      duration: (json['duration'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'cmd': cmd,
      'duration': duration,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Convert to JSONL line
  String toJsonLine() => jsonEncode(toMap());

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';

  @override
  String toString() => 'BuildRecord($id, $status, ${duration}s)';
}

/// Manages build history in JSONL format
class BuildHistory {
  static const String _historyDir = '.fluttercraft';
  static const String _historyFile = 'build_history.jsonl';

  final String projectRoot;

  BuildHistory({required this.projectRoot});

  /// Get path to history file
  String get historyPath => p.join(projectRoot, _historyDir, _historyFile);

  /// Get path to .fluttercraft directory
  String get fluttercraftDir => p.join(projectRoot, _historyDir);

  /// Append a record to history
  Future<void> append(BuildRecord record) async {
    final dir = Directory(fluttercraftDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(historyPath);
    await file.writeAsString(
      '${record.toJsonLine()}\n',
      mode: FileMode.append,
    );
  }

  /// Read all records from history
  Future<List<BuildRecord>> readAll() async {
    final file = File(historyPath);
    if (!await file.exists()) {
      return [];
    }

    final lines = await file.readAsLines();
    final records = <BuildRecord>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        records.add(BuildRecord.fromJson(json));
      } catch (_) {
        // Skip corrupted lines
      }
    }

    return records;
  }

  /// Get the most recent build record
  Future<BuildRecord?> lastBuild() async {
    final records = await readAll();
    if (records.isEmpty) return null;
    return records.last;
  }

  /// Get recent builds (most recent first)
  Future<List<BuildRecord>> recentBuilds({int limit = 10}) async {
    final records = await readAll();
    final reversed = records.reversed.toList();
    if (reversed.length <= limit) return reversed;
    return reversed.sublist(0, limit);
  }

  /// Filter builds by status
  Future<List<BuildRecord>> filterByStatus(String status) async {
    final records = await readAll();
    return records.where((r) => r.status == status).toList();
  }
}

