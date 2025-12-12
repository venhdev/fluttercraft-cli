import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/console.dart';
import '../utils/process_runner.dart';

/// Result of APK conversion
class ConversionResult {
  final bool success;
  final String? outputPath;
  final String? error;

  ConversionResult({
    required this.success,
    this.outputPath,
    this.error,
  });
}

/// Keystore configuration parsed from key.properties
class KeystoreConfig {
  final String storeFile;
  final String storePassword;
  final String keyAlias;
  final String keyPassword;

  KeystoreConfig({
    required this.storeFile,
    required this.storePassword,
    required this.keyAlias,
    required this.keyPassword,
  });

  bool get isValid =>
      storeFile.isNotEmpty &&
      storePassword.isNotEmpty &&
      keyAlias.isNotEmpty &&
      keyPassword.isNotEmpty;
}

/// Converts AAB files to universal APK using bundletool
class ApkConverter {
  final ProcessRunner _processRunner;
  final Console _console;
  final String projectRoot;

  ApkConverter({
    required this.projectRoot,
    ProcessRunner? processRunner,
    Console? console,
  })  : _processRunner = processRunner ?? ProcessRunner(),
        _console = console ?? Console();

  /// Default paths to search for bundletool
  static final List<String> defaultBundletoolPaths = [
    r'%USERPROFILE%\tools\bundletool-all-*.jar',
    r'%USERPROFILE%\Downloads\bundletool-all-*.jar',
    r'D:\Dev\tools\bundletool\bundletool-all-*.jar',
    r'C:\tools\bundletool-all-*.jar',
    r'D:\tools\bundletool-all-*.jar',
  ];

  /// Find bundletool.jar
  Future<String?> findBundletool({String? customPath}) async {
    // Check custom path first
    if (customPath != null && customPath.isNotEmpty) {
      if (await File(customPath).exists()) {
        return customPath;
      }
    }

    // Search default paths
    for (var pattern in defaultBundletoolPaths) {
      // Expand environment variables
      pattern = pattern.replaceAll(
        r'%USERPROFILE%',
        Platform.environment['USERPROFILE'] ?? '',
      );

      // Handle glob pattern
      final dir = Directory(p.dirname(pattern));
      if (!await dir.exists()) continue;

      final globPattern = p.basename(pattern);
      await for (final entity in dir.list()) {
        if (entity is File && _matchesGlob(p.basename(entity.path), globPattern)) {
          return entity.path;
        }
      }
    }

    return null;
  }

  /// Simple glob matching for bundletool-all-*.jar pattern
  bool _matchesGlob(String filename, String pattern) {
    if (!pattern.contains('*')) {
      return filename == pattern;
    }
    
    final prefix = pattern.split('*').first;
    final suffix = pattern.split('*').last;
    
    return filename.startsWith(prefix) && filename.endsWith(suffix);
  }

  /// Parse key.properties file
  Future<KeystoreConfig?> parseKeyProperties(String keyPropertiesPath) async {
    final file = File(keyPropertiesPath);
    if (!await file.exists()) {
      return null;
    }

    final props = <String, String>{};
    final lines = await file.readAsLines();

    for (final line in lines) {
      if (line.trim().isEmpty || line.trim().startsWith('#')) continue;

      final match = RegExp(r'^([^#]+?)=(.*)$').firstMatch(line);
      if (match != null) {
        props[match.group(1)!.trim()] = match.group(2)!.trim();
      }
    }

    return KeystoreConfig(
      storeFile: props['storeFile'] ?? '',
      storePassword: props['storePassword'] ?? '',
      keyAlias: props['keyAlias'] ?? '',
      keyPassword: props['keyPassword'] ?? '',
    );
  }

  /// Resolve keystore path (handle relative paths)
  Future<String?> resolveKeystorePath(
    String storeFile,
    String keyPropertiesPath,
  ) async {
    // If absolute path, check directly
    if (p.isAbsolute(storeFile)) {
      if (await File(storeFile).exists()) {
        return storeFile;
      }
      return null;
    }

    // Try relative to key.properties directory
    final keyPropsDir = p.dirname(keyPropertiesPath);
    final relativePath = p.join(keyPropsDir, storeFile);
    if (await File(relativePath).exists()) {
      return relativePath;
    }

    // Try common Flutter keystore locations
    final searchDirs = [
      keyPropsDir,
      p.join(keyPropsDir, 'android'),
      p.join(keyPropsDir, 'android', 'app'),
      p.join(projectRoot, 'android'),
      p.join(projectRoot, 'android', 'app'),
    ];

    final keystoreName = p.basename(storeFile);
    for (final dir in searchDirs) {
      final path = p.join(dir, keystoreName);
      if (await File(path).exists()) {
        return path;
      }

      // Also search for any .jks file
      final dirEntity = Directory(dir);
      if (await dirEntity.exists()) {
        await for (final entity in dirEntity.list()) {
          if (entity is File && entity.path.endsWith('.jks')) {
            return entity.path;
          }
        }
      }
    }

    return null;
  }

