import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluttercraft/src/utils/console.dart';
import 'package:test/test.dart';

// Mock Stdout to capture output
class MockStdout implements Stdout {
  final StringBuffer _buffer = StringBuffer();

  String get output => _buffer.toString();
  void clear() => _buffer.clear();

  @override
  void write(Object? object) {
    _buffer.write(object);
  }

  @override
  void writeln([Object? object = ""]) {
    _buffer.writeln(object);
  }

  @override
  void add(List<int> data) {
    _buffer.write(utf8.decode(data));
  }

  @override
  bool get hasTerminal => false;

  @override
  int get terminalColumns => 80;

  @override
  bool get supportsAnsiEscapes => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock Stdin to simulate user input
class MockStdin implements Stdin {
  final List<String> _inputQueue = [];

  void queueInput(String input) {
    _inputQueue.add(input);
  }

  @override
  String? readLineSync({Encoding encoding = systemEncoding, bool retainNewlines = false}) {
    if (_inputQueue.isEmpty) return null;
    return _inputQueue.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Console', () {
    late Console console;
    late MockStdout mockStdout;
    late MockStdin mockStdin;
    late StringBuffer printBuffer;

    setUp(() {
      console = Console(useColors: false);
      mockStdout = MockStdout();
      mockStdin = MockStdin();
      printBuffer = StringBuffer();
    });

    // Helper to run code with mocked IO
    T runWithIO<T>(T Function() body) {
      return IOOverrides.runZoned(
        () {
          return runZoned(
            body,
            zoneSpecification: ZoneSpecification(
              print: (self, parent, zone, line) {
                printBuffer.writeln(line);
              },
            ),
          );
        },
        stdout: () => mockStdout,
        stdin: () => mockStdin,
      );
    }

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

    group('basic output (no colors)', () {
      setUp(() {
        console = Console(useColors: false);
      });

      test('success prints message', () {
        runWithIO(() => console.success('Done'));
        expect(printBuffer.toString(), 'Done\n');
      });

      test('error prints message', () {
        runWithIO(() => console.error('Failed'));
        expect(printBuffer.toString(), 'Failed\n');
      });

      test('warning prints message', () {
        runWithIO(() => console.warning('Warning'));
        expect(printBuffer.toString(), 'Warning\n');
      });

      test('info prints message', () {
        runWithIO(() => console.info('Info'));
        expect(printBuffer.toString(), 'Info\n');
      });

      test('debug prints indented message', () {
        runWithIO(() => console.debug('Debug'));
        expect(printBuffer.toString(), '  Debug\n');
      });

      test('log prints message', () {
        runWithIO(() => console.log('Log'));
        expect(printBuffer.toString(), 'Log\n');
      });

      test('blank prints empty line', () {
        runWithIO(() => console.blank());
        expect(printBuffer.toString(), '\n');
      });
    });

    group('styled output (no colors)', () {
      setUp(() {
        console = Console(useColors: false);
      });

      test('header prints formatted header', () {
        runWithIO(() => console.header('Header'));
        expect(printBuffer.toString(), '\n=== Header ===\n\n');
      });

      test('section prints title with blank line', () {
        runWithIO(() => console.section('Section'));
        expect(printBuffer.toString(), '\nSection\n');
      });

      test('sectionCompact prints title without blank line', () {
        runWithIO(() => console.sectionCompact('Compact'));
        expect(printBuffer.toString(), 'Compact\n');
      });

      test('subSection prints indented title', () {
        runWithIO(() => console.subSection('Sub'));
        expect(printBuffer.toString(), '  -- Sub --\n');
      });

      test('keyValue prints formatted pair', () {
        runWithIO(() => console.keyValue('Key', 'Value'));
        // Default width 16, indent 2
        expect(printBuffer.toString(), '  Key             : Value\n');
      });

      test('keyValue supports custom indent', () {
        runWithIO(() => console.keyValue('Key', 'Value', indent: 4));
        expect(printBuffer.toString(), '    Key             : Value\n');
      });
    });

    group('box drawing', () {
      setUp(() {
        console = Console(useColors: false);
      });

      test('box prints correct frame', () {
        runWithIO(() => console.box('Title', ['Line 1']));
        final output = printBuffer.toString().split('\n');
        // Check some structural elements
        expect(output[0], contains('╔═'));
        expect(output[1], contains('Title'));
        expect(output[3], contains('Line 1'));
        expect(output.last, isEmpty); // Trailing newline from writeln
      });

      test('menu prints correct frame', () {
        runWithIO(() => console.menu('Menu', ['Opt 1']));
        final output = printBuffer.toString();
        expect(output, contains('╔═'));
        expect(output, contains('Menu'));
        expect(output, contains('Opt 1'));
      });
    });

    group('interactive methods', () {
      setUp(() {
        console = Console(useColors: false);
      });

      test('prompt returns user input', () {
        mockStdin.queueInput('User Input');
        final result = runWithIO(() => console.prompt('Enter name'));
        
        expect(mockStdout.output, 'Enter name: ');
        expect(result, 'User Input');
      });

      test('prompt uses default value on empty input', () {
        mockStdin.queueInput(''); // Empty input
        final result = runWithIO(() => console.prompt('Name', defaultValue: 'Guest'));
        
        expect(mockStdout.output, 'Name [Guest]: ');
        expect(result, 'Guest');
      });

      test('confirm returns true on "y"', () {
        mockStdin.queueInput('y');
        final result = runWithIO(() => console.confirm('Sure?'));
        
        expect(mockStdout.output, 'Sure? (Y/n): ');
        expect(result, true);
      });

      test('confirm returns false on "n"', () {
        mockStdin.queueInput('n');
        final result = runWithIO(() => console.confirm('Sure?'));
        
        expect(result, false);
      });

      test('confirm uses default (true) on empty input', () {
        mockStdin.queueInput('');
        final result = runWithIO(() => console.confirm('Sure?', defaultValue: true));
        
        expect(result, true);
      });

      test('choose returns selected index', () {
        mockStdin.queueInput('1');
        final result = runWithIO(() => console.choose('Select:', ['A', 'B', 'C']));
        
        // Output should show options
        final output = printBuffer.toString();
        expect(output, contains('0. A'));
        expect(output, contains('1. B'));
        // And prompt
        expect(mockStdout.output, contains('Enter choice [0-2]: '));
        expect(result, 1);
      });

      test('choose returns default on empty input', () {
        mockStdin.queueInput('');
        final result = runWithIO(() => console.choose('Select:', ['A', 'B'], defaultIndex: 1));
        
        expect(result, 1);
      });

      test('choose returns default on invalid input', () {
        mockStdin.queueInput('invalid');
        final result = runWithIO(() => console.choose('Select:', ['A', 'B']));
        
        expect(result, 0); // Default defaultIndex is 0
        expect(printBuffer.toString(), contains('Invalid choice'));
      });
      
      test('choose handles empty options', () {
         final result = runWithIO(() => console.choose('Select:', []));
         expect(result, -1);
      });
    });

    group('spinner', () {
      setUp(() {
        console = Console(useColors: false);
      });

      test('startSpinner writes to stdout', () {
        runWithIO(() => console.startSpinner('Loading'));
        expect(mockStdout.output, 'Loading...');
      });

      test('stopSpinnerSuccess prints success', () {
        runWithIO(() => console.stopSpinnerSuccess('Done'));
        // Usually prints \r...
        expect(printBuffer.toString(), '\rDone                    \n');
      });

      test('stopSpinnerError prints error', () {
        runWithIO(() => console.stopSpinnerError('Error'));
        expect(printBuffer.toString(), '\rError                    \n');
      });
    });
    
    group('colors', () {
       test('success uses ANSI codes provided by colored_logger extensions', () {
         console = Console(useColors: true);
         // Note: we can't easily verify exact ANSI codes without knowing what colored_logger does,
         // but checking it doesn't just print plain text is a start. 
         // Actually, colored_logger adds invisible chars.
         // Let's just check it runs. The plain text comparison would match if strip is used, 
         // but here we expect the raw string to NOT be equal to 'Msg' alone.
         
         runWithIO(() => console.success('Msg'));
         expect(printBuffer.toString().trim(), isNot(equals('Msg')));
         expect(printBuffer.toString(), contains('Msg'));
       });

       test('section uses colors when enabled', () {
         console = Console(useColors: true);
         runWithIO(() => console.section('Section'));
         // Should contain ANSI codes + Section + newline
         expect(printBuffer.toString().trim(), isNot(equals('Section')));
         expect(printBuffer.toString(), contains('Section'));
       });

       test('subSection uses colors when enabled', () {
         console = Console(useColors: true);
         runWithIO(() => console.subSection('Sub'));
         expect(printBuffer.toString().trim(), isNot(equals('-- Sub --')));
         expect(printBuffer.toString(), contains('-- Sub --'));
       });
    });
  });
}
