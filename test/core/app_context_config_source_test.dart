import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:fluttercraft/src/core/app_context.dart';

void main() {
  group('AppContext Config Source Tracking', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fluttercraft_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('tracks config source as fluttercraft.yaml when separate file exists', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: test\nversion: 1.0.0+1');

      final configFile = File(p.join(tempDir.path, 'fluttercraft.yaml'));
      await configFile.writeAsString('''
fluttercraft:
  build:
    platform: apk
''');

      final context = await AppContext.load(projectRoot: tempDir.path);

      expect(context.configSource, equals('fluttercraft.yaml'));
      expect(context.hasConfigFile, isTrue);
    });

    test('tracks config source as embedded when only in pubspec.yaml', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: test
version: 1.0.0+1

fluttercraft:
  build:
    platform: apk
''');

      final context = await AppContext.load(projectRoot: tempDir.path);

      expect(context.configSource, equals('pubspec.yaml (fluttercraft: section)'));
      expect(context.hasConfigFile, isFalse);
    });

    test('tracks config source as defaults when no config found', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: test\nversion: 1.0.0+1');

      final context = await AppContext.load(projectRoot: tempDir.path);

      expect(context.configSource, equals('defaults (no config found)'));
      expect(context.hasConfigFile, isFalse);
    });

    test('separate file takes precedence in configSource tracking', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: test
version: 1.0.0+1

fluttercraft:
  build:
    platform: ipa
''');

      final configFile = File(p.join(tempDir.path, 'fluttercraft.yaml'));
      await configFile.writeAsString('''
fluttercraft:
  build:
    platform: apk
''');

      final context = await AppContext.load(projectRoot: tempDir.path);

      // Should track as separate file, not embedded
      expect(context.configSource, equals('fluttercraft.yaml'));
      expect(context.hasConfigFile, isTrue);
    });
  });
}
