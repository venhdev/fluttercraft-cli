import 'dart:io';

import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';

void main() {
  group('BuildConfig - Alias Parsing', () {
    late String tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('alias_test_').path;
    });

    tearDown(() async {
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (_) {}
    });

    test('parses empty alias section', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

alias:
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      expect(config.aliases, isEmpty);
    });

    test('parses single alias with single command', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

alias:
  test:
    cmds:
      - fvm dart pub get
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      
      expect(config.aliases, hasLength(1));
      expect(config.aliases.containsKey('test'), true);
      
      final testAlias = config.aliases['test']!;
      expect(testAlias.name, 'test');
      expect(testAlias.commands, hasLength(1));
      expect(testAlias.commands[0], 'fvm dart pub get');
    });

    test('parses single alias with multiple commands', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

alias:
  gen-icon:
    cmds:
      - fvm flutter pub get
      - fvm flutter pub run flutter_launcher_icons
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      
      expect(config.aliases, hasLength(1));
      expect(config.aliases.containsKey('gen-icon'), true);
      
      final genIconAlias = config.aliases['gen-icon']!;
      expect(genIconAlias.name, 'gen-icon');
      expect(genIconAlias.commands, hasLength(2));
      expect(genIconAlias.commands[0], 'fvm flutter pub get');
      expect(genIconAlias.commands[1], 'fvm flutter pub run flutter_launcher_icons');
    });

    test('parses multiple aliases', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

alias:
  gen-icon:
    cmds:
      - fvm flutter pub get
      - fvm flutter pub run flutter_launcher_icons
  brn:
    cmds:
      - fvm flutter pub get
      - fvm flutter packages pub run build_runner build --delete-conflicting-outputs
  test-all:
    cmds:
      - fvm flutter test
      - fvm dart analyze
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      
      expect(config.aliases, hasLength(3));
      expect(config.aliases.containsKey('gen-icon'), true);
      expect(config.aliases.containsKey('brn'), true);
      expect(config.aliases.containsKey('test-all'), true);
      
      final brnAlias = config.aliases['brn']!;
      expect(brnAlias.commands, hasLength(2));
      
      final testAllAlias = config.aliases['test-all']!;
      expect(testAllAlias.commands, hasLength(2));
      expect(testAllAlias.commands[0], 'fvm flutter test');
      expect(testAllAlias.commands[1], 'fvm dart analyze');
    });

    test('handles config without alias section', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

build:
  name: 1.0.0
  number: 1
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      expect(config.aliases, isEmpty);
    });

    test('ignores alias with no cmds field', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

alias:
  invalid:
    name: test
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      expect(config.aliases, isEmpty);
    });

    test('ignores alias with empty cmds list', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

alias:
  empty:
    cmds: []
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      expect(config.aliases, isEmpty);
    });

    test('handles complex command strings', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

alias:
  complex:
    cmds:
      - echo "Hello World"
      - fvm flutter build apk --release --target=lib/main.dart
      - echo 'Single quotes work too'
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      
      expect(config.aliases, hasLength(1));
      final complexAlias = config.aliases['complex']!;
      expect(complexAlias.commands, hasLength(3));
      expect(complexAlias.commands[0], 'echo "Hello World"');
      expect(complexAlias.commands[1], 'fvm flutter build apk --release --target=lib/main.dart');
      expect(complexAlias.commands[2], "echo 'Single quotes work too'");
    });

    test('preserves command order', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

alias:
  ordered:
    cmds:
      - echo "First"
      - echo "Second"
      - echo "Third"
      - echo "Fourth"
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      
      final orderedAlias = config.aliases['ordered']!;
      expect(orderedAlias.commands[0], 'echo "First"');
      expect(orderedAlias.commands[1], 'echo "Second"');
      expect(orderedAlias.commands[2], 'echo "Third"');
      expect(orderedAlias.commands[3], 'echo "Fourth"');
    });

    test('handles aliases with special characters in names', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
app:
  name: testapp

alias:
  gen-icon:
    cmds:
      - echo "test"
  build_runner:
    cmds:
      - echo "test"
  test-all-123:
    cmds:
      - echo "test"
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      
      expect(config.aliases, hasLength(3));
      expect(config.aliases.containsKey('gen-icon'), true);
      expect(config.aliases.containsKey('build_runner'), true);
      expect(config.aliases.containsKey('test-all-123'), true);
    });
  });
}
