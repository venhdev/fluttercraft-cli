import 'package:test/test.dart';
import 'package:mobile_build_cli/src/ui/styles.dart';

void main() {
  group('Colors', () {
    test('reset code is correct', () {
      expect(Colors.reset, equals('\x1B[0m'));
    });

    test('basic colors are defined', () {
      expect(Colors.red, isNotEmpty);
      expect(Colors.green, isNotEmpty);
      expect(Colors.yellow, isNotEmpty);
      expect(Colors.blue, isNotEmpty);
      expect(Colors.cyan, isNotEmpty);
      expect(Colors.magenta, isNotEmpty);
      expect(Colors.white, isNotEmpty);
      expect(Colors.black, isNotEmpty);
    });

    test('bright colors are defined', () {
      expect(Colors.brightRed, isNotEmpty);
      expect(Colors.brightGreen, isNotEmpty);
      expect(Colors.brightCyan, isNotEmpty);
    });

    test('styles are defined', () {
      expect(Colors.bold, isNotEmpty);
      expect(Colors.dim, isNotEmpty);
      expect(Colors.italic, isNotEmpty);
      expect(Colors.underline, isNotEmpty);
    });

    test('colorize wraps text with color and reset', () {
      final result = Colors.colorize('hello', Colors.red);
      expect(result, startsWith(Colors.red));
      expect(result, contains('hello'));
      expect(result, endsWith(Colors.reset));
    });

    test('semantic methods return colored text', () {
      expect(Colors.success('ok'), contains('ok'));
      expect(Colors.success('ok'), contains(Colors.green));

      expect(Colors.error('err'), contains('err'));
      expect(Colors.error('err'), contains(Colors.red));

      expect(Colors.warning('warn'), contains('warn'));
      expect(Colors.warning('warn'), contains(Colors.yellow));

      expect(Colors.info('info'), contains('info'));
      expect(Colors.info('info'), contains(Colors.cyan));

      expect(Colors.muted('dim'), contains('dim'));
      expect(Colors.muted('dim'), contains(Colors.dim));
    });
  });

  group('Symbols', () {
    test('status indicators are defined', () {
      expect(Symbols.success, equals('✓'));
      expect(Symbols.error, equals('✗'));
      expect(Symbols.warning, equals('⚠'));
      expect(Symbols.info, equals('ℹ'));
    });

    test('arrows are defined', () {
      expect(Symbols.arrowRight, equals('→'));
      expect(Symbols.arrowLeft, equals('←'));
      expect(Symbols.arrowUp, equals('↑'));
      expect(Symbols.arrowDown, equals('↓'));
      expect(Symbols.pointer, equals('❯'));
    });

    test('box drawing characters are defined', () {
      expect(Symbols.boxTopLeft, equals('┌'));
      expect(Symbols.boxTopRight, equals('┐'));
      expect(Symbols.boxBottomLeft, equals('└'));
      expect(Symbols.boxBottomRight, equals('┘'));
      expect(Symbols.boxHorizontal, equals('─'));
      expect(Symbols.boxVertical, equals('│'));
    });

    test('progress characters are defined', () {
      expect(Symbols.progressFilled, equals('█'));
      expect(Symbols.progressEmpty, equals('░'));
    });

    test('checkbox/radio characters are defined', () {
      expect(Symbols.checkboxOn, equals('☑'));
      expect(Symbols.checkboxOff, equals('☐'));
      expect(Symbols.radioOn, equals('◉'));
      expect(Symbols.radioOff, equals('○'));
    });
  });
}
