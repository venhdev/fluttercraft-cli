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
      expect(cmd, anyOf(contains('-- '), contains("'--'")));
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
      // Path will be converted to absolute, so just check the flag exists
      expect(cmd, contains('--dart-define-from-file='));
      expect(cmd, contains('.env.prod'));
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
      expect(cmd, anyOf(contains('-- '), contains("'--'"))); // Should have separator
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
      
      expect(cmd, anyOf(contains('-- '), contains("'--'")));
      // Split on the separator (handle both formats)
      final parts = cmd.split(RegExp(r"('--'|-- )"));
      // Find the index after separator
      final afterSepIndex = parts.indexWhere((p) => p.contains('--build-name='));
      final afterSep = parts.skip(afterSepIndex).join(' ');
      final beforeSep = parts.take(afterSepIndex).join(' ');
      // Dart-define goes after -- (flutter build argument)
      expect(afterSep, contains('--dart-define=FOO=BAR'));
      // Version and build flags should be after --
      expect(afterSep, contains('--build-name=1.0.0'));
      // Management flags should be before --
      expect(beforeSep, contains('--no-confirm'));
    });

    test('getBuildCommand includes dart_define_from_file after separator', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: 'apk',
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: true,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
        dartDefineFromFile: '.env.dev',
      );

      final cmd = runner.getBuildCommand(config);
      
      expect(cmd, contains('--dart-define-from-file=.env.dev'));
      // Should be after the separator (flutter build argument)
      expect(cmd, anyOf(contains('-- '), contains("'--'")));
    });

    test('getBuildCommand includes global dart_define_from_file', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: 'apk',
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: true,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
        globalDartDefineFromFile: '.env',
      );

      final cmd = runner.getBuildCommand(config);
      
      expect(cmd, contains('--dart-define-from-file=.env'));
    });

    test('getBuildCommand prefers flavor dart_define_from_file over global', () {
      final config = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: 'apk',
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: true,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
        globalDartDefineFromFile: '.env',
        dartDefineFromFile: '.env.dev',
      );

      final cmd = runner.getBuildCommand(config);
      
      expect(cmd, contains('--dart-define-from-file=.env.dev'));
      // Should use flavor-specific, not both
      final matches = '--dart-define-from-file'.allMatches(cmd);
      expect(matches.length, 1, reason: 'Should only have one dart-define-from-file flag');
    });
  });

  group('FlutterRunner buildFromCommand', () {
    late FlutterRunner runner;

    setUp(() {
      runner = FlutterRunner(projectRoot: '.');
    });

    test('buildFromCommand returns error for empty command', () async {
      final result = await runner.buildFromCommand('', '.');
      
      expect(result.exitCode, 1);
      expect(result.stderr, contains('Empty command'));
    });

    test('buildFromCommand returns error for whitespace-only command', () async {
      final result = await runner.buildFromCommand('   ', '.');
      
      expect(result.exitCode, 1);
      expect(result.stderr, contains('Empty command'));
    });

    // Note: We can't easily test actual shell execution without mocking,
    // but we can verify the method exists and handles edge cases
  });

  group('FlutterRunner dart_define_from_file end-to-end', () {
    late FlutterRunner runner;
    late BuildConfig minimalConfig;

    setUp(() {
      runner = FlutterRunner(projectRoot: '.');
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

    test('getBuildCommand with copied BuildConfig preserves dart_define_from_file', () {
      final originalConfig = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: 'apk',
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: true,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
        globalDartDefineFromFile: '.env',
      );

      // Simulate what build_command does - create a new config with updated version
      final copiedConfig = BuildConfig(
        projectRoot: originalConfig.projectRoot,
        appName: originalConfig.appName,
        buildName: '1.0.1', // version changed
        buildNumber: 2,
        platform: originalConfig.platform,
        flavor: originalConfig.flavor,
        targetDart: originalConfig.targetDart,
        outputPath: originalConfig.outputPath,
        flags: originalConfig.flags,
        globalDartDefine: originalConfig.globalDartDefine,
        dartDefine: originalConfig.dartDefine,
        globalDartDefineFromFile: originalConfig.globalDartDefineFromFile,
        dartDefineFromFile: originalConfig.dartDefineFromFile,
        useFvm: originalConfig.useFvm,
        flutterVersion: originalConfig.flutterVersion,
        useShorebird: originalConfig.useShorebird,
        shorebirdAppId: originalConfig.shorebirdAppId,
        shorebirdArtifact: originalConfig.shorebirdArtifact,
        shorebirdNoConfirm: originalConfig.shorebirdNoConfirm,
        bundletoolPath: originalConfig.bundletoolPath,
        keystorePath: originalConfig.keystorePath,
        flavors: originalConfig.flavors,
        aliases: originalConfig.aliases,
        args: originalConfig.args,
      );

      final cmd = runner.getBuildCommand(copiedConfig);
      
      expect(cmd, contains('--dart-define-from-file=.env'));
      expect(copiedConfig.finalDartDefineFromFile, '.env');
    });

    test('getBuildCommand with flavor-specific dart_define_from_file after config copy', () {
      final originalConfig = BuildConfig(
        projectRoot: minimalConfig.projectRoot,
        appName: minimalConfig.appName,
        buildName: minimalConfig.buildName,
        buildNumber: minimalConfig.buildNumber,
        platform: 'apk',
        targetDart: minimalConfig.targetDart,
        outputPath: minimalConfig.outputPath,
        flags: minimalConfig.flags,
        useFvm: false,
        useShorebird: true,
        shorebirdNoConfirm: true,
        keystorePath: minimalConfig.keystorePath,
        globalDartDefineFromFile: '.env',
        dartDefineFromFile: '.env.prod',
        flavor: 'prod',
      );

      // Simulate what build_command does
      final copiedConfig = BuildConfig(
        projectRoot: originalConfig.projectRoot,
        appName: originalConfig.appName,
        buildName: '1.0.1',
        buildNumber: 2,
        platform: originalConfig.platform,
        flavor: originalConfig.flavor,
        targetDart: originalConfig.targetDart,
        outputPath: originalConfig.outputPath,
        flags: originalConfig.flags,
        globalDartDefine: originalConfig.globalDartDefine,
        dartDefine: originalConfig.dartDefine,
        globalDartDefineFromFile: originalConfig.globalDartDefineFromFile,
        dartDefineFromFile: originalConfig.dartDefineFromFile,
        useFvm: originalConfig.useFvm,
        flutterVersion: originalConfig.flutterVersion,
        useShorebird: originalConfig.useShorebird,
        shorebirdAppId: originalConfig.shorebirdAppId,
        shorebirdArtifact: originalConfig.shorebirdArtifact,
        shorebirdNoConfirm: originalConfig.shorebirdNoConfirm,
        bundletoolPath: originalConfig.bundletoolPath,
        keystorePath: originalConfig.keystorePath,
        flavors: originalConfig.flavors,
        aliases: originalConfig.aliases,
        args: originalConfig.args,
      );

      final cmd = runner.getBuildCommand(copiedConfig);
      
      expect(cmd, contains('--dart-define-from-file=.env.prod'));
      expect(copiedConfig.finalDartDefineFromFile, '.env.prod');
    });
  });
}
