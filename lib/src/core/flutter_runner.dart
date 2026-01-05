import 'dart:io' show Platform;

import 'package:path/path.dart' as p;

import '../utils/console.dart';
import '../utils/process_runner.dart';
import 'build_config.dart';

/// Handles execution of Flutter, FVM, and Shorebird commands
class FlutterRunner {
  final ProcessRunner _processRunner;
  final Console _console;
  final String projectRoot;

  FlutterRunner({
    required this.projectRoot,
    ProcessRunner? processRunner,
    Console? console,
  }) : _processRunner = processRunner ?? ProcessRunner(),
       _console = console ?? Console();

  /// Run flutter clean
  Future<ProcessResult> clean({bool useFvm = false}) async {
    _console.section('Cleaning project...');

    if (useFvm) {
      return _processRunner.run('fvm', [
        'flutter',
        'clean',
      ], workingDirectory: projectRoot);
    }
    return _processRunner.run('flutter', [
      'clean',
    ], workingDirectory: projectRoot);
  }

  /// Get the full clean command for logging
  String getCleanCommand({bool useFvm = false}) {
    if (useFvm) {
      return 'fvm flutter clean';
    }
    return 'flutter clean';
  }

  /// Run pub get
  Future<ProcessResult> pubGet({bool useFvm = false}) async {
    _console.info('Running pub get...');

    if (useFvm) {
      return _processRunner.run('fvm', [
        'flutter',
        'pub',
        'get',
      ], workingDirectory: projectRoot);
    }
    return _processRunner.run('flutter', [
      'pub',
      'get',
    ], workingDirectory: projectRoot);
  }

  /// Run build_runner
  Future<ProcessResult> buildRunner({bool useFvm = false}) async {
    _console.section('Running build_runner...');

    final args = [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ];

    if (useFvm) {
      return _processRunner.run('fvm', [
        'dart',
        ...args,
      ], workingDirectory: projectRoot);
    }
    return _processRunner.run('dart', args, workingDirectory: projectRoot);
  }

  /// Build Flutter app
  Future<ProcessResult> build(BuildConfig config) async {
    _console.section('Building ${config.platform.toUpperCase()}...');

    // Determine platform from build type
    final platform = _getPlatform(config.platform);

    // Build flutter args (exclude --release for Shorebird per official docs)
    final flutterArgs = _buildFlutterArgs(
      config,
      forShorebird: config.useShorebird,
    );

    if (config.useShorebird) {
      return _buildWithShorebird(config, flutterArgs);
    } else if (config.useFvm) {
      return _buildWithFvm(platform, flutterArgs);
    } else {
      return _buildWithFlutter(platform, flutterArgs);
    }
  }

  /// Execute a raw command string (for manually edited commands)
  Future<ProcessResult> buildFromCommand(String command, String projectRoot) async {
    if (command.trim().isEmpty) {
      return ProcessResult(
        exitCode: 1,
        stdout: '',
        stderr: 'Error: Empty command',
      );
    }

    _console.info('Executing custom command via shell');
    
    // Execute via shell to properly handle complex commands with -- separators
    // This avoids parsing issues and lets the OS handle the command correctly
    String shellProgram;
    List<String> shellArgs;
    
    if (Platform.isWindows) {
      // Use PowerShell on Windows
      shellProgram = 'powershell.exe';
      shellArgs = ['-NoProfile', '-Command', command];
    } else {
      // Use sh on Unix-like systems
      shellProgram = 'sh';
      shellArgs = ['-c', command];
    }

    return _processRunner.run(shellProgram, shellArgs, workingDirectory: projectRoot);
  }

