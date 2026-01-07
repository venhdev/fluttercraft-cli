import 'dart:io' hide ProcessResult;
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../core/artifact_mover.dart';
import '../core/build_config.dart';
import '../core/build_record.dart';
import '../core/flutter_runner.dart';
import '../core/pubspec_parser.dart';
import '../core/version_manager.dart';
import '../utils/command_logger.dart';
import '../utils/console.dart';
import '../utils/process_runner.dart';

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
        'platform',
        abbr: 'p',
        help: 'Build platform: apk, aab, ipa, ios',
        allowed: ['apk', 'aab', 'ipa', 'ios'],
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
      ..addFlag(
        'review',
        help: 'Ask for final confirmation/review before building',
        defaultsTo: true,
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        help: 'Skip all confirmation prompts (same as --no-review)',
        defaultsTo: false,
        negatable: false,
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

    // Validate Flutter project (must have pubspec.yaml)
    final pubspecParser = PubspecParser(projectRoot: projectRoot);
    if (!await pubspecParser.exists()) {
      console.error('This command must be run from a Flutter project root.');
      console.info('Expected: pubspec.yaml in current directory');
      console.info('Current directory: $projectRoot');
      return 1;
    }

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

    // Override build platform from command line
    String platform = config.platform;
    if (argResults?['platform'] != null) {
      platform = argResults!['platform'] as String;
    }

    // Validate Platform (Mobile Only)
    const supportedPlatforms = ['apk', 'aab', 'ipa', 'ios'];
    if (!supportedPlatforms.contains(platform)) {
      console.error('Platform "$platform" is not currently supported.');
      console.info('Supported platforms: ${supportedPlatforms.join(", ")}');
      console.warning('Desktop and Web builds are coming soon!');
      return 1;
    }

    final versionManager = VersionManager();
    final flutterRunner = FlutterRunner(projectRoot: projectRoot);
    final artifactMover = ArtifactMover(projectRoot: projectRoot);
    final logger = CommandLogger(projectRoot: projectRoot, commandName: 'build', buildId: buildId);
    final history = BuildHistory(projectRoot: projectRoot);

    // Update config with overridden build platform
    config = BuildConfig(
      projectRoot: config.projectRoot,
      appName: config.appName,
      buildName: config.buildName,
      buildNumber: config.buildNumber,
      platform: platform,
      flavor: config.flavor,
      targetDart: config.targetDart,
      noReview: config.noReview,
      outputPath: config.outputPath,
      flags: config.flags,
      globalDartDefine: config.globalDartDefine,
      dartDefine: config.dartDefine,
      globalDartDefineFromFile: config.globalDartDefineFromFile,
      dartDefineFromFile: config.dartDefineFromFile,
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
      args: config.args,
    );

    // Get version from pubspec.yaml (since config now has null buildName/buildNumber)
    final pubspecInfo = await pubspecParser.parse();
    final versionToUse = pubspecInfo?.fullVersion;
    
    // If no version available, use minimal default for version management UI only
    var currentVersion = versionToUse != null 
        ? SemanticVersion.parse(versionToUse)
        : SemanticVersion(major: 1, minor: 0, patch: 0, buildNumber: 1);

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

    // Update pubspec.yaml if version changed
    if (currentVersion.fullVersion != versionToUse && argResults?['no-confirm'] != true) {
      final updated = await pubspecParser.updateVersion(currentVersion.fullVersion);
      if (updated) {
        console.success(
          'Updated pubspec.yaml version to ${currentVersion.fullVersion}',
        );
      } else {
        console.warning('Failed to update pubspec.yaml version.');
      }
    }

    // Create updated config with new version
    final buildConfig = BuildConfig(
      projectRoot: config.projectRoot,
      appName: config.appName,
      buildName: currentVersion.buildName,
      buildNumber: currentVersion.buildNumber,
      platform: config.platform,
      flavor: config.flavor,
      targetDart: config.targetDart,
      noReview: config.noReview,
      outputPath: config.outputPath,
      flags: config.flags,
      globalDartDefine: config.globalDartDefine,
      dartDefine: config.dartDefine,
      globalDartDefineFromFile: config.globalDartDefineFromFile,
      dartDefineFromFile: config.dartDefineFromFile,
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
      args: config.args,
    );

    // Determine if we should ask for review
    final shouldReview =
        argResults?['review'] == true &&
        argResults?['yes'] != true &&
        argResults?['no-confirm'] != true &&
        !buildConfig.noReview;

    // Start logging
    await logger.startSession(version: currentVersion.fullVersion);
    logger.info('Build started');
    logger.info('Build ID: $buildId');

    // Log full build configuration
    logger.section('Build Configuration');
    logger.info('App Name: ${buildConfig.appName}');
    logger.info('Version: ${currentVersion.fullVersion}');
    logger.info('Platform: ${buildConfig.platform.toUpperCase()}');
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

    // Log dart define from file if configured
    if (buildConfig.finalDartDefineFromFile != null) {
      logger.section('Dart Define From File');
      logger.info('Configured path: ${buildConfig.finalDartDefineFromFile}');
      
      // Validate file existence
      final envFilePath = p.join(buildConfig.projectRoot, buildConfig.finalDartDefineFromFile!);
      final envFile = File(envFilePath);
      logger.info('Resolved path: $envFilePath');
      
      if (!envFile.existsSync()) {
        logger.warning('⚠ File not found!');
        logger.warning('This flag will NOT be included in the build command.');
        logger.warning('Create the file or update fluttercraft.yaml to fix this.');
      } else {
        logger.info('File exists: ✓');
        logger.info('This file will be passed to Flutter build.');
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

    // Debug: Check dart_define_from_file value before command generation
    logger.section('Debug: Command Generation');
    logger.info('buildConfig.finalDartDefineFromFile = ${buildConfig.finalDartDefineFromFile}');
    logger.info('buildConfig.dartDefineFromFile = ${buildConfig.dartDefineFromFile}');
    logger.info('buildConfig.globalDartDefineFromFile = ${buildConfig.globalDartDefineFromFile}');

    // Get full build command for JSONL record
    var buildCmd = flutterRunner.getBuildCommand(buildConfig);
    logger.section('Build Command');
    logger.info('Command: $buildCmd');

    // Show final configuration
    console.section('Build Configuration');
    console.keyValue('App Name', buildConfig.appName);
    console.keyValue('Version', currentVersion.fullVersion);
    console.keyValue('Platform', buildConfig.platform.toUpperCase());
    console.keyValue('Output', buildConfig.absoluteOutputPath);
    console.keyValue('Use FVM', buildConfig.useFvm.toString());
    console.keyValue('Use Shorebird', buildConfig.useShorebird.toString());
    if (buildConfig.finalDartDefineFromFile != null) {
      final envFilePath = p.join(buildConfig.projectRoot, buildConfig.finalDartDefineFromFile!);
      final envFile = File(envFilePath);
      final fileStatus = envFile.existsSync() ? '✓' : '✗ NOT FOUND';
      
      // Show source: flavor override or default
      String source = '';
      if (buildConfig.flavor != null) {
        // Check if flavor overrides it
        final hasFlavorOverride = buildConfig.dartDefineFromFile != null;
        source = hasFlavorOverride ? ' (from flavor)' : ' (from defaults)';
      }
      
      console.keyValue('Dart Define From File', '${buildConfig.finalDartDefineFromFile}$source $fileStatus');
      
      if (!envFile.existsSync()) {
        console.warning('Warning: File not found at $envFilePath');
        console.info('The build may fail if Flutter expects this file.');
      }
    }
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
    if (shouldReview) {
      var currentCmd = buildCmd;

      while (true) {
        stdout.write('\nDo you want to proceed? (y/n) or (e)dit command: ');
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
            // Validate required flags for Shorebird commands
            if (buildConfig.useShorebird && edited.contains('shorebird')) {
              final hasDoubleDash = edited.contains(' -- ');
              if (hasDoubleDash) {
                final parts = edited.split(' -- ');
                final flutterArgs = parts.length > 1 ? parts[1] : '';
                
                // Warn if build-name or build-number are missing from Flutter args
                if (!flutterArgs.contains('--build-name')) {
                  console.warning('Warning: --build-name is missing from Flutter arguments (after --).');
                  console.info('Shorebird requires --build-name for release commands.');
                }
                if (!flutterArgs.contains('--build-number')) {
                  console.warning('Warning: --build-number is missing from Flutter arguments (after --).');
                  console.info('Shorebird requires --build-number for release commands.');
                }
              } else {
                console.warning('Warning: Missing -- separator for Flutter build arguments.');
              }
            }
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
      logger.section('Building ${buildConfig.platform.toUpperCase()}');
      
      // Clean existing artifacts before build to prevent stale results
      await artifactMover.cleanArtifacts(buildConfig);

      // Check if command was manually edited
      final generatedCmd = flutterRunner.getBuildCommand(buildConfig);
      final wasEdited = buildCmd != generatedCmd;

      // Show final command before execution
      console.blank();
      console.section('Final Command');
      console.info('Executing:');
      console.info('  $buildCmd');
      if (wasEdited) {
        console.warning('(Custom edited command - not generated from config)');
      }
      console.blank();
      
      logger.section('Executing Build Command');
      logger.info('Command: $buildCmd');
      if (wasEdited) {
        logger.info('Note: Command was manually edited by user');
      }

      // Execute: use edited command if modified, otherwise use config
      final ProcessResult buildResult;
      if (wasEdited) {
        buildResult = await flutterRunner.buildFromCommand(buildCmd, buildConfig.projectRoot);
      } else {
        buildResult = await flutterRunner.build(buildConfig);
      }
      logger.output(buildResult.stdout);
      if (buildResult.stderr.isNotEmpty) {
        logger.section('Build Errors/Warnings');
        logger.output(buildResult.stderr);
      }

      // Check for Shorebird-specific error patterns even when exit code is 0
      final hasShorebirdError = buildConfig.useShorebird && (
        buildResult.stdout.contains('Missing argument') ||
        buildResult.stdout.contains('Usage: shorebird') ||
        buildResult.stdout.contains('Run "shorebird help"') ||
        buildResult.stderr.contains('error:') ||
        buildResult.stderr.contains('Error:')
      );

      if (!buildResult.success || hasShorebirdError) {
        if (hasShorebirdError && buildResult.success) {
          console.error('Build failed: Shorebird command error detected');
          logger.error('Build failed: Shorebird returned usage/error message');
        } else {
          console.error('Build failed!');
          logger.error('Build failed with exit code: ${buildResult.exitCode}');
        }

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
        platform: buildConfig.platform.toUpperCase(),
        outputPath: artifactResult.outputPath ?? buildConfig.absoluteOutputPath,
        duration: duration,
      );

      logger.info('Build completed successfully');
      await logger.endSession(
        success: true,
        duration: duration,
        outputPath: artifactResult.outputPath,
      );

      console.info('Log: ${logger.logFilePath}');
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
