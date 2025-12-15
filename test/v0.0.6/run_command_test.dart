import 'dart:io';

import 'package:test/test.dart';
import 'package:fluttercraft/src/core/app_context.dart';
import 'package:fluttercraft/src/commands/run_command.dart';
import '../test_helper.dart';

void main() {
  group('RunCommand - Integration Tests', () {
    late String tempDir;
    late String configPath;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup('run_command_test_');
      configPath = '$tempDir/fluttercraft.yaml';
    });

    tearDown(() async {
      await cleanup();
    });

    /// Create test context using the shared test config
    Future<AppContext> createTestContextFromSharedConfig() async {
      // Copy shared test config to temp directory
      await TestHelper.copyTestFile(
        'v0.0.6',
        'fluttercraft-test.yaml',
        configPath,
      );
      
      // Change to temp directory
      final originalDir = Directory.current;
      Directory.current = tempDir;
      
      try {
        return await AppContext.load();
      } finally {
        Directory.current = originalDir;
      }
    }

    /// Create test context with custom YAML content
    Future<AppContext> createTestContext(String yamlContent) async {
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', yamlContent);
      
      // Change to temp directory
      final originalDir = Directory.current;
      Directory.current = tempDir;
      
      try {
        return await AppContext.load();
      } finally {
        Directory.current = originalDir;
      }
    }

    group('List Aliases', () {
      test('lists aliases when --list flag is provided', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);
        
        // Should complete without error
        await expectLater(
          runCmd.execute(['--list']),
          completes,
        );
      });

      test('lists aliases when -l flag is provided', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);
        
        await expectLater(
          runCmd.execute(['-l']),
          completes,
        );
      });

      test('shows message when no aliases are defined', () async {
        final context = await createTestContext('''
app:
  name: testapp
''');

        final runCmd = RunCommand(context);
        await expectLater(
          runCmd.execute(['--list']),
          completes,
        );
      });
    });

    group('Alias Execution', () {
      test('shows error when no alias name is provided', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);
        
        await expectLater(
          runCmd.execute([]),
          completes,
        );
      });

      test('executes single simple command successfully', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);
        
        // This will actually execute the echo command
        await expectLater(
          runCmd.execute(['simple']),
          completes,
        );
      });

      test('executes multiple commands in sequence', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);
        
        await expectLater(
          runCmd.execute(['multi']),
          completes,
        );
      });

      test('executes commands with arguments', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);
        
        await expectLater(
          runCmd.execute(['args']),
          completes,
        );
      });

      test('executes fvm dart pub get', () async {
        // Create a minimal pubspec.yaml for the test
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0

environment:
  sdk: ^3.0.0
''');

        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);
        
        // This will execute fvm dart pub get
        await expectLater(
          runCmd.execute(['get']),
          completes,
        );
      }, skip: 'Requires fvm to be installed - run manually');

      test('executes fvm flutter doctor', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);
        
        await expectLater(
          runCmd.execute(['doctor']),
          completes,
        );
      }, skip: 'Requires fvm and flutter to be installed - run manually');

      test('combines fvm dart pub get and fvm flutter doctor', () async {
        // Create a minimal pubspec.yaml
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0

environment:
  sdk: ^3.0.0
''');

        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);
        
        await expectLater(
          runCmd.execute(['check']),
          completes,
        );
      }, skip: 'Requires fvm and flutter to be installed - run manually');
    });

    group('Error Handling', () {
      test('handles nonexistent alias gracefully', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);
        
        // Should exit with error message (but not throw in test)
        // The exit() call will terminate the process in real usage
        expect(
          () async => await runCmd.execute(['nonexistent']),
          throwsA(anything), // Will throw because exit() is called
        );
      });

      test('handles invalid command gracefully', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);
        
        // Should handle the error and exit
        expect(
          () async => await runCmd.execute(['invalid']),
          throwsA(anything),
        );
      });
    });
  });
}
