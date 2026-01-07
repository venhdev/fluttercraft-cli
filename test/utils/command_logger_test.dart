import 'dart:io';

import 'package:fluttercraft/src/utils/command_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('CommandLogger', () {
    late Directory tempDir;
    late String projectRoot;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fluttercraft_logger_test_');
      projectRoot = tempDir.path;
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should generate correct log path', () {
      final logger = CommandLogger(
        projectRoot: projectRoot,
        commandName: 'test_cmd',
      );

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      expect(
        logger.logFilePath,
        contains(p.join('.fluttercraft', 'logs', 'test_cmd', 'test_cmd-$dateStr.log')),
      );
    });

    test('should create directories and write log', () async {
      final logger = CommandLogger(
        projectRoot: projectRoot,
        commandName: 'test_cmd',
      );

      await logger.startSession(version: '1.2.3');
      logger.info('Hello World');
      await logger.endSession(success: true);

      final logFile = File(logger.logFilePath);
      expect(await logFile.exists(), isTrue);

      final content = await logFile.readAsString();
      expect(content, contains('fluttercraft CLI - TEST_CMD Session'));
      expect(content, contains('[INFO] Hello World'));
      expect(content, contains('Result: COMPLETED'));
    });

    test('should append to existing log file', () async {
      final logger = CommandLogger(
        projectRoot: projectRoot,
        commandName: 'test_cmd',
      );

      // First session
      await logger.startSession(version: '1.0.0');
      logger.info('Session 1');
      await logger.endSession(success: true);

      // Second session
      await logger.startSession(version: '1.0.0');
      logger.info('Session 2');
      await logger.endSession(success: true);

      final logFile = File(logger.logFilePath);
      final content = await logFile.readAsString();
      
      expect(content, contains('Session 1'));
      expect(content, contains('Session 2'));
      // Should have two headers
      expect('TEST_CMD Session'.allMatches(content).length, equals(2));
    });
  });
}