  /// Get the full build command for logging
  String getBuildCommand(BuildConfig config) {
    final platform = _getPlatform(config.platform);
    final flutterArgs = _buildFlutterArgs(
      config,
      forShorebird: config.useShorebird,
    );

    if (config.useShorebird) {
      final sbPlatform = _getShorebirdPlatform(config.platform);
      final sbArgs = <String>['shorebird', 'release', sbPlatform];

      // Shorebird Management & Versioning Arguments (Before --)
      if (sbPlatform == 'android' && config.platform == 'apk') {
        sbArgs.add('--artifact=apk');
      }
      if (config.shorebirdNoConfirm) {
        sbArgs.add('--no-confirm');
      }
      if (config.flutterVersion != null && config.flutterVersion!.isNotEmpty) {
        sbArgs.add('--flutter-version=${config.flutterVersion}');
      }

      // Everything else goes after -- (Flutter build arguments)
      // Note: PowerShell requires '--' to be quoted when typed manually (per Shorebird docs)
      sbArgs.add(Platform.isWindows ? "'--'" : '--');
      
      // Version flags for Flutter build
      if (config.buildName != null && config.buildName!.isNotEmpty) {
        sbArgs.add('--build-name=${config.buildName}');
      }
      if (config.buildNumber != null) {
        sbArgs.add('--build-number=${config.buildNumber}');
      }

      if (config.flavor != null && config.flavor!.isNotEmpty) {
        sbArgs.add('--flavor=${config.flavor}');
      }

      if (config.targetDart.isNotEmpty && config.targetDart != 'lib/main.dart') {
        sbArgs.add('--target=${config.targetDart}');
      }

      // Dart-define flags (Flutter build arguments)
      final dartDefines = config.finalDartDefine;
      for (final entry in dartDefines.entries) {
        sbArgs.add('--dart-define=${entry.key}=${entry.value}');
      }

      // Dart-define-from-file (Flutter build argument)
      if (config.finalDartDefineFromFile != null) {
        sbArgs.add('--dart-define-from-file=${config.finalDartDefineFromFile}');
      }

      // Custom args from config
      sbArgs.addAll(flutterArgs);

      return sbArgs.join(' ');
    } else if (config.useFvm) {
      return 'fvm flutter build $platform ${flutterArgs.join(' ')}';
    } else {
      return 'flutter build $platform ${flutterArgs.join(' ')}';
    }
  }

