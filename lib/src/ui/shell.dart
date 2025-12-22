import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/app_context.dart';
import '../core/config_backup.dart';
import '../commands/run_command.dart';
import '../core/pubspec_parser.dart';
import '../utils/console.dart';
import '../version.dart';

/// Interactive Shell REPL for the CLI
///
/// Provides a continuous command-line interface that keeps running
/// until the user exits. Supports built-in commands and dispatches
/// to registered command handlers.
class Shell {
  final Console console;
  AppContext? _appContext;
  final Map<String, Future<int> Function(List<String> args)> _commands = {};

  bool _running = false;

  Shell({Console? console, AppContext? appContext})
    : console = console ?? Console(),
      _appContext = appContext;

  /// Get current app context
  AppContext? get appContext => _appContext;

  /// Register a command handler
  void registerCommand(
    String name,
    Future<int> Function(List<String> args) handler,
  ) {
    _commands[name] = handler;
  }

  /// Run the shell REPL
  Future<int> run() async {
    _running = true;
    _printBanner();

    while (_running) {
      stdout.write('fluttercraft> ');
      final input = stdin.readLineSync()?.trim() ?? '';

      if (input.isEmpty) continue;

      try {
        await _processInput(input);
      } catch (e) {
        console.error('Error: $e');
      }
    }

    return 0;
  }

  /// Process user input
  Future<void> _processInput(String input) async {
    final parts = input.split(RegExp(r'\s+'));
    final command = parts.first.toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    // Built-in commands
    switch (command) {
      case 'exit':
      case 'quit':
      case 'q':
        await stop();
        console.info('Goodbye!');
        return;

      case 'help':
      case '?':
        _printHelp();
        return;

      case 'clear':
      case 'cls':
      case 'c':
        _clearScreen();
        return;

      case 'version':
      case 'v':
        console.info('flc v$appVersion');
        return;

      case 'info':
      case '-i':
        final verbose = args.contains('-v') || args.contains('--verbose');
        _showInfo(verbose: verbose);
        return;

      case 'reload':
      case 'r':
        await _reloadContext();
        return;
    }

    // Check registered commands
    if (_commands.containsKey(command)) {
      final handler = _commands[command]!;
      await handler(args);
      return;
    }

    // Check aliases
    if (_appContext != null &&
        _appContext!.config.aliases.containsKey(command)) {
      final runCmd = RunCommand(_appContext!, console: console);
      await runCmd.execute([command, ...args]);
      return;
    }

    // Unknown command
    console.warning('Unknown command: $command');
    console.info('Type "help" to see available commands.');
  }

  /// Print welcome banner
  void _printBanner() {
    print('');
    print('\x1B[1m\x1B[36m┌─────────────────────────────────────────┐\x1B[0m');
    print('\x1B[1m\x1B[36m│         fluttercraft CLI                │\x1B[0m');
    print(
      '\x1B[1m\x1B[36m│         v$appVersion                          │\x1B[0m',
    );
    print('\x1B[1m\x1B[36m└─────────────────────────────────────────┘\x1B[0m');
    print('');

    // Show warning if fluttercraft.yaml doesn't exist
    if (appContext != null && !appContext!.hasConfigFile) {
      console.warning(
        '⚠ No fluttercraft.yaml found. Run \'gen\' to create one.',
      );
      print('');
    }

    console.info('Type "help" for available commands, "exit" to quit.');
    print('');
  }

  /// Print help message
  void _printHelp() {
    console.section('Available Commands');
    console.keyValue('help, ?', 'Show this help message');
    console.keyValue('exit, quit, q', 'Exit the shell');
    console.keyValue('clear, cls, c', 'Clear the screen');
    console.keyValue('version, v', 'Show CLI version');
    console.keyValue('info, -i', 'Show project info (use -v for verbose)');
    console.keyValue('reload, r', 'Reload configuration from disk');

    if (_commands.isNotEmpty) {
      console.section('Registered Commands');
      for (final name in _commands.keys) {
        console.keyValue(name, 'Run $name command');
      }
    }
  }

