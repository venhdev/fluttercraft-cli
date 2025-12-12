import 'dart:io';

/// ANSI colors for menu styling
class _MenuColors {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String cyan = '\x1B[36m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
}

/// Interactive menu selector using numeric input
/// 
/// Works across all platforms and terminals.
class Menu {
  /// Select an option from a list
  /// 
  /// Returns the selected option string, or null if cancelled.
  static Future<String?> select({
    required String title,
    required List<String> options,
    int defaultIndex = 0,
  }) async {
    if (options.isEmpty) {
      return null;
    }
    
    // Clamp default index
    defaultIndex = defaultIndex.clamp(0, options.length - 1);
    
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
      stdout.writeln('${_MenuColors.green}✔ Selected: ${options[defaultIndex]}${_MenuColors.reset}');
      return options[defaultIndex];
    }
    
    // Handle 'q' or 'cancel'
    if (input.toLowerCase() == 'q' || input.toLowerCase() == 'cancel') {
      return null;
    }
    
    // Parse number
    final number = int.tryParse(input);
    if (number != null && number >= 1 && number <= options.length) {
      stdout.writeln('${_MenuColors.green}✔ Selected: ${options[number - 1]}${_MenuColors.reset}');
      return options[number - 1];
    }
    
    // Invalid input - show error and use default
    stdout.writeln('${_MenuColors.yellow}Invalid selection, using default.${_MenuColors.reset}');
    stdout.writeln('${_MenuColors.green}✔ Selected: ${options[defaultIndex]}${_MenuColors.reset}');
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
