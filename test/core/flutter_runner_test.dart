import 'package:test/test.dart';
import 'package:fluttercraft/src/core/flutter_runner.dart';
import 'package:fluttercraft/src/core/build_config.dart';
import 'package:fluttercraft/src/core/build_flags.dart';

void main() {
  group('FlutterRunner Clean Command', () {
    late FlutterRunner runner;

    setUp(() {
      runner = FlutterRunner(projectRoot: '.');
    });

    test('getCleanCommand returns plain flutter clean when useFvm is false', () {
      expect(runner.getCleanCommand(useFvm: false), 'flutter clean');
    });

    test('getCleanCommand returns fvm flutter clean when useFvm is true', () {
      expect(runner.getCleanCommand(useFvm: true), 'fvm flutter clean');
    });
  });

  group('FlutterRunner Build Command', () {
    late FlutterRunner runner;
    late BuildConfig minimalConfig;

    setUp(() {
      runner = FlutterRunner(projectRoot: '.');
      // Create a minimal config for testing
      minimalConfig = BuildConfig(
        projectRoot: '.',
        appName: 'test_app',
        buildName: '1.0.0',
        buildNumber: 1,
        buildType: 'apk',
        targetDart: 'lib/main.dart',
        outputPath: 'dist',
        flags: BuildFlags.defaults,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: 'key.jks',
      );
    });

    test('getBuildCommand returns plain flutter build for standard config', () {
      final config = minimalConfig;
      // Default build is release for plain flutter
      expect(
        runner.getBuildCommand(config),
        contains('flutter build apk --release'),
      );
    });

    test('getBuildCommand returns fvm flutter build when useFvm is true', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        buildType: minimalConfig.buildType,
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: true, // Enable FVM
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
      );
      
      expect(runner.getBuildCommand(config), startsWith('fvm flutter build'));
    });

    test('getBuildCommand handles Shorebird with standard settings', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        buildType: minimalConfig.buildType,
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: true, // Enable Shorebird
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
      );

      final cmd = runner.getBuildCommand(config);
      
      expect(cmd, startsWith('shorebird release android'));
      expect(cmd, contains('--artifact apk'));
      expect(cmd, contains('--no-confirm'));
      expect(cmd, contains('-- --build-name=1.0.0'));
      // Should NOT contain --release inside the flutter args part (after --)
      // but simplistic check might be hard. 
      // Shorebird command itself implies release.
    });

    test('getBuildCommand includes flutter-version for Shorebird if configured', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        buildType: minimalConfig.buildType,
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: true,
        flutterVersion: '3.13.0',
        useShorebird: true, // Enable Shorebird
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
      );

      final cmd = runner.getBuildCommand(config);
      
      expect(cmd, contains('shorebird release android'));
      expect(cmd, contains('--flutter-version=3.13.0'));
    });
    
    test('getBuildCommand includes dart-define-from-file', () {
       final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        buildType: minimalConfig.buildType,
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
        dartDefineFromFile: '.env.prod',
      );

      final cmd = runner.getBuildCommand(config);
      expect(cmd, contains('--dart-define-from-file=.env.prod'));
    });
  });
}
