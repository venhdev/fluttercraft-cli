import 'dart:io';

import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';

/// Tests for dart_define_from_file support in v0.1.2
void main() {
  group('BuildConfig - dart_define_from_file (v0.1.2)', () {
    late String tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('dart_define_from_file_test_').path;
    });

    tearDown(() async {
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (_) {}
    });

    group('global dart_define_from_file', () {
      test('parses global dart_define_from_file from build_defaults', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define_from_file: .env
  flags:
    should_add_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.globalDartDefineFromFile, equals('.env'));
        expect(config.dartDefineFromFile, equals('.env'));
        expect(config.finalDartDefineFromFile, equals('.env'));
      });

      test('returns finalDartDefineFromFile as null when should_add_dart_define is false', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define_from_file: .env
  flags:
    should_add_dart_define: false

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.globalDartDefineFromFile, equals('.env'));
        expect(config.dartDefineFromFile, equals('.env'));
        expect(config.finalDartDefineFromFile, isNull);
      });

      test('handles null dart_define_from_file gracefully', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  flags:
    should_add_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.globalDartDefineFromFile, isNull);
        expect(config.dartDefineFromFile, isNull);
        expect(config.finalDartDefineFromFile, isNull);
      });
    });

    group('flavor dart_define_from_file override', () {
      test('flavor dart_define_from_file overrides global', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define_from_file: .env
  flags:
    should_add_dart_define: true

build:
  <<: *build_defaults
  flavor: dev

flavors:
  dev:
    dart_define_from_file: .env.dev
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.globalDartDefineFromFile, equals('.env'));
        expect(config.dartDefineFromFile, equals('.env.dev'));
        expect(config.finalDartDefineFromFile, equals('.env.dev'));
      });

      test('flavor can set dart_define_from_file when global is null', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  flags:
    should_add_dart_define: true

build:
  <<: *build_defaults
  flavor: dev

flavors:
  dev:
    dart_define_from_file: .env.dev
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.globalDartDefineFromFile, isNull);
        expect(config.dartDefineFromFile, equals('.env.dev'));
        expect(config.finalDartDefineFromFile, equals('.env.dev'));
      });

      test('uses global when flavor does not specify dart_define_from_file', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define_from_file: .env
  flags:
    should_add_dart_define: true

build:
  <<: *build_defaults
  flavor: dev

flavors:
  dev:
    flags:
      should_clean: true
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.globalDartDefineFromFile, equals('.env'));
        expect(config.dartDefineFromFile, equals('.env'));
        expect(config.finalDartDefineFromFile, equals('.env'));
      });
    });

    group('dart_define_from_file file path formats', () {
      test('accepts simple .env filename', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define_from_file: .env
  flags:
    should_add_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);
        expect(config.finalDartDefineFromFile, equals('.env'));
      });

      test('accepts .env with flavor suffix', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define_from_file: .env.prod
  flags:
    should_add_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);
        expect(config.finalDartDefineFromFile, equals('.env.prod'));
      });

      test('accepts .json file', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define_from_file: config/defines.json
  flags:
    should_add_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);
        expect(config.finalDartDefineFromFile, equals('config/defines.json'));
      });
    });
  });
}
