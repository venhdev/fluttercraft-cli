import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';
import 'package:fluttercraft/src/core/flutter_runner.dart';
import '../test_helper.dart';

/// Tests for v0.1.0 Shorebird argument fixes
///
/// Per official Shorebird docs:
/// "never add --release | --debug | --profile when using shorebird"
void main() {
  group('Shorebird Build Args', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'shorebird_test_',
      );
    });

    tearDown(() async {
      await cleanup();
    });

    test('does NOT include --release when using Shorebird', () async {
      // Copy shared test config
      await TestHelper.copyTestFile(
        'v0.1.0',
        'fluttercraft-test.yaml',
        '$tempDir/fluttercraft.yaml',
      );

      // Use projectRoot injection
      final config = await BuildConfig.load(projectRoot: tempDir);
      final runner = FlutterRunner(projectRoot: tempDir);
      final command = runner.getBuildCommand(config);

      expect(config.useShorebird, true);
      expect(command.contains('shorebird release'), true);

      // Split command to check flutter args part (after --)
      final parts = command.split('--');
      if (parts.length > 1) {
        final flutterArgs = parts.sublist(1).join('--');
        expect(
          flutterArgs.contains('--release'),
          false,
          reason: 'Shorebird builds should NOT include --release flag',
        );
      }
    });

    test('DOES include --release when NOT using Shorebird', () async {
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
app:
  name: testapp
build:
  name: 1.0.0
  number: 1
  type: apk
shorebird:
  enabled: false
fvm:
  enabled: false
''');

      // Use projectRoot injection
      final config = await BuildConfig.load(projectRoot: tempDir);
      final runner = FlutterRunner(projectRoot: tempDir);
      final command = runner.getBuildCommand(config);

      expect(config.useShorebird, false);
      expect(
        command.contains('--release'),
        true,
        reason: 'Non-Shorebird builds SHOULD include --release flag',
      );
    });

    test('includes --no-confirm when no_confirm is true', () async {
      await TestHelper.copyTestFile(
        'v0.1.0',
        'fluttercraft-test.yaml',
        '$tempDir/fluttercraft.yaml',
      );

      // Use projectRoot injection
      final config = await BuildConfig.load(projectRoot: tempDir);
      final runner = FlutterRunner(projectRoot: tempDir);
      final command = runner.getBuildCommand(config);

      expect(config.shorebirdNoConfirm, true);
      expect(command.contains('--no-confirm'), true);
    });

    test('does NOT include --no-confirm when no_confirm is false', () async {
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
app:
  name: testapp
shorebird:
  enabled: true
  no_confirm: false
''');

      // Use projectRoot injection
      final config = await BuildConfig.load(projectRoot: tempDir);
      final runner = FlutterRunner(projectRoot: tempDir);
      final command = runner.getBuildCommand(config);

      expect(config.shorebirdNoConfirm, false);
      expect(command.contains('--no-confirm'), false);
    });
  });
}
