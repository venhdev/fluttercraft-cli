import 'dart:io';

import 'package:test/test.dart';
import 'package:buildcraft/src/core/build_record.dart';

void main() {
  group('BuildRecord', () {
    test('success factory creates record with status success', () {
      final record = BuildRecord.success(
        id: 'test-id-123',
        cmd: 'flutter build apk',
        duration: const Duration(seconds: 45),
      );

      expect(record.id, 'test-id-123');
      expect(record.status, 'success');
      expect(record.cmd, 'flutter build apk');
      expect(record.duration, closeTo(45.0, 0.1));
      expect(record.isSuccess, true);
      expect(record.isFailed, false);
    });

    test('failed factory creates record with status failed', () {
      final record = BuildRecord.failed(
        id: 'test-id-456',
        cmd: 'flutter build aab',
        duration: const Duration(seconds: 10),
      );

      expect(record.id, 'test-id-456');
      expect(record.status, 'failed');
      expect(record.isSuccess, false);
      expect(record.isFailed, true);
    });

    test('toJsonLine produces valid JSON', () {
      final record = BuildRecord.success(
        id: 'abc123',
        cmd: 'test command',
        duration: const Duration(milliseconds: 1500),
      );

      final jsonLine = record.toJsonLine();
      
      expect(jsonLine, contains('"id":"abc123"'));
      expect(jsonLine, contains('"status":"success"'));
      expect(jsonLine, contains('"cmd":"test command"'));
      expect(jsonLine, contains('"duration":1.5'));
      expect(jsonLine, contains('"timestamp":"'));
    });

    test('fromJson parses JSON correctly', () {
      final json = {
        'id': 'xyz789',
        'status': 'failed',
        'cmd': 'build command',
        'duration': 30.5,
        'timestamp': '2025-01-01T12:00:00.000Z',
      };

      final record = BuildRecord.fromJson(json);

      expect(record.id, 'xyz789');
      expect(record.status, 'failed');
      expect(record.cmd, 'build command');
      expect(record.duration, 30.5);
      expect(record.timestamp.year, 2025);
    });

    test('toMap and fromJson are inverse operations', () {
      final original = BuildRecord.success(
        id: 'round-trip-test',
        cmd: 'flutter build ipa',
        duration: const Duration(minutes: 2),
      );

      final json = original.toMap();
      final restored = BuildRecord.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.status, original.status);
      expect(restored.cmd, original.cmd);
      expect(restored.duration, original.duration);
    });
  });

  group('BuildHistory', () {
    late String tempDir;
    late BuildHistory history;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('buildhistory_test_').path;
      history = BuildHistory(projectRoot: tempDir);
    });

    tearDown(() async {
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (_) {}
    });

    test('append creates history file and writes record', () async {
      final record = BuildRecord.success(
        id: 'test-1',
        cmd: 'flutter build',
        duration: const Duration(seconds: 10),
      );

      await history.append(record);

      final historyFile = File(history.historyPath);
      expect(await historyFile.exists(), true);

      final content = await historyFile.readAsString();
      expect(content, contains('"id":"test-1"'));
    });

    test('readAll returns empty list when no history', () async {
      final records = await history.readAll();
      expect(records, isEmpty);
    });

    test('readAll returns all appended records', () async {
      await history.append(BuildRecord.success(
        id: 'build-1',
        cmd: 'cmd 1',
        duration: const Duration(seconds: 1),
      ));
      await history.append(BuildRecord.failed(
        id: 'build-2',
        cmd: 'cmd 2',
        duration: const Duration(seconds: 2),
      ));
      await history.append(BuildRecord.success(
        id: 'build-3',
        cmd: 'cmd 3',
        duration: const Duration(seconds: 3),
      ));

      final records = await history.readAll();

      expect(records.length, 3);
      expect(records[0].id, 'build-1');
      expect(records[1].id, 'build-2');
      expect(records[2].id, 'build-3');
    });

    test('lastBuild returns most recent record', () async {
      await history.append(BuildRecord.success(
        id: 'first',
        cmd: 'cmd',
        duration: const Duration(seconds: 1),
      ));
      await history.append(BuildRecord.failed(
        id: 'last',
        cmd: 'cmd',
        duration: const Duration(seconds: 1),
      ));

      final last = await history.lastBuild();

      expect(last, isNotNull);
      expect(last!.id, 'last');
    });

    test('lastBuild returns null when no history', () async {
      final last = await history.lastBuild();
      expect(last, isNull);
    });

    test('recentBuilds returns limited results in reverse order', () async {
      for (var i = 1; i <= 15; i++) {
        await history.append(BuildRecord.success(
          id: 'build-$i',
          cmd: 'cmd',
          duration: const Duration(seconds: 1),
        ));
      }

      final recent = await history.recentBuilds(limit: 5);

      expect(recent.length, 5);
      expect(recent[0].id, 'build-15'); // most recent first
      expect(recent[4].id, 'build-11');
    });

    test('filterByStatus returns only matching records', () async {
      await history.append(BuildRecord.success(
        id: 's1',
        cmd: 'cmd',
        duration: const Duration(seconds: 1),
      ));
      await history.append(BuildRecord.failed(
        id: 'f1',
        cmd: 'cmd',
        duration: const Duration(seconds: 1),
      ));
      await history.append(BuildRecord.success(
        id: 's2',
        cmd: 'cmd',
        duration: const Duration(seconds: 1),
      ));

      final successes = await history.filterByStatus('success');
      final failures = await history.filterByStatus('failed');

      expect(successes.length, 2);
      expect(failures.length, 1);
      expect(failures[0].id, 'f1');
    });
  });
}
