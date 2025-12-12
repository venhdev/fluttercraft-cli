import 'dart:io';

import '../core/app_context.dart';
import '../utils/console.dart';

/// Interactive Shell REPL for the CLI
/// 
/// Provides a continuous command-line interface that keeps running
/// until the user exits. Supports built-in commands and dispatches
/// to registered command handlers.
class Shell {
  final Console console;
  final AppContext? appContext;
  final Map<String, Future<int> Function(List<String> args)> _commands = {};
  
  bool _running = false;
  
  Shell({
    Console? console,
    this.appContext,
  }) : console = console ?? Console();
  
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
      stdout.write('buildcraft> ');
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
        _running = false;
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
        console.info('buildcraft v0.0.3');
        return;
        
      case 'context':
      case 'ctx':
        _showContext();
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
    print('');
    print('\x1B[1m\x1B[36m┌─────────────────────────────────────────┐\x1B[0m');
    print('\x1B[1m\x1B[36m│         BUILDCRAFT CLI                  │\x1B[0m');
    print('\x1B[1m\x1B[36m│         v0.0.3                          │\x1B[0m');
    print('\x1B[1m\x1B[36m└─────────────────────────────────────────┘\x1B[0m');
    print('');
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
    console.keyValue('context, ctx', 'Show loaded context');
    
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
  
  /// Show loaded context info
  void _showContext() {
    console.section('Runtime Context');
    console.blank();
    
    if (appContext == null) {
      console.warning('No context loaded.');
      console.info('Context is loaded automatically when shell starts.');
      return;
    }
    
    final ctx = appContext!;
    console.keyValue('App Name', ctx.appName);
    console.keyValue('Version', ctx.version);
    console.keyValue('Build Type', ctx.buildType);
    console.keyValue('Flavor', (ctx.flavor == null || ctx.flavor!.isEmpty) ? '(none)' : ctx.flavor!);
    console.keyValue('Output Path', ctx.outputPath);
    console.keyValue('Use FVM', ctx.useFvm.toString());
    console.keyValue('Use Shorebird', ctx.useShorebird.toString());
    console.keyValue('Project Root', ctx.projectRoot);
    console.keyValue('Loaded At', ctx.loadedAt.toString());
    console.keyValue('Context Age', '${ctx.age.inSeconds}s');
    
    if (ctx.isStale) {
      console.warning('Context is stale (>5 min). Run "reload" to refresh.');
    }
    console.blank();
  }
  
  /// Stop the shell (can be called from external handlers)
  void stop() {
    _running = false;
  }
  
  /// Check if shell is running
  bool get isRunning => _running;
}
