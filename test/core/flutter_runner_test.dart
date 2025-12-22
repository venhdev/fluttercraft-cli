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
        platform: 'apk',
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
        platform: minimalConfig.platform,
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
        platform: minimalConfig.platform,
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
      expect(cmd, contains('--artifact=apk'));
      expect(cmd, contains('--no-confirm'));
      // Should find it twice now: before & after --
      expect(cmd, contains('--build-name=1.0.0')); 
      expect(cmd, contains('-- '));
    });

    test('getBuildCommand includes flutter-version for Shorebird if configured', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: minimalConfig.platform,
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
    
    test('getBuildCommand for ipa returns correct command', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: 'ipa',
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
      );
      final cmd = runner.getBuildCommand(config);
      expect(cmd, 'flutter build ipa --release --build-name=1.0.0 --build-number=1');
    });

    test('getBuildCommand for apk returns correct command', () {
      final cmd = runner.getBuildCommand(minimalConfig);
      expect(cmd, 'flutter build apk --release --build-name=1.0.0 --build-number=1');
    });

    test('getBuildCommand includes extra args from config', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: minimalConfig.platform,
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
        args: ['--obfuscate', '--split-debug-info=symbols'],
      );

      final cmd = runner.getBuildCommand(config);
      expect(cmd, contains('--obfuscate'));
      expect(cmd, contains('--split-debug-info=symbols'));
    });

    test('getBuildCommand for aab returns correct command', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: 'aab',
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
      );
      final cmd = runner.getBuildCommand(config);
      expect(cmd, 'flutter build appbundle --release --build-name=1.0.0 --build-number=1');
    });
    
    test('getBuildCommand includes dart-define-from-file', () {
       final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: minimalConfig.platform,
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

    test('getBuildCommand handles Shorebird iOS with correct flags', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: 'ipa', // iOS
        targetDart: 'lib/main_prod.dart',
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: true,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
        flavor: 'prod',
      );

      final cmd = runner.getBuildCommand(config);
      
      expect(cmd, startsWith('shorebird release ios'));
      expect(cmd, contains('--build-name=1.0.0'));
      expect(cmd, contains('--build-number=1'));
      expect(cmd, contains('--flavor=prod'));
      expect(cmd, contains('--target=lib/main_prod.dart'));
      expect(cmd, contains('-- ')); // Should have separator
      expect(cmd, contains('--target=lib/main_prod.dart')); // Should also be after -- because it wraps
    });

    test('getBuildCommand handles Shorebird macOS', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: '2.0.0',
        buildNumber: 10,
        platform: 'macos',
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: true,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
      );

      final cmd = runner.getBuildCommand(config);
      
      expect(cmd, startsWith('shorebird release macos'));
      expect(cmd, contains('--build-name=2.0.0'));
      expect(cmd, contains('--build-number=10'));
    });

    test('getBuildCommand for Shorebird places dart-defines after separator', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: 'aab',
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: true,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
        dartDefine: {'FOO': 'BAR'},
      );

      final cmd = runner.getBuildCommand(config);
      
      expect(cmd, contains('-- '));
      final parts = cmd.split('-- ');
      expect(parts[1], contains('--dart-define=FOO=BAR'));
      // Management flags should be in the first part
      expect(parts[0], contains('--build-name=1.0.0'));
    });
  });
}