  /// Clear the screen
  void _clearScreen() {
    if (Platform.isWindows) {
      // Windows clear screen
      print('\x1B[2J\x1B[0;0H');
    } else {
      // Unix clear screen
      print('\x1B[2J\x1B[H');
    }
  }

  /// Show project info (default or verbose)
  void _showInfo({bool verbose = false}) {
    if (appContext == null) {
      console.warning('No context loaded.');
      console.info('Context is loaded automatically when shell starts.');
      return;
    }

    final ctx = appContext!;
    const kw = 20; // key width for alignment

    // ─────────────────────────────────────────────────────────────────
    // APPLICATION
    // ─────────────────────────────────────────────────────────────────
    console.section('Application');
    console.keyValue('App Name', ctx.appName, keyWidth: kw);
    console.keyValue('Version', ctx.version, keyWidth: kw);

    // ─────────────────────────────────────────────────────────────────
    // BUILD CONFIGURATION (consolidated section)
    // ─────────────────────────────────────────────────────────────────
    console.section('Build Configuration');

    // Core build settings
    console.keyValue('Platform', ctx.platform, keyWidth: kw);
    console.keyValue(
      'Flavor',
      (ctx.flavor == null || ctx.flavor!.isEmpty) ? '(none)' : ctx.flavor!,
      keyWidth: kw,
    );
    console.keyValue('Output Path', ctx.outputPath, keyWidth: kw);

    // FVM sub-section
    console.subSection('FVM');
    console.keyValue('Enabled', ctx.useFvm.toString(), keyWidth: kw, indent: 4);
    if (verbose && ctx.useFvm) {
      console.keyValue(
        'Flutter Version',
        ctx.flutterVersion ?? '(auto-detected)',
        keyWidth: kw,
        indent: 4,
      );
    }

    // Shorebird sub-section
    console.subSection('Shorebird');
    console.keyValue('Enabled', ctx.useShorebird.toString(), keyWidth: kw, indent: 4);
    if (verbose && ctx.useShorebird) {
      console.keyValue(
        'App ID',
        ctx.shorebirdAppId ?? '(from shorebird.yaml)',
        keyWidth: kw,
        indent: 4,
      );
      if (ctx.shorebirdArtifact != null) {
        console.keyValue('Artifact', ctx.shorebirdArtifact!, keyWidth: kw, indent: 4);
      }
      console.keyValue('No Confirm', ctx.shorebirdNoConfirm.toString(), keyWidth: kw, indent: 4);
    }

    // Verbose: Build flags
    if (verbose) {
      console.subSection('Build Flags');
      console.keyValue('Should Clean', ctx.shouldClean.toString(), keyWidth: kw, indent: 4);
      console.keyValue('Should Build Runner', ctx.shouldBuildRunner.toString(), keyWidth: kw, indent: 4);
      console.keyValue('Prompt Dart Define', ctx.shouldPromptDartDefine.toString(), keyWidth: kw, indent: 4);
    }

    // Verbose: Paths
    if (verbose) {
      console.subSection('Paths');
      console.keyValue('Target', ctx.targetDart, keyWidth: kw, indent: 4);
      console.keyValue('Keystore', ctx.keystorePath, keyWidth: kw, indent: 4);
      if (ctx.bundletoolPath != null) {
        console.keyValue('Bundletool', ctx.bundletoolPath!, keyWidth: kw, indent: 4);
      }
      console.keyValue('Project Root', ctx.projectRoot, keyWidth: kw, indent: 4);
    }

    // ─────────────────────────────────────────────────────────────────
    // VERBOSE-ONLY SECTIONS
    // ─────────────────────────────────────────────────────────────────
    if (verbose) {
      // Dart defines (only if present or from file)
      if (ctx.finalDartDefine.isNotEmpty || ctx.dartDefineFromFile != null) {
        console.section('Dart Define');
        
        // Show dart_define_from_file source first if specified
        if (ctx.dartDefineFromFile != null) {
          console.keyValue('From File', ctx.dartDefineFromFile!, keyWidth: kw);
        }
        
        for (final entry in ctx.finalDartDefine.entries) {
          console.keyValue(entry.key, entry.value.toString(), keyWidth: kw);
        }
      }

      // Flavors (only if defined)
      if (ctx.flavors.isNotEmpty) {
        console.section('Flavors');
        console.keyValue('Available', ctx.flavors.keys.join(', '), keyWidth: kw);
      }

      // Aliases (only if defined)
      if (ctx.aliases.isNotEmpty) {
        console.section('Aliases');
        console.keyValue('Defined', ctx.aliases.keys.join(', '), keyWidth: kw);
      }

      // Console settings
      console.section('Console');
      console.keyValue('No Color', ctx.noColor.toString(), keyWidth: kw);

      // Context metadata
      console.section('Context Metadata');
      console.keyValue('Loaded At', ctx.loadedAt.toString(), keyWidth: kw);
      console.keyValue('Context Age', '${ctx.age.inSeconds}s', keyWidth: kw);

      if (ctx.isStale) {
        console.warning('Context is stale (>5 min). Run "reload" to refresh.');
      }
    } else {
      // Hint for verbose mode
      console.blank();
      console.info('Use "info -v" for detailed configuration.');
    }
  }

