import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';
import '../test_helper.dart';

/// Tests for BuildConfig
///
/// Verifies YAML parsing, default values, and flavor resolution.
void main() {
  group('BuildConfig', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'build_config_test_',
      );
    });

    tearDown(() async {
      await cleanup();
    });

    group('load', () {
      test('returns default config when no file exists', () async {
        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.appName, 'app');
        expect(config.buildName, '1.0.0');
        expect(config.buildNumber, 1);
        expect(config.platform, 'aab');
        expect(config.outputPath, '.fluttercraft/dist');
      });

      test('loads config from YAML file', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  name: 2.0.0
  number: 42
  platform: apk
paths:
  output: custom/output
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.appName, 'myapp');
        expect(config.buildName, '2.0.0');
        expect(config.buildNumber, 42);
        expect(config.platform, 'apk');
        expect(config.outputPath, 'custom/output');
      });

      test('uses default output path .fluttercraft/dist when not specified', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
''');

        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.outputPath, '.fluttercraft/dist');
      });
    });

    group('build_defaults inheritance', () {
      test('build inherits from build_defaults', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build_defaults:
  app_name: defaultapp
  name: 1.0.0
  target: lib/main.dart
  platform: apk

build:
  name: 2.0.0
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.appName, 'defaultapp'); // inherited from defaults
        expect(config.buildName, '2.0.0'); // overridden in build
        expect(config.targetDart, 'lib/main.dart'); // inherited
        expect(config.platform, 'apk'); // inherited
      });
    });

    group('flags parsing', () {
      test('parses flags from build section', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  flags:
    should_clean: true
    should_build_runner: true
    should_prompt_dart_define: true
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.flags.shouldClean, true);
        expect(config.flags.shouldBuildRunner, true);
        expect(config.flags.shouldPromptDartDefine, true);
      });

      test('platform delegates to config', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: testapp
  platform: ipa
''');
        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.platform, 'ipa');
      });

      test('defaults all flags to false', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.flags.shouldClean, false);
        expect(config.flags.shouldBuildRunner, false);
        expect(config.flags.shouldPromptDartDefine, false);
      });
    });

    group('dart_define parsing', () {
      test('parses dart_define from build section', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  dart_define:
    API_KEY: secret123
    DEBUG: true
    VERSION: 1
''');

        final config = await BuildConfig.load(projectRoot: tempDir);
        final dartDefine = config.finalDartDefine;

        expect(dartDefine['API_KEY'], 'secret123');
        expect(dartDefine['DEBUG'], true);
        expect(dartDefine['VERSION'], 1);
      });

      test('merges global and flavor dart_define', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  global_dart_define:
    GLOBAL_KEY: global_value
  dart_define:
    LOCAL_KEY: local_value
''');

        final config = await BuildConfig.load(projectRoot: tempDir);
        final dartDefine = config.finalDartDefine;

        expect(dartDefine['GLOBAL_KEY'], 'global_value');
        expect(dartDefine['LOCAL_KEY'], 'local_value');
      });
    });

    group('flavors', () {
      test('throws error when flavor not found', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  flavor: nonexistent
flavors:
  dev:
    name: 1.0.0-dev
''');

        expect(
          () async => await BuildConfig.load(projectRoot: tempDir),
          throwsA(isA<ConfigParseException>()),
        );
      });

      test('applies flavor overrides', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  name: 1.0.0
  flavor: dev
flavors:
  dev:
    name: 1.0.0-dev
    flags:
      should_clean: true
    platform: ios
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.buildName, '1.0.0-dev');
        expect(config.flags.shouldClean, true);
        expect(config.flavor, 'dev');
        expect(config.platform, 'ios');
      });

      test('absoluteOutputPath includes flavor', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  flavor: dev
flavors:
  dev:
    name: 1.0.0-dev
paths:
  output: .fluttercraft/dist
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.absoluteOutputPath, contains('dev'));
      });
    });

    group('environments', () {
      test('parses FVM settings', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
environments:
  fvm:
    enabled: true
    version: "3.24.0"
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.useFvm, true);
        expect(config.flutterVersion, '3.24.0');
      });

      test('parses Shorebird settings', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
environments:
  shorebird:
    enabled: true
    app_id: test_app_id
    no_confirm: false
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.useShorebird, true);
        expect(config.shorebirdAppId, 'test_app_id');
        expect(config.shorebirdNoConfirm, false);
      });

      test('parses bundletool settings', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
environments:
  bundletool:
    path: tools/bundletool.jar
    keystore: android/key.properties
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.bundletoolPath, 'tools/bundletool.jar');
        expect(config.keystorePath, 'android/key.properties');
      });
    });

    group('aliases', () {
      test('parses command aliases', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
alias:
  gen-icon:
    cmds:
      - flutter pub get
      - flutter pub run flutter_launcher_icons
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.aliases.containsKey('gen-icon'), true);
        expect(config.aliases['gen-icon']?.commands.length, 2);
      });
    });

    group('computed properties', () {
      test('fullVersion combines name and number', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  name: 1.2.3
  number: 45
''');

        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.fullVersion, '1.2.3+45');
      });
    });

    group('edge cases', () {
      test('empty build section uses defaults', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
''');
        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.appName, 'app');
        expect(config.buildName, '1.0.0');
        expect(config.buildNumber, 1);
        expect(config.platform, 'aab'); // Default platform
      });

      test('null values in YAML use defaults', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: null
  name: null
  number: null
  platform: null
''');
        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.appName, 'app');
        expect(config.buildName, '1.0.0');
        expect(config.platform, 'aab');
      });

      test('missing environments section uses defaults', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
''');
        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.useFvm, false);
        expect(config.useShorebird, false);
        expect(config.noColor, false);
      });

      test('alias with commands is created', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
alias:
  test-alias:
    cmds:
      - echo test
''');
        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.aliases.containsKey('test-alias'), true);
        expect(config.aliases['test-alias']?.commands.isNotEmpty, true);
      });

      test('dart_define with null value is skipped', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  dart_define:
    VALID_KEY: valid_value
    NULL_KEY: null
''');
        final config = await BuildConfig.load(projectRoot: tempDir);
        final defines = config.finalDartDefine;

        expect(defines['VALID_KEY'], 'valid_value');
        expect(defines.containsKey('NULL_KEY'), true); // null is preserved
      });

      test('flavor section with content is parsed', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
flavors:
  dev:
    name: 1.0.0-dev
''');
        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.flavors.containsKey('dev'), true);
      });

      test('flavor dart_define overrides global dart_define', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  flavor: dev
  global_dart_define:
    KEY: global_value
flavors:
  dev:
    dart_define:
      KEY: dev_value
''');
        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.finalDartDefine['KEY'], 'dev_value');
      });

      test('throws ConfigParseException for empty YAML', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '');

        expect(
          () async => await BuildConfig.load(projectRoot: tempDir),
          throwsA(isA<ConfigParseException>()),
        );
      });

      test('handles boolean values in dart_define', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  dart_define:
    IS_DEBUG: true
    IS_PROD: false
''');
        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.finalDartDefine['IS_DEBUG'], true);
        expect(config.finalDartDefine['IS_PROD'], false);
      });

      test('handles numeric values in dart_define', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: myapp
  dart_define:
    VERSION_CODE: 42
    TIMEOUT: 30.5
''');
        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.finalDartDefine['VERSION_CODE'], 42);
        expect(config.finalDartDefine['TIMEOUT'], 30.5);
      });
    });
  });
}
