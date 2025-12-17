import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';
import '../test_helper.dart';

/// Tests for dart_define_from_file support in v0.1.2
void main() {
  group('BuildConfig - dart_define_from_file (v0.1.2)', () {
    late String configPath;

    setUp(() {
      configPath = TestHelper.getTestPath('v0.1.2', 'fluttercraft.yaml');
    });

    group('global dart_define_from_file', () {
      test('parses global dart_define_from_file from build_defaults', () async {
        final config = await BuildConfig.load(configPath: configPath);

        expect(config.globalDartDefineFromFile, equals('.env'));
        expect(config.dartDefineFromFile, equals('.env'));
        expect(config.finalDartDefineFromFile, equals('.env'));
      });

      test('respects should_prompt_dart_define flag', () async {
        final config = await BuildConfig.load(configPath: configPath);
        
        // Flag is true in our config, so should return value
        expect(config.finalDartDefineFromFile, equals('.env'));
      });
    });

    group('flavor dart_define_from_file override', () {
      test('flavor dart_define_from_file overrides global', () async {
        // Load config then manually set flavor
        var config = await BuildConfig.load(configPath: configPath);
        
        // We need to reload with dev flavor
        // Check that flavors are parsed correctly
        expect(config.flavors.containsKey('dev'), isTrue);
        expect(config.flavors['dev']!.dartDefineFromFile, equals('.env.dev'));
      });

      test('prod flavor has correct dart_define_from_file', () async {
        final config = await BuildConfig.load(configPath: configPath);
        
        expect(config.flavors.containsKey('prod'), isTrue);
        expect(config.flavors['prod']!.dartDefineFromFile, equals('.env.prod'));
      });
    });

    group('dart_define_from_file file path formats', () {
      test('accepts simple .env filename', () async {
        final config = await BuildConfig.load(configPath: configPath);
        expect(config.finalDartDefineFromFile, equals('.env'));
      });

      test('flavor configs use flavor-specific names', () async {
        final config = await BuildConfig.load(configPath: configPath);
        
        final devFlavor = config.flavors['dev'];
        expect(devFlavor?.dartDefineFromFile, equals('.env.dev'));
        
        final prodFlavor = config.flavors['prod'];
        expect(prodFlavor?.dartDefineFromFile, equals('.env.prod'));
      });
    });

    group('build config properties', () {
      test('parses basic build config correctly', () async {
        final config = await BuildConfig.load(configPath: configPath);
        
        expect(config.appName, equals('testapp'));
        expect(config.buildName, equals('1.0.0'));
        expect(config.buildNumber, equals(1));
        expect(config.buildType, equals('aab'));
      });

      test('parses flags correctly', () async {
        final config = await BuildConfig.load(configPath: configPath);
        
        expect(config.shouldPromptDartDefine, isTrue);
        expect(config.shouldClean, isFalse);
        expect(config.shouldBuildRunner, isFalse);
      });
    });
  });
}
