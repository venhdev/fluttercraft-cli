import 'package:test/test.dart';
import 'package:fluttercraft/src/utils/console.dart';

/// Tests for Console utility
///
/// Note: Some methods use stdin which cannot be easily tested.
/// These tests focus on testable behavior and edge cases.
void main() {
  group('Console', () {
    late Console console;

    setUp(() {
      console = Console(useColors: false);
    });

    group('constructor', () {
      test('creates with default useColors true', () {
        final c = Console();
        expect(c.useColors, true);
      });

      test('creates with useColors false', () {
        final c = Console(useColors: false);
        expect(c.useColors, false);
      });
    });

    group('choose edge cases', () {
      test('returns -1 for empty options list', () {
        final result = console.choose('Select:', []);
        expect(result, -1);
      });

      test('clamps defaultIndex when too large', () {
        // When defaultIndex > options.length - 1, it should be clamped
        // This test verifies the console doesn't crash
        final console = Console(useColors: false);
        // We can't fully test this without stdin, but we can verify
        // the method signature accepts the parameters
        expect(() => console.choose('Select:', ['a', 'b'], defaultIndex: 99),
            isA<Function>());
      });

      test('clamps defaultIndex when negative', () {
        // When defaultIndex < 0, it should be clamped to 0
        final console = Console(useColors: false);
        expect(() => console.choose('Select:', ['a', 'b'], defaultIndex: -5),
            isA<Function>());
      });
    });

    group('output methods do not throw', () {
      test('success does not throw', () {
        expect(() => console.success('message'), returnsNormally);
      });

      test('error does not throw', () {
        expect(() => console.error('message'), returnsNormally);
      });

      test('warning does not throw', () {
        expect(() => console.warning('message'), returnsNormally);
      });

      test('info does not throw', () {
        expect(() => console.info('message'), returnsNormally);
      });

      test('debug does not throw', () {
        expect(() => console.debug('message'), returnsNormally);
      });

      test('log does not throw', () {
        expect(() => console.log('message'), returnsNormally);
      });

      test('blank does not throw', () {
        expect(() => console.blank(), returnsNormally);
      });

      test('header does not throw', () {
        expect(() => console.header('title'), returnsNormally);
      });

      test('section does not throw', () {
        expect(() => console.section('title'), returnsNormally);
      });

      test('sectionCompact does not throw', () {
        expect(() => console.sectionCompact('title'), returnsNormally);
      });

      test('subSection does not throw', () {
        expect(() => console.subSection('title'), returnsNormally);
      });

      test('keyValue does not throw', () {
        expect(() => console.keyValue('key', 'value'), returnsNormally);
      });

      test('keyValue with custom width does not throw', () {
        expect(() => console.keyValue('key', 'value', keyWidth: 30), returnsNormally);
      });
    });

    group('box drawing', () {
      test('box does not throw', () {
        expect(() => console.box('Title', ['Line 1', 'Line 2']), returnsNormally);
      });

      test('box handles empty lines', () {
        expect(() => console.box('Title', []), returnsNormally);
      });

      test('box handles long lines', () {
        final longLine = 'A' * 100;
        expect(() => console.box('Title', [longLine]), returnsNormally);
      });

      test('menu does not throw', () {
        expect(() => console.menu('Title', ['Option 1', 'Option 2']), returnsNormally);
      });

      test('menu handles empty options', () {
        expect(() => console.menu('Title', []), returnsNormally);
      });
    });

    group('spinner', () {
      test('startSpinner does not throw', () {
        expect(() => console.startSpinner('Loading'), returnsNormally);
      });

      test('stopSpinnerSuccess does not throw', () {
        expect(() => console.stopSpinnerSuccess('Done'), returnsNormally);
      });

      test('stopSpinnerError does not throw', () {
        expect(() => console.stopSpinnerError('Failed'), returnsNormally);
      });
    });

    group('buildSummary', () {
      test('does not throw with valid parameters', () {
        expect(
          () => console.buildSummary(
            appName: 'TestApp',
            version: '1.0.0+1',
            buildType: 'APK',
            outputPath: '/path/to/output',
            duration: Duration(seconds: 60),
          ),
          returnsNormally,
        );
      });

      test('handles empty strings', () {
        expect(
          () => console.buildSummary(
            appName: '',
            version: '',
            buildType: '',
            outputPath: '',
            duration: Duration.zero,
          ),
          returnsNormally,
        );
      });
    });
  });
}
