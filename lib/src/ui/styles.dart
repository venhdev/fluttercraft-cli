/// ANSI color codes for terminal styling
/// 
/// Provides consistent color theming across the CLI.
class Colors {
  // Reset
  static const String reset = '\x1B[0m';
  
  // Basic colors
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  
  // Bright colors
  static const String brightBlack = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';
  
  // Styles
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String underline = '\x1B[4m';
  static const String inverse = '\x1B[7m';
  static const String strikethrough = '\x1B[9m';
  
  // Background colors
  static const String bgBlack = '\x1B[40m';
  static const String bgRed = '\x1B[41m';
  static const String bgGreen = '\x1B[42m';
  static const String bgYellow = '\x1B[43m';
  static const String bgBlue = '\x1B[44m';
  static const String bgMagenta = '\x1B[45m';
  static const String bgCyan = '\x1B[46m';
  static const String bgWhite = '\x1B[47m';
  
  /// Apply color to text
  static String colorize(String text, String color) {
    return '$color$text$reset';
  }
  
  // Semantic colors for CLI
  static String success(String text) => colorize(text, green);
  static String error(String text) => colorize(text, red);
  static String warning(String text) => colorize(text, yellow);
  static String info(String text) => colorize(text, cyan);
  static String muted(String text) => colorize(text, dim);
  static String highlight(String text) => colorize(text, bold + cyan);
  static String primary(String text) => colorize(text, brightCyan);
}

/// Unicode symbols for CLI visuals
class Symbols {
  // Status indicators
  static const String success = '✓';
  static const String error = '✗';
  static const String warning = '⚠';
  static const String info = 'ℹ';
  static const String question = '?';
  
  // Arrows
  static const String arrowRight = '→';
  static const String arrowLeft = '←';
  static const String arrowUp = '↑';
  static const String arrowDown = '↓';
  static const String pointer = '❯';
  static const String pointerSmall = '›';
  
  // Bullet points
  static const String bullet = '•';
  static const String star = '★';
  static const String heart = '♥';
  static const String diamond = '◆';
  
  // Box drawing
  static const String boxTopLeft = '┌';
  static const String boxTopRight = '┐';
  static const String boxBottomLeft = '└';
  static const String boxBottomRight = '┘';
  static const String boxHorizontal = '─';
  static const String boxVertical = '│';
  
  // Progress
  static const String progressFilled = '█';
  static const String progressEmpty = '░';
  static const String progressPartial = '▒';
  
  // Misc
  static const String ellipsis = '…';
  static const String radioOn = '◉';
  static const String radioOff = '○';
  static const String checkboxOn = '☑';
  static const String checkboxOff = '☐';
}
