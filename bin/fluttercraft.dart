import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'package:fluttercraft/src/core/app_context.dart';
import 'package:fluttercraft/src/core/command_registry.dart';
import 'package:fluttercraft/src/commands/run_command.dart';
import 'package:fluttercraft/src/ui/shell.dart';
import 'package:fluttercraft/src/version.dart';

/// fluttercraft CLI
/// 
/// A cross-platform CLI tool for building Flutter apps.
/// Replaces PowerShell build scripts with a single portable executable.
/// 
/// Behavior:
/// - `flc` - Show help (default, like shorebird)
/// - `flc --shell` or `flc -s` - Start interactive shell
/// - `flc <command>` - Run single command and exit
void main(List<String> arguments) async {
  final registry = CommandRegistry();
  
  // Check if first argument is a known command
  final knownCommands = ['build', 'clean', 'convert', 'gen', 'run', 'help'];
  final firstArg = arguments.isNotEmpty ? arguments.first : '';
  final isCommand = knownCommands.contains(firstArg);
  
  // If it's a known command, run in single-command mode
  if (isCommand) {
    await _runSingleCommand(registry, arguments);
    return;
  }
  
  // Parse global options
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
    
    // Handle --version
    if (globalResult['version'] == true) {
      print('flc v$appVersion');
      exit(0);
    }
    
    // Handle --shell: start interactive shell
    if (globalResult['shell'] == true) {
      print('Loading project context...');
      final appContext = await AppContext.load();
      
      final shell = Shell(appContext: appContext);
      
      // Register commands
      final commands = registry.getShellCommands();
      for (final entry in commands.entries) {
        shell.registerCommand(entry.key, entry.value);
      }
      
      // Register run command with AppContext
      shell.registerCommand('run', (args) async {
        final runCmd = RunCommand(appContext);
        return await runCmd.execute(args);
      });
      
      final exitCode = await shell.run();
      exit(exitCode);
    }
    
    // Default: show help (like shorebird)
    _printUsage(globalParser);
    exit(0);
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
  // Handle run command specially since it needs AppContext
  if (arguments.isNotEmpty && arguments.first == 'run') {
    try {
      final appContext = await AppContext.load();
      final runCmd = RunCommand(appContext);
      final exitCode = await runCmd.execute(arguments.sublist(1));
      exit(exitCode);
    } catch (e) {
      print('Error: $e');
      exit(1);
    }
  }
  
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
  print('fluttercraft - Craft Your Flutter Builds with Precision');
  print('');
  print('Usage: fluttercraft <command> [arguments]');
  print('       flc <command> [arguments]');
  print('');
  print('Global options:');
  print('-h, --help       Print this usage information.');
  print('-v, --version    Print the current version.');
  print('-s, --shell      Start interactive shell mode.');
  print('');
  print('Available commands:');
  print('  build     Build Flutter app (APK/AAB/IPA)');
  print('  clean     Clean project and dist folder');
  print('  convert   Convert AAB to universal APK');
  print('  gen       Generate fluttercraft.yaml');
  print('  run       Run custom command alias');
  print('');
  print('Run "fluttercraft help <command>" for more information about a command.');
}