  /// Convert AAB to universal APK
  Future<ConversionResult> convert({
    required String aabPath,
    required String outputPath,
    required String bundletoolPath,
    required String keystorePath,
    required KeystoreConfig keystoreConfig,
  }) async {
    _console.section('Converting AAB to Universal APK');

    // Validate inputs
    if (!await File(aabPath).exists()) {
      return ConversionResult(success: false, error: 'AAB file not found: $aabPath');
    }

    if (!await File(bundletoolPath).exists()) {
      return ConversionResult(success: false, error: 'Bundletool not found: $bundletoolPath');
    }

    if (!await File(keystorePath).exists()) {
      return ConversionResult(success: false, error: 'Keystore not found: $keystorePath');
    }

    // Create temp paths
    final tempDir = Directory.systemTemp;
    final apksTemp = p.join(tempDir.path, 'temp_bundle.apks');
    final extractTemp = p.join(tempDir.path, 'aab_extract_temp');

    // Generate output filename
    final aabName = p.basenameWithoutExtension(aabPath);
    final finalApkPath = p.join(outputPath, '$aabName-universal.apk');

    // Ensure output directory exists
    final outputDir = Directory(outputPath);
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    _console.info('Running bundletool...');

    // Run bundletool
    final result = await _processRunner.run(
      'java',
      [
        '-jar',
        bundletoolPath,
        'build-apks',
        '--bundle=$aabPath',
        '--output=$apksTemp',
        '--mode=universal',
        '--ks=$keystorePath',
        '--ks-key-alias=${keystoreConfig.keyAlias}',
        '--ks-pass=pass:${keystoreConfig.storePassword}',
        '--key-pass=pass:${keystoreConfig.keyPassword}',
        '--overwrite',
      ],
      workingDirectory: projectRoot,
    );

    if (!result.success) {
      return ConversionResult(success: false, error: 'Bundletool failed: ${result.stderr}');
    }

    // Extract APK from APKS file
    _console.info('Extracting universal APK...');

    // Clean up extract temp if it exists
    final extractDir = Directory(extractTemp);
    if (await extractDir.exists()) {
      await extractDir.delete(recursive: true);
    }
    await extractDir.create(recursive: true);

    // Extract APKS (it's a ZIP file)
    final extractResult = await _processRunner.run(
      'powershell',
      [
        '-Command',
        'Expand-Archive',
        '-Path',
        apksTemp,
        '-DestinationPath',
        extractTemp,
        '-Force',
      ],
      workingDirectory: projectRoot,
      streamOutput: false,
    );

    if (!extractResult.success) {
      return ConversionResult(success: false, error: 'Failed to extract APKS');
    }

    // Move universal.apk to final location
    final universalApk = File(p.join(extractTemp, 'universal.apk'));
    if (await universalApk.exists()) {
      await universalApk.copy(finalApkPath);
      _console.success('Created: $finalApkPath');

      // Cleanup temp files
      await File(apksTemp).delete();
      await extractDir.delete(recursive: true);

      return ConversionResult(success: true, outputPath: finalApkPath);
    }

    return ConversionResult(success: false, error: 'universal.apk not found in extracted files');
  }

  /// Find AAB files in a directory
  Future<List<String>> findAabFiles(String searchPath) async {
    final aabFiles = <String>[];
    final dir = Directory(searchPath);

    if (!await dir.exists()) return aabFiles;

    await for (final entity in dir.list(recursive: false)) {
      if (entity is File && entity.path.endsWith('.aab')) {
        aabFiles.add(entity.path);
      }
    }

    // Sort by modification time (newest first)
    aabFiles.sort((a, b) {
      final aTime = File(a).lastModifiedSync();
      final bTime = File(b).lastModifiedSync();
      return bTime.compareTo(aTime);
    });

    return aabFiles;
  }
}
