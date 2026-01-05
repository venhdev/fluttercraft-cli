import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Manual Shorebird Real Execution Test
///
/// This test ACTUALLY RUNS the Shorebird command for real testing.
///
/// Usage:
/// ```bash
/// dart test test/manual/manual_shorebird_test.dart
/// ```
///
/// Requirements:
/// - Shorebird CLI installed and configured
/// - Valid shorebird.yaml in project root
/// - Valid .env.dev file (or remove that flag)
/// - You must be in a Flutter project directory
void main() {
  test('RUN: shorebird release android with full flags', () async {
    final fooProjPathRoot = 'C:\\src\\cds_apps\\ubergas_bulk';
    // Get project root
    final projectRoot = fooProjPathRoot;
    // final projectRoot = Directory.current.path;
    final envFilePath = p.join(projectRoot, '.env.dev');

    print('\n' + '=' * 60);
    print('REAL SHOREBIRD COMMAND EXECUTION');
    print('=' * 60);
    print('Working Directory: $projectRoot');
    print('Env File: $envFilePath');
    print('Env File Exists: ${File(envFilePath).existsSync()}');
    print('=' * 60 + '\n');

    // Build the command arguments (EXACT structure from CLI)
    final args = <String>[
      'release',
      'android',
      '--artifact=apk',
      '--flutter-version=3.35.3',
      '--no-confirm',
      '\'--\'',
      '--build-name=1.2.2',
      '--build-number=80',
      '--dart-define-from-file=$envFilePath',
    ];

    print('EXECUTING COMMAND:');
    print('> shorebird ${args.join(' ')}\n');
    print('Starting build process...\n');

    // final shouldStop = true;
    // if (shouldStop) {
    //   print('Stop build process...\n');
    //   return;
    // }

    // Execute the command (SAME METHOD AS CLI)
    final stopwatch = Stopwatch()..start();
    final result = await Process.run(
      'shorebird',
      args,
      workingDirectory: projectRoot,
      runInShell: false, // Critical: No shell on Windows
    );
    stopwatch.stop();

    // Display full output
    print('\n' + '=' * 60);
    print('COMMAND COMPLETED');
    print('=' * 60);
    print('Duration: ${stopwatch.elapsed.inSeconds}s');
    print('Exit Code: ${result.exitCode}\n');

    print('-' * 60);
    print('STDOUT:');
    print('-' * 60);
    print(result.stdout);

    print('\n' + '-' * 60);
    print('STDERR:');
    print('-' * 60);
    print(result.stderr);

    print('\n' + '=' * 60);

    // Check for errors (SAME DETECTION AS CLI)
    final hasError = result.exitCode != 0 ||
        result.stdout.toString().contains('Missing argument') ||
        result.stdout.toString().contains('Usage: shorebird') ||
        result.stdout.toString().contains('Run "shorebird help"') ||
        result.stderr.toString().contains('error:') ||
        result.stderr.toString().contains('Error:');

    if (hasError) {
      print('\n❌ BUILD FAILED - Error detected in output\n');
      fail('Shorebird command failed. Check output above.');
    } else {
      print('\n✅ BUILD SUCCEEDED\n');
    }

    expect(result.exitCode, equals(0));
  }, timeout: const Timeout(Duration(minutes: 15)));
}
