import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';
import 'package:fluttercraft/src/core/flutter_runner.dart';
import '../test_helper.dart';

/// Tests for dart_define_from_file loading and build command generation (v0.1.3)
void main() {
  group('dart_define_from_file (v0.1.3)', () {
    late String configPath;

    setUp(() {
      configPath = TestHelper.getTestPath('v0.1.3', 'fluttercraft.yaml');
    });

    group('config loading', () {
      test('loads global dart_define_from_file correctly', () async {
        final config = await BuildConfig.load(configPath: configPath);

        expect(config.globalDartDefineFromFile, equals('.env'));
        expect(config.dartDefineFromFile, equals('.env'));
        expect(config.finalDartDefineFromFile, equals('.env'));
      });

      test('flavor overrides global dart_define_from_file', () async {
        final config = await BuildConfig.load(configPath: configPath);

        expect(config.flavors['dev']!.dartDefineFromFile, equals('.env.dev'));
        expect(config.flavors['prod']!.dartDefineFromFile, equals('.env.prod'));
      });

      test('returns value regardless of shouldPromptDartDefine flag', () async {
        // v0.1.4+: finalDartDefineFromFile always returns value if configured
        // Flag only controls interactive prompting, not config-defined paths
        final config = await BuildConfig.load(configPath: configPath);
        
        // Config-defined paths always return
        expect(config.finalDartDefineFromFile, isNotNull);
        expect(config.finalDartDefineFromFile, equals('.env'));
      });
    });

    group('build command', () {
      test('includes --dart-define-from-file flag in build command', () async {
        final config = await BuildConfig.load(configPath: configPath);
        final runner = FlutterRunner(projectRoot: config.projectRoot);
        final command = runner.getBuildCommand(config);

        expect(
          command.contains('--dart-define-from-file=.env'),
          isTrue,
          reason: 'Build command should include --dart-define-from-file=.env',
        );
      });

      test('command format is correct for flutter build', () async {
        final config = await BuildConfig.load(configPath: configPath);
        final runner = FlutterRunner(projectRoot: config.projectRoot);
        final command = runner.getBuildCommand(config);

        // Should be: flutter build appbundle --release --build-name=1.0.0 --build-number=1 --dart-define-from-file=.env
        expect(command.startsWith('flutter build appbundle'), isTrue);
        expect(command.contains('--release'), isTrue);
        expect(command.contains('--dart-define-from-file=.env'), isTrue);
      });
    });
  });
}
