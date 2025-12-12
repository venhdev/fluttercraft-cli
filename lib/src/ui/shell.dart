import 'dart:io';

import '../utils/console.dart';
import 'interactive_mode.dart';

/// Interactive Shell REPL for the CLI
/// 
/// Provides a continuous command-line interface that keeps running
/// until the user exits. Supports built-in commands and dispatches
/// to registered command handlers.
class Shell {
  final Console console;
  final InteractiveMode interactiveMode;
  final Map<String, Future<int> Function(List<String> args)> _commands = {};
  
  bool _running = false;
  
  Shell({
    Console? console,
    this.interactiveMode = InteractiveMode.arrow,
  }) : console = console ?? Console();
  
  /// Register a command handler
  void registerCommand(
    String name, 
    Future<int> Function(List<String> args) handler,
  ) {
    _commands[name] = handler;
  }
  
  /// Get list of registered command names
  List<String> get commandNames => _commands.keys.toList();
  
  /// Run the shell REPL loop
  Future<int> run() async {
    _running = true;
    
    _printBanner();
    
    while (_running) {
      stdout.write('mycli> ');
      final input = stdin.readLineSync()?.trim();
      
      if (input == null || input.isEmpty) {
        continue;
      }
      
      try {
        await _processInput(input);
      } catch (e) {
        console.error('Error: $e');
        // Don't exit on error - continue the loop
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
        _running = false;
        console.info('Goodbye!');
        return;
        
      case 'help':
      case '?':
        _printHelp();
        return;
        
      case 'clear':
      case 'cls':
        _clearScreen();
        return;
        
      case 'version':
        console.info('mycli v0.0.2-continuous-shell');
        return;
    }
    
    // Check registered commands
    if (_commands.containsKey(command)) {
      final handler = _commands[command]!;
      await handler(args);
      return;
    }
    
    // Unknown command
    console.warning('Unknown command: $command');
    console.info('Type "help" to see available commands.');
  }
  
  /// Print welcome banner
  void _printBanner() {
    console.blank();
    console.header('┌─────────────────────────────────────────┐');
    console.header('│     MYCLI - Mobile Build CLI            │');
    console.header('│     v0.0.2-continuous-shell             │');
    console.header('└─────────────────────────────────────────┘');
    console.blank();
    console.info('Interactive mode: ${interactiveMode.name}');
    console.info('Type "help" for available commands, "exit" to quit.');
    console.blank();
  }
  
  /// Print help message
  void _printHelp() {
    console.section('Available Commands');
    console.blank();
    
    // Built-in commands
    console.keyValue('help, ?', 'Show this help message');
    console.keyValue('exit, quit, q', 'Exit the shell');
    console.keyValue('clear, cls', 'Clear the screen');
    console.keyValue('version', 'Show CLI version');
    console.blank();
    
    // Registered commands
    if (_commands.isNotEmpty) {
      console.section('Registered Commands');
      console.blank();
      for (final name in _commands.keys) {
        console.keyValue(name, 'Run $name command');
      }
      console.blank();
    }
    
    console.info('Tip: You can also run commands with arguments, e.g., "build --type apk"');
  }
  
  /// Clear the terminal screen
  void _clearScreen() {
    if (Platform.isWindows) {
      // Windows uses different escape sequences
      stdout.write('\x1B[2J\x1B[0;0H');
    } else {
      stdout.write('\x1B[2J\x1B[H');
    }
  }
  
  /// Stop the shell (can be called from external handlers)
  void stop() {
    _running = false;
  }
  
  /// Check if shell is running
  bool get isRunning => _running;
}
