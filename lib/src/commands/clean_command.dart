import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../core/build_config.dart';
import '../core/build_flags.dart';
import '../core/flutter_runner.dart';
import '../utils/command_logger.dart';
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
        'all',
        help: 'Clean everything in .fluttercraft (including logs and history)',
        defaultsTo: false,
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        help: 'Skip confirmation',
        defaultsTo: false,
        negatable: false,
      );
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
        platform: 'aab',
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
    final logger = CommandLogger(projectRoot: projectRoot, commandName: 'clean');
    await logger.startSession();
    
    final isAll = argResults?['all'] == true;
    final fluttercraftDir = Directory(p.join(projectRoot, '.fluttercraft'));
    final distDir = Directory(config.absoluteOutputPath);

    // Show what will be cleaned
    console.section('Clean Targets');

    if (isAll) {
      console.keyValue('Entire .fluttercraft', fluttercraftDir.path);
    } else {
      final distExists = await distDir.exists();
      console.keyValue('Build folder', distExists ? distDir.path : '(not found)');
    }

    console.keyValue(
      'Flutter clean',
      flutterRunner.getCleanCommand(useFvm: config.useFvm),
    );
    console.blank();

    // Confirmation
    if (argResults?['yes'] != true) {
      if (!console.confirm('Proceed with clean?')) {
        console.warning('Clean cancelled.');
        return 0;
      }

      if (isAll) {
        if (!console.confirm(
          'WARNING: --all will delete ALL logs and build history. Are you SURE?',
          defaultValue: false,
        )) {
          console.warning('Clean cancelled.');
          return 0;
        }
      }
    }

    try {
      // Flutter clean
      console.section('Running flutter clean...');
      final result = await flutterRunner.clean(useFvm: config.useFvm);
      logger.output(result.stdout);

      if (result.success) {
        console.success('Flutter clean completed');
      } else {
        console.warning('Flutter clean exited with code ${result.exitCode}');
        logger.warning('Flutter clean exited with code ${result.exitCode}');
      }

      // Remove dist folder (already handled if we do --all later, but dist-only might be used)
      final distExists = await distDir.exists();
      if (distExists && !isAll) {
        console.section('Removing build folder...');
        logger.section('Removing build folder');
        try {
          await distDir.delete(recursive: true);
          console.success('Build folder removed');
          logger.info('Build folder removed');
        } catch (e) {
          console.error('Failed to delete build folder: $e');
          logger.error('Failed to delete build folder: $e');
          console.info('Try closing any open files in the build folder');
          return 1;
        }
      } else if (!isAll) {
        console.info('Build folder not found (nothing to delete)');
        logger.info('Build folder not found');
      }

      // If --all, remove entire .fluttercraft directory
      if (isAll) {
        console.section('Removing .fluttercraft directory...');
        logger.section('Full Reset (--all)');
        logger.info('Cleaning all files in .fluttercraft');
        
        // We close the logger before deleting the directory it's in
        await logger.endSession(success: true);
        
        try {
          if (await fluttercraftDir.exists()) {
            await fluttercraftDir.delete(recursive: true);
            console.success('Full clean complete: .fluttercraft folder removed');
          }
          return 0;
        } catch (e) {
          console.error('Failed to delete .fluttercraft directory: $e');
          console.info('Some files might be in use by another process.');
          return 1;
        }
      }

      console.blank();
      console.success('Clean complete!');
      console.info('Log: ${logger.logFilePath}');
      
      await logger.endSession(success: true);
      return 0;
    } catch (e) {
      console.error('Clean failed: $e');
      await logger.endSession(success: false);
      return 1;
    }
  }
}
