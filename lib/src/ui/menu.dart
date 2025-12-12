import 'dart:async';
import 'dart:io';

import '../utils/terminal_helper.dart';
import 'interactive_mode.dart';

/// ANSI colors for menu styling
class _MenuColors {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String cyan = '\x1B[36m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
}

/// Interactive menu selector supporting both arrow-key and numeric modes
class Menu {
  /// Select an option from a list using the specified interactive mode
  /// 
  /// Returns the selected option string, or null if cancelled.
  static Future<String?> select({
    required String title,
    required List<String> options,
    InteractiveMode mode = InteractiveMode.arrow,
    int defaultIndex = 0,
  }) async {
    if (options.isEmpty) {
      return null;
    }
    
    // Clamp default index
    defaultIndex = defaultIndex.clamp(0, options.length - 1);
    
    switch (mode) {
      case InteractiveMode.arrow:
        return _selectArrowMode(title, options, defaultIndex);
      case InteractiveMode.numeric:
        return _selectNumericMode(title, options, defaultIndex);
    }
  }
  
  /// Arrow-key navigation mode
  static Future<String?> _selectArrowMode(
    String title,
    List<String> options,
    int defaultIndex,
  ) async {
    // Check if raw mode is supported
    if (!TerminalHelper.supportsRawMode()) {
      // Fall back to numeric mode
      stdout.writeln('${_MenuColors.yellow}(Arrow mode not supported, using numeric)${_MenuColors.reset}');
      return _selectNumericMode(title, options, defaultIndex);
    }
    
    var currentIndex = defaultIndex;
    final completer = Completer<String?>();
    
    void drawMenu() {
      // Clear previous menu lines and redraw
      // First, move to top of menu area
      TerminalHelper.moveCursorUp(options.length + 1);
      TerminalHelper.moveCursorToLineStart();
      
      // Draw title
      stdout.writeln('${_MenuColors.bold}${_MenuColors.cyan}$title${_MenuColors.reset}');
      
      // Draw options
      for (var i = 0; i < options.length; i++) {
        TerminalHelper.clearLine();
        if (i == currentIndex) {
          // Highlighted option
          stdout.writeln('  ${_MenuColors.green}❯ ${options[i]}${_MenuColors.reset}');
        } else {
          stdout.writeln('  ${_MenuColors.dim}  ${options[i]}${_MenuColors.reset}');
        }
      }
      
      // Show hint
      TerminalHelper.clearLine();
      stdout.write('${_MenuColors.dim}  (↑↓ to move, Enter to select, Ctrl+C to cancel)${_MenuColors.reset}');
    }
    
    void initialDraw() {
      // Print title and options first time
      stdout.writeln('${_MenuColors.bold}${_MenuColors.cyan}$title${_MenuColors.reset}');
      for (var i = 0; i < options.length; i++) {
        if (i == currentIndex) {
          stdout.writeln('  ${_MenuColors.green}❯ ${options[i]}${_MenuColors.reset}');
        } else {
          stdout.writeln('  ${_MenuColors.dim}  ${options[i]}${_MenuColors.reset}');
        }
      }
      stdout.write('${_MenuColors.dim}  (↑↓ to move, Enter to select, Ctrl+C to cancel)${_MenuColors.reset}');
    }
    
    try {
      TerminalHelper.enableRawMode();
      TerminalHelper.hideCursor();
      
      initialDraw();
      
      final parser = KeyParser();
      
      await for (final bytes in stdin) {
        final key = parser.parse(bytes);
        if (key == null) continue;
        
        switch (key.type) {
          case KeyType.arrowUp:
            currentIndex = (currentIndex - 1) % options.length;
            if (currentIndex < 0) currentIndex = options.length - 1;
            drawMenu();
            break;
            
          case KeyType.arrowDown:
            currentIndex = (currentIndex + 1) % options.length;
            drawMenu();
            break;
            
          case KeyType.enter:
            completer.complete(options[currentIndex]);
            break;
            
          case KeyType.ctrlC:
          case KeyType.escape:
            completer.complete(null);
            break;
            
          default:
            // Ignore other keys
            break;
        }
        
        if (completer.isCompleted) break;
      }
    } finally {
      TerminalHelper.showCursor();
      TerminalHelper.disableRawMode();
      stdout.writeln(); // New line after menu
    }
    
    return completer.future;
  }
  
  /// Numeric selection mode
  static Future<String?> _selectNumericMode(
    String title,
    List<String> options,
    int defaultIndex,
  ) async {
    // Print title
    stdout.writeln('${_MenuColors.bold}${_MenuColors.cyan}$title${_MenuColors.reset}');
    
    // Print numbered options
    for (var i = 0; i < options.length; i++) {
      final marker = i == defaultIndex ? '*' : ' ';
      stdout.writeln('  ${_MenuColors.bold}${i + 1})${_MenuColors.reset}$marker ${options[i]}');
    }
    
    // Prompt for selection
    stdout.write('${_MenuColors.dim}Enter number [1-${options.length}] (default: ${defaultIndex + 1}): ${_MenuColors.reset}');
    
    final input = stdin.readLineSync()?.trim();
    
    // Handle empty input (use default)
    if (input == null || input.isEmpty) {
      return options[defaultIndex];
    }
    
    // Handle 'q' or 'cancel'
    if (input.toLowerCase() == 'q' || input.toLowerCase() == 'cancel') {
      return null;
    }
    
    // Parse number
    final number = int.tryParse(input);
    if (number != null && number >= 1 && number <= options.length) {
      return options[number - 1];
    }
    
    // Invalid input - show error and use default
    stdout.writeln('${_MenuColors.yellow}Invalid selection, using default.${_MenuColors.reset}');
    return options[defaultIndex];
  }
  
  /// Prompt for confirmation (yes/no)
  static Future<bool> confirm({
    required String message,
    bool defaultValue = true,
  }) async {
    final defaultHint = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('${_MenuColors.cyan}$message${_MenuColors.reset} [$defaultHint]: ');
    
    final input = stdin.readLineSync()?.trim().toLowerCase();
    
    if (input == null || input.isEmpty) {
      return defaultValue;
    }
    
    return input == 'y' || input == 'yes';
  }
  
  /// Prompt for text input
  static Future<String> prompt({
    required String message,
    String? defaultValue,
  }) async {
    if (defaultValue != null) {
      stdout.write('${_MenuColors.cyan}$message${_MenuColors.reset} [$defaultValue]: ');
    } else {
      stdout.write('${_MenuColors.cyan}$message${_MenuColors.reset}: ');
    }
    
    final input = stdin.readLineSync()?.trim();
    
    if (input == null || input.isEmpty) {
      return defaultValue ?? '';
    }
    
    return input;
  }
}
