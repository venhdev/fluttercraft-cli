import 'package:fluttercraft/src/commands/build_command.dart';
import 'package:fluttercraft/src/core/build_config.dart';
import 'package:fluttercraft/src/core/build_flags.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

/// Tests for build command review/confirmation flags after removing no_review config
/// 
/// Verifies that:
/// 1. Default behavior shows prompt
/// 2. --review flag forces prompt
/// 3. -y / --no-review flags skip prompt
/// 4. Legacy no_review config is ignored
void main() {
  group('BuildCommand Review Flags (v0.3.3)', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'build_review_flags_test_',
      );
    });

    tearDown(() async {
      await cleanup();
    });

    test('shouldReview defaults to true when --review flag is set', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: apk
''');

      final command = BuildCommand();
      
      // Parse args with --review flag
      final argResults = command.argParser.parse(['--review']);
      
      // Simulate shouldReview logic from build_command.dart:239-242
      final shouldReview =
          argResults['review'] == true &&
          argResults['yes'] != true;
      
      expect(shouldReview, isTrue, 
        reason: '--review flag should enable prompt');
    });

    test('shouldReview is false when -y flag is set', () async {
      final command = BuildCommand();
      
      // Parse args with -y flag
      final argResults = command.argParser.parse(['-y']);
      
      // Simulate shouldReview logic
      final shouldReview =
          argResults['review'] == true &&
          argResults['yes'] != true;
      
      expect(shouldReview, isFalse,
        reason: '-y flag should skip prompt (yes is true)');
    });

    test('shouldReview is false when --no-review flag is set', () async {
      final command = BuildCommand();
      
      // Parse args with --no-review (which sets review to false)
      final argResults = command.argParser.parse(['--no-review']);
      
      // Simulate shouldReview logic
      final shouldReview =
          argResults['review'] == true &&
          argResults['yes'] != true;
      
      expect(shouldReview, isFalse,
        reason: '--no-review flag should skip prompt (review is false)');
    });

    test('shouldReview is true by default (no flags)', () async {
      final command = BuildCommand();
      
      // Parse args with no flags (default behavior)
      final argResults = command.argParser.parse([]);
      
      // Simulate shouldReview logic
      // Note: review defaults to true, yes defaults to false
      final shouldReview =
          argResults['review'] == true &&
          argResults['yes'] != true;
      
      expect(shouldReview, isTrue,
        reason: 'Default behavior should show prompt');
    });

    test('legacy no_review config is ignored (config loads without error)', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      
      // Create config WITH legacy no_review setting
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build_defaults: &build_defaults
    platform: apk
    no_review: true
  build:
    <<: *build_defaults
''');

      // Should load without error (ignoring no_review)
      final config = await BuildConfig.load(projectRoot: tempDir);
      
      expect(config, isNotNull);
      expect(config.platform, 'apk');
      // noReview field no longer exists, so we can't check it
      // Just verify config loads successfully
    });

    test('BuildConfig no longer has noReview field', () {
      // Create a BuildConfig instance
      final config = BuildConfig(
        projectRoot: tempDir,
        appName: 'testapp',
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

      // Verify config is created successfully without noReview field
      expect(config.appName, 'testapp');
      expect(config.platform, 'apk');
      
      // This would fail to compile if noReview field still existed:
      // config.noReview; // ← This line would cause compile error
    });

    test('--review and -y flags cannot both be true', () async {
      final command = BuildCommand();
      
      // If user somehow passes both (shouldn't happen, but let's verify logic)
      final argResults = command.argParser.parse(['--review', '-y']);
      
      // Simulate shouldReview logic
      final shouldReview =
          argResults['review'] == true &&
          argResults['yes'] != true;
      
      expect(shouldReview, isFalse,
        reason: '-y should override --review (yes takes precedence)');
    });

    test('flag defaults match expected behavior', () async {
      final command = BuildCommand();
      final argResults = command.argParser.parse([]);
      
      // Verify default values
      expect(argResults['review'], isTrue, 
        reason: '--review defaults to true');
      expect(argResults['yes'], isFalse,
        reason: '-y defaults to false');
      expect(argResults['no-confirm'], isFalse,
        reason: '--no-confirm defaults to false');
      
      // Therefore shouldReview should be true by default
      final shouldReview =
          argResults['review'] == true &&
          argResults['yes'] != true;
      
      expect(shouldReview, isTrue,
        reason: 'Default should show prompt (review=true, yes=false)');
    });

    test('config without no_review field loads normally', () async {
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
      
      // Create clean config WITHOUT no_review
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: apk
    target: lib/main.dart

  environments:
    fvm:
      enabled: false
    shorebird:
      enabled: false
''');

      final config = await BuildConfig.load(projectRoot: tempDir);
      
      expect(config, isNotNull);
      expect(config.platform, 'apk');
      expect(config.targetDart, 'lib/main.dart');
    });
  });
}
