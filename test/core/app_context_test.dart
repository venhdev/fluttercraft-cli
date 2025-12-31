import 'package:test/test.dart';
import 'package:fluttercraft/src/core/app_context.dart';
import '../test_helper.dart';

/// Tests for AppContext
///
/// Verifies context loading, convenience getters, and reload functionality.
void main() {
  group('AppContext', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'app_context_test_',
      );
    });

    tearDown(() async {
      await cleanup();
    });

    group('load', () {
      test('loads context without fluttercraft.yaml', () async {
        final context = await AppContext.load(projectRoot: tempDir);

        expect(context.hasConfigFile, false);
        expect(context.appName, 'app'); // default
        expect(context.platform, 'aab'); // default
      });

      test('loads context with fluttercraft.yaml', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: myapp
version: 1.0.0+1
''');
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: apk
''');
        final context = await AppContext.load(projectRoot: tempDir);

        expect(context.hasConfigFile, true);
        expect(context.appName, 'myapp'); // from pubspec
        expect(context.platform, 'apk');
      });

      test('loads pubspec info when available', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: pubspecapp
version: 2.0.0+5
''');
        final context = await AppContext.load(projectRoot: tempDir);

        expect(context.hasPubspec, true);
        expect(context.version, '2.0.0+5');
      });

      test('works without pubspec.yaml', () async {
        final context = await AppContext.load(projectRoot: tempDir);

        expect(context.hasPubspec, false);
        expect(context.pubspecInfo, isNull);
      });

      test('prefers pubspec app name when config is default', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: pubspecapp
version: 1.0.0+1
''');
        // No fluttercraft.yaml, so config.appName will be empty/default

        final context = await AppContext.load(projectRoot: tempDir);
        // appName getter should prefer non-empty config, fall back to pubspec
        expect(context.appName, isNotEmpty);
      });
    });

    group('convenience getters', () {
      test('appName comes from pubspec', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: aab
''');
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.appName, 'testapp');
      });

      test('version is nullable when not in pubspec', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: aab
''');
        final context = await AppContext.load(projectRoot: tempDir);
        // version is null when no pubspec and buildName/buildNumber are null
        expect(context.version, isNull);
      });

      test('platform delegates to config', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    app_name: testapp
    platform: ipa
''');
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.platform, 'ipa');
      });

      test('flavor returns null when not set', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    app_name: testapp
''');
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.flavor, isNull);
      });

      test('useFvm defaults to false', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    app_name: testapp
''');
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.useFvm, false);
      });

      test('useShorebird defaults to false', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    app_name: testapp
''');
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.useShorebird, false);
      });
    });

    group('verbose getters', () {
      test('flutterVersion returns config value', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    app_name: testapp
  environments:
    fvm:
      enabled: true
      version: "3.24.0"
''');
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.flutterVersion, '3.24.0');
      });

      test('shorebirdAppId returns config value', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    app_name: testapp
  environments:
    shorebird:
      enabled: true
      app_id: test_app_123
''');
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.shorebirdAppId, 'test_app_123');
      });

      test('flags getters return config values', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    app_name: testapp
    flags:
      should_clean: true
      should_build_runner: true
      should_prompt_dart_define: true
''');
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.shouldClean, true);
        expect(context.shouldBuildRunner, true);
        expect(context.shouldPromptDartDefine, true);
      });

      test('finalDartDefine returns merged defines', () async {
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    app_name: testapp
    dart_define:
      API_KEY: secret
''');
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.finalDartDefine['API_KEY'], 'secret');
      });
    });

    group('context metadata', () {
      test('loadedAt is set', () async {
        final before = DateTime.now();
        final context = await AppContext.load(projectRoot: tempDir);
        final after = DateTime.now();

        expect(context.loadedAt.isAfter(before.subtract(Duration(seconds: 1))), true);
        expect(context.loadedAt.isBefore(after.add(Duration(seconds: 1))), true);
      });

      test('age increases over time', () async {
        final context = await AppContext.load(projectRoot: tempDir);
        final initialAge = context.age;

        await Future.delayed(Duration(milliseconds: 100));

        expect(context.age.inMilliseconds, greaterThan(initialAge.inMilliseconds));
      });

      test('isStale is false for fresh context', () async {
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.isStale, false);
      });

      test('projectRoot is set correctly', () async {
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.projectRoot, tempDir);
      });
    });

    group('reload', () {
      test('reload creates new context', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: original
version: 1.0.0+1
''');
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: aab
''');
        final context = await AppContext.load(projectRoot: tempDir);
        expect(context.appName, 'original');

        // Update file
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: updated
version: 1.0.0+1
''');

        final reloaded = await context.reload();
        expect(reloaded.appName, 'updated');
      });
    });

    group('toString', () {
      test('includes key properties', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
        await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: aab
''');
        final context = await AppContext.load(projectRoot: tempDir);
        final str = context.toString();

        expect(str, contains('appName'));
        expect(str, contains('testapp'));
        expect(str, contains('platform'));
        expect(str, contains('projectRoot'));
      });
    });
  });
}
