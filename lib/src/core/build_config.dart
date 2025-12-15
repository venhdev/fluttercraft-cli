import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

import 'pubspec_parser.dart';

/// Custom command alias definition
class CommandAlias {
  final String name;
  final List<String> commands;
  
  CommandAlias({
    required this.name,
    required this.commands,
  });
}

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
  final String? shorebirdAppId;  // Informational only - actual commands read from shorebird.yaml
  final String? shorebirdArtifact;
  final bool shorebirdAutoConfirm;
  
  // Bundletool
  final String? bundletoolPath;
  final String keystorePath;
  
  // Custom command aliases
  final Map<String, CommandAlias> aliases;

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
    this.shorebirdAppId,
    this.shorebirdArtifact,
    required this.shorebirdAutoConfirm,
    this.bundletoolPath,
    required this.keystorePath,
    this.aliases = const {},
  });

  /// Load configuration from fluttercraft.yaml
  /// 
  /// If [pubspecInfo] is provided and fluttercraft.yaml doesn't exist,
  /// creates a default config using pubspec data.
  static Future<BuildConfig> load({
    String? configPath,
    PubspecInfo? pubspecInfo,
  }) async {
    final projectRoot = Directory.current.path;
    final path = configPath ?? p.join(projectRoot, 'fluttercraft.yaml');
    
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
      throw ConfigParseException('fluttercraft.yaml is empty or invalid');
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
    var flutterVersion = _getStringOrNull(fvm, 'version');
    
    // Auto-detect FVM version from .fvmrc if enabled but version is null
    if (useFvm && flutterVersion == null) {
      flutterVersion = detectFvmVersion(projectRoot);
    }
    
    // Shorebird section
    final shorebird = yaml['shorebird'] as YamlMap?;
    final useShorebird = _getBool(shorebird, 'enabled', false);
    var shorebirdAppId = _getStringOrNull(shorebird, 'app_id');
    final shorebirdArtifact = _getStringOrNull(shorebird, 'artifact');
    final shorebirdAutoConfirm = _getBool(shorebird, 'auto_confirm', true);
    
    // Auto-detect Shorebird app_id from shorebird.yaml if enabled but app_id is null
    if (useShorebird && shorebirdAppId == null) {
      shorebirdAppId = detectShorebirdAppId(projectRoot);
    }
    
    // Bundletool section
    final bundletool = yaml['bundletool'] as YamlMap?;
    final bundletoolPath = _getStringOrNull(bundletool, 'path');
    final keystorePath = _getString(bundletool, 'keystore', 'android/key.properties');
    
    // Alias section
    final aliasMap = yaml['alias'] as YamlMap?;
    final aliases = _parseAliases(aliasMap);
    
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
      shorebirdAppId: shorebirdAppId,
      shorebirdArtifact: shorebirdArtifact,
      shorebirdAutoConfirm: shorebirdAutoConfirm,
      bundletoolPath: bundletoolPath,
      keystorePath: keystorePath,
      aliases: aliases,
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

  static Map<String, CommandAlias> _parseAliases(YamlMap? aliasMap) {
    if (aliasMap == null) return {};
    
    final result = <String, CommandAlias>{};
    
    for (final entry in aliasMap.entries) {
      final name = entry.key.toString();
      final config = entry.value as YamlMap?;
      
      if (config == null) continue;
      
      final cmds = config['cmds'];
      if (cmds == null) continue;
      
      final commands = <String>[];
      if (cmds is YamlList) {
        for (final cmd in cmds) {
          commands.add(cmd.toString());
        }
      }
      
      if (commands.isNotEmpty) {
        result[name] = CommandAlias(name: name, commands: commands);
      }
    }
    
    return result;
  }

  /// Detect FVM version from .fvmrc file
  /// 
  /// Reads the .fvmrc JSON file in the project root and extracts the Flutter version.
  /// Also checks .fvm/version file as a fallback.
  /// Returns null if neither file exists or cannot be parsed.
  static String? detectFvmVersion(String projectRoot) {
    try {
      final fvmrcPath = p.join(projectRoot, '.fvmrc');
      final fvmrcFile = File(fvmrcPath);
      
      if (!fvmrcFile.existsSync()) {
        return null;
      }
      
      final content = fvmrcFile.readAsStringSync();
      final json = loadYaml(content) as YamlMap?;
      
      if (json == null) {
        return null;
      }
      
      final version = json['flutter'];
      return version?.toString();
    } catch (e) {
      // If we can't read or parse .fvmrc, return null
      return null;
    }
  }

  /// Detect Shorebird app_id from shorebird.yaml file
  /// 
  /// Reads the shorebird.yaml file in the project root and extracts the app_id.
  /// Returns null if the file doesn't exist or cannot be parsed.
  /// 
  /// Note: This is informational only. Actual Shorebird commands read from shorebird.yaml directly.
  static String? detectShorebirdAppId(String projectRoot) {
    try {
      final shorebirdPath = p.join(projectRoot, 'shorebird.yaml');
      final shorebirdFile = File(shorebirdPath);
      
      if (!shorebirdFile.existsSync()) {
        return null;
      }
      
      final content = shorebirdFile.readAsStringSync();
      final yaml = loadYaml(content) as YamlMap?;
      
      if (yaml == null) {
        return null;
      }
      
      final appId = yaml['app_id'];
      return appId?.toString();
    } catch (e) {
      // If we can't read or parse shorebird.yaml, return null
      return null;
    }
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

/// Exception thrown when fluttercraft.yaml is not found
class ConfigNotFoundException implements Exception {
  final String message;
  ConfigNotFoundException(this.message);
  
  @override
  String toString() => message;
}

/// Exception thrown when fluttercraft.yaml cannot be parsed
class ConfigParseException implements Exception {
  final String message;
  ConfigParseException(this.message);
  
  @override
  String toString() => message;
}

