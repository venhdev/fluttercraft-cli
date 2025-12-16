import 'dart:io';

import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';

/// Tests for flavor resolution in v0.1.1
void main() {
  group('BuildConfig - Flavor Resolution (v0.1.1)', () {
    late String tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('flavor_test_').path;
    });

    tearDown(() async {
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (_) {}
    });

    group('flavor override', () {
      test('applies dev flavor overrides', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  name: 1.0.0
  number: 1
  flags:
    should_add_dart_define: false
    should_clean: false
    should_build_runner: false

build:
  <<: *build_defaults
  flavor: dev

flavors:
  dev:
    flags:
      should_add_dart_define: true
    dart_define:
      IS_DEV: true
      LOG_LEVEL: debug
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.flavor, 'dev');
        expect(config.shouldAddDartDefine, true); // overridden by flavor
        expect(config.shouldClean, false); // not overridden
        expect(config.dartDefine['IS_DEV'], true);
        expect(config.dartDefine['LOG_LEVEL'], 'debug');
      });

      test('applies staging flavor with version override', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  name: 1.0.0
  number: 1

build:
  <<: *build_defaults
  flavor: staging

flavors:
  staging:
    name: 1.0.0-rc.1
    number: 99
    flags:
      should_add_dart_define: true
      should_clean: true
    dart_define:
      IS_STAGING: true
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.flavor, 'staging');
        expect(config.buildName, '1.0.0-rc.1'); // overridden
        expect(config.buildNumber, 99); // overridden
        expect(config.shouldAddDartDefine, true);
        expect(config.shouldClean, true);
        expect(config.dartDefine['IS_STAGING'], true);
      });

      test('applies prod flavor with all flags', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  name: 1.0.0
  number: 1
  flags:
    should_add_dart_define: false
    should_clean: false
    should_build_runner: false

build:
  <<: *build_defaults
  flavor: prod

flavors:
  prod:
    flags:
      should_add_dart_define: true
      should_clean: true
      should_build_runner: true
    dart_define:
      IS_PROD: true
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.flavor, 'prod');
        expect(config.shouldAddDartDefine, true);
        expect(config.shouldClean, true);
        expect(config.shouldBuildRunner, true);
        expect(config.dartDefine['IS_PROD'], true);
      });

      test('throws error when flavor not found in flavors section', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp

build:
  <<: *build_defaults
  flavor: nonexistent

flavors:
  dev:
    dart_define:
      IS_DEV: true
''');

        expect(
          () => BuildConfig.load(configPath: configFile.path),
          throwsA(
            isA<ConfigParseException>().having(
              (e) => e.message,
              'message',
              contains('Flavor "nonexistent" not found'),
            ),
          ),
        );
      });

      test('null flavor does not apply any flavor overrides', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  name: 1.0.0
  number: 1
  flags:
    should_add_dart_define: false

build:
  <<: *build_defaults
  flavor: null

flavors:
  dev:
    flags:
      should_add_dart_define: true
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.flavor, isNull);
        expect(config.shouldAddDartDefine, false); // no override applied
      });

      test('empty string flavor treated as null', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  flags:
    should_clean: false

build:
  <<: *build_defaults
  flavor: ""

flavors:
  dev:
    flags:
      should_clean: true
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        // Empty string is NOT null, but isNotEmpty check should handle it
        expect(config.shouldClean, false); // no override applied
      });
    });

    group('flavor output path', () {
      test('appends flavor to output path when flavor is set', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp

build:
  <<: *build_defaults
  flavor: dev

flavors:
  dev:
    dart_define:
      IS_DEV: true

paths:
  output: dist
''');

        final config = await BuildConfig.load(
          configPath: configFile.path,
          projectRoot: tempDir,
        );

        expect(config.outputPath, 'dist');
        // absoluteOutputPath should include flavor
        expect(config.absoluteOutputPath, contains('dist'));
        expect(config.absoluteOutputPath, contains('dev'));
      });

      test('does not append flavor when flavor is null', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp

build:
  <<: *build_defaults
  flavor: null

paths:
  output: dist
''');

        final config = await BuildConfig.load(
          configPath: configFile.path,
          projectRoot: tempDir,
        );

        expect(config.absoluteOutputPath, endsWith('dist'));
        expect(config.absoluteOutputPath, isNot(contains('null')));
      });
    });

    group('partial flavor overrides', () {
      test('flavor only overrides specified values', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  name: 1.0.0
  number: 1
  type: aab
  target: lib/main.dart
  flags:
    should_add_dart_define: false
    should_clean: false
    should_build_runner: false

build:
  <<: *build_defaults
  flavor: minimal

flavors:
  minimal:
    # Only override one flag
    flags:
      should_clean: true
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        // These should remain from defaults
        expect(config.buildName, '1.0.0');
        expect(config.buildNumber, 1);
        expect(config.buildType, 'aab');
        expect(config.targetDart, 'lib/main.dart');
        expect(config.shouldAddDartDefine, false);
        expect(config.shouldBuildRunner, false);

        // This should be overridden
        expect(config.shouldClean, true);
      });
    });
  });
}