  /// Reload configuration from fluttercraft.yaml
  Future<void> _reloadContext() async {
    // Backup before reload (just in case)
    await _backupConfig('reload');

    console.info('Reloading configuration...');

    // Sync version from pubspec.yaml before loading
    await syncVersion();

    try {
      _appContext = await AppContext.load();
      console.success('Configuration reloaded successfully.');

      // Show brief summary of loaded config
      if (_appContext != null) {
        console.keyValue('App Name', _appContext!.appName);
        console.keyValue('Version', _appContext!.version);
        console.keyValue('Platform', _appContext!.platform);
      }
    } catch (e) {
      console.error('Failed to reload: $e');
    }
  }

  /// Sync version from pubspec.yaml to fluttercraft.yaml
  Future<void> syncVersion() async {
    final root = appContext?.projectRoot ?? Directory.current.path;
    final parser = PubspecParser(projectRoot: root);
    final pubspecInfo = await parser.parse();

    if (pubspecInfo == null) return;

    final configPath = p.join(root, 'fluttercraft.yaml');
    final file = File(configPath);
    if (!await file.exists()) return;

    var content = await file.readAsString();
    bool changed = false;

    // Use regex to update version in build_defaults
    // We use replaceFirst to target the first occurrence which is typically in build_defaults
    final nameRegex = RegExp(r'^(\s+name:\s*)(.+)$', multiLine: true);
    final numberRegex = RegExp(r'^(\s+number:\s*)(\d+)$', multiLine: true);

    if (nameRegex.hasMatch(content)) {
      final match = nameRegex.firstMatch(content);
      if (match != null && match.group(2) != pubspecInfo.buildName) {
        content = content.replaceFirst(
          nameRegex,
          '${match.group(1)}${pubspecInfo.buildName}',
        );
        changed = true;
        console.info('Updated version name to ${pubspecInfo.buildName}');
      }
    }

    if (numberRegex.hasMatch(content)) {
      final match = numberRegex.firstMatch(content);
      if (match != null && match.group(2) != pubspecInfo.buildNumber) {
        content = content.replaceFirst(
          numberRegex,
          '${match.group(1)}${pubspecInfo.buildNumber}',
        );
        changed = true;
        console.info('Updated build number to ${pubspecInfo.buildNumber}');
      }
    }

    if (changed) {
      await file.writeAsString(content);
    }
  }

  /// Backup configuration
  Future<void> _backupConfig(String reason) async {
    if (appContext == null) return;
    
    final backup = ConfigBackup(
      projectRoot: appContext!.projectRoot, 
      console: console,
    );
    await backup.backup(reason: reason);
  }

  /// Stop the shell (can be called from external handlers)
  Future<void> stop() async {
    await _backupConfig('quit');
    _running = false;
  }

  /// Check if shell is running
  bool get isRunning => _running;
}
