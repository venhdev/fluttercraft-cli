import 'package:fluttercraft/src/utils/console.dart';
import 'package:fluttercraft/src/utils/process_runner.dart';

class MockConsole implements Console {
  final List<String> logs = [];
  final Map<String, String> _promptResponses = {};
  
  // ignore: unused_field
  final bool _useColors;

  MockConsole({bool useColors = false}) : _useColors = useColors;

  @override
  bool get useColors => _useColors;

  void setPromptResponse(String key, String value) {
    _promptResponses[key] = value;
  }

  @override
  void log(String message) => logs.add('[LOG] $message');

  @override
  void info(String message) => logs.add('[INFO] $message');
  
  @override
  void success(String message) => logs.add('[SUCCESS] $message');

  @override
  void error(String message) => logs.add('[ERROR] $message');

  @override
  void warning(String message) => logs.add('[WARNING] $message');

  @override
  void debug(String message) => logs.add('[DEBUG] $message');

  @override
  void section(String message) => logs.add('[SECTION] $message');

  @override
  void sectionCompact(String message) => logs.add('[SECTION] $message');

  @override
  void header(String message) => logs.add('[HEADER] $message');

  @override
  void subSection(String message) => logs.add('[SUB] $message');

  @override
  void keyValue(String key, String value, {int keyWidth = 16, int indent = 2}) {
     logs.add('[KV] $key: $value');
  }

  @override
  void blank() => logs.add('');

  @override
  String prompt(String message, {String? defaultValue}) {
    logs.add('[PROMPT] $message');
    // Simple heuristic to match prompt message to response
    for (final key in _promptResponses.keys) {
      if (message.contains(key)) {
        return _promptResponses[key]!;
      }
    }
    return defaultValue ?? 'mock_value';
  }

  @override
  bool confirm(String message, {bool defaultValue = true}) {
    logs.add('[CONFIRM] $message');
    return defaultValue;
  }
  
  @override
  int choose(String message, List<String> options, {int defaultIndex = 0}) {
     logs.add('[CHOOSE] $message');
     return defaultIndex;
  }

  @override
  void box(String title, List<String> lines) {
    logs.add('[BOX] $title');
  }

  @override
  void menu(String title, List<String> options) {
    logs.add('[MENU] $title');
  }

  @override
  void startSpinner(String message) {
    logs.add('[SPINNER] $message');
  }

  @override
  void stopSpinnerSuccess(String message) {
     logs.add('[SPINNER_DONE] $message');
  }

  @override
  void stopSpinnerError(String message) {
    logs.add('[SPINNER_FAIL] $message');
  }
  
  @override
  void buildSummary({required String appName, required String version, required String platform, required String outputPath, Duration? duration}) {
    logs.add('[SUMMARY] $appName $version');
  }
}

class MockProcessRunner implements ProcessRunner {
  final List<List<String>> executedCommands = [];
  bool shouldFail = false;

  @override
  final bool verbose;

  MockProcessRunner({Console? console, this.verbose = false});

  @override
  Future<ProcessResult> run(
    String command,
    List<String> args, {
    String? workingDirectory,
    bool streamOutput = true,
    Map<String, String>? environment,
    bool? runInShell,
  }) async {
    executedCommands.add([command, ...args]);
    
    if (shouldFail) {
      return ProcessResult(exitCode: 1, stdout: 'Mock failure', stderr: 'Mock failure');
    }
    return ProcessResult(exitCode: 0, stdout: 'Mock success', stderr: '');
  }

  @override
  Future<bool> commandExists(String command) async {
    return true;
  }

  @override
  Future<ProcessResult> dart(List<String> args, {String? workingDirectory, bool useFvm = false, bool streamOutput = true}) async {
      return run('dart', args);
  }

  @override
  Future<ProcessResult> flutter(List<String> args, {String? workingDirectory, bool useFvm = false, bool streamOutput = true}) async {
      return run('flutter', args);
  }

  @override
  Future<ProcessResult> runSilent(String command, List<String> args, {String? workingDirectory, Map<String, String>? environment}) {
      return run(command, args, streamOutput: false);
  }

  @override
  Future<ProcessResult> shorebird(List<String> args, {String? workingDirectory, bool streamOutput = true}) {
      return run('shorebird', args);
  }
}