  /// Get Shorebird platform from build platform
  String _getShorebirdPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'ipa':
      case 'ios':
        return 'ios';
      case 'app':
      case 'macos':
        return 'macos';
      case 'apk':
      case 'aab':
      default:
        return 'android';
    }
  }

  /// Get platform from build platform
  String _getPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'aab':
        return 'appbundle';
      case 'apk':
        return 'apk';
      case 'ipa':
      case 'ios':
        return 'ipa';
      case 'app':
      case 'macos':
        return 'macos';
      default:
        return 'apk';
    }
  }

  /// Build flutter command arguments
  ///
  /// When [forShorebird] is true, excludes --release flag per Shorebird docs:
  /// "never add --release | --debug | --profile when using shorebird"
  List<String> _buildFlutterArgs(
    BuildConfig config, {
    bool forShorebird = false,
  }) {
    final args = <String>[];

    // Only add --release for non-Shorebird builds
    if (!forShorebird) {
      args.add('--release');
    }

    // Flavor and target are also added before -- for Shorebird, so skip them
    if (!forShorebird) {
      if (config.flavor != null && config.flavor!.isNotEmpty) {
        args.add('--flavor=${config.flavor}');
      }

      if (config.targetDart.isNotEmpty && config.targetDart != 'lib/main.dart') {
        args.add('--target=${config.targetDart}');
      }
    }

    // Only add version flags if explicitly set AND not using Shorebird
    // (Shorebird adds these flags before the -- separator)
    if (!forShorebird) {
      if (config.buildName != null && config.buildName!.isNotEmpty) {
        args.add('--build-name=${config.buildName}');
      }
      if (config.buildNumber != null) {
        args.add('--build-number=${config.buildNumber}');
      }
    }

    // When building for Shorebird, dart-define flags are Shorebird-specific
    // and should be added before the -- separator, not after
    if (!forShorebird) {
      // Always add dart defines from config for regular Flutter builds
      final dartDefines = config.finalDartDefine;
      for (final entry in dartDefines.entries) {
        args.add('--dart-define=${entry.key}=${entry.value}');
      }

      // Add dart-define-from-file if specified for regular Flutter builds
      if (config.finalDartDefineFromFile != null) {
        // Convert to absolute path for consistency
        final dartDefineFilePath = p.isAbsolute(config.finalDartDefineFromFile!)
            ? config.finalDartDefineFromFile!
            : p.join(config.projectRoot, config.finalDartDefineFromFile!);
        args.add('--dart-define-from-file=$dartDefineFilePath');
      }
    }

    // Add extra args from config (these go after -- for Shorebird)
    args.addAll(config.args);
    
    return args;
  }

  /// Build with Shorebird
  Future<ProcessResult> _buildWithShorebird(
    BuildConfig config,
    List<String> flutterArgs,
  ) async {
    _console.info('Using Shorebird for build');

    final sbPlatform = _getShorebirdPlatform(config.platform);
    final sbArgs = <String>['release', sbPlatform];

    // Shorebird Management & Versioning Arguments (Before --)
    if (sbPlatform == 'android') {
      if (config.platform == 'apk') {
        sbArgs.add('--artifact=apk');
        _console.info('Shorebird → building APK');
      } else {
        _console.info('Shorebird → building AAB (default)');
      }

      // Manual artifact override
      if (config.shorebirdArtifact != null &&
          config.shorebirdArtifact!.isNotEmpty) {
        // Remove any existing artifact args
        sbArgs.removeWhere(
          (arg) => arg.startsWith('--artifact') || arg == 'apk' || arg == 'aab',
        );
        sbArgs.add('--artifact=${config.shorebirdArtifact}');
        _console.info(
          'Shorebird → using manual artifact: ${config.shorebirdArtifact}',
        );
      }
    } else {
      _console.info('Shorebird → building $sbPlatform');
    }

    if (config.shorebirdNoConfirm) {
      sbArgs.add('--no-confirm');
    }

    if (config.flutterVersion != null && config.flutterVersion!.isNotEmpty) {
      sbArgs.add('--flutter-version=${config.flutterVersion}');
    }

    // Everything else goes after -- (Flutter build arguments)
    sbArgs.add('--');
    
    // Version flags for Flutter build
    if (config.buildName != null && config.buildName!.isNotEmpty) {
      sbArgs.add('--build-name=${config.buildName}');
    }
    if (config.buildNumber != null) {
      sbArgs.add('--build-number=${config.buildNumber}');
    }

    if (config.flavor != null && config.flavor!.isNotEmpty) {
      sbArgs.add('--flavor=${config.flavor}');
    }

    if (config.targetDart.isNotEmpty && config.targetDart != 'lib/main.dart') {
      sbArgs.add('--target=${config.targetDart}');
    }

    // Dart-define flags (Flutter build arguments)
    final dartDefines = config.finalDartDefine;
    for (final entry in dartDefines.entries) {
      sbArgs.add('--dart-define=${entry.key}=${entry.value}');
    }

    // Dart-define-from-file (Flutter build argument)
    if (config.finalDartDefineFromFile != null) {
      // Convert to absolute path for Shorebird to ensure it can find the file
      // regardless of its internal working directory
      final dartDefineFilePath = p.isAbsolute(config.finalDartDefineFromFile!)
          ? config.finalDartDefineFromFile!
          : p.join(config.projectRoot, config.finalDartDefineFromFile!);
      sbArgs.add('--dart-define-from-file=$dartDefineFilePath');
    }

    // Custom args from config
    sbArgs.addAll(flutterArgs);

    // On Windows, must NOT use shell to properly handle -- separator
    // When runInShell: false, arguments are passed directly to the executable
    // without cmd.exe interference, preserving the -- separator correctly
    return _processRunner.run(
      'shorebird',
      sbArgs,
      workingDirectory: projectRoot,
      runInShell: false,
    );
  }

  /// Build with FVM
  Future<ProcessResult> _buildWithFvm(
    String platform,
    List<String> flutterArgs,
  ) async {
    _console.info('Using FVM for build');

    final args = ['flutter', 'build', platform, ...flutterArgs];
    return _processRunner.run('fvm', args, workingDirectory: projectRoot);
  }

  /// Build with plain Flutter
  Future<ProcessResult> _buildWithFlutter(
    String platform,
    List<String> flutterArgs,
  ) async {
    final args = ['build', platform, ...flutterArgs];
    return _processRunner.run('flutter', args, workingDirectory: projectRoot);
  }

  /// Check if Flutter is available
  Future<bool> isFlutterAvailable() async {
    return _processRunner.commandExists('flutter');
  }

  /// Check if FVM is available
  Future<bool> isFvmAvailable() async {
    return _processRunner.commandExists('fvm');
  }

  /// Check if Shorebird is available
  Future<bool> isShorebirdAvailable() async {
    return _processRunner.commandExists('shorebird');
  }
}
