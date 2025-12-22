import 'dart:io';
import 'package:test/test.dart';
import 'package:fluttercraft/src/ui/shell.dart';
import 'package:fluttercraft/src/core/app_context.dart';
import 'package:path/path.dart' as p;
import '../test_helper.dart';

void main() {
  group('Shell Version Sync', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup('shell_test_');
    });

    tearDown(() async {
      await cleanup();
    });

    test('syncVersion updates fluttercraft.yaml from pubspec.yaml', () async {
      // 1. Setup initial pubspec.yaml and fluttercraft.yaml
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: test_app
version: 1.2.3+45
''');

      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build_defaults: &build_defaults
  app_name: test_app
  name: 1.0.0
  number: 1
build:
  <<: *build_defaults
''');

      // 2. Load context
      final context = await AppContext.load(projectRoot: tempDir);
      final shell = Shell(appContext: context);

      // 3. Update pubspec.yaml version
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: test_app
version: 2.1.0+99
''');

      // 4. Trigger syncVersion
      await shell.syncVersion();

      // 5. Verify fluttercraft.yaml was updated
      final configContent = await File(p.join(tempDir, 'fluttercraft.yaml')).readAsString();
      expect(configContent, contains('name: 2.1.0'));
      expect(configContent, contains('number: 99'));
    });

    test('syncVersion does not change fluttercraft.yaml if versions match', () async {
       await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: test_app
version: 1.0.0+1
''');

      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build_defaults: &build_defaults
  app_name: test_app
  name: 1.0.0
  number: 1
build:
  <<: *build_defaults
''');

      final context = await AppContext.load(projectRoot: tempDir);
      final shell = Shell(appContext: context);

      final beforeContent = await File(p.join(tempDir, 'fluttercraft.yaml')).readAsString();
      await shell.syncVersion();
      final afterContent = await File(p.join(tempDir, 'fluttercraft.yaml')).readAsString();

      expect(afterContent, equals(beforeContent));
    });
  });
}
