import 'package:args/command_runner.dart';

import '../commands/build_command.dart';
import '../commands/clean_command.dart';
import '../commands/convert_command.dart';

/// Centralized command registry for the CLI
/// 
/// Allows both the CommandRunner (single-command mode) and the Shell
/// (interactive mode) to access the same commands.
class CommandRegistry {
  static final CommandRegistry _instance = CommandRegistry._internal();
  
  factory CommandRegistry() => _instance;
  
  CommandRegistry._internal();
  
  /// Create a new CommandRunner with all registered commands
  CommandRunner<int> createRunner() {
    return CommandRunner<int>(
      'buildcraft',
      'BuildCraft CLI - Cross-platform Flutter build system\n'
      '\n'
      'Commands:\n'
      '  build     Build Flutter app (APK/AAB/IPA)\n'
      '  clean     Clean project and dist folder\n'
      '  convert   Convert AAB to universal APK',
    )
      ..addCommand(BuildCommand())
      ..addCommand(CleanCommand())
      ..addCommand(ConvertCommand());
  }
  
  /// Get a map of command names to their execution handlers
  /// Used by the Shell for interactive command dispatch
  Map<String, Future<int> Function(List<String> args)> getShellCommands() {
    final runner = createRunner();
    
    return {
      'build': (args) async => await runner.run(['build', ...args]) ?? 0,
      'clean': (args) async => await runner.run(['clean', ...args]) ?? 0,
      'convert': (args) async => await runner.run(['convert', ...args]) ?? 0,
    };
  }
  
  /// List of available command names
  List<String> get commandNames => ['build', 'clean', 'convert'];
  
  /// Get command descriptions for help display
  Map<String, String> get commandDescriptions => {
    'build': 'Build Flutter app (APK/AAB/IPA)',
    'clean': 'Clean project and dist folder',
    'convert': 'Convert AAB to universal APK',
  };
}
