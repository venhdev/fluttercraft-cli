import 'dart:io';

import 'package:colored_logger/colored_logger.dart';

/// Console utility for pretty terminal output
class Console {
  final bool useColors;

  Console({this.useColors = true});

  // ─────────────────────────────────────────────────────────────────
  // Basic Output
  // ─────────────────────────────────────────────────────────────────

  /// Print a success message (green)
  void success(String message) {
    if (useColors) {
      print(message.green());
    } else {
      print(message);
    }
  }

  /// Print an error message (red)
  void error(String message) {
    if (useColors) {
      print(message.red());
    } else {
      print(message);
    }
  }

  /// Print a warning message (plain)
  void warning(String message) {
    print(message);
  }

  /// Print an info message (plain)
  void info(String message) {
    print(message);
  }

  /// Print a debug message (plain)
  void debug(String message) {
    print('  $message');
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

  /// Print a header (plain)
  void header(String message) {
    blank();
    print('=== $message ===');
    blank();
  }

  /// Print a section title (plain/colored)
  void section(String message) {
    blank();
    if (useColors) {
      // Assuming bold is a property and cyan is a method based on existing code '.bold.green()'
      print(message.bold.cyan());
    } else {
      print(message);
    }
  }

  /// Print a section title without leading blank line (plain)
  void sectionCompact(String message) {
    if (useColors) {
      print(message.bold.cyan());
    } else {
      print(message);
    }
  }

  /// Print a sub-section title (plain)
  void subSection(String message) {
    final label = '-- $message --';
    if (useColors) {
      // Use ANSI bright black (gray)
      print('  \x1B[90m$label\x1B[0m');
    } else {
      print('  $label');
    }
  }

  /// Print a key-value pair (plain)
  void keyValue(String key, String value, {int keyWidth = 16, int indent = 2}) {
    final padding = ' ' * indent;
    final paddedKey = key.padRight(keyWidth);
    print('$padding$paddedKey: $value');
  }

  // ─────────────────────────────────────────────────────────────────
  // Box Drawing
  // ─────────────────────────────────────────────────────────────────

  /// Print a box with title and content (plain)
  void box(String title, List<String> lines) {
    const width = 50;
    final topBorder = '╔${'═' * (width - 2)}╗';
    final bottomBorder = '╚${'═' * (width - 2)}╝';
    final divider = '╠${'═' * (width - 2)}╣';

    print(topBorder);
    print('║ ${title.padRight(width - 4)} ║');
    print(divider);

    for (final line in lines) {
      final truncated =
          line.length > width - 4 ? '${line.substring(0, width - 7)}...' : line;
      print('║ ${truncated.padRight(width - 4)} ║');
    }

    print(bottomBorder);
  }

  /// Print a menu box (plain)
  void menu(String title, List<String> options) {
    const width = 50;
    final topBorder = '╔${'═' * (width - 2)}╗';
    final bottomBorder = '╚${'═' * (width - 2)}╝';
    final divider = '╠${'═' * (width - 2)}╣';

    blank();
    print(topBorder);
    print('║ ${title.padRight(width - 4)} ║');
    print(divider);

    for (final option in options) {
      print('║   ${option.padRight(width - 6)} ║');
    }

    print(bottomBorder);
    blank();
  }

  // ─────────────────────────────────────────────────────────────────
  // Progress / Spinner
  // ─────────────────────────────────────────────────────────────────

  /// Start a spinner (simple version - prints message plain)
  void startSpinner(String message) {
    stdout.write('$message...');
  }

  /// Stop spinner with success (green)
  void stopSpinnerSuccess(String message) {
    if (useColors) {
      print('\r${message.green()}${' ' * 20}');
    } else {
      print('\r$message${' ' * 20}');
    }
  }

  /// Stop spinner with error (red)
  void stopSpinnerError(String message) {
    if (useColors) {
      print('\r${message.red()}${' ' * 20}');
    } else {
      print('\r$message${' ' * 20}');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // User Input
  // ─────────────────────────────────────────────────────────────────

  /// Prompt for text input (plain)
  String prompt(String message, {String? defaultValue}) {
    if (defaultValue != null) {
      stdout.write('$message [$defaultValue]: ');
    } else {
      stdout.write('$message: ');
    }

    final input = stdin.readLineSync()?.trim() ?? '';
    return input.isEmpty && defaultValue != null ? defaultValue : input;
  }

  /// Prompt for yes/no confirmation (plain)
  bool confirm(String message, {bool defaultValue = true}) {
    final defaultStr = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('$message ($defaultStr): ');

    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';

    if (input.isEmpty) return defaultValue;
    return input == 'y' || input == 'yes';
  }

  /// Prompt for choice selection
  ///
  /// Returns the index of the selected option, or -1 if options list is empty.
  /// If [defaultIndex] is out of bounds, it is clamped to a valid range.
  int choose(String message, List<String> options, {int defaultIndex = 0}) {
    // Handle empty options list
    if (options.isEmpty) {
      warning('No options available.');
      return -1;
    }

    // Clamp defaultIndex to valid range
    final safeDefault = defaultIndex.clamp(0, options.length - 1);

    print('\n$message');

    for (var i = 0; i < options.length; i++) {
      final marker = i == safeDefault ? '>' : ' ';
      // Current selection in green if colors enabled, otherwise just marker
      final line = '  $marker $i. ${options[i]}';
      if (useColors && i == safeDefault) {
        print(line.green());
      } else {
        print(line);
      }
    }

    stdout.write('Enter choice [0-${options.length - 1}]: ');
    final input = stdin.readLineSync()?.trim() ?? '';

    if (input.isEmpty) return safeDefault;

    final choice = int.tryParse(input);
    if (choice != null && choice >= 0 && choice < options.length) {
      return choice;
    }

    warning('Invalid choice, using default: ${options[safeDefault]}');
    return safeDefault;
  }

  // ─────────────────────────────────────────────────────────────────
  // Summary / Tables
  // ─────────────────────────────────────────────────────────────────

  /// Print a build summary
  void buildSummary({
    required String appName,
    required String version,
    required String platform,
    required String outputPath,
    Duration? duration,
  }) {
    blank();
    section('Build Summary');
    
    print('═══════════════════════════════════════════');
    if (useColors) {
      print('  BUILD COMPLETE'.bold.green());
    } else {
      print('  BUILD COMPLETE');
    }
    print('═══════════════════════════════════════════');
    
    keyValue('App Name', appName);
    keyValue('Version', version);
    keyValue('Platform', platform);
    keyValue('Output', outputPath);
    keyValue('Duration', '${duration?.inSeconds ?? 0}s');
    
    print('═══════════════════════════════════════════');
    blank();
  }
}
