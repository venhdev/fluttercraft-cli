import 'dart:io';
import 'package:path/path.dart' as p;

import '../utils/console.dart';

/// Handles backing up the configuration file
class ConfigBackup {
  final String projectRoot;
  final Console console;

  ConfigBackup({
    String? projectRoot,
    Console? console,
  })  : projectRoot = projectRoot ?? Directory.current.path,
        console = console ?? Console();

  /// Backup directory path: .fluttercraft/backups
  String get backupDir => p.join(projectRoot, '.fluttercraft', 'backups');

  /// Create a backup of fluttercraft.yaml
  ///
  /// [reason] is appended to the filename (e.g. 'gen', 'reload', 'quit')
  /// Returns the path to the backup file if successful, null otherwise.
  Future<String?> backup({required String reason}) async {
    final configPath = p.join(projectRoot, 'fluttercraft.yaml');
    final file = File(configPath);

    if (!await file.exists()) {
      return null;
    }

    try {
      final dir = Directory(backupDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        await _createGitignore();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = p.join(
        backupDir,
        'fluttercraft.yaml.$timestamp.$reason.bak',
      );

      await file.copy(backupPath);
      
      // Cleanup old backups (keep last 10)
      await _cleanupOldBackups();

      return backupPath;
    } catch (e) {
      console.error('Failed to backup config: $e');
      return null;
    }
  }

  /// Create .gitignore in backups directory to avoid committing them
  Future<void> _createGitignore() async {
    final gitignorePath = p.join(projectRoot, '.fluttercraft', '.gitignore');
    final file = File(gitignorePath);
    
    // Check if we need to add backups/ to ignore
    // Note: The user requested "add more .gitignore in .fluttercraft/ to ignore backups/"
    // Ideally .fluttercraft/ is already ignored by root .gitignore, but this adds an extra layer
    // or allows users to commit .fluttercraft/ but NOT backups.

    const content = '''
# Ignore backups directory
backups/
''';

    if (!await file.exists()) {
      await file.writeAsString(content);
    } else {
        // If it exists, ensure backups/ is in it
        final currentContent = await file.readAsString();
        if (!currentContent.contains('backups/')) {
            await file.writeAsString('$currentContent\n$content');
        }
    }
  }

  /// Keep only the last 10 backups to avoid disk space usage
  Future<void> _cleanupOldBackups() async {
    try {
      final dir = Directory(backupDir);
      final files = await dir.list().toList();
      
      final backups = files
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('fluttercraft.yaml.'))
          .toList();

      if (backups.length <= 10) return;

      // Sort by modification time (oldest first)
      backups.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      // Delete oldest, keeping last 10
      final toDelete = backups.take(backups.length - 10);
      for (final file in toDelete) {
        await file.delete();
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
