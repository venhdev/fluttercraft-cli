import 'package:test/test.dart';
import 'package:fluttercraft/src/commands/convert_command.dart';

/// Tests for ConvertCommand
///
/// Verifies command properties and argument parsing.
void main() {
  group('ConvertCommand', () {
    test('command has correct name', () {
      final convertCmd = ConvertCommand();
      expect(convertCmd.name, 'convert');
    });

    test('command has correct description', () {
      final convertCmd = ConvertCommand();
      expect(convertCmd.description, contains('AAB'));
      expect(convertCmd.description, contains('APK'));
    });

    test('argParser includes aab option with abbreviation', () {
      final convertCmd = ConvertCommand();
      final options = convertCmd.argParser.options;
      expect(options.containsKey('aab'), true);
      expect(options['aab']?.abbr, 'a');
    });

    test('argParser includes output option with abbreviation', () {
      final convertCmd = ConvertCommand();
      final options = convertCmd.argParser.options;
      expect(options.containsKey('output'), true);
      expect(options['output']?.abbr, 'o');
    });

    test('argParser includes bundletool option', () {
      final convertCmd = ConvertCommand();
      final options = convertCmd.argParser.options;
      expect(options.containsKey('bundletool'), true);
    });

    test('argParser includes key-properties option', () {
      final convertCmd = ConvertCommand();
      final options = convertCmd.argParser.options;
      expect(options.containsKey('key-properties'), true);
    });
  });
}
