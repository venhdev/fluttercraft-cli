import 'package:test/test.dart';
import 'package:fluttercraft/src/commands/build_command.dart';

/// Tests for BuildCommand
///
/// Verifies command properties and argument parsing.
void main() {
  group('BuildCommand', () {
    test('command has correct name', () {
      final buildCmd = BuildCommand();
      expect(buildCmd.name, 'build');
    });

    test('command has correct description', () {
      final buildCmd = BuildCommand();
      expect(buildCmd.description, contains('Build'));
    });

    test('argParser includes type option with abbreviation', () {
      final buildCmd = BuildCommand();
      final options = buildCmd.argParser.options;
      expect(options.containsKey('type'), true);
      expect(options['type']?.abbr, 't');
    });

    test('argParser includes clean flag with abbreviation', () {
      final buildCmd = BuildCommand();
      final options = buildCmd.argParser.options;
      expect(options.containsKey('clean'), true);
      expect(options['clean']?.abbr, 'c');
    });

    test('argParser includes no-confirm flag', () {
      final buildCmd = BuildCommand();
      final options = buildCmd.argParser.options;
      expect(options.containsKey('no-confirm'), true);
    });

    test('argParser includes version option with abbreviation', () {
      final buildCmd = BuildCommand();
      final options = buildCmd.argParser.options;
      expect(options.containsKey('version'), true);
      expect(options['version']?.abbr, 'v');
    });

    test('argParser includes build-number option', () {
      final buildCmd = BuildCommand();
      final options = buildCmd.argParser.options;
      expect(options.containsKey('build-number'), true);
    });

    test('type option allows only valid build types', () {
      final buildCmd = BuildCommand();
      final options = buildCmd.argParser.options;
      final allowed = options['type']?.allowed;
      expect(allowed, containsAll(['apk', 'aab', 'ipa', 'app']));
    });
  });
}
