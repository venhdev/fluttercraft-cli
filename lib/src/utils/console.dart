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

  /// Print a box with title and content (styled)
  void box(String title, List<String> lines) {
    const width = 50;
    final topBorder = '╔${'═' * (width - 2)}╗';
    final bottomBorder = '╚${'═' * (width - 2)}╝';
    
    // Center title
    final titleLen = title.length;
    final padLeft = (width - 4 - titleLen) ~/ 2;
    final padRight = width - 4 - titleLen - padLeft;
    final styledTitle = '${' ' * padLeft}$title${' ' * padRight}';

    final colorTitle = useColors ? styledTitle.bold.cyan() : styledTitle;
    final colorBorderTop = useColors ? topBorder.cyan() : topBorder;
    final colorBorderBottom = useColors ? bottomBorder.cyan() : bottomBorder;
    final colorDivider = useColors ? '║'.cyan() : '║';

    blank();
    print(colorBorderTop);
    print('$colorDivider $colorTitle $colorDivider');
    print(useColors ? '╠${'═' * (width - 2)}╣'.cyan() : '╠${'═' * (width - 2)}╣');

    for (final line in lines) {
      final truncated =
          line.length > width - 4 ? '${line.substring(0, width - 7)}...' : line;
      // Plain text content, but bordered
      print('$colorDivider ${truncated.padRight(width - 4)} $colorDivider');
    }

    print(colorBorderBottom);
    blank();
  }

  /// Print a menu box (styled)
  void menu(String title, List<String> options) {
    const width = 50;
    final topBorder = '╔${'═' * (width - 2)}╗';
    final bottomBorder = '╚${'═' * (width - 2)}╝';
    
    final titleLen = title.length;
    final padLeft = (width - 4 - titleLen) ~/ 2;
    final padRight = width - 4 - titleLen - padLeft;
    final styledTitle = '${' ' * padLeft}$title${' ' * padRight}';

    final colorTitle = useColors ? styledTitle.bold.yellow() : styledTitle;
    final colorBorderTop = useColors ? topBorder.yellow() : topBorder;
    final colorBorderBottom = useColors ? bottomBorder.yellow() : bottomBorder;
    final colorDivider = useColors ? '║'.yellow() : '║';

    blank();
    print(colorBorderTop);
    print('$colorDivider $colorTitle $colorDivider');
    print(useColors ? '╠${'═' * (width - 2)}╣'.yellow() : '╠${'═' * (width - 2)}╣');

    for (final option in options) {
      print('$colorDivider   ${option.padRight(width - 6)} $colorDivider');
    }

    print(colorBorderBottom);
    blank();
  }

  // ─────────────────────────────────────────────────────────────────
  // Progress / Spinner
  // ─────────────────────────────────────────────────────────────────

  /// Start a spinner (simple version - prints message plain)
  void startSpinner(String message) {
    if (useColors) {
      stdout.write('${message.cyan()}... ');
    } else {
      stdout.write('$message... ');
    }
  }

  /// Stop spinner with success (green)
  void stopSpinnerSuccess(String message) {
    if (useColors) {
      print('\r${'✔'.green()} $message${' ' * 10}');
    } else {
      print('\rOK $message${' ' * 10}');
    }
  }

  /// Stop spinner with error (red)
  void stopSpinnerError(String message) {
    if (useColors) {
      print('\r${'✖'.red()} $message${' ' * 10}');
    } else {
      print('\rERR $message${' ' * 10}');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // User Input
  // ─────────────────────────────────────────────────────────────────

  /// Prompt for text input (styled)
  String prompt(String message, {String? defaultValue}) {
    final msg = useColors ? message.bold.blue() : message;
    if (defaultValue != null) {
      final defVal = useColors ? defaultValue.cyan() : defaultValue;
      stdout.write('$msg [$defVal]: ');
    } else {
      stdout.write('$msg: ');
    }

    final input = stdin.readLineSync()?.trim() ?? '';
    return input.isEmpty && defaultValue != null ? defaultValue : input;
  }

  /// Prompt for yes/no confirmation (styled)
  bool confirm(String message, {bool defaultValue = true}) {
    final defaultStr = defaultValue ? 'Y/n' : 'y/N';
    final msg = useColors ? message.bold.blue() : message;
    stdout.write('$msg ($defaultStr): ');

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

    print('\n${useColors ? message.bold.blue() : message}');

    for (var i = 0; i < options.length; i++) {
      final marker = i == safeDefault ? '➜' : ' ';
      final line = '  $marker $i. ${options[i]}';
      
      if (useColors && i == safeDefault) {
        print(line.green().bold());
      } else {
        print(line);
      }
    }

    stdout.write('\nEnter choice [0-${options.length - 1}]: ');
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
    
    void printRow(String k, String v) {
      final key = k.padRight(12);
      print('${'║ $key : $v'.padRight(49)}║');
    }

    final header = 'BUILD COMPLETE'.padLeft(26).padRight(48);
    
    if (useColors) {
      print('╔════════════════════════════════════════════════╗'.green());
      print('║$header║'.green().bold());
      print('╠════════════════════════════════════════════════╣'.green());
      printRow('App Name', appName);
      printRow('Version', version);
      printRow('Platform', platform);
      printRow('Output', outputPath);
      printRow('Duration', '${duration?.inSeconds ?? 0}s');
      print('╚════════════════════════════════════════════════╝'.green());
    } else {
      print('╔════════════════════════════════════════════════╗');
      print('║$header║');
      print('╠════════════════════════════════════════════════╣');
      printRow('App Name', appName);
      printRow('Version', version);
      printRow('Platform', platform);
      printRow('Output', outputPath);
      printRow('Duration', '${duration?.inSeconds ?? 0}s');
      print('╚════════════════════════════════════════════════╝');
    }
    blank();
  }
}
