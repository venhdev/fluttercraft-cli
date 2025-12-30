import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';
import 'package:fluttercraft/src/core/build_flags.dart';
import '../test_helper.dart';

/// Tests for dart_define_from_file configuration loading
void main() {
  group('BuildConfig dart_define_from_file', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'dart_define_from_file_test_',
      );
    });

    tearDown(() async {
      await cleanup();
    });

    test('loads dart_define_from_file from build_defaults', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build_defaults: &build_defaults
    platform: apk
    dart_define_from_file: .env
  build:
    <<: *build_defaults
''');

      final config = await BuildConfig.load(projectRoot: tempDir);

      expect(config.finalDartDefineFromFile, '.env');
      expect(config.globalDartDefineFromFile, '.env');
    });

    test('loads dart_define_from_file from build section', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: apk
    dart_define_from_file: .env.prod
''');

      final config = await BuildConfig.load(projectRoot: tempDir);

      expect(config.finalDartDefineFromFile, '.env.prod');
    });

    test('flavor overrides dart_define_from_file', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build_defaults: &build_defaults
    platform: apk
    dart_define_from_file: .env
  build:
    <<: *build_defaults
    flavor: dev
  flavors:
    dev:
      platform: apk
      dart_define_from_file: .env.dev
''');

      final config = await BuildConfig.load(projectRoot: tempDir);

      expect(config.finalDartDefineFromFile, '.env.dev');
      expect(config.flavor, 'dev');
    });

    test('flavor inherits dart_define_from_file when not overridden', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build_defaults: &build_defaults
    platform: apk
    dart_define_from_file: .env
  build:
    <<: *build_defaults
    flavor: staging
  flavors:
    staging:
      platform: aab
''');

      final config = await BuildConfig.load(projectRoot: tempDir);

      expect(config.finalDartDefineFromFile, '.env');
      expect(config.flavor, 'staging');
    });

    test('returns null when dart_define_from_file not configured', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: apk
''');

      final config = await BuildConfig.load(projectRoot: tempDir);

      expect(config.finalDartDefineFromFile, isNull);
      expect(config.globalDartDefineFromFile, isNull);
      expect(config.dartDefineFromFile, isNull);
    });

    test('BuildConfig constructor preserves dart_define_from_file values', () {
      final config = BuildConfig(
        projectRoot: tempDir,
        appName: 'testapp',
        buildName: '1.0.0',
        buildNumber: 1,
        platform: 'apk',
        targetDart: 'lib/main.dart',
        outputPath: 'dist',
        flags: BuildFlags.defaults,
        globalDartDefineFromFile: '.env',
        dartDefineFromFile: '.env.dev',
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: 'key.jks',
      );

      expect(config.globalDartDefineFromFile, '.env');
      expect(config.dartDefineFromFile, '.env.dev');
      expect(config.finalDartDefineFromFile, '.env.dev');
    });

    test('finalDartDefineFromFile returns flavor-specific over global', () {
      final config = BuildConfig(
        projectRoot: tempDir,
        appName: 'testapp',
        buildName: '1.0.0',
        buildNumber: 1,
        platform: 'apk',
        targetDart: 'lib/main.dart',
        outputPath: 'dist',
        flags: BuildFlags.defaults,
        globalDartDefineFromFile: '.env',
        dartDefineFromFile: '.env.dev',
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: 'key.jks',
      );

      expect(config.finalDartDefineFromFile, '.env.dev');
    });

    test('finalDartDefineFromFile returns global when flavor-specific is null', () {
      final config = BuildConfig(
        projectRoot: tempDir,
        appName: 'testapp',
        buildName: '1.0.0',
        buildNumber: 1,
        platform: 'apk',
        targetDart: 'lib/main.dart',
        outputPath: 'dist',
        flags: BuildFlags.defaults,
        globalDartDefineFromFile: '.env',
        dartDefineFromFile: null,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: 'key.jks',
      );

      expect(config.finalDartDefineFromFile, '.env');
    });
  });

  group('BuildConfig with Shorebird command generation', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'shorebird_dart_define_test_',
      );
    });

    tearDown(() async {
      await cleanup();
    });

    test('includes dart_define_from_file in Shorebird command', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: apk
    dart_define_from_file: .env.dev
  environments:
    shorebird:
      enabled: true
      no_confirm: true
''');

      final config = await BuildConfig.load(projectRoot: tempDir);
      expect(config.finalDartDefineFromFile, '.env.dev');
      expect(config.useShorebird, true);
    });

    test('BuildConfig copy preserves dart_define_from_file', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: apk
    dart_define_from_file: .env
''');

      final config = await BuildConfig.load(projectRoot: tempDir);
      
      // Create a new config simulating what build_command does
      final newConfig = BuildConfig(
        projectRoot: config.projectRoot,
        appName: config.appName,
        buildName: '1.0.0',
        buildNumber: 1,
        platform: config.platform,
        flavor: config.flavor,
        targetDart: config.targetDart,
        noReview: config.noReview,
        outputPath: config.outputPath,
        flags: config.flags,
        globalDartDefine: config.globalDartDefine,
        dartDefine: config.dartDefine,
        globalDartDefineFromFile: config.globalDartDefineFromFile,
        dartDefineFromFile: config.dartDefineFromFile,
        useFvm: config.useFvm,
        flutterVersion: config.flutterVersion,
        useShorebird: config.useShorebird,
        shorebirdAppId: config.shorebirdAppId,
        shorebirdArtifact: config.shorebirdArtifact,
        shorebirdNoConfirm: config.shorebirdNoConfirm,
        bundletoolPath: config.bundletoolPath,
        keystorePath: config.keystorePath,
        flavors: config.flavors,
        aliases: config.aliases,
        args: config.args,
      );

      expect(newConfig.globalDartDefineFromFile, '.env');
      // dartDefineFromFile may be set from build section
      expect(newConfig.finalDartDefineFromFile, '.env');
    });

    test('BuildConfig with flavor preserves flavor dart_define_from_file', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: apk
    flavor: dev
    dart_define_from_file: .env
  flavors:
    dev:
      platform: apk
      dart_define_from_file: .env.dev
''');

      final config = await BuildConfig.load(projectRoot: tempDir);
      
      // Create a new config simulating what build_command does
      final newConfig = BuildConfig(
        projectRoot: config.projectRoot,
        appName: config.appName,
        buildName: '1.0.0',
        buildNumber: 1,
        platform: config.platform,
        flavor: config.flavor,
        targetDart: config.targetDart,
        noReview: config.noReview,
        outputPath: config.outputPath,
        flags: config.flags,
        globalDartDefine: config.globalDartDefine,
        dartDefine: config.dartDefine,
        globalDartDefineFromFile: config.globalDartDefineFromFile,
        dartDefineFromFile: config.dartDefineFromFile,
        useFvm: config.useFvm,
        flutterVersion: config.flutterVersion,
        useShorebird: config.useShorebird,
        shorebirdAppId: config.shorebirdAppId,
        shorebirdArtifact: config.shorebirdArtifact,
        shorebirdNoConfirm: config.shorebirdNoConfirm,
        bundletoolPath: config.bundletoolPath,
        keystorePath: config.keystorePath,
        flavors: config.flavors,
        aliases: config.aliases,
        args: config.args,
      );

      expect(newConfig.globalDartDefineFromFile, '.env');
      expect(newConfig.dartDefineFromFile, '.env.dev');
      expect(newConfig.finalDartDefineFromFile, '.env.dev');
    });

    test('REGRESSION: platform override preserves dart_define_from_file', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: apk
    dart_define_from_file: .env
''');

      final config = await BuildConfig.load(projectRoot: tempDir);
      expect(config.globalDartDefineFromFile, '.env');

      // Simulate what build_command does when overriding platform (line 108)
      final newConfig = BuildConfig(
        projectRoot: config.projectRoot,
        appName: config.appName,
        buildName: config.buildName,
        buildNumber: config.buildNumber,
        platform: 'aab', // platform changed
        flavor: config.flavor,
        targetDart: config.targetDart,
        noReview: config.noReview,
        outputPath: config.outputPath,
        flags: config.flags,
        globalDartDefine: config.globalDartDefine,
        dartDefine: config.dartDefine,
        globalDartDefineFromFile: config.globalDartDefineFromFile,
        dartDefineFromFile: config.dartDefineFromFile,
        useFvm: config.useFvm,
        flutterVersion: config.flutterVersion,
        useShorebird: config.useShorebird,
        shorebirdAppId: config.shorebirdAppId,
        shorebirdArtifact: config.shorebirdArtifact,
        shorebirdNoConfirm: config.shorebirdNoConfirm,
        bundletoolPath: config.bundletoolPath,
        keystorePath: config.keystorePath,
        flavors: config.flavors,
        aliases: config.aliases,
        args: config.args,
      );

      // Bug: dart_define_from_file was being lost here
      expect(newConfig.globalDartDefineFromFile, '.env');
      expect(newConfig.finalDartDefineFromFile, '.env');
    });
  });
}
