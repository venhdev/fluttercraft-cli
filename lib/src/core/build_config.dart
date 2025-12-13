import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

import 'pubspec_parser.dart';

/// Configuration loaded from buildcraft.yaml
class BuildConfig {
  final String projectRoot;
  
  // App info
  final String appName;
  
  // Core build settings
  final String buildName;
  final int buildNumber;
  final String buildType;
  final String? flavor;
  final String targetDart;
  
  // Paths
  final String outputPath;
  final String? envPath;
  
  // Build flags
  final bool useDartDefine;
  final bool needClean;
  final bool needBuildRunner;
  
  // FVM integration
  final bool useFvm;
  final String? flutterVersion;
  
  // Shorebird integration
  final bool useShorebird;
  final String? shorebirdArtifact;
  final bool shorebirdAutoConfirm;
  
  // Bundletool
  final String? bundletoolPath;
  final String keystorePath;

  BuildConfig({
    required this.projectRoot,
    required this.appName,
    required this.buildName,
    required this.buildNumber,
    required this.buildType,
    this.flavor,
    required this.targetDart,
    required this.outputPath,
    this.envPath,
    required this.useDartDefine,
    required this.needClean,
    required this.needBuildRunner,
    required this.useFvm,
    this.flutterVersion,
    required this.useShorebird,
    this.shorebirdArtifact,
    required this.shorebirdAutoConfirm,
    this.bundletoolPath,
    required this.keystorePath,
  });

  /// Load configuration from flutterbuild.yaml
  /// 
  /// If [pubspecInfo] is provided and flutterbuild.yaml doesn't exist,
  /// creates a default config using pubspec data.
  static Future<BuildConfig> load({
    String? configPath,
    PubspecInfo? pubspecInfo,
  }) async {
    final projectRoot = Directory.current.path;
    final path = configPath ?? p.join(projectRoot, 'flutterbuild.yaml');
    
    final file = File(path);
    if (!await file.exists()) {
      // Return default config with pubspec fallback
      return BuildConfig(
        projectRoot: projectRoot,
        appName: pubspecInfo?.name ?? 'app',
        buildName: pubspecInfo?.buildName ?? '1.0.0',
        buildNumber: pubspecInfo != null 
            ? int.tryParse(pubspecInfo.buildNumber) ?? 1 
            : 1,
        buildType: 'aab',
        targetDart: 'lib/main.dart',
        outputPath: 'dist',
        useDartDefine: false,
        needClean: false,
        needBuildRunner: false,
        useFvm: false,
        useShorebird: false,
        shorebirdAutoConfirm: true,
        keystorePath: 'android/key.properties',
      );
    }
    
    final content = await file.readAsString();
    final yaml = loadYaml(content) as YamlMap?;
    
    if (yaml == null) {
      throw ConfigParseException('flutterbuild.yaml is empty or invalid');
    }
    
    return _parseYaml(yaml, projectRoot);
  }

  /// Parse YAML map into BuildConfig
  static BuildConfig _parseYaml(YamlMap yaml, String projectRoot) {
    // App section
    final app = yaml['app'] as YamlMap?;
    final appName = _getString(app, 'name', 'app');
    
    // Build section
    final build = yaml['build'] as YamlMap?;
    final buildName = _getString(build, 'name', '1.0.0');
    final buildNumber = _getInt(build, 'number', 1);
    final buildType = _getString(build, 'type', 'aab');
    final flavor = _getStringOrNull(build, 'flavor');
    final targetDart = _getString(build, 'target', 'lib/main.dart');
    
    // Paths section
    final paths = yaml['paths'] as YamlMap?;
    final outputPath = _getString(paths, 'output', 'dist');
    final envPath = _getStringOrNull(paths, 'env');
    
    // Flags section
    final flags = yaml['flags'] as YamlMap?;
    final useDartDefine = _getBool(flags, 'use_dart_define', false);
    final needClean = _getBool(flags, 'need_clean', false);
    final needBuildRunner = _getBool(flags, 'need_build_runner', false);
    
    // FVM section
    final fvm = yaml['fvm'] as YamlMap?;
    final useFvm = _getBool(fvm, 'enabled', false);
    final flutterVersion = _getStringOrNull(fvm, 'version');
    
    // Shorebird section
    final shorebird = yaml['shorebird'] as YamlMap?;
    final useShorebird = _getBool(shorebird, 'enabled', false);
    final shorebirdArtifact = _getStringOrNull(shorebird, 'artifact');
    final shorebirdAutoConfirm = _getBool(shorebird, 'auto_confirm', true);
    
    // Bundletool section
    final bundletool = yaml['bundletool'] as YamlMap?;
    final bundletoolPath = _getStringOrNull(bundletool, 'path');
    final keystorePath = _getString(bundletool, 'keystore', 'android/key.properties');
    
    return BuildConfig(
      projectRoot: projectRoot,
      appName: appName,
      buildName: buildName,
      buildNumber: buildNumber,
      buildType: buildType,
      flavor: flavor,
      targetDart: targetDart,
      outputPath: outputPath,
      envPath: envPath,
      useDartDefine: useDartDefine,
      needClean: needClean,
      needBuildRunner: needBuildRunner,
      useFvm: useFvm,
      flutterVersion: flutterVersion,
      useShorebird: useShorebird,
      shorebirdArtifact: shorebirdArtifact,
      shorebirdAutoConfirm: shorebirdAutoConfirm,
      bundletoolPath: bundletoolPath,
      keystorePath: keystorePath,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // YAML parsing helpers
  // ─────────────────────────────────────────────────────────────────

  static String _getString(YamlMap? map, String key, String defaultValue) {
    if (map == null) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  static String? _getStringOrNull(YamlMap? map, String key) {
    if (map == null) return null;
    final value = map[key];
    if (value == null || value.toString() == 'null') return null;
    return value.toString();
  }

  static int _getInt(YamlMap? map, String key, int defaultValue) {
    if (map == null) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static bool _getBool(YamlMap? map, String key, bool defaultValue) {
    if (map == null) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  // ─────────────────────────────────────────────────────────────────
  // Computed properties
  // ─────────────────────────────────────────────────────────────────

  /// Full version string (e.g., "1.2.3+45")
  String get fullVersion => '$buildName+$buildNumber';

  /// Full app name with version (e.g., "myapp_1.2.3+45")
  String get fullAppName {
    var name = '${appName}_$fullVersion';
    if (useShorebird) {
      name += '.sb.base';
    }
    return name;
  }

  /// Absolute output directory path
  String get absoluteOutputPath {
    if (p.isAbsolute(outputPath)) {
      return outputPath;
    }
    return p.join(projectRoot, outputPath);
  }

  @override
  String toString() {
    return '''BuildConfig:
  appName: $appName
  version: $fullVersion
  buildType: $buildType
  flavor: $flavor
  targetDart: $targetDart
  outputPath: $outputPath
  useFvm: $useFvm
  useShorebird: $useShorebird''';
  }
}

/// Exception thrown when flutterbuild.yaml is not found
class ConfigNotFoundException implements Exception {
  final String message;
  ConfigNotFoundException(this.message);
  
  @override
  String toString() => message;
}

/// Exception thrown when flutterbuild.yaml cannot be parsed
class ConfigParseException implements Exception {
  final String message;
  ConfigParseException(this.message);
  
  @override
  String toString() => message;
}
