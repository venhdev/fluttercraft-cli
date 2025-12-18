import 'dart:io';

import 'package:fluttercraft/src/core/config_backup.dart';
import 'package:fluttercraft/src/utils/console.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ConfigBackup', () {
    late Directory tempDir;
    late String projectRoot;
    late String configPath;
    late ConfigBackup backupService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('config_backup_test');
      projectRoot = tempDir.path;
      configPath = p.join(projectRoot, 'fluttercraft.yaml');
      backupService = ConfigBackup(projectRoot: projectRoot, console: Console());
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('backup() returns null if config does not exist', () async {
      final result = await backupService.backup(reason: 'test');
      expect(result, isNull);
    });

    test('backup() creates backup file and .gitignore', () async {
      // Create dummy config
      await File(configPath).writeAsString('name: test_app');

      final result = await backupService.backup(reason: 'gen');

      expect(result, isNotNull);
      final backupFile = File(result!);
      expect(await backupFile.exists(), isTrue);
      expect(p.basename(result), contains('.gen.bak'));
      expect(await backupFile.readAsString(), 'name: test_app');

      // Check .gitignore
      final gitignorePath = p.join(projectRoot, '.fluttercraft', '.gitignore');
      final gitignoreFile = File(gitignorePath);
      expect(await gitignoreFile.exists(), isTrue);
      expect(await gitignoreFile.readAsString(), contains('backups/'));
    });

    test('backup() cleans up old backups', () async {
      await File(configPath).writeAsString('name: test_app');

      // Create 15 dummy backups
      final backupDir = Directory(p.join(projectRoot, '.fluttercraft', 'backups'));
      await backupDir.create(recursive: true);

      for (var i = 0; i < 15; i++) {
        // Use slight delay to ensure different timestamps if needed, 
        // but explicit naming is easier for setup
        final path = p.join(
          backupDir.path, 
          'fluttercraft.yaml.${1000 + i}.test.bak',
        );
        await File(path).writeAsString('backup $i');
      }

      // Perform a new backup
      await backupService.backup(reason: 'cleanup');

      final files = await backupDir.list().toList();
      final backups = files
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('fluttercraft.yaml.'))
          .toList();

      // Should have 10 files max (logic says "keep last 10")
      // wait, logic is: read all, if length > 10, delete oldest until 10 remain.
      // My implementation: 
      // if (backups.length <= 10) return;
      // take(backups.length - 10) -> delete.
      // So checks if > 10, deletes surplus.
      // We added 15, then did 1 real backup -> total 16.
      // Should delete 6, leaving 10.
      expect(backups.length, 10);
    });

    test('gitignore is updated if existing without backups/', () async {
      await File(configPath).writeAsString('name: test_app');
      final gitignorePath = p.join(projectRoot, '.fluttercraft', '.gitignore');
      final gitignoreFile = File(gitignorePath);
      
      await gitignoreFile.create(recursive: true);
      await gitignoreFile.writeAsString('# existing ignore\nfoo/\n');

      await backupService.backup(reason: 'test');

      final content = await gitignoreFile.readAsString();
      expect(content, contains('foo/'));
      expect(content, contains('backups/'));
    });
  });
}
