import 'package:test/test.dart';
import 'package:fluttercraft/src/core/pubspec_parser.dart';
import '../test_helper.dart';

/// Tests for PubspecParser
///
/// Verifies pubspec.yaml parsing and version extraction.
void main() {
  group('PubspecParser', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'pubspec_parser_test_',
      );
    });

    tearDown(() async {
      await cleanup();
    });

    group('exists', () {
      test('returns false when pubspec.yaml does not exist', () async {
        final parser = PubspecParser(projectRoot: tempDir);
        expect(await parser.exists(), false);
      });

      test('returns true when pubspec.yaml exists', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
        final parser = PubspecParser(projectRoot: tempDir);
        expect(await parser.exists(), true);
      });
    });

    group('parse', () {
      test('returns null when pubspec.yaml does not exist', () async {
        final parser = PubspecParser(projectRoot: tempDir);
        final result = await parser.parse();
        expect(result, isNull);
      });

      test('parses valid pubspec with full version', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: myapp
version: 2.5.3+42
''');
        final parser = PubspecParser(projectRoot: tempDir);
        final result = await parser.parse();

        expect(result, isNotNull);
        expect(result!.name, 'myapp');
        expect(result.version, '2.5.3+42');
        expect(result.buildName, '2.5.3');
        expect(result.buildNumber, '42');
        expect(result.fullVersion, '2.5.3+42');
      });

      test('parses version without build number', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: myapp
version: 1.2.3
''');
        final parser = PubspecParser(projectRoot: tempDir);
        final result = await parser.parse();

        expect(result, isNotNull);
        expect(result!.buildName, '1.2.3');
        expect(result.buildNumber, '1'); // default
        expect(result.fullVersion, '1.2.3+1');
      });

      test('uses default name when missing', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
version: 1.0.0+1
''');
        final parser = PubspecParser(projectRoot: tempDir);
        final result = await parser.parse();

        expect(result, isNotNull);
        expect(result!.name, 'app'); // default
      });

      test('uses default version when missing', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: myapp
''');
        final parser = PubspecParser(projectRoot: tempDir);
        final result = await parser.parse();

        expect(result, isNotNull);
        expect(result!.version, '1.0.0+1'); // default
      });

      test('returns null on malformed YAML', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: [invalid yaml
  unclosed bracket
''');
        final parser = PubspecParser(projectRoot: tempDir);
        final result = await parser.parse();

        expect(result, isNull);
      });

      test('handles empty pubspec.yaml', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '');
        final parser = PubspecParser(projectRoot: tempDir);
        final result = await parser.parse();

        // Empty YAML parses to null, which triggers catch block
        expect(result, isNull);
      });
    });

    group('updateVersion', () {
      test('returns false when pubspec does not exist', () async {
        final parser = PubspecParser(projectRoot: tempDir);
        final result = await parser.updateVersion('2.0.0+1');
        expect(result, false);
      });

      test('updates version line in pubspec', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: myapp
version: 1.0.0+1
environment:
  sdk: ^3.0.0
''');
        final parser = PubspecParser(projectRoot: tempDir);
        final result = await parser.updateVersion('2.0.0+50');

        expect(result, true);

        final content = await TestHelper.readFile(tempDir, 'pubspec.yaml');
        expect(content, contains('version: 2.0.0+50'));
        expect(content, contains('name: myapp')); // other content preserved
      });

      test('returns false when no version line exists', () async {
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: myapp
environment:
  sdk: ^3.0.0
''');
        final parser = PubspecParser(projectRoot: tempDir);
        final result = await parser.updateVersion('2.0.0+1');

        expect(result, false);
      });
    });

    group('PubspecInfo', () {
      test('toString includes name and version', () {
        final info = PubspecInfo(
          name: 'testapp',
          version: '1.2.3+45',
          buildName: '1.2.3',
          buildNumber: '45',
        );

        expect(info.toString(), contains('testapp'));
        expect(info.toString(), contains('1.2.3+45'));
      });
    });
  });
}
