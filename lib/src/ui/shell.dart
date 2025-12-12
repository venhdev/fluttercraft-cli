import 'dart:io';

import '../core/app_context.dart';
import '../flows/build_flow.dart';
import '../utils/console.dart';
import 'interactive_mode.dart';
import 'menu.dart';

/// Interactive Shell REPL for the CLI
/// 
/// Provides a continuous command-line interface that keeps running
/// until the user exits. Supports built-in commands and dispatches
/// to registered command handlers.
class Shell {
  final Console console;
  final InteractiveMode interactiveMode;
  final AppContext? appContext;
  final Map<String, Future<int> Function(List<String> args)> _commands = {};
  
  bool _running = false;
  
  Shell({
    Console? console,
    this.interactiveMode = InteractiveMode.arrow,
    this.appContext,
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
        
      case 'demo':
        await _runDemo();
        return;
        
      case 'wizard':
      case 'w':
        await _runBuildWizard();
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
    console.keyValue('demo', 'Test interactive menu');
    console.keyValue('wizard, w', 'Build wizard (multi-step)');
    console.keyValue('context, ctx', 'Show loaded context');
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
  
  /// Run interactive menu demo
  Future<void> _runDemo() async {
    console.section('Interactive Menu Demo');
    console.blank();
    
    // Demo arrow-key menu
    final target = await Menu.select(
      title: 'Select build target:',
      options: ['apk', 'aab', 'ipa', 'macos'],
      mode: interactiveMode,
    );
    
    if (target == null) {
      console.warning('Selection cancelled.');
      return;
    }
    
    console.success('Selected: $target');
    console.blank();
    
    // Demo confirm
    final confirmed = await Menu.confirm(
      message: 'Would you like to continue?',
    );
    console.info('Confirmed: $confirmed');
    console.blank();
    
    console.success('Demo complete!');
  }
  
  /// Run the build wizard
  Future<void> _runBuildWizard() async {
    final flow = BuildFlow(
      console: console,
      interactiveMode: interactiveMode,
    );
    
    final confirmed = await flow.execute();
    
    if (confirmed) {
      final config = flow.buildConfig;
      console.blank();
      console.success('Build wizard complete!');
      console.keyValue('Config', config.toString());
      console.blank();
      
      // Ask if they want to run the build now
      final runNow = await Menu.confirm(
        message: 'Run build now?',
        defaultValue: true,
      );
      
      if (runNow && _commands.containsKey('build')) {
        console.info('Starting build...');
        await _commands['build']!(config.toArgs());
      } else if (runNow) {
        console.warning('Build command not registered in shell.');
        console.info('Run manually: mycli build ${config.toArgs().join(' ')}');
      }
    } else {
      console.warning('Build wizard cancelled.');
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
    console.keyValue('Flavor', ctx.flavor.isEmpty ? '(none)' : ctx.flavor);
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
