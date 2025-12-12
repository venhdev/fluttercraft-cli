import 'dart:io';

/// Terminal helper utilities for cross-platform terminal manipulation
class TerminalHelper {
  /// Check if the terminal supports raw mode
  static bool supportsRawMode() {
    try {
      // Try to access lineMode - will throw if not supported
      final current = stdin.lineMode;
      stdin.lineMode = current; // Reset to same value
      return true;
    } catch (_) {
      return false;
    }
  }
  
  /// Enable raw mode for character-by-character input
  static void enableRawMode() {
    stdin.lineMode = false;
    stdin.echoMode = false;
  }
  
  /// Restore normal terminal mode
  static void disableRawMode() {
    stdin.lineMode = true;
    stdin.echoMode = true;
  }
  
  /// Clear the terminal screen
  static void clearScreen() {
    if (Platform.isWindows) {
      stdout.write('\x1B[2J\x1B[0;0H');
    } else {
      stdout.write('\x1B[2J\x1B[H');
    }
  }
  
  /// Clear the current line
  static void clearLine() {
    stdout.write('\x1B[2K\r');
  }
  
  /// Move cursor up n lines
  static void moveCursorUp(int n) {
    if (n > 0) {
      stdout.write('\x1B[${n}A');
    }
  }
  
  /// Move cursor down n lines
  static void moveCursorDown(int n) {
    if (n > 0) {
      stdout.write('\x1B[${n}B');
    }
  }
  
  /// Move cursor to beginning of line
  static void moveCursorToLineStart() {
    stdout.write('\r');
  }
  
  /// Hide cursor
  static void hideCursor() {
    stdout.write('\x1B[?25l');
  }
  
  /// Show cursor
  static void showCursor() {
    stdout.write('\x1B[?25h');
  }
  
  /// Save cursor position
  static void saveCursorPosition() {
    stdout.write('\x1B[s');
  }
  
  /// Restore cursor position
  static void restoreCursorPosition() {
    stdout.write('\x1B[u');
  }
}

/// Keyboard key codes and escape sequences
class KeyCode {
  // Control characters
  static const int enter = 13;
  static const int escape = 27;
  static const int ctrlC = 3;
  static const int ctrlD = 4;
  static const int backspace = 127;
  static const int backspaceAlt = 8;
  
  // Escape sequence marker
  static const int escapeStart = 27;
  static const int bracketStart = 91; // [
  
  // Arrow key final bytes (after ESC [)
  static const int arrowUp = 65;    // A
  static const int arrowDown = 66;  // B
  static const int arrowRight = 67; // C
  static const int arrowLeft = 68;  // D
  
  // Number keys
  static const int num0 = 48;
  static const int num9 = 57;
  
  /// Check if byte is a number (0-9)
  static bool isNumber(int byte) => byte >= num0 && byte <= num9;
  
  /// Convert number byte to int
  static int toNumber(int byte) => byte - num0;
}

/// Parsed keyboard input
enum KeyType {
  character,
  enter,
  escape,
  arrowUp,
  arrowDown,
  arrowLeft,
  arrowRight,
  ctrlC,
  backspace,
  unknown,
}

class KeyInput {
  final KeyType type;
  final String? character;
  
  KeyInput(this.type, [this.character]);
  
  @override
  String toString() => 'KeyInput($type, $character)';
}

/// Parse bytes from stdin into KeyInput
class KeyParser {
  final List<int> _buffer = [];
  
  /// Parse a list of bytes into a KeyInput
  KeyInput? parse(List<int> bytes) {
    _buffer.addAll(bytes);
    
    if (_buffer.isEmpty) return null;
    
    final first = _buffer.removeAt(0);
    
    // Handle escape sequences (arrow keys, etc.)
    if (first == KeyCode.escapeStart) {
      if (_buffer.isEmpty) {
        return KeyInput(KeyType.escape);
      }
      
      final second = _buffer.removeAt(0);
      if (second == KeyCode.bracketStart && _buffer.isNotEmpty) {
        final third = _buffer.removeAt(0);
        switch (third) {
          case KeyCode.arrowUp:
            return KeyInput(KeyType.arrowUp);
          case KeyCode.arrowDown:
            return KeyInput(KeyType.arrowDown);
          case KeyCode.arrowLeft:
            return KeyInput(KeyType.arrowLeft);
          case KeyCode.arrowRight:
            return KeyInput(KeyType.arrowRight);
        }
      }
      return KeyInput(KeyType.unknown);
    }
    
    // Handle control characters
    switch (first) {
      case KeyCode.enter:
        return KeyInput(KeyType.enter);
      case KeyCode.ctrlC:
        return KeyInput(KeyType.ctrlC);
      case KeyCode.backspace:
      case KeyCode.backspaceAlt:
        return KeyInput(KeyType.backspace);
    }
    
    // Regular character
    if (first >= 32 && first < 127) {
      return KeyInput(KeyType.character, String.fromCharCode(first));
    }
    
    return KeyInput(KeyType.unknown);
  }
  
  /// Clear the buffer
  void clear() => _buffer.clear();
}
