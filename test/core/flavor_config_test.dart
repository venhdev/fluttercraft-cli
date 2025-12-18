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
name: 1.0.0-dev
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('dev', yaml);

        expect(flavor.name, 'dev');
        expect(flavor.versionName, '1.0.0-dev');
      });

      test('parses version name override', () {
        final yaml = loadYaml('''
name: 2.0.0-rc
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('staging', yaml);

        expect(flavor.versionName, '2.0.0-rc');
      });

      test('parses build number override', () {
        final yaml = loadYaml('''
number: 99
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('prod', yaml);

        expect(flavor.buildNumber, 99);
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

      test('handles null values gracefully', () {
        final yaml = loadYaml('''
name: null
number: null
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('test', yaml);

        expect(flavor.versionName, isNull);
        expect(flavor.buildNumber, isNull);
      });
    });

    group('complete flavor config', () {
      test('parses all fields', () {
        final yaml = loadYaml('''
name: 1.5.0-staging
number: 50
flags:
  should_clean: true
  should_build_runner: false
  should_prompt_dart_define: true
dart_define:
  ENV: staging
  API_URL: https://staging.api.com
dart_define_from_file: .env.staging
''') as YamlMap;

        final flavor = FlavorConfig.fromYaml('staging', yaml);

        expect(flavor.name, 'staging');
        expect(flavor.versionName, '1.5.0-staging');
        expect(flavor.buildNumber, 50);
        expect(flavor.shouldClean, true);
        expect(flavor.shouldBuildRunner, false);
        expect(flavor.shouldPromptDartDefine, true);
        expect(flavor.dartDefine['ENV'], 'staging');
        expect(flavor.dartDefine['API_URL'], 'https://staging.api.com');
        expect(flavor.dartDefineFromFile, '.env.staging');
      });
    });
  });
}
