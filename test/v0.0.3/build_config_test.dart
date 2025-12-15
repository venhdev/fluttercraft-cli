import 'dart:io';

import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';

void main() {
  group('BuildConfig', () {
    late String tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('buildconfig_test_').path;
    });

    tearDown(() async {
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (_) {}
    });

    test('returns default config when file does not exist', () async {
      final config = await BuildConfig.load(configPath: '$tempDir/nonexistent.yaml');
      
      expect(config.appName, 'app'); // default
      expect(config.buildName, '1.0.0'); // default
      expect(config.useFvm, false); // default
    });

    test('parses minimal config with defaults', () async {
      // Create minimal config file
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp
''');

      final config = await BuildConfig.load(configPath: configFile.path);

      expect(config.appName, 'testapp');
      expect(config.buildName, '1.0.0'); // default
      expect(config.buildNumber, 1); // default
      expect(config.buildType, 'aab'); // default
      expect(config.targetDart, 'lib/main.dart'); // default
      expect(config.outputPath, 'dist'); // default
      expect(config.useFvm, false); // default
      expect(config.useShorebird, false); // default
    });

    test('parses full config correctly', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: myapp

build:
  name: 2.0.0
  number: 42
  type: apk
  flavor: staging
  target: lib/main_staging.dart

paths:
  output: build/output
  env: .env.staging

flags:
  use_dart_define: true
  need_clean: true
  need_build_runner: true

fvm:
  enabled: true
  version: 3.24.0

shorebird:
  enabled: true
  artifact: apk
  no_confirm: false

bundletool:
  path: /tools/bundletool.jar
  keystore: keys/release.properties
''');

      final config = await BuildConfig.load(configPath: configFile.path);

      expect(config.appName, 'myapp');
      expect(config.buildName, '2.0.0');
      expect(config.buildNumber, 42);
      expect(config.buildType, 'apk');
      expect(config.flavor, 'staging');
      expect(config.targetDart, 'lib/main_staging.dart');
      expect(config.outputPath, 'build/output');
      expect(config.envPath, '.env.staging');
      expect(config.useDartDefine, true);
      expect(config.needClean, true);
      expect(config.needBuildRunner, true);
      expect(config.useFvm, true);
      expect(config.flutterVersion, '3.24.0');
      expect(config.useShorebird, true);
      expect(config.shorebirdArtifact, 'apk');
      expect(config.shorebirdNoConfirm, false);
      expect(config.bundletoolPath, '/tools/bundletool.jar');
      expect(config.keystorePath, 'keys/release.properties');
    });

    test('fullVersion combines buildName and buildNumber', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
build:
  name: 1.2.3
  number: 99
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      expect(config.fullVersion, '1.2.3+99');
    });

    test('fullAppName includes shorebird suffix when enabled', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp
build:
  name: 1.0.0
  number: 1
shorebird:
  enabled: true
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      expect(config.fullAppName, 'testapp_1.0.0+1.sb.base');
    });

    test('throws ConfigParseException for empty file', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('');

      expect(
        () => BuildConfig.load(configPath: configFile.path),
        throwsA(isA<ConfigParseException>()),
      );
    });

    test('auto-detects FVM version from .fvmrc when version is null', () async {
      // Create .fvmrc file in temp directory
      final fvmrcFile = File('$tempDir/.fvmrc');
      await fvmrcFile.writeAsString('''{
  "flutter": "3.35.3"
}''');

      // Create config with FVM enabled but version null
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

fvm:
  enabled: true
  version: null
''');

      // Change to temp directory to test detection
      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        final config = await BuildConfig.load(configPath: configFile.path);
        
        expect(config.useFvm, true);
        expect(config.flutterVersion, '3.35.3');
      } finally {
        Directory.current = originalDir;
      }
    });

    test('uses explicit version when provided even if .fvmrc exists', () async {
      // Create .fvmrc file
      final fvmrcFile = File('$tempDir/.fvmrc');
      await fvmrcFile.writeAsString('''{
  "flutter": "3.35.3"
}''');

      // Create config with explicit version
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

fvm:
  enabled: true
  version: 3.24.0
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      
      expect(config.useFvm, true);
      expect(config.flutterVersion, '3.24.0'); // Should use explicit version
    });
  });
}

