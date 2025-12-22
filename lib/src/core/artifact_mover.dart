import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/console.dart';
import 'build_config.dart';

/// Result of artifact moving operation
class ArtifactResult {
  final bool success;
  final String? outputPath;
  final String? error;

  ArtifactResult({required this.success, this.outputPath, this.error});
}

/// Handles locating and copying build artifacts to output directory
class ArtifactMover {
  final Console _console;
  final String projectRoot;

  ArtifactMover({required this.projectRoot, Console? console})
    : _console = console ?? Console();

  /// Move build artifacts to output directory
  /// Move artifacts based on platform
  Future<ArtifactResult> moveArtifacts(BuildConfig config) async {
    _console.info('Moving artifacts for platform: ${config.platform}...');

    // Ensure output directory exists
    final outputDir = config.absoluteOutputPath;
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    switch (config.platform) {
      case 'apk':
        return _moveApk(config);
      case 'aab':
        return _moveAab(config);
      case 'ipa':
        return _moveIpa(config);
      case 'app':
      case 'macos':
        return _moveMacOsApp(config);
      default:
        throw Exception('Unsupported platform: ${config.platform}');
    }
  }

  /// Clean existing artifacts before build to prevent stale results
  Future<void> cleanArtifacts(BuildConfig config) async {
    final extensions = ['.apk', '.aab', '.ipa', '.app'];
    final outputDir = config.absoluteOutputPath;
    final fullAppName = config.fullAppName;

    for (final ext in extensions) {
      final file = File(p.join(outputDir, '$fullAppName$ext'));
      if (await file.exists()) {
        try {
          await file.delete(recursive: true);
          _console.info('Cleaned stale artifact: ${p.basename(file.path)}');
        } catch (e) {
          _console.warning('Failed to clean stale artifact: $e');
        }
      }
    }
  }

  /// Move APK artifact
  Future<ArtifactResult> _moveApk(BuildConfig config) async {
    final outputDir = config.absoluteOutputPath;
    final fullAppName = config.fullAppName;
    final srcPath = p.join(
      projectRoot,
      'build',
      'app',
      'outputs',
      'flutter-apk',
    );
    final flavor = config.flavor ?? '';

    // Possible APK file patterns
    final patterns = <String>[
      'app-release.apk',
      '$flavor-release.apk',
      'app-$flavor-release.apk',
    ];

    for (final pattern in patterns) {
      final srcFile = File(p.join(srcPath, pattern));
      if (await srcFile.exists()) {
        final destPath = p.join(outputDir, '$fullAppName.apk');
        await srcFile.copy(destPath);
        _console.success('Copied APK → $fullAppName.apk');
        return ArtifactResult(success: true, outputPath: destPath);
      }
    }

    return ArtifactResult(
      success: false,
      error: 'APK file not found in $srcPath',
    );
  }

  /// Move AAB artifact
  Future<ArtifactResult> _moveAab(BuildConfig config) async {
    final outputDir = config.absoluteOutputPath;
    final fullAppName = config.fullAppName;
    final srcPath = p.join(projectRoot, 'build', 'app', 'outputs', 'bundle');
    final flavor = config.flavor ?? '';

    // Possible AAB file patterns
    final patterns = <String>[
      p.join('release', 'app-release.aab'),
      p.join('${flavor}Release', 'app-$flavor-release.aab'),
    ];

    for (final pattern in patterns) {
      final srcFile = File(p.join(srcPath, pattern));
      if (await srcFile.exists()) {
        final destPath = p.join(outputDir, '$fullAppName.aab');
        await srcFile.copy(destPath);
        _console.success('Copied AAB → $fullAppName.aab');
        return ArtifactResult(success: true, outputPath: destPath);
      }
    }

    return ArtifactResult(
      success: false,
      error: 'AAB file not found in $srcPath',
    );
  }

  /// Move IPA artifact
  Future<ArtifactResult> _moveIpa(BuildConfig config) async {
    final outputDir = config.absoluteOutputPath;
    final fullAppName = config.fullAppName;
    final srcPath = p.join(projectRoot, 'build', 'ios', 'ipa');

    final dir = Directory(srcPath);
    if (!await dir.exists()) {
      return ArtifactResult(
        success: false,
        error: 'IPA directory not found: $srcPath',
      );
    }

    // Find first .ipa file
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.ipa')) {
        final destPath = p.join(outputDir, '$fullAppName.ipa');
        await entity.copy(destPath);
        _console.success('Copied IPA → $fullAppName.ipa');
        return ArtifactResult(success: true, outputPath: destPath);
      }
    }

    return ArtifactResult(
      success: false,
      error: 'IPA file not found in $srcPath',
    );
  }

  /// Move macOS app artifact
  Future<ArtifactResult> _moveMacOsApp(BuildConfig config) async {
    final outputDir = config.absoluteOutputPath;
    final fullAppName = config.fullAppName;
    final appName = config.appName;
    final srcPath = p.join(
      projectRoot,
      'build',
      'macos',
      'Build',
      'Products',
      'Release',
      '$appName.app',
    );

    final srcDir = Directory(srcPath);
    if (!await srcDir.exists()) {
      return ArtifactResult(
        success: false,
        error: 'macOS app not found: $srcPath',
      );
    }

    final destPath = p.join(outputDir, '$fullAppName.app');
    await _copyDirectory(srcDir, Directory(destPath));
    _console.success('Copied macOS app → $fullAppName.app');
    return ArtifactResult(success: true, outputPath: destPath);
  }

  /// Recursively copy a directory
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (final entity in source.list(recursive: false)) {
      final destPath = p.join(destination.path, p.basename(entity.path));

      if (entity is File) {
        await entity.copy(destPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(destPath));
      }
    }
  }

  /// Find AAB files in output directory (for converter)
  Future<List<String>> findAabFiles(String searchPath) async {
    final aabFiles = <String>[];
    final dir = Directory(searchPath);

    if (!await dir.exists()) return aabFiles;

    await for (final entity in dir.list(recursive: false)) {
      if (entity is File && entity.path.endsWith('.aab')) {
        aabFiles.add(entity.path);
      }
    }

    return aabFiles;
  }
}
