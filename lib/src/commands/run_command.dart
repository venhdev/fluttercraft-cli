import 'dart:io';

import '../core/app_context.dart';
import '../utils/console.dart';
import '../utils/process_runner.dart';

/// Run command - executes custom command aliases
class RunCommand {
  final AppContext context;
  final Console _console;
  final ProcessRunner _runner;
  
  RunCommand(this.context)
      : _console = Console(),
        _runner = ProcessRunner();
  
  Future<int> execute(List<String> args) async {
    // Parse flags
    final showList = args.contains('--list') || args.contains('-l');
    final showHelp = args.contains('--help') || args.contains('-h');
    
    if (showHelp) {
      _printHelp();
      return 0;
    }
    
    if (showList) {
      _listAliases();
      return 0;
    }
    
    if (args.isEmpty) {
      _console.error('Usage: flc run <alias> or flc run --list');
      _console.info('Run "flc run --list" to see available aliases');
      return 1;
    }
    
    final aliasName = args[0];
    return _runAlias(aliasName);
  }
  
  void _printHelp() {
    _console.log('Run custom command aliases defined in fluttercraft.yaml');
    _console.blank();
    _console.log('Usage: fluttercraft run <alias> [arguments]');
    _console.log('-h, --help     Print this usage information.');
    _console.log('-l, --list     List all available aliases');
    _console.blank();
    _console.log('Run "fluttercraft help" to see global options.');
  }
  
  void _listAliases() {
    final aliases = context.config.aliases;
    
    if (aliases.isEmpty) {
      _console.info('No aliases defined in fluttercraft.yaml');
      _console.blank();
      _console.info('Add aliases in the "alias" section of your config:');
      _console.blank();
      _console.log('  alias:');
      _console.log('    gen-icon:');
      _console.log('      cmds:');
      _console.log('        - fvm flutter pub get');
      _console.log('        - fvm flutter pub run flutter_launcher_icons');
      _console.blank();
      return;
    }
    
    _console.blank();
    _console.info('Available aliases:');
    _console.blank();
    
    for (final alias in aliases.values) {
      _console.success('  ${alias.name}');
      for (final cmd in alias.commands) {
        _console.debug('    → $cmd');
      }
      _console.blank();
    }
  }
  
  Future<int> _runAlias(String name) async {
    final alias = context.config.aliases[name];
    
    if (alias == null) {
      _console.error('Alias "$name" not found');
      _console.info('Run "flc run --list" to see available aliases');
      return 1;
    }
    
    _console.blank();
    _console.header('Running alias: $name');
    
    for (var i = 0; i < alias.commands.length; i++) {
      final cmd = alias.commands[i];
      _console.section('[${i + 1}/${alias.commands.length}] $cmd');
      
      // Parse command and arguments
      final parts = _parseCommand(cmd);
      if (parts.isEmpty) {
        _console.error('Invalid command: $cmd');
        return 1;
      }
      
      final command = parts[0];
      final cmdArgs = parts.sublist(1);
      
      final result = await _runner.run(
        command,
        cmdArgs,
        workingDirectory: context.projectRoot,
        streamOutput: true,
      );
      
      if (!result.success) {
        _console.blank();
        _console.error('Command failed with exit code ${result.exitCode}');
        _console.error('Alias "$name" execution stopped');
        return result.exitCode;
      }
      
      _console.blank();
    }
    
    _console.success('✓ Alias "$name" completed successfully');
    _console.blank();
    return 0;
  }
  
  /// Parse command string into command and arguments
  /// Handles quoted strings and basic shell parsing
  List<String> _parseCommand(String cmd) {
    final parts = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    var quoteChar = '';
    
    for (var i = 0; i < cmd.length; i++) {
      final char = cmd[i];
      
      if ((char == '"' || char == "'") && !inQuotes) {
        inQuotes = true;
        quoteChar = char;
      } else if (char == quoteChar && inQuotes) {
        inQuotes = false;
        quoteChar = '';
      } else if (char == ' ' && !inQuotes) {
        if (current.isNotEmpty) {
          parts.add(current.toString());
          current = StringBuffer();
        }
      } else {
        current.write(char);
      }
    }
    
    if (current.isNotEmpty) {
      parts.add(current.toString());
    }
    
    return parts;
  }
}
