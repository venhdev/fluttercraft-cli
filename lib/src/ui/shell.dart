import 'dart:io';

import '../core/app_context.dart';
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
  
  Shell({
    Console? console,
    AppContext? appContext,
  }) : console = console ?? Console(),
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
        console.info('flc v$appVersion');
        return;
        
      case 'context':
      case 'ctx':
        _showContext();
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
    
    // Unknown command
    console.warning('Unknown command: $command');
    console.info('Type "help" to see available commands.');
  }
  
  /// Print welcome banner
  void _printBanner() {
    print('');
    print('\x1B[1m\x1B[36m┌─────────────────────────────────────────┐\x1B[0m');
    print('\x1B[1m\x1B[36m│         fluttercraft CLI                │\x1B[0m');
    print('\x1B[1m\x1B[36m│         v$appVersion                          │\x1B[0m');
    print('\x1B[1m\x1B[36m└─────────────────────────────────────────┘\x1B[0m');
    print('');
    
    // Show warning if fluttercraft.yaml doesn't exist
    if (appContext != null && !appContext!.hasConfigFile) {
      console.warning('⚠ No fluttercraft.yaml found. Run \'gen\' to create one.');
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
    console.keyValue('context, ctx', 'Show loaded context');
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
  
  /// Show loaded context info
  void _showContext() {
    console.section('Runtime Context');
    
    if (appContext == null) {
      console.warning('No context loaded.');
      console.info('Context is loaded automatically when shell starts.');
      return;
    }
    
    final ctx = appContext!;
    
    // Application Info
    console.section('Application');
    console.keyValue('App Name', ctx.appName);
    console.keyValue('Version', ctx.version);
    
    // Build Configuration
    console.section('Build Configuration');
    console.keyValue('Build Type', ctx.buildType);
    console.keyValue('Flavor', (ctx.flavor == null || ctx.flavor!.isEmpty) ? '(none)' : ctx.flavor!);
    console.keyValue('Output Path', ctx.outputPath);
    
    // Tools & Integrations
    console.section('Tools & Integrations');
    console.keyValue('Use FVM', ctx.useFvm.toString());
    console.keyValue('Use Shorebird', ctx.useShorebird.toString());
    
    // Project Info
    console.section('Project');
    console.keyValue('Project Root', ctx.projectRoot);
    
    // Context Metadata
    console.section('Context Metadata');
    console.keyValue('Loaded At', ctx.loadedAt.toString());
    console.keyValue('Context Age', '${ctx.age.inSeconds}s');
    
    if (ctx.isStale) {
      console.warning('Context is stale (>5 min). Run "reload" to refresh.');
    }
  }
  
  /// Reload configuration from fluttercraft.yaml
  Future<void> _reloadContext() async {
    console.info('Reloading configuration...');
    
    try {
      _appContext = await AppContext.load();
      console.success('Configuration reloaded successfully.');
      
      // Show brief summary of loaded config
      if (_appContext != null) {
        console.keyValue('App Name', _appContext!.appName);
        console.keyValue('Version', _appContext!.version);
        console.keyValue('Build Type', _appContext!.buildType);
      }
    } catch (e) {
      console.error('Failed to reload: $e');
    }
  }
  
  /// Stop the shell (can be called from external handlers)
  void stop() {
    _running = false;
  }
  
  /// Check if shell is running
  bool get isRunning => _running;
}


