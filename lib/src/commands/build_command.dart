import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../core/build_env.dart';
import '../core/pubspec_parser.dart';
import '../core/version_manager.dart';
import '../core/flutter_runner.dart';
import '../core/artifact_mover.dart';
import '../utils/console.dart';
import '../utils/logger.dart';

/// Build command - builds Flutter app with version management
class BuildCommand extends Command<int> {
  @override
  final String name = 'build';

  @override
  final String description = 'Build Flutter app (APK/AAB/IPA) with version management';

  BuildCommand() {
    argParser
      ..addOption(
        'type',
        abbr: 't',
        help: 'Build type: apk, aab, ipa, app',
        allowed: ['apk', 'aab', 'ipa', 'app'],
      )
      ..addFlag(
        'clean',
        abbr: 'c',
        help: 'Run flutter clean before building',
        defaultsTo: false,
      )
      ..addFlag(
        'no-confirm',
        help: 'Skip confirmation prompts',
        defaultsTo: false,
      )
      ..addOption(
        'version',
        abbr: 'v',
        help: 'Set version directly (e.g., 1.2.3)',
      )
      ..addOption(
        'build-number',
        help: 'Set build number directly',
      );
  }

  @override
  Future<int> run() async {
    final console = Console();
    final projectRoot = Directory.current.path;
    
    console.header('FLUTTER BUILD CLI');

    // Initialize components
    final buildEnv = BuildEnv(projectRoot: projectRoot);
    final pubspecParser = PubspecParser(projectRoot: projectRoot);
    final versionManager = VersionManager();
    final flutterRunner = FlutterRunner(projectRoot: projectRoot);
    final artifactMover = ArtifactMover(projectRoot: projectRoot);
    final logger = Logger(
      logDirectory: p.join(projectRoot, 'dist', 'logs'),
      appName: 'build',
    );

    // Check if .buildenv exists
    if (!await buildEnv.exists()) {
      console.warning('.buildenv not found. Run "mycli gen-env" first.');
      console.info('Attempting to generate .buildenv automatically...');
      
      // Try to load defaults
      await buildEnv.load();
    } else {
      await buildEnv.load();
    }

    // Override with command line options
    if (argResults?['type'] != null) {
      buildEnv.buildType = argResults!['type'] as String;
    }

    // Get current version
    final pubspec = await pubspecParser.parse();
    var currentVersion = SemanticVersion.parse(
      pubspec?.version ?? buildEnv.fullVersion,
    );

    // Handle version from command line
    if (argResults?['version'] != null) {
      currentVersion = SemanticVersion.parse(argResults!['version'] as String);
    } else if (argResults?['no-confirm'] != true) {
      // Interactive version bump
      console.section('Version Management');
      console.keyValue('Current Version', currentVersion.fullVersion);
      
      final bumpOptions = versionManager.getBumpOptions(currentVersion);
      final bumpChoice = console.choose('Select version increment:', bumpOptions);
      final bump = versionManager.bumpFromChoice(bumpChoice);
      currentVersion = versionManager.applyBump(currentVersion, bump);
    }

    // Handle build number from command line
    if (argResults?['build-number'] != null) {
      currentVersion.buildNumber = int.parse(argResults!['build-number'] as String);
    } else if (argResults?['no-confirm'] != true) {
      // Interactive build number
      final buildNumOptions = versionManager.getBuildNumberOptions(currentVersion);
      final buildNumChoice = console.choose('Build number:', buildNumOptions);
      final action = versionManager.buildNumberActionFromChoice(buildNumChoice);
      
      if (action == BuildNumberAction.custom) {
        final customNum = console.prompt('Enter build number');
        currentVersion = versionManager.applyBuildNumber(
          currentVersion,
          action,
          customNumber: int.tryParse(customNum) ?? currentVersion.buildNumber,
        );
      } else {
        currentVersion = versionManager.applyBuildNumber(currentVersion, action);
      }
    }

    // Update buildEnv with new version
    buildEnv.buildName = currentVersion.buildName;
    buildEnv.buildNumber = currentVersion.buildNumber.toString();

    // Start logging
    final archiveLog = await logger.startSession(version: currentVersion.fullVersion);
    logger.info('Build started');
    logger.info('Version: ${currentVersion.fullVersion}');
    logger.info('Build type: ${buildEnv.buildType}');

    // Show final configuration
    console.section('Build Configuration');
    console.keyValue('App Name', buildEnv.appName);
    console.keyValue('Version', currentVersion.fullVersion);
    console.keyValue('Build Type', buildEnv.buildType.toUpperCase());
    console.keyValue('Output', buildEnv.absoluteOutputPath);
    console.keyValue('Use FVM', buildEnv.useFvm.toString());
    console.keyValue('Use Shorebird', buildEnv.useShorebird.toString());
    console.blank();

    // Confirmation
    if (argResults?['no-confirm'] != true) {
      if (!console.confirm('Proceed with build?')) {
        console.warning('Build cancelled by user.');
        await logger.endSession(success: false);
        return 0;
      }
    }

    final startTime = DateTime.now();

    try {
      // Clean if requested
      if (argResults?['clean'] == true || buildEnv.needClean) {
        logger.section('Cleaning');
        final cleanResult = await flutterRunner.clean(useFvm: buildEnv.useFvm);
        logger.output(cleanResult.stdout);
        if (!cleanResult.success) {
          console.error('Clean failed');
          return 1;
        }
      }

      // Build runner if needed
      if (buildEnv.needBuildRunner) {
        logger.section('Build Runner');
        final brResult = await flutterRunner.buildRunner(useFvm: buildEnv.useFvm);
        logger.output(brResult.stdout);
        if (!brResult.success) {
          console.error('Build runner failed');
          return 1;
        }
      }

      // Build
      logger.section('Building ${buildEnv.buildType.toUpperCase()}');
      final buildResult = await flutterRunner.build(buildEnv);
      logger.output(buildResult.stdout);

      if (!buildResult.success) {
        console.error('Build failed!');
        logger.error('Build failed');
        await logger.endSession(success: false);
        return 1;
      }

      // Save updated .buildenv
      await buildEnv.save();

      // Move artifacts
      logger.section('Moving Artifacts');
      final artifactResult = await artifactMover.moveArtifacts(buildEnv);

      if (!artifactResult.success) {
        console.warning('Could not copy artifact: ${artifactResult.error}');
        logger.warning('Artifact copy failed: ${artifactResult.error}');
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Show summary
      console.buildSummary(
        appName: buildEnv.appName,
        version: currentVersion.fullVersion,
        buildType: buildEnv.buildType.toUpperCase(),
        outputPath: artifactResult.outputPath ?? buildEnv.absoluteOutputPath,
        duration: duration,
      );

      logger.info('Build completed successfully');
      await logger.endSession(
        success: true,
        duration: duration,
        outputPath: artifactResult.outputPath,
      );

      console.info('Log: ${logger.latestLogPath}');
      console.info('Archive: $archiveLog');

      return 0;
    } catch (e) {
      console.error('Build failed: $e');
      logger.error('Exception: $e');
      await logger.endSession(success: false);
      return 1;
    }
  }
}
