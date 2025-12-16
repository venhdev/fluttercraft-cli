import 'dart:io';

import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';
import '../test_helper.dart';

/// Tests for v0.1.0 no_confirm config parsing
void main() {
  group('Config no_confirm Parsing', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup('noconfirm_test_');
    });

    tearDown(() async {
      await cleanup();
    });

    test('parses no_confirm: true from shared config', () async {
      await TestHelper.copyTestFile('v0.1.0', 'fluttercraft-test.yaml', '$tempDir/fluttercraft.yaml');

      final config = await BuildConfig.load(projectRoot: tempDir);
      expect(config.shorebirdNoConfirm, true);
    });

    test('parses no_confirm: false correctly', () async {
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
app:
  name: testapp
shorebird:
  enabled: true
  no_confirm: false
''');

      final config = await BuildConfig.load(projectRoot: tempDir);
      expect(config.shorebirdNoConfirm, false);
    });

    test('defaults to true when no_confirm is not specified', () async {
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
app:
  name: testapp
shorebird:
  enabled: true
''');

      final config = await BuildConfig.load(projectRoot: tempDir);
      expect(config.shorebirdNoConfirm, true);
    });

    test('defaults to true when shorebird section is missing', () async {
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
app:
  name: testapp
''');

      final config = await BuildConfig.load(projectRoot: tempDir);
      expect(config.shorebirdNoConfirm, true);
    });

    test('defaults to true when config file does not exist', () async {
      final config = await BuildConfig.load(
        configPath: '$tempDir/nonexistent.yaml',
      );
      expect(config.shorebirdNoConfirm, true);
    });
  });
}
