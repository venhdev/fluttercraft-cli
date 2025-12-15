import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'package:fluttercraft/src/core/app_context.dart';
import 'package:fluttercraft/src/core/command_registry.dart';
import 'package:fluttercraft/src/ui/shell.dart';

/// fluttercraft CLI
/// 
/// A cross-platform CLI tool for building Flutter apps.
/// Replaces PowerShell build scripts with a single portable executable.
/// 
/// Supports two modes:
/// - Single-command mode: `flb build --type apk` (runs and exits)
/// - Interactive shell mode: `flb` or `flb --shell` (continuous REPL)
void main(List<String> arguments) async {
  final registry = CommandRegistry();
  
  // Check if first argument is a known command
  final knownCommands = ['build', 'clean', 'convert', 'gen'];
  final firstArg = arguments.isNotEmpty ? arguments.first : '';
  final isCommand = knownCommands.contains(firstArg);
  
  // If it's a known command, run in single-command mode
  if (isCommand) {
    await _runSingleCommand(registry, arguments);
    return;
  }
  
  // Parse global options for shell mode
  final globalParser = ArgParser()
    ..addFlag(
      'shell',
      abbr: 's',
      help: 'Start interactive shell mode',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    )
    ..addFlag(
      'version',
      abbr: 'v',
      help: 'Show version',
      negatable: false,
    );
  
  try {
    final globalResult = globalParser.parse(arguments);
    
    // Handle --help
    if (globalResult['help'] == true) {
      _printUsage(globalParser);
      exit(0);
    }
    
    // Handle --version
    if (globalResult['version'] == true) {
      print('flb v0.0.4');
      exit(0);
    }
    
    // Load AppContext
    print('Loading project context...');
    final appContext = await AppContext.load();
    
    // Start interactive shell
    final shell = Shell(appContext: appContext);
    
    // Register commands
    final commands = registry.getShellCommands();
    for (final entry in commands.entries) {
      shell.registerCommand(entry.key, entry.value);
    }
    
    final exitCode = await shell.run();
    exit(exitCode);
  } on FormatException catch (e) {
    print('Error: $e');
    _printUsage(globalParser);
    exit(64);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

/// Run in single-command mode using CommandRunner
Future<void> _runSingleCommand(CommandRegistry registry, List<String> arguments) async {
  final runner = registry.createRunner();
  
  try {
    final exitCode = await runner.run(arguments) ?? 0;
    exit(exitCode);
  } on UsageException catch (e) {
    print(e);
    exit(64); // EX_USAGE
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('flb - Flutter Build CLI');
  print('');
  print('Usage:');
  print('  flb                      Start interactive shell (default)');
  print('  flb --shell              Start interactive shell (explicit)');
  print('  flb <command> [options]  Run single command and exit');
  print('');
  print('Global Options:');
  print(parser.usage);
  print('');
  print('Commands:');
  print('  build     Build Flutter app (APK/AAB/IPA)');
  print('  clean     Clean project and dist folder');
  print('  convert   Convert AAB to universal APK');
  print('  gen       Generate fluttercraft.yaml');
  print('');
  print('Configuration:');
  print('  Create a fluttercraft.yaml file in your project root.');
  print('  Run \'flb gen\' to generate a template.');
  print('');
  print('Examples:');
  print('  flb                    # Start interactive shell');
  print('  flb build --type apk   # Build APK and exit');
  print('  flb gen                # Generate fluttercraft.yaml');
  print('  flb clean              # Clean and exit');
}

