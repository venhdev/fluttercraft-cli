import 'dart:io';

/// ANSI color codes for terminal output
class _AnsiColors {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  
  // Foreground colors
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  
  // Background colors
  static const String bgRed = '\x1B[41m';
  static const String bgGreen = '\x1B[42m';
  static const String bgYellow = '\x1B[43m';
  static const String bgBlue = '\x1B[44m';
}

/// Console utility for pretty terminal output
class Console {
  final bool useColors;

  Console({this.useColors = true});

  bool get _supportsAnsi => useColors && stdout.supportsAnsiEscapes;

  String _colorize(String text, String color) {
    if (_supportsAnsi) {
      return '$color$text${_AnsiColors.reset}';
    }
    return text;
  }

  // ─────────────────────────────────────────────────────────────────
  // Basic Output
  // ─────────────────────────────────────────────────────────────────

  /// Print a success message (green)
  void success(String message) {
    print(_colorize('✔ $message', _AnsiColors.green));
  }

  /// Print an error message (red)
  void error(String message) {
    print(_colorize('✖ $message', _AnsiColors.red));
  }

  /// Print a warning message (yellow)
  void warning(String message) {
    print(_colorize('⚠ $message', _AnsiColors.yellow));
  }

  /// Print an info message (cyan)
  void info(String message) {
    print(_colorize('ℹ $message', _AnsiColors.cyan));
  }

  /// Print a debug message (dim)
  void debug(String message) {
    print(_colorize('  $message', _AnsiColors.dim));
  }

  /// Print a normal message
  void log(String message) {
    print(message);
  }

  /// Print a blank line
  void blank() {
    print('');
  }

  // ─────────────────────────────────────────────────────────────────
  // Styled Output
  // ─────────────────────────────────────────────────────────────────

  /// Print a header (bold cyan)
  void header(String message) {
    blank();
    print(_colorize('${_AnsiColors.bold}═══ $message ═══', _AnsiColors.cyan));
    blank();
  }

  /// Print a section title (bold)
  void section(String message) {
    blank();
    print(_colorize('▸ $message', '${_AnsiColors.bold}${_AnsiColors.white}'));
  }

  /// Print a key-value pair
  void keyValue(String key, String value, {int keyWidth = 16}) {
    final paddedKey = key.padRight(keyWidth);
    print('  ${_colorize(paddedKey, _AnsiColors.dim)}: ${_colorize(value, _AnsiColors.white)}');
  }

  // ─────────────────────────────────────────────────────────────────
  // Box Drawing
  // ─────────────────────────────────────────────────────────────────

  /// Print a box with title and content
  void box(String title, List<String> lines) {
    const width = 50;
    final topBorder = '╔${'═' * (width - 2)}╗';
    final bottomBorder = '╚${'═' * (width - 2)}╝';
    final divider = '╠${'═' * (width - 2)}╣';

    print(_colorize(topBorder, _AnsiColors.cyan));
    print(_colorize('║ ${title.padRight(width - 4)} ║', _AnsiColors.cyan));
    print(_colorize(divider, _AnsiColors.cyan));
    
    for (final line in lines) {
      final truncated = line.length > width - 4 
          ? '${line.substring(0, width - 7)}...' 
          : line;
      print(_colorize('║ ${truncated.padRight(width - 4)} ║', _AnsiColors.cyan));
    }
    
    print(_colorize(bottomBorder, _AnsiColors.cyan));
  }

  /// Print a menu box
  void menu(String title, List<String> options) {
    const width = 50;
    final topBorder = '╔${'═' * (width - 2)}╗';
    final bottomBorder = '╚${'═' * (width - 2)}╝';
    final divider = '╠${'═' * (width - 2)}╣';

    blank();
    print(_colorize(topBorder, _AnsiColors.cyan));
    print(_colorize('║ ${title.padRight(width - 4)} ║', _AnsiColors.cyan));
    print(_colorize(divider, _AnsiColors.cyan));
    
    for (final option in options) {
      print(_colorize('║   ${option.padRight(width - 6)} ║', _AnsiColors.cyan));
    }
    
    print(_colorize(bottomBorder, _AnsiColors.cyan));
    blank();
  }

  // ─────────────────────────────────────────────────────────────────
  // Progress / Spinner
  // ─────────────────────────────────────────────────────────────────

  /// Start a spinner (simple version - prints message)
  void startSpinner(String message) {
    stdout.write(_colorize('⏳ $message...', _AnsiColors.yellow));
  }

  /// Stop spinner with success
  void stopSpinnerSuccess(String message) {
    print('\r${_colorize('✔ $message', _AnsiColors.green)}${' ' * 20}');
  }

  /// Stop spinner with error
  void stopSpinnerError(String message) {
    print('\r${_colorize('✖ $message', _AnsiColors.red)}${' ' * 20}');
  }

  // ─────────────────────────────────────────────────────────────────
  // User Input
  // ─────────────────────────────────────────────────────────────────

  /// Prompt for text input
  String prompt(String message, {String? defaultValue}) {
    if (defaultValue != null) {
      stdout.write(_colorize('? $message [$defaultValue]: ', _AnsiColors.cyan));
    } else {
      stdout.write(_colorize('? $message: ', _AnsiColors.cyan));
    }
    
    final input = stdin.readLineSync()?.trim() ?? '';
    return input.isEmpty && defaultValue != null ? defaultValue : input;
  }

  /// Prompt for yes/no confirmation
  bool confirm(String message, {bool defaultValue = true}) {
    final defaultStr = defaultValue ? 'Y/n' : 'y/N';
    stdout.write(_colorize('? $message ($defaultStr): ', _AnsiColors.cyan));
    
    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    
    if (input.isEmpty) return defaultValue;
    return input == 'y' || input == 'yes';
  }

  /// Prompt for choice selection
  int choose(String message, List<String> options, {int defaultIndex = 0}) {
    print(_colorize('\n? $message', _AnsiColors.cyan));
    
    for (var i = 0; i < options.length; i++) {
      final marker = i == defaultIndex ? '>' : ' ';
      print(_colorize('  $marker $i. ${options[i]}', 
          i == defaultIndex ? _AnsiColors.green : _AnsiColors.white));
    }
    
    stdout.write(_colorize('Enter choice [0-${options.length - 1}]: ', _AnsiColors.cyan));
    final input = stdin.readLineSync()?.trim() ?? '';
    
    if (input.isEmpty) return defaultIndex;
    
    final choice = int.tryParse(input);
    if (choice != null && choice >= 0 && choice < options.length) {
      return choice;
    }
    
    warning('Invalid choice, using default: ${options[defaultIndex]}');
    return defaultIndex;
  }

  // ─────────────────────────────────────────────────────────────────
  // Summary / Tables
  // ─────────────────────────────────────────────────────────────────

  /// Print a build summary
  void buildSummary({
    required String appName,
    required String version,
    required String buildType,
    required String outputPath,
    required Duration duration,
  }) {
    blank();
    print(_colorize('═══════════════════════════════════════════', _AnsiColors.green));
    print(_colorize('  BUILD COMPLETE', '${_AnsiColors.bold}${_AnsiColors.green}'));
    print(_colorize('═══════════════════════════════════════════', _AnsiColors.green));
    keyValue('App Name', appName);
    keyValue('Version', version);
    keyValue('Build Type', buildType);
    keyValue('Output', outputPath);
    keyValue('Duration', '${duration.inSeconds}s');
    print(_colorize('═══════════════════════════════════════════', _AnsiColors.green));
    blank();
  }
}
