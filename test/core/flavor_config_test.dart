import 'package:test/test.dart';
import 'package:fluttercraft/src/core/flavor_config.dart';
import 'package:yaml/yaml.dart';

/// Tests for FlavorConfig
///
/// Verifies flavor parsing and dart_define merging.
void main() {
  group('FlavorConfig', () {
    group('fromYaml', () {
      test('parses minimal flavor config', () {
        final yaml = loadYaml('''
platform: apk
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('dev', yaml);

        expect(flavor.name, 'dev');
        expect(flavor.platform, 'apk');
      });

      test('parses platform override', () {
        final yaml = loadYaml('''
platform: aab
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('prod', yaml);

        expect(flavor.platform, 'aab');
      });

      test('parses flags', () {
        final yaml = loadYaml('''
flags:
  should_clean: true
  should_build_runner: true
  should_prompt_dart_define: false
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('dev', yaml);

        expect(flavor.shouldClean, true);
        expect(flavor.shouldBuildRunner, true);
        expect(flavor.shouldPromptDartDefine, false);
      });

      test('parses dart_define', () {
        final yaml = loadYaml('''
dart_define:
  IS_DEV: true
  LOG_LEVEL: debug
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('dev', yaml);

        expect(flavor.dartDefine['IS_DEV'], true);
        expect(flavor.dartDefine['LOG_LEVEL'], 'debug');
      });

      test('parses dart_define_from_file', () {
        final yaml = loadYaml('''
dart_define_from_file: .env.dev
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('dev', yaml);

        expect(flavor.dartDefineFromFile, '.env.dev');
      });

      test('parses args', () {
        final yaml = loadYaml('''
args:
  - --obfuscate
  - --split-debug-info=debug_info
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('prod', yaml);

        expect(flavor.args, ['--obfuscate', '--split-debug-info=debug_info']);
      });
    });

    group('complete flavor config', () {
      test('parses all fields', () {
        final yaml = loadYaml('''
platform: aab
flags:
  should_clean: true
  should_build_runner: false
  should_prompt_dart_define: true
dart_define:
  ENV: staging
  API_URL: https://staging.api.com
dart_define_from_file: .env.staging
args:
  - --obfuscate
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('staging', yaml);

        expect(flavor.name, 'staging');
        expect(flavor.platform, 'aab');
        expect(flavor.shouldClean, true);
        expect(flavor.shouldBuildRunner, false);
        expect(flavor.shouldPromptDartDefine, true);
        expect(flavor.dartDefine['ENV'], 'staging');
        expect(flavor.dartDefine['API_URL'], 'https://staging.api.com');
        expect(flavor.dartDefineFromFile, '.env.staging');
        expect(flavor.args, ['--obfuscate']);
      });
    });
  });
}
