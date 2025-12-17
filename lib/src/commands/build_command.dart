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
  final String description =
      'Build Flutter app (APK/AAB/IPA) with version management';

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
      ..addOption('build-number', help: 'Set build number directly');
  }

  @override
  Future<int> run() async {
    final console = Console();
    final projectRoot = Directory.current.path;

    console.header('fluttercraft CLI');

    // Generate build ID for logging
    final buildId = _generateBuildId();

    // Load config from fluttercraft.yaml
    BuildConfig config;
    try {
      config = await BuildConfig.load();
    } on ConfigNotFoundException catch (e) {
      console.error(e.message);
      console.info('Create a fluttercraft.yaml file in your project root.');
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
      flags: config.flags,
      globalDartDefine: config.globalDartDefine,
      dartDefine: config.dartDefine,
      useFvm: config.useFvm,
      flutterVersion: config.flutterVersion,
      useShorebird: config.useShorebird,
      shorebirdAppId: config.shorebirdAppId,
      shorebirdArtifact: config.shorebirdArtifact,
      shorebirdNoConfirm: config.shorebirdNoConfirm,
      bundletoolPath: config.bundletoolPath,
      keystorePath: config.keystorePath,
      flavors: config.flavors,
      aliases: config.aliases,
    );

    // Get current version
    // Priority: fluttercraft.yaml > pubspec.yaml (if fluttercraft.yaml has custom values)
    final pubspec = await pubspecParser.parse();
    final configVersion = config.fullVersion;
    final pubspecVersion = pubspec?.fullVersion;

    // Use fluttercraft.yaml version if it's not the default (1.0.0+1)
    // Otherwise fall back to pubspec.yaml
    String versionToUse;
    if (configVersion != '1.0.0+1') {
      // fluttercraft.yaml has custom version - use it
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
      final bumpChoice = console.choose(
        'Select version increment:',
        bumpOptions,
      );
      final bump = versionManager.bumpFromChoice(bumpChoice);
      currentVersion = versionManager.applyBump(currentVersion, bump);
    }

    // Handle build number from command line
    if (argResults?['build-number'] != null) {
      currentVersion.buildNumber = int.parse(
        argResults!['build-number'] as String,
      );
    } else if (argResults?['no-confirm'] != true) {
      // Interactive build number
      final buildNumOptions = versionManager.getBuildNumberOptions(
        currentVersion,
      );
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
        currentVersion = versionManager.applyBuildNumber(
          currentVersion,
          action,
        );
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
      flags: config.flags,
      globalDartDefine: config.globalDartDefine,
      dartDefine: config.dartDefine,
      useFvm: config.useFvm,
      flutterVersion: config.flutterVersion,
      useShorebird: config.useShorebird,
      shorebirdAppId: config.shorebirdAppId,
      shorebirdArtifact: config.shorebirdArtifact,
      shorebirdNoConfirm: config.shorebirdNoConfirm,
      bundletoolPath: config.bundletoolPath,
      keystorePath: config.keystorePath,
      flavors: config.flavors,
      aliases: config.aliases,
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

    logger.section('Build Flags');
    logger.info('Prompt Dart Define: ${buildConfig.shouldPromptDartDefine}');
    logger.info('Should Clean: ${buildConfig.shouldClean}');
    logger.info('Should Build Runner: ${buildConfig.shouldBuildRunner}');

    // Log dart define (always logged now since they always apply)
    if (buildConfig.finalDartDefine.isNotEmpty) {
      logger.section('Dart Define');
      final finalDefines = buildConfig.finalDartDefine;
      for (final entry in finalDefines.entries) {
        logger.info('${entry.key}: ${entry.value}');
      }
    }

    logger.section('Integrations');
    logger.info('Use FVM: ${buildConfig.useFvm}');
    logger.info('Flutter Version: ${buildConfig.flutterVersion ?? "(auto)"}');
    logger.info('Use Shorebird: ${buildConfig.useShorebird}');
    logger.info(
      'Shorebird Artifact: ${buildConfig.shorebirdArtifact ?? "(default)"}',
    );
    logger.info('Shorebird Auto Confirm: ${buildConfig.shorebirdNoConfirm}');

    // Get full build command for JSONL record
    var buildCmd = flutterRunner.getBuildCommand(buildConfig);
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

    // Show the full command that will be executed
    console.section('Build Command');
    console.info('The following command will be executed:');
    console.blank();
    console.info('  $buildCmd');
    console.blank();

    // Interactive dart-define input (if flag is enabled)
    final customDartDefines = <String>[];
    if (buildConfig.shouldPromptDartDefine && argResults?['no-confirm'] != true) {
      console.section('Custom Dart Defines');
      console.info('Enter custom dart-define values (format: KEY=VALUE)');
      console.info('Press Enter on empty line to finish.');
      console.blank();

      while (true) {
        stdout.write('dart-define> ');
        final input = stdin.readLineSync()?.trim() ?? '';

        if (input.isEmpty) break;

        if (input.contains('=')) {
          customDartDefines.add(input);
          console.success('Added: --dart-define=$input');
        } else {
          console.warning('Invalid format. Use KEY=VALUE');
        }
      }

      // Append custom dart defines to build command
      if (customDartDefines.isNotEmpty) {
        for (final define in customDartDefines) {
          buildCmd += ' --dart-define=$define';
        }
        console.blank();
        console.info('Updated command:');
        console.info('  $buildCmd');
        console.blank();
      }
    }

    // Confirmation with edit option
    if (argResults?['no-confirm'] != true) {
      var currentCmd = buildCmd;

      while (true) {
        stdout.write('\nProceed with build? (y/n/e to edit): ');
        final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';

        if (input == 'n' || input == 'no') {
          console.warning('Build cancelled by user.');
          await logger.endSession(success: false);
          return 0;
        } else if (input == 'y' || input == 'yes' || input.isEmpty) {
          // Update buildCmd if it was edited
          buildCmd = currentCmd;
          break;
        } else if (input == 'e' || input == 'edit') {
          console.section('Edit Command');
          console.info('Current command:');
          console.info('  $currentCmd');
          console.blank();
          stdout.write(
            'Enter modified command (or press Enter to keep current): ',
          );
          final edited = stdin.readLineSync()?.trim() ?? '';
          if (edited.isNotEmpty) {
            currentCmd = edited;
            console.success('Command updated.');
            console.info('New command:');
            console.info('  $currentCmd');
          }
        } else {
          console.warning('Invalid input. Use y (yes), n (no), or e (edit).');
        }
      }
    }

    final startTime = DateTime.now();

    try {
      // Clean if requested
      if (argResults?['clean'] == true || buildConfig.shouldClean) {
        logger.section('Cleaning');
        final cleanResult = await flutterRunner.clean(
          useFvm: buildConfig.useFvm,
        );
        logger.output(cleanResult.stdout);
        if (!cleanResult.success) {
          console.error('Clean failed');
          return 1;
        }
      }

      // Build runner if needed
      if (buildConfig.shouldBuildRunner) {
        logger.section('Build Runner');
        final brResult = await flutterRunner.buildRunner(
          useFvm: buildConfig.useFvm,
        );
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
