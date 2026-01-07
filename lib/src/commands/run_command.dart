import '../core/app_context.dart';
import '../utils/command_logger.dart';
import '../utils/console.dart';
import '../utils/process_runner.dart';

/// Run command - executes custom command aliases
class RunCommand {
  final AppContext context;
  final Console _console;
  final ProcessRunner _runner;

  RunCommand(this.context, {Console? console, ProcessRunner? runner})
      : _console = console ?? Console(),
        _runner = runner ?? ProcessRunner();

  late final CommandLogger _logger;

  Future<int> execute(List<String> args) async {
    // Parse flags
    final showList = args.contains('--list') ||
        args.contains('-l') ||
        (args.isNotEmpty && args[0] == 'list');
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
      // Step 1: Show available aliases if no args provided
      _listAliases();
      return 0;
    }

    final aliasName = args[0];
    final runArgs = args.sublist(1);
    
    _logger = CommandLogger(projectRoot: context.projectRoot, commandName: 'run');
    await _logger.startSession();
    _logger.info('Running alias: $aliasName');
    
    try {
      final exitCode = await _runAlias(aliasName, runArgs);
      await _logger.endSession(success: exitCode == 0);
      return exitCode;
    } catch (e) {
      _logger.error('Alias execution failed: $e');
      await _logger.endSession(success: false);
      rethrow;
    }
  }

  void _printHelp() {
    _console.log('Run custom command aliases defined in fluttercraft.yaml');
    _console.blank();
    _console.log('Usage: fluttercraft run <alias> [arguments]');
    _console.log('-h, --help     Print this usage information.');
    _console.log('-l, --list     List all available aliases');
    _console.blank();
    _console.log('Runtime Parameters:');
    _console.log('  Use {0}, {1} placeholders for positional arguments');
    _console.log('  Use {key} placeholders for named arguments (e.g. --key value)');
    _console.log('  Use {all} to pass all arguments');
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

  Future<int> _runAlias(String name, List<String> args) async {
    final alias = context.config.aliases[name];

    if (alias == null) {
      _console.error('Alias "$name" not found');
      _listAliases();
      return 1;
    }

    // Check if alias has params (placeholders)
    final placeholderRegex = RegExp(r'\{([a-zA-Z0-9_]+)\}');
    bool hasParams = false;
    for (final cmd in alias.commands) {
      if (cmd.contains('{all}') || placeholderRegex.hasMatch(cmd)) {
        hasParams = true;
        break;
      }
    }

    _console.blank();
    _console.header('Preparing alias: $name');

    // Parse runtime arguments
    final parsedArgs = _parseRuntimeArgs(args);
    final processedCommands = <String>[];

    // Process all commands first
    for (final cmd in alias.commands) {
      String processed = cmd;
      
      // 1. Replace named placeholders {key}
      final matches = placeholderRegex.allMatches(processed).toList();
      
      for (final match in matches) {
        final key = match.group(1)!;
        
        // Skip numeric placeholders for now (handled in next step)
        if (int.tryParse(key) != null) continue;

        if (parsedArgs.named.containsKey(key)) {
          processed = processed.replaceAll('{$key}', parsedArgs.named[key]!);
        } else {
          // Prompt for missing named placeholder
          final input = _console.prompt('Enter value for {$key}');
          processed = processed.replaceAll('{$key}', input);
        }
      }

      // 2. Replace positional placeholders {0}, {1}
      // Also fill sequentially from remaining positional args if no specific index used?
      // User said: "fill provided {arg}, then substitute sequentially"
      // Let's handle explicit {0} first
      for (var i = 0; i < parsedArgs.positional.length; i++) {
        if (processed.contains('{$i}')) {
          processed = processed.replaceAll('{$i}', parsedArgs.positional[i]);
        }
      }

      // Identify remaining numeric placeholders that weren't filled?
      // Or just leave them? If commands uses {0} and we have no args, we should prompt?
      // Checking for remaining placeholders
      final remainingMatches = placeholderRegex.allMatches(processed).toList();
      for (final match in remainingMatches) {
         final key = match.group(1)!;
         if (key == 'all') continue;
         
         // If it's numeric and we didn't have a positional arg for it
         if (int.tryParse(key) != null) {
            final input = _console.prompt('Enter value for argument {$key}');
            processed = processed.replaceAll('{$key}', input);
         }
      }

      processedCommands.add(processed);
    }

    // Preview
    _console.section('Command Preview');
    for (final cmd in processedCommands) {
      _console.info('  > $cmd');
    }
    _console.blank();

    if (hasParams) {
      if (!_console.confirm('Continue?', defaultValue: true)) {
        _console.log('Aborted.');
        return 0;
      }
      _console.blank();
    }
    
    // Execute
    for (var i = 0; i < processedCommands.length; i++) {
      final cmd = processedCommands[i];
      _console.sectionCompact('[${i + 1}/${alias.commands.length}] Executing...');

      final parts = _parseCommand(cmd);
      if (parts.isEmpty) continue;

      final command = parts[0];
      final cmdArgs = parts.sublist(1);

      final result = await _runner.run(
        command,
        cmdArgs,
        workingDirectory: context.projectRoot,
        streamOutput: true,
      );
      _logger.output(result.stdout);

      if (!result.success) {
        _console.blank();
        _console.error('Command failed with exit code ${result.exitCode}');
        _logger.error('Command failed with exit code ${result.exitCode}');
        return result.exitCode;
      }
    }

    _console.blank();
    _console.success('✓ Alias "$name" execution complete');
    _console.info('Log: ${_logger.logFilePath}');
    return 0;
  }

  _RuntimeArgs _parseRuntimeArgs(List<String> args) {
    final named = <String, String>{};
    final positional = <String>[];

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg.startsWith('--')) {
        final key = arg.substring(2);
        if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
          named[key] = args[i + 1];
          i++; // Skip next value
        } else {
          named[key] = 'true'; // Flag treated as true? Or just empty string?
        }
      } else {
        positional.add(arg);
      }
    }
    return _RuntimeArgs(named, positional);
  }

  /// Parse command string into command and arguments
  /// Handles quoted strings and basic shell parsing
  List<String> _parseCommand(String cmd) {
    final parts = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    var quoteChar = '';
    var hasToken = false; // Track if we've started a token (even empty "")

    for (var i = 0; i < cmd.length; i++) {
      final char = cmd[i];

      if ((char == '"' || char == "'") && !inQuotes) {
        inQuotes = true;
        quoteChar = char;
        hasToken = true; // Quotes start a token
      } else if (char == quoteChar && inQuotes) {
        inQuotes = false;
        quoteChar = '';
        hasToken = true; // Closed quotes confirm a token
      } else if (char == ' ' && !inQuotes) {
        if (hasToken || current.isNotEmpty) {
          parts.add(current.toString());
          current = StringBuffer();
          hasToken = false;
        }
      } else {
        current.write(char);
        hasToken = true; // Characters mean we have a token
      }
    }

    // Add final token if exists
    if (hasToken || current.isNotEmpty) {
      parts.add(current.toString());
    }

    return parts;
  }
}

class _RuntimeArgs {
  final Map<String, String> named;
  final List<String> positional;

  _RuntimeArgs(this.named, this.positional);
}
