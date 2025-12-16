import 'dart:io';

import 'package:test/test.dart';
import 'package:fluttercraft/src/utils/build_logger.dart';

void main() {
  group('BuildLogger', () {
    late String tempDir;
    late BuildLogger logger;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('buildlogger_test_').path;
      logger = BuildLogger(projectRoot: tempDir, buildId: 'test-build-123');
    });

    tearDown(() async {
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (_) {}
    });

    test('init creates .fluttercraft and logs directories', () async {
      await logger.init();

      expect(await Directory(logger.fluttercraftPath).exists(), true);
      expect(await Directory(logger.logsPath).exists(), true);
    });

    test('startSession creates both log files', () async {
      await logger.startSession(version: '1.0.0');

      expect(await File(logger.latestLogPath).exists(), true);
      expect(await File(logger.buildLogPath).exists(), true);

      await logger.endSession();
    });

    test('log writes to both files', () async {
      await logger.startSession();

      logger.info('Test info message');
      logger.warning('Test warning');
      logger.error('Test error');

      await logger.endSession();

      final latestContent = await File(logger.latestLogPath).readAsString();
      final buildContent = await File(logger.buildLogPath).readAsString();

      expect(latestContent, contains('[INFO] Test info message'));
      expect(latestContent, contains('[WARN] Test warning'));
      expect(latestContent, contains('[ERROR] Test error'));

      expect(buildContent, contains('[INFO] Test info message'));
      expect(buildContent, contains('[WARN] Test warning'));
      expect(buildContent, contains('[ERROR] Test error'));
    });

    test('endSession writes footer with build status', () async {
      await logger.startSession(version: '2.0.0');
      await logger.endSession(
        success: true,
        duration: const Duration(seconds: 30),
        outputPath: '/path/to/output.apk',
      );

      final content = await File(logger.latestLogPath).readAsString();

      expect(content, contains('Build COMPLETED'));
      expect(content, contains('Build ID: test-build-123'));
      expect(content, contains('Duration: 30s'));
      expect(content, contains('Output: /path/to/output.apk'));
    });

    test('failed build shows FAILED in footer', () async {
      await logger.startSession();
      await logger.endSession(success: false);

      final content = await File(logger.latestLogPath).readAsString();
      expect(content, contains('Build FAILED'));
    });

    test('section writes separator with title', () async {
      await logger.startSession();
      logger.section('Build Phase');
      await logger.endSession();

      final content = await File(logger.latestLogPath).readAsString();
      expect(content, contains('Build Phase'));
      expect(content, contains('─' * 60));
    });

    test('output splits and logs each line', () async {
      await logger.startSession();
      logger.output('Line 1\nLine 2\n\nLine 3');
      await logger.endSession();

      final content = await File(logger.latestLogPath).readAsString();
      expect(content, contains('[OUT] Line 1'));
      expect(content, contains('[OUT] Line 2'));
      expect(content, contains('[OUT] Line 3'));
    });

    test('buildLogPath uses build ID', () {
      expect(logger.buildLogPath, contains('test-build-123.log'));
    });
  });
}
