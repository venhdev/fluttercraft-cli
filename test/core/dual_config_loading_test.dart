import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:fluttercraft/src/core/build_config.dart';

void main() {
  group('Dual Config Loading', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fluttercraft_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('loads from fluttercraft.yaml when it exists', () async {
      // Create pubspec.yaml
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: testapp
version: 1.0.0+1
''');

      // Create fluttercraft.yaml with root key
      final configFile = File(p.join(tempDir.path, 'fluttercraft.yaml'));
      await configFile.writeAsString('''
fluttercraft:
  build:
    platform: apk
    target: lib/main.dart
''');

      final config = await BuildConfig.load(projectRoot: tempDir.path);

      expect(config.platform, equals('apk'));
      expect(config.targetDart, equals('lib/main.dart'));
    });

    test('loads from embedded pubspec.yaml when no separate file', () async {
      // Create pubspec.yaml with embedded config
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: testapp
version: 1.0.0+1

fluttercraft:
  build:
    platform: ipa
    target: lib/main_prod.dart
''');

      final config = await BuildConfig.load(projectRoot: tempDir.path);

      expect(config.platform, equals('ipa'));
      expect(config.targetDart, equals('lib/main_prod.dart'));
    });

    test('uses defaults when no config found', () async {
      // Create minimal pubspec.yaml without fluttercraft section
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: testapp
version: 1.0.0+1
''');

      final config = await BuildConfig.load(projectRoot: tempDir.path);

      expect(config.platform, equals('aab')); // default
      expect(config.targetDart, equals('lib/main.dart')); // default
      expect(config.appName, equals('testapp')); // from pubspec
    });

    test('separate file takes precedence over embedded config', () async {
      // Create pubspec.yaml with embedded config
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: testapp
version: 1.0.0+1

fluttercraft:
  build:
    platform: ipa
''');

      // Create separate fluttercraft.yaml
      final configFile = File(p.join(tempDir.path, 'fluttercraft.yaml'));
      await configFile.writeAsString('''
fluttercraft:
  build:
    platform: apk
''');

      final config = await BuildConfig.load(projectRoot: tempDir.path);

      // Should use separate file (apk), not embedded (ipa)
      expect(config.platform, equals('apk'));
    });

    test('throws error when fluttercraft.yaml missing root key', () async {
      // Create pubspec.yaml
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: testapp
version: 1.0.0+1
''');

      // Create fluttercraft.yaml WITHOUT root key (old format)
      final configFile = File(p.join(tempDir.path, 'fluttercraft.yaml'));
      await configFile.writeAsString('''
build_defaults:
  platform: apk
build:
  platform: aab
''');

      expect(
        () => BuildConfig.load(projectRoot: tempDir.path),
        throwsA(isA<ConfigParseException>().having(
          (e) => e.toString(),
          'error message',
          contains('must have "fluttercraft:" as root key'),
        )),
      );
    });

    test('error message includes migration guidance', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: test\nversion: 1.0.0+1');

      final configFile = File(p.join(tempDir.path, 'fluttercraft.yaml'));
      await configFile.writeAsString('build:\n  platform: apk');

      try {
        await BuildConfig.load(projectRoot: tempDir.path);
        fail('Should have thrown ConfigParseException');
      } catch (e) {
        expect(e.toString(), contains('fluttercraft gen -f'));
        expect(e.toString(), contains('manually add "fluttercraft:" root key'));
      }
    });

    test('loads config with YAML anchors correctly', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('name: test\nversion: 1.0.0+1');

      final configFile = File(p.join(tempDir.path, 'fluttercraft.yaml'));
      await configFile.writeAsString('''
fluttercraft:
  build_defaults: &defaults
    platform: aab
    target: lib/main.dart
    
  build:
    <<: *defaults
    flavor: dev
    
  flavors:
    dev:
      platform: aab
''');

      final config = await BuildConfig.load(projectRoot: tempDir.path);

      expect(config.platform, equals('aab'));
      expect(config.targetDart, equals('lib/main.dart'));
      expect(config.flavor, equals('dev'));
    });
  });
}
