import 'dart:async';
import 'dart:io';

/// Animated spinner for showing progress on long-running operations
class Spinner {
  static const List<String> _defaultFrames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  static const List<String> _simpleFrames = ['-', '\\', '|', '/'];
  static const List<String> _dotsFrames = ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'];
  
  final List<String> frames;
  final String message;
  final Duration interval;
  
  Timer? _timer;
  int _frameIndex = 0;
  bool _running = false;
  
  Spinner({
    this.message = 'Loading...',
    this.frames = _defaultFrames,
    this.interval = const Duration(milliseconds: 80),
  });
  
  /// Create a spinner with simple frames (works in all terminals)
  factory Spinner.simple({String message = 'Loading...'}) {
    return Spinner(
      message: message,
      frames: _simpleFrames,
      interval: const Duration(milliseconds: 100),
    );
  }
  
  /// Create a spinner with dots animation
  factory Spinner.dots({String message = 'Loading...'}) {
    return Spinner(
      message: message,
      frames: _dotsFrames,
    );
  }
  
  /// Start the spinner animation
  void start() {
    if (_running) return;
    _running = true;
    _frameIndex = 0;
    
    // Hide cursor
    stdout.write('\x1B[?25l');
    
    _timer = Timer.periodic(interval, (_) {
      _draw();
      _frameIndex = (_frameIndex + 1) % frames.length;
    });
    
    _draw();
  }
  
  /// Update the message while spinning
  void update(String newMessage) {
    if (!_running) return;
    _clearLine();
    stdout.write('\r${_Colors.cyan}${frames[_frameIndex]}${_Colors.reset} $newMessage');
  }
  
  /// Stop the spinner with a success indicator
  void success([String? message]) {
    _stop();
    final msg = message ?? this.message;
    stdout.writeln('${_Colors.green}✓${_Colors.reset} $msg');
  }
  
  /// Stop the spinner with a failure indicator
  void fail([String? message]) {
    _stop();
    final msg = message ?? this.message;
    stdout.writeln('${_Colors.red}✗${_Colors.reset} $msg');
  }
  
  /// Stop the spinner with a warning indicator
  void warn([String? message]) {
    _stop();
    final msg = message ?? this.message;
    stdout.writeln('${_Colors.yellow}⚠${_Colors.reset} $msg');
  }
  
  /// Stop the spinner with an info indicator
  void info([String? message]) {
    _stop();
    final msg = message ?? this.message;
    stdout.writeln('${_Colors.cyan}ℹ${_Colors.reset} $msg');
  }
  
  /// Stop the spinner without any indicator
  void stop() {
    _stop();
    stdout.writeln();
  }
  
  void _stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _clearLine();
    // Show cursor
    stdout.write('\x1B[?25h');
  }
  
  void _draw() {
    _clearLine();
    stdout.write('\r${_Colors.cyan}${frames[_frameIndex]}${_Colors.reset} $message');
  }
  
  void _clearLine() {
    stdout.write('\r\x1B[2K');
  }
  
  bool get isRunning => _running;
}

/// Run an async action with a spinner
Future<T> withSpinner<T>({
  required Future<T> Function() action,
  required String message,
  String? successMessage,
  String? failureMessage,
}) async {
  final spinner = Spinner(message: message);
  spinner.start();
  
  try {
    final result = await action();
    spinner.success(successMessage ?? message);
    return result;
  } catch (e) {
    spinner.fail(failureMessage ?? '$message - Failed');
    rethrow;
  }
}

/// Simple color codes for spinner
class _Colors {
  static const String reset = '\x1B[0m';
  static const String cyan = '\x1B[36m';
  static const String green = '\x1B[32m';
  static const String red = '\x1B[31m';
  static const String yellow = '\x1B[33m';
}
