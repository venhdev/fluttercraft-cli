import 'dart:io';

import 'package:args/command_runner.dart';

import '../core/build_config.dart';
import '../core/build_flags.dart';
import '../core/flutter_runner.dart';
import '../utils/console.dart';

/// Clean command - cleans project and build folder
class CleanCommand extends Command<int> {
  @override
  final String name = 'clean';

  @override
  final String description = 'Clean project and build folder';

  CleanCommand() {
    argParser
      ..addFlag(
        'dist-only',
        help: 'Only remove build folder, skip flutter clean',
        defaultsTo: false,
      )
      ..addFlag('yes', abbr: 'y', help: 'Skip confirmation', defaultsTo: false);
  }

  @override
  Future<int> run() async {
    final console = Console();
    final projectRoot = Directory.current.path;

    console.header('CLEAN PROJECT');

    // Load config
    BuildConfig config;
    try {
      config = await BuildConfig.load();
    } on ConfigNotFoundException {
      // Use default output path if no config
      config = BuildConfig(
        projectRoot: projectRoot,
        appName: 'app',
        buildName: '1.0.0',
        buildNumber: 1,
        buildType: 'aab',
        targetDart: 'lib/main.dart',
        outputPath: '.fluttercraft/dist',
        flags: BuildFlags.defaults,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: 'android/key.properties',
      );
    }

    final flutterRunner = FlutterRunner(projectRoot: projectRoot);
    final distDir = Directory(config.absoluteOutputPath);

    // Show what will be cleaned
    console.section('Clean Targets');

    final distExists = await distDir.exists();
    console.keyValue('Build folder', distExists ? distDir.path : '(not found)');

    if (argResults?['dist-only'] != true) {
      console.keyValue('Flutter clean', 'Yes');
    }
    console.blank();

    // Confirmation
    if (argResults?['yes'] != true) {
      if (!console.confirm('Proceed with clean?')) {
        console.warning('Clean cancelled.');
        return 0;
      }
    }

    try {
      // Flutter clean (unless dist-only)
      if (argResults?['dist-only'] != true) {
        console.section('Running flutter clean...');
        final result = await flutterRunner.clean(useFvm: config.useFvm);

        if (result.success) {
          console.success('Flutter clean completed');
        } else {
          console.warning('Flutter clean exited with code ${result.exitCode}');
        }
      }

      // Remove dist folder
      if (distExists) {
        console.section('Removing build folder...');
        try {
          await distDir.delete(recursive: true);
          console.success('Build folder removed');
        } catch (e) {
          console.error('Failed to delete build folder: $e');
          console.info('Try closing any open files in the build folder');
          return 1;
        }
      } else {
        console.info('Build folder not found (nothing to delete)');
      }

      console.blank();
      console.success('Clean complete!');
      return 0;
    } catch (e) {
      console.error('Clean failed: $e');
      return 1;
    }
  }
}
