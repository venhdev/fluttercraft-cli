import 'dart:io';

import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';

/// Tests for dart_define and global_dart_define merging in v0.1.1
void main() {
  group('BuildConfig - Dart Define Merging (v0.1.1)', () {
    late String tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('dartdefine_test_').path;
    });

    tearDown(() async {
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (_) {}
    });

    group('global_dart_define', () {
      test('parses global_dart_define from build_defaults', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  global_dart_define:
    APP_NAME: myapp
    API_VERSION: v1
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.globalDartDefine['APP_NAME'], 'myapp');
        expect(config.globalDartDefine['API_VERSION'], 'v1');
      });

      test('global_dart_define appears in finalDartDefine when enabled', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  global_dart_define:
    MY_KEY: my_value
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.finalDartDefine['MY_KEY'], 'my_value');
      });

      test('finalDartDefine returns values regardless of should_prompt_dart_define flag', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  global_dart_define:
    MY_KEY: my_value
  flags:
    should_prompt_dart_define: false

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        // v0.1.4+: finalDartDefine always returns values
        // Flag only controls interactive prompting, not config-defined dart-defines
        expect(config.finalDartDefine, isNotEmpty);
        expect(config.finalDartDefine['MY_KEY'], 'my_value');
      });
    });

    group('dart_define merging', () {
      test('dart_define merges with global_dart_define', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  global_dart_define:
    APP_NAME: myapp
    GLOBAL_KEY: global_value
  dart_define:
    BUILD_KEY: build_value
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);
        final finalDefines = config.finalDartDefine;

        expect(finalDefines['APP_NAME'], 'myapp');
        expect(finalDefines['GLOBAL_KEY'], 'global_value');
        expect(finalDefines['BUILD_KEY'], 'build_value');
      });

      test('dart_define overrides global_dart_define for same key', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  global_dart_define:
    MY_KEY: global_value
    OTHER_KEY: other
  dart_define:
    MY_KEY: local_override
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);
        final finalDefines = config.finalDartDefine;

        expect(finalDefines['MY_KEY'], 'local_override'); // overridden
        expect(finalDefines['OTHER_KEY'], 'other'); // not overridden
      });

      test('flavor dart_define merges and overrides', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  global_dart_define:
    APP_NAME: myapp
  dart_define:
    ENV: default
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: dev

flavors:
  dev:
    flags:
      should_prompt_dart_define: true
    dart_define:
      ENV: development
      IS_DEV: true
''');

        final config = await BuildConfig.load(configPath: configFile.path);
        final finalDefines = config.finalDartDefine;

        expect(finalDefines['APP_NAME'], 'myapp'); // from global
        expect(finalDefines['ENV'], 'development'); // overridden by flavor
        expect(finalDefines['IS_DEV'], true); // added by flavor
      });
    });

    group('dart_define value types', () {
      test('accepts string values', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define:
    STRING_VAL: "hello world"
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.finalDartDefine['STRING_VAL'], 'hello world');
      });

      test('accepts boolean values', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define:
    BOOL_TRUE: true
    BOOL_FALSE: false
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.finalDartDefine['BOOL_TRUE'], true);
        expect(config.finalDartDefine['BOOL_FALSE'], false);
      });

      test('accepts numeric values', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define:
    INT_VAL: 42
    DOUBLE_VAL: 3.14
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.finalDartDefine['INT_VAL'], 42);
        expect(config.finalDartDefine['DOUBLE_VAL'], 3.14);
      });

      test('rejects object values in dart_define', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define:
    NESTED:
      key: value
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        expect(
          () => BuildConfig.load(configPath: configFile.path),
          throwsA(
            isA<ConfigParseException>().having(
              (e) => e.message,
              'message',
              contains('must be a primitive'),
            ),
          ),
        );
      });

      test('rejects list values in dart_define', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define:
    LIST_VAL:
      - item1
      - item2
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        expect(
          () => BuildConfig.load(configPath: configFile.path),
          throwsA(
            isA<ConfigParseException>().having(
              (e) => e.message,
              'message',
              contains('must be a primitive'),
            ),
          ),
        );
      });
    });

    group('empty dart_define', () {
      test('handles empty dart_define gracefully', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  dart_define: {}
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.dartDefine, isEmpty);
        expect(config.finalDartDefine, isEmpty);
      });

      test('handles missing dart_define gracefully', () async {
        final configFile = File('$tempDir/fluttercraft.yaml');
        await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: myapp
  flags:
    should_prompt_dart_define: true

build:
  <<: *build_defaults
  flavor: null
''');

        final config = await BuildConfig.load(configPath: configFile.path);

        expect(config.dartDefine, isEmpty);
        expect(config.globalDartDefine, isEmpty);
      });
    });
  });
}
