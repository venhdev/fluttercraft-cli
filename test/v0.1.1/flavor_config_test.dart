import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:fluttercraft/src/core/flavor_config.dart';

/// Tests for FlavorConfig model in v0.1.1
void main() {
  group('FlavorConfig', () {
    group('fromYaml', () {
      test('parses flavor with all fields', () {
        final yamlContent = '''
name: 1.0.0-rc.1
number: 99
flags:
  should_add_dart_define: true
  should_clean: true
  should_build_runner: true
dart_define:
  IS_STAGING: true
  API_URL: https://staging.api.com
''';
        final yaml = loadYaml(yamlContent) as YamlMap;
        final config = FlavorConfig.fromYaml('staging', yaml);

        expect(config.name, 'staging');
        expect(config.versionName, '1.0.0-rc.1');
        expect(config.buildNumber, 99);
        expect(config.shouldAddDartDefine, true);
        expect(config.shouldClean, true);
        expect(config.shouldBuildRunner, true);
        expect(config.dartDefine['IS_STAGING'], true);
        expect(config.dartDefine['API_URL'], 'https://staging.api.com');
      });

      test('parses flavor with only flags', () {
        final yamlContent = '''
flags:
  should_add_dart_define: true
''';
        final yaml = loadYaml(yamlContent) as YamlMap;
        final config = FlavorConfig.fromYaml('dev', yaml);

        expect(config.name, 'dev');
        expect(config.versionName, isNull);
        expect(config.buildNumber, isNull);
        expect(config.shouldAddDartDefine, true);
        expect(config.shouldClean, isNull);
        expect(config.shouldBuildRunner, isNull);
        expect(config.dartDefine, isEmpty);
      });

      test('parses flavor with only dart_define', () {
        final yamlContent = '''
dart_define:
  MY_KEY: my_value
''';
        final yaml = loadYaml(yamlContent) as YamlMap;
        final config = FlavorConfig.fromYaml('test', yaml);

        expect(config.name, 'test');
        expect(config.dartDefine['MY_KEY'], 'my_value');
        expect(config.shouldAddDartDefine, isNull);
      });

      test('parses flavor with version override only', () {
        final yamlContent = '''
name: 2.0.0-beta
number: 1
''';
        final yaml = loadYaml(yamlContent) as YamlMap;
        final config = FlavorConfig.fromYaml('beta', yaml);

        expect(config.name, 'beta');
        expect(config.versionName, '2.0.0-beta');
        expect(config.buildNumber, 1);
        expect(config.dartDefine, isEmpty);
      });

      test('handles empty yaml map', () {
        // Empty map case
        final emptyYaml = loadYaml('{}') as YamlMap;
        final config = FlavorConfig.fromYaml('empty', emptyYaml);

        expect(config.name, 'empty');
        expect(config.versionName, isNull);
        expect(config.buildNumber, isNull);
        expect(config.dartDefine, isEmpty);
      });
    });

    group('dart_define validation', () {
      test('accepts string values', () {
        final yamlContent = '''
dart_define:
  STRING_KEY: "hello"
''';
        final yaml = loadYaml(yamlContent) as YamlMap;
        final config = FlavorConfig.fromYaml('test', yaml);

        expect(config.dartDefine['STRING_KEY'], 'hello');
      });

      test('accepts boolean values', () {
        final yamlContent = '''
dart_define:
  BOOL_KEY: true
''';
        final yaml = loadYaml(yamlContent) as YamlMap;
        final config = FlavorConfig.fromYaml('test', yaml);

        expect(config.dartDefine['BOOL_KEY'], true);
      });

      test('accepts numeric values', () {
        final yamlContent = '''
dart_define:
  INT_KEY: 42
  DOUBLE_KEY: 3.14
''';
        final yaml = loadYaml(yamlContent) as YamlMap;
        final config = FlavorConfig.fromYaml('test', yaml);

        expect(config.dartDefine['INT_KEY'], 42);
        expect(config.dartDefine['DOUBLE_KEY'], 3.14);
      });

      test('rejects object values', () {
        final yamlContent = '''
dart_define:
  OBJECT_KEY:
    nested: value
''';
        final yaml = loadYaml(yamlContent) as YamlMap;

        expect(
          () => FlavorConfig.fromYaml('test', yaml),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must be a primitive'),
            ),
          ),
        );
      });
    });

    group('flag parsing', () {
      test('parses all flags correctly', () {
        final yamlContent = '''
flags:
  should_add_dart_define: true
  should_clean: false
  should_build_runner: true
''';
        final yaml = loadYaml(yamlContent) as YamlMap;
        final config = FlavorConfig.fromYaml('test', yaml);

        expect(config.shouldAddDartDefine, true);
        expect(config.shouldClean, false);
        expect(config.shouldBuildRunner, true);
      });

      test('handles missing flags gracefully', () {
        final yamlContent = '''
flags:
  should_clean: true
''';
        final yaml = loadYaml(yamlContent) as YamlMap;
        final config = FlavorConfig.fromYaml('test', yaml);

        expect(config.shouldAddDartDefine, isNull);
        expect(config.shouldClean, true);
        expect(config.shouldBuildRunner, isNull);
      });

      test('handles missing flags section', () {
        final yamlContent = '''
dart_define:
  KEY: value
''';
        final yaml = loadYaml(yamlContent) as YamlMap;
        final config = FlavorConfig.fromYaml('test', yaml);

        expect(config.shouldAddDartDefine, isNull);
        expect(config.shouldClean, isNull);
        expect(config.shouldBuildRunner, isNull);
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final yamlContent = '''
name: 1.0.0-dev
number: 5
dart_define:
  IS_DEV: true
''';
        final yaml = loadYaml(yamlContent) as YamlMap;
        final config = FlavorConfig.fromYaml('dev', yaml);

        final str = config.toString();

        expect(str, contains('name: dev'));
        expect(str, contains('versionName: 1.0.0-dev'));
        expect(str, contains('buildNumber: 5'));
      });
    });
  });
}
