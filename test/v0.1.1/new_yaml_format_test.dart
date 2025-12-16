import 'dart:io';

import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';

/// Tests for new v0.1.1 YAML format with build_defaults, flavors, and environments
void main() {
  group('BuildConfig - New YAML Format (v0.1.1)', () {
    late String tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('buildconfig_v011_').path;
    });

    tearDown(() async {
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (_) {}
    });

    group('build_defaults parsing', () {
      test('parses build_defaults anchor correctly', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  name: 2.0.0
  number: 10
  type: apk
  target: lib/main_dev.dart
  flags:
    should_add_dart_define: true
    should_clean: false
    should_build_runner: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.appName, 'myapp');
        expect(config.buildName, '2.0.0');
        expect(config.buildNumber, 10);
        expect(config.buildType, 'apk');
        expect(config.targetDart, 'lib/main_dev.dart');
        expect(config.shouldAddDartDefine, true);
        expect(config.shouldClean, false);
        expect(config.shouldBuildRunner, true);
      });

      test('build section overrides build_defaults', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: baseapp
  name: 1.0.0
  number: 1
  type: aab

build:
  <<: *build_defaults
  name: 2.0.0
  number: 99
  type: apk
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.appName, 'baseapp'); // from defaults
        expect(config.buildName, '2.0.0'); // overridden
        expect(config.buildNumber, 99); // overridden
        expect(config.buildType, 'apk'); // overridden
      });
    });

    group('environments section', () {
      test('parses fvm from environments', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp

build:
  <<: *build_defaults
  flavor: null

environments:
  fvm:
    enabled: true
    version: 3.24.0
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.useFvm, true);
        expect(config.flutterVersion, '3.24.0');
      });

      test('parses shorebird from environments', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp

build:
  <<: *build_defaults
  flavor: null

environments:
  shorebird:
    enabled: true
    app_id: abc-123-def
    artifact: apk
    no_confirm: false
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.useShorebird, true);
        expect(config.shorebirdAppId, 'abc-123-def');
        expect(config.shorebirdArtifact, 'apk');
        expect(config.shorebirdNoConfirm, false);
      });

      test('parses bundletool from environments', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp

build:
  <<: *build_defaults
  flavor: null

environments:
  bundletool:
    path: /tools/bundletool.jar
    keystore: keys/my.properties
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.bundletoolPath, '/tools/bundletool.jar');
        expect(config.keystorePath, 'keys/my.properties');
      });

      test('handles missing environments section gracefully', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.useFvm, false);
        expect(config.useShorebird, false);
        expect(config.noColor, false);
      });

      test('parses no_color from environments', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp

build:
  <<: *build_defaults
  flavor: null

environments:
  no_color: true
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.noColor, true);
      });

      test('no_color defaults to false when not specified', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp

build:
  <<: *build_defaults
  flavor: null

environments:
  fvm:
    enabled: true
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.noColor, false);
      });
    });

    group('paths section', () {
      test('parses output path', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp

build:
  <<: *build_defaults
  flavor: null

paths:
  output: custom/output
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.outputPath, 'custom/output');
      });
    });

    group('flags with new names', () {
      test('parses should_add_dart_define flag', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp
  flags:
    should_add_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.shouldAddDartDefine, true);
        expect(config.flags.shouldAddDartDefine, true);
      });

      test('parses should_clean flag', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp
  flags:
    should_clean: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.shouldClean, true);
        expect(config.flags.shouldClean, true);
      });

      test('parses should_build_runner flag', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp
  flags:
    should_build_runner: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.shouldBuildRunner, true);
        expect(config.flags.shouldBuildRunner, true);
      });

      test('flags default to false when not specified', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.shouldAddDartDefine, false);
        expect(config.shouldClean, false);
        expect(config.shouldBuildRunner, false);
      });
    });
  });
}
