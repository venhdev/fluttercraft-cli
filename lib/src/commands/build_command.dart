import 'dart:io';
import 'dart:math';

import 'package:args/command_runner.dart';

import '../core/build_config.dart';
import '../core/build_record.dart';
import '../core/pubspec_parser.dart';
import '../core/version_manager.dart';
import '../core/flutter_runner.dart';
import '../core/artifact_mover.dart';
import '../utils/console.dart';
import '../utils/build_logger.dart';

/// Build command - builds Flutter app with version management and JSONL logging
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
    
    console.header('BUILDCRAFT CLI');

    // Generate build ID for logging
    final buildId = _generateBuildId();

    // Load config from buildcraft.yaml
    BuildConfig config;
    try {
      config = await BuildConfig.load();
    } on ConfigNotFoundException catch (e) {
      console.error(e.message);
      console.info('Create a buildcraft.yaml file in your project root.');
      return 1;
    }

    final pubspecParser = PubspecParser(projectRoot: projectRoot);
    final versionManager = VersionManager();
    final flutterRunner = FlutterRunner(projectRoot: projectRoot);
    final artifactMover = ArtifactMover(projectRoot: projectRoot);
    final logger = BuildLogger(projectRoot: projectRoot, buildId: buildId);
    final history = BuildHistory(projectRoot: projectRoot);

    // Override build type from command line
    String buildType = config.buildType;
    if (argResults?['type'] != null) {
      buildType = argResults!['type'] as String;
    }

    // Update config with overridden build type
    config = BuildConfig(
      projectRoot: config.projectRoot,
      appName: config.appName,
      buildName: config.buildName,
      buildNumber: config.buildNumber,
      buildType: buildType,
      flavor: config.flavor,
      targetDart: config.targetDart,
      outputPath: config.outputPath,
      envPath: config.envPath,
      useDartDefine: config.useDartDefine,
      needClean: config.needClean,
      needBuildRunner: config.needBuildRunner,
      useFvm: config.useFvm,
      flutterVersion: config.flutterVersion,
      useShorebird: config.useShorebird,
      shorebirdArtifact: config.shorebirdArtifact,
      shorebirdAutoConfirm: config.shorebirdAutoConfirm,
      bundletoolPath: config.bundletoolPath,
      keystorePath: config.keystorePath,
    );

    // Get current version
    // Priority: buildcraft.yaml > pubspec.yaml (if buildcraft.yaml has custom values)
    final pubspec = await pubspecParser.parse();
    final configVersion = config.fullVersion;
    final pubspecVersion = pubspec?.fullVersion;
    
    // Use buildcraft.yaml version if it's not the default (1.0.0+1)
    // Otherwise fall back to pubspec.yaml
    String versionToUse;
    if (configVersion != '1.0.0+1') {
      // buildcraft.yaml has custom version - use it
      versionToUse = configVersion;
    } else if (pubspecVersion != null) {
      // Use pubspec.yaml version
      versionToUse = pubspecVersion;
    } else {
      // Fall back to config default
      versionToUse = configVersion;
    }
    
    var currentVersion = SemanticVersion.parse(versionToUse);

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

    // Create updated config with new version
    final buildConfig = BuildConfig(
      projectRoot: config.projectRoot,
      appName: config.appName,
      buildName: currentVersion.buildName,
      buildNumber: currentVersion.buildNumber,
      buildType: config.buildType,
      flavor: config.flavor,
      targetDart: config.targetDart,
      outputPath: config.outputPath,
      envPath: config.envPath,
      useDartDefine: config.useDartDefine,
      needClean: config.needClean,
      needBuildRunner: config.needBuildRunner,
      useFvm: config.useFvm,
      flutterVersion: config.flutterVersion,
      useShorebird: config.useShorebird,
      shorebirdArtifact: config.shorebirdArtifact,
      shorebirdAutoConfirm: config.shorebirdAutoConfirm,
      bundletoolPath: config.bundletoolPath,
      keystorePath: config.keystorePath,
    );

    // Start logging
    await logger.startSession(version: currentVersion.fullVersion);
    logger.info('Build started');
    logger.info('Build ID: $buildId');
    
    // Log full build configuration
    logger.section('Build Configuration');
    logger.info('App Name: ${buildConfig.appName}');
    logger.info('Version: ${currentVersion.fullVersion}');
    logger.info('Build Type: ${buildConfig.buildType.toUpperCase()}');
    logger.info('Flavor: ${buildConfig.flavor ?? "(none)"}');
    logger.info('Target: ${buildConfig.targetDart}');
    logger.info('Output Path: ${buildConfig.absoluteOutputPath}');
    logger.info('Env Path: ${buildConfig.envPath ?? "(none)"}');
    
    logger.section('Build Flags');
    logger.info('Use Dart Define: ${buildConfig.useDartDefine}');
    logger.info('Need Clean: ${buildConfig.needClean}');
    logger.info('Need Build Runner: ${buildConfig.needBuildRunner}');
    
    logger.section('Integrations');
    logger.info('Use FVM: ${buildConfig.useFvm}');
    logger.info('Flutter Version: ${buildConfig.flutterVersion ?? "(auto)"}');
    logger.info('Use Shorebird: ${buildConfig.useShorebird}');
    logger.info('Shorebird Artifact: ${buildConfig.shorebirdArtifact ?? "(default)"}');
    logger.info('Shorebird Auto Confirm: ${buildConfig.shorebirdAutoConfirm}');

    // Get full build command for JSONL record
    final buildCmd = flutterRunner.getBuildCommand(buildConfig);
    logger.section('Build Command');
    logger.info('Command: $buildCmd');

    // Show final configuration
    console.section('Build Configuration');
    console.keyValue('App Name', buildConfig.appName);
    console.keyValue('Version', currentVersion.fullVersion);
    console.keyValue('Build Type', buildConfig.buildType.toUpperCase());
    console.keyValue('Output', buildConfig.absoluteOutputPath);
    console.keyValue('Use FVM', buildConfig.useFvm.toString());
    console.keyValue('Use Shorebird', buildConfig.useShorebird.toString());
    console.keyValue('Build ID', buildId);
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
      if (argResults?['clean'] == true || buildConfig.needClean) {
        logger.section('Cleaning');
        final cleanResult = await flutterRunner.clean(useFvm: buildConfig.useFvm);
        logger.output(cleanResult.stdout);
        if (!cleanResult.success) {
          console.error('Clean failed');
          return 1;
        }
      }

      // Build runner if needed
      if (buildConfig.needBuildRunner) {
        logger.section('Build Runner');
        final brResult = await flutterRunner.buildRunner(useFvm: buildConfig.useFvm);
        logger.output(brResult.stdout);
        if (!brResult.success) {
          console.error('Build runner failed');
          return 1;
        }
      }

      // Build
      logger.section('Building ${buildConfig.buildType.toUpperCase()}');
      final buildResult = await flutterRunner.build(buildConfig);
      logger.output(buildResult.stdout);
      if (buildResult.stderr.isNotEmpty) {
        logger.section('Build Errors/Warnings');
        logger.output(buildResult.stderr);
      }

      if (!buildResult.success) {
        console.error('Build failed!');
        logger.error('Build failed with exit code: ${buildResult.exitCode}');
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        
        // Record failed build
        final record = BuildRecord.failed(
          id: buildId,
          cmd: buildCmd,
          duration: duration,
        );
        await history.append(record);
        
        await logger.endSession(success: false, duration: duration);
        return 1;
      }

      // Move artifacts
      logger.section('Moving Artifacts');
      final artifactResult = await artifactMover.moveArtifacts(buildConfig);

      if (!artifactResult.success) {
        console.warning('Could not copy artifact: ${artifactResult.error}');
        logger.warning('Artifact copy failed: ${artifactResult.error}');
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Record successful build
      final record = BuildRecord.success(
        id: buildId,
        cmd: buildCmd,
        duration: duration,
      );
      await history.append(record);

      // Show summary
      console.buildSummary(
        appName: buildConfig.appName,
        version: currentVersion.fullVersion,
        buildType: buildConfig.buildType.toUpperCase(),
        outputPath: artifactResult.outputPath ?? buildConfig.absoluteOutputPath,
        duration: duration,
      );

      logger.info('Build completed successfully');
      await logger.endSession(
        success: true,
        duration: duration,
        outputPath: artifactResult.outputPath,
      );

      console.info('Log: ${logger.latestLogPath}');
      console.info('Build Log: ${logger.buildLogPath}');
      console.info('History: ${history.historyPath}');

      return 0;
    } catch (e) {
      console.error('Build failed: $e');
      logger.error('Exception: $e');
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      // Record failed build
      final record = BuildRecord.failed(
        id: buildId,
        cmd: buildCmd,
        duration: duration,
      );
      await history.append(record);
      
      await logger.endSession(success: false, duration: duration);
      return 1;
    }
  }

  /// Generate a simple unique build ID
  String _generateBuildId() {
    final now = DateTime.now();
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}'
        '-$random';
  }
}
