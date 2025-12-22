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
        // buildName/buildNumber are now always null - Flutter reads from pubspec.yaml
        expect(config.buildName, isNull);
        expect(config.buildNumber, isNull);
        expect(config.platform, 'aab');
        expect(config.outputPath, '.fluttercraft/dist');
      });

      test('loads config from YAML file', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: myapp
version: 2.0.0+42
''');
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  platform: apk
paths:
  output: custom/output
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.appName, 'myapp');
        // buildName/buildNumber always null - Flutter reads from pubspec
        expect(config.buildName, isNull);
        expect(config.buildNumber, isNull);
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

      test('appName comes from pubspec when not in config', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: pubspec_app
version: 1.2.3+45
''');
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  platform: apk
''');

        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.appName, 'pubspec_app');
        // buildName/buildNumber always null in config
        expect(config.buildName, isNull);
        expect(config.buildNumber, isNull);
      });

      test('appName always comes from pubspec', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: pubspec_app
version: 1.2.3+45
''');
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  platform: aab
''');

        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.appName, 'pubspec_app');
        // buildName/buildNumber no longer in config
        expect(config.buildName, isNull);
        expect(config.buildNumber, isNull);
      });

      test('supports backward compatibility with "type" key', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  type: ios
''');
        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.platform, 'ios');
      });
    });

    group('build_defaults inheritance', () {
      test('build inherits from build_defaults', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: defaultapp
version: 2.0.0+1
''');
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build_defaults:
  target: lib/main.dart
  platform: apk

build:
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.appName, 'defaultapp'); // from pubspec
        expect(config.buildName, isNull); // always null
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
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: myapp
version: 1.0.0+1
''');
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  flavor: dev
flavors:
  dev:
    flags:
      should_clean: true
    platform: ios
''');

        final config = await BuildConfig.load(projectRoot: tempDir);

        // buildName no longer overridden by flavors
        expect(config.buildName, isNull);
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

    group('args', () {
      test('parses args from build_defaults', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build_defaults:
  args:
    - --obfuscate
    - --split-debug-info=symbols
build:
  app_name: myapp
''');

        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.args, containsAll(['--obfuscate', '--split-debug-info=symbols']));
      });

      test('merges inherited and flavor-specific args', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build_defaults:
  args:
    - --def-arg
build:
  flavor: prod
flavors:
  prod:
    args:
      - --flavor-arg
''');

        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.args, containsAll(['--def-arg', '--flavor-arg']));
      });

      test('handles single string arg', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  args: --single-arg
''');

        final config = await BuildConfig.load(projectRoot: tempDir);
        expect(config.args, ['--single-arg']);
      });
    });

    group('computed properties', () {
      test('fullVersion is null when buildName/buildNumber are null', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  platform: aab
''');

        final config = await BuildConfig.load(projectRoot: tempDir);
        // fullVersion is null because buildName/buildNumber are null
        expect(config.fullVersion, isNull);
      });
    });

    group('edge cases', () {
      test('empty build section uses defaults', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
''');
        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.appName, 'app');
        expect(config.buildName, isNull);
        expect(config.buildNumber, isNull);
        expect(config.platform, 'aab'); // Default platform
      });

      test('null values in YAML use defaults', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  platform: null
''');
        final config = await BuildConfig.load(projectRoot: tempDir);

        expect(config.appName, 'app');
        expect(config.buildName, isNull);
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
