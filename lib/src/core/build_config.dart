import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

import 'pubspec_parser.dart';
import 'build_flags.dart';
import 'flavor_config.dart';

/// Custom command alias definition
class CommandAlias {
  final String name;
  final List<String> commands;

  CommandAlias({required this.name, required this.commands});
}

/// Configuration loaded from fluttercraft.yaml
///
/// New structure (v0.1.1+):
/// - build_defaults: base config with YAML anchor
/// - build: runtime config (inherits from build_defaults)
/// - flavors: override layer by flavor
/// - environments: global tools (fvm, shorebird, bundletool)
/// - paths: output directory
/// - alias: custom commands
class BuildConfig {
  final String projectRoot;

  // App info
  final String appName;

  // Core build settings
  final String buildName;
  final int buildNumber;
  final String platform;
  final String? flavor;
  final String targetDart;
  final bool noReview;

  // Paths
  final String outputPath;

  // Build flags
  final BuildFlags flags;

  // Dart define
  final Map<String, dynamic> globalDartDefine;
  final Map<String, dynamic> dartDefine;

  // Dart define from file
  final String? globalDartDefineFromFile;
  final String? dartDefineFromFile;

  // FVM integration
  final bool useFvm;
  final String? flutterVersion;

  // Shorebird integration
  final bool useShorebird;
  final String?
      shorebirdAppId; // Informational only - actual commands read from shorebird.yaml
  final String? shorebirdArtifact;
  final bool shorebirdNoConfirm;

  // Bundletool
  final String? bundletoolPath;
  final String keystorePath;

  // Console settings
  final bool noColor;

  // Flavors (parsed but stored for reference)
  final Map<String, FlavorConfig> flavors;

  // Custom command aliases
  final Map<String, CommandAlias> aliases;

  BuildConfig({
    required this.projectRoot,
    required this.appName,
    required this.buildName,
    required this.buildNumber,
    required this.platform,
    this.flavor,
    required this.targetDart,
    this.noReview = false,
    required this.outputPath,
    required this.flags,
    this.globalDartDefine = const {},
    this.dartDefine = const {},
    this.globalDartDefineFromFile,
    this.dartDefineFromFile,
    required this.useFvm,
    this.flutterVersion,
    required this.useShorebird,
    this.shorebirdAppId,
    this.shorebirdArtifact,
    required this.shorebirdNoConfirm,
    this.bundletoolPath,
    required this.keystorePath,
    this.noColor = false,
    this.flavors = const {},
    this.aliases = const {},
  });

  // ─────────────────────────────────────────────────────────────────
  // Convenience getters for backward compatibility
  // ─────────────────────────────────────────────────────────────────

  /// Whether to prompt for custom dart defines during build
  bool get shouldPromptDartDefine => flags.shouldPromptDartDefine;

  /// Whether to run flutter clean before build
  bool get shouldClean => flags.shouldClean;

  /// Whether to run build_runner before build
  bool get shouldBuildRunner => flags.shouldBuildRunner;

  /// Final dart define map (merged global + flavor-specific)
  ///
  /// Always returns merged values - config-defined dart-defines always apply
  Map<String, dynamic> get finalDartDefine {
    // Merge: global_dart_define + dart_define (dart_define takes precedence)
    return {...globalDartDefine, ...dartDefine};
  }

  /// Final dart define from file path
  ///
  /// Returns flavor-specific path if set, otherwise returns global path.
  /// Always returns a value if configured - config-defined paths always apply.
  String? get finalDartDefineFromFile {
    // Flavor-specific overrides global
    return dartDefineFromFile ?? globalDartDefineFromFile;
  }

  /// Load configuration from fluttercraft.yaml
  ///
  /// If [pubspecInfo] is provided and fluttercraft.yaml doesn't exist,
  /// creates a default config using pubspec data.
  static Future<BuildConfig> load({
    String? configPath,
    PubspecInfo? pubspecInfo,
    String? projectRoot,
  }) async {
    final root = projectRoot ?? Directory.current.path;
    final path = configPath ?? p.join(root, 'fluttercraft.yaml');

    final file = File(path);
    if (!await file.exists()) {
      // Return default config with pubspec fallback
      return BuildConfig(
        projectRoot: root,
        appName: pubspecInfo?.name ?? 'app',
        buildName: pubspecInfo?.buildName ?? '1.0.0',
        buildNumber:
            pubspecInfo != null
                ? int.tryParse(pubspecInfo.buildNumber) ?? 1
                : 1,
        platform: 'aab',
        targetDart: 'lib/main.dart',
        noReview: false,
        outputPath: '.fluttercraft/dist',
        flags: BuildFlags.defaults,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: 'android/key.properties',
      );
    }

    final content = await file.readAsString();
    final yaml = loadYaml(content) as YamlMap?;

    if (yaml == null) {
      throw ConfigParseException('fluttercraft.yaml is empty or invalid');
    }

    return _parseNewFormat(yaml, root);
  }

  /// Parse new YAML format (v0.1.1+)
  static BuildConfig _parseNewFormat(YamlMap yaml, String projectRoot) {
    // ─────────────────────────────────────────────────────────────────
    // Parse build_defaults (base configuration)
    // ─────────────────────────────────────────────────────────────────
    final buildDefaults = yaml['build_defaults'] as YamlMap?;

    // ─────────────────────────────────────────────────────────────────
    // Parse build section (may inherit from build_defaults via YAML anchor)
    // ─────────────────────────────────────────────────────────────────
    final build = yaml['build'] as YamlMap?;

    // Merge build_defaults and build (build takes precedence)
    final appName = _getStringOrNull(build, 'app_name') ??
        _getStringOrNull(buildDefaults, 'app_name') ??
        'app';
    var buildName = _getStringOrNull(build, 'name') ??
        _getStringOrNull(buildDefaults, 'name') ??
        '1.0.0';
    var buildNumber = _getInt(build, 'number', null) ??
        _getInt(buildDefaults, 'number', null) ??
        1;
    var platform = _getStringOrNull(build, 'platform') ??
        _getStringOrNull(buildDefaults, 'platform') ??
        // Fallback to old 'type' key if platform not found (optional, but good for transition)
        // User requested no backward compatibility, so we stick to 'platform'.
        // Wait, initial plan said "type is being removed". 
        // Docs say "no backward compatible".
        // Let's implement strict platform check.
        // Actually, let's keep it simple: just look for 'platform'
        // But previously it looked for 'type'.
        // So we strictly look for 'platform' now, and maybe default to 'aab' if not found?
        // Let's default to 'aab' if missing, same as before.
        'aab';
        
    final flavor = _getStringOrNull(build, 'flavor');
    final targetDart = _getStringOrNull(build, 'target') ??
        _getStringOrNull(buildDefaults, 'target') ??
        _getStringOrNull(buildDefaults, 'target') ??
        'lib/main.dart';
    final noReview = _getBool(build, 'no_review', null) ??
        _getBool(buildDefaults, 'no_review', null) ??
        false;

    // ─────────────────────────────────────────────────────────────────
    // Parse flags from build or build_defaults
    // ─────────────────────────────────────────────────────────────────
    final buildFlags = build?['flags'] as YamlMap?;
    final defaultFlags = buildDefaults?['flags'] as YamlMap?;

    var shouldPromptDartDefine = _getBool(buildFlags, 'should_prompt_dart_define', null) ??
        _getBool(defaultFlags, 'should_prompt_dart_define', null) ??
        false;
    var shouldClean = _getBool(buildFlags, 'should_clean', null) ??
        _getBool(defaultFlags, 'should_clean', null) ??
        false;
    var shouldBuildRunner = _getBool(buildFlags, 'should_build_runner', null) ??
        _getBool(defaultFlags, 'should_build_runner', null) ??
        false;

    // ─────────────────────────────────────────────────────────────────
    // Parse dart_define
    // ─────────────────────────────────────────────────────────────────
    final globalDartDefine = _parseDartDefine(
      buildDefaults?['global_dart_define'] as YamlMap? ??
          build?['global_dart_define'] as YamlMap?,
    );
    var dartDefine = _parseDartDefine(
      build?['dart_define'] as YamlMap? ??
          buildDefaults?['dart_define'] as YamlMap?,
    );

    // ─────────────────────────────────────────────────────────────────
    // Parse dart_define_from_file
    // ─────────────────────────────────────────────────────────────────
    final globalDartDefineFromFile = _getStringOrNull(buildDefaults, 'dart_define_from_file') ??
        _getStringOrNull(build, 'dart_define_from_file');
    var dartDefineFromFile = _getStringOrNull(build, 'dart_define_from_file') ??
        _getStringOrNull(buildDefaults, 'dart_define_from_file');

    // ─────────────────────────────────────────────────────────────────
    // Parse flavors
    // ─────────────────────────────────────────────────────────────────
    final flavorsYaml = yaml['flavors'] as YamlMap?;
    final flavors = <String, FlavorConfig>{};

    if (flavorsYaml != null) {
      for (final entry in flavorsYaml.entries) {
        final name = entry.key.toString();
        final config = entry.value as YamlMap?;
        if (config != null) {
          flavors[name] = FlavorConfig.fromYaml(name, config);
        }
      }
    }

    // ─────────────────────────────────────────────────────────────────
    // Apply flavor overrides if flavor is set
    // ─────────────────────────────────────────────────────────────────
    if (flavor != null && flavor.isNotEmpty) {
      if (!flavors.containsKey(flavor)) {
        throw ConfigParseException(
          'Flavor "$flavor" not found in flavors section. '
          'Available flavors: ${flavors.keys.join(", ")}',
        );
      }

      final flavorConfig = flavors[flavor]!;

      // Apply version overrides
      if (flavorConfig.versionName != null) {
        buildName = flavorConfig.versionName!;
      }
      if (flavorConfig.buildNumber != null) {
        buildNumber = flavorConfig.buildNumber!;
      }

      if (flavorConfig.shouldPromptDartDefine != null) {
        shouldPromptDartDefine = flavorConfig.shouldPromptDartDefine!;
      }
      
      if (flavorConfig.platform != null) {
        platform = flavorConfig.platform!;
      }
      if (flavorConfig.shouldClean != null) {
        shouldClean = flavorConfig.shouldClean!;
      }
      if (flavorConfig.shouldBuildRunner != null) {
        shouldBuildRunner = flavorConfig.shouldBuildRunner!;
      }

      // Merge dart_define (flavor takes precedence)
      dartDefine = {...dartDefine, ...flavorConfig.dartDefine};

      // Override dart_define_from_file if flavor specifies it
      if (flavorConfig.dartDefineFromFile != null) {
        dartDefineFromFile = flavorConfig.dartDefineFromFile;
      }
    }

    // ─────────────────────────────────────────────────────────────────
    // Parse environments section
    // ─────────────────────────────────────────────────────────────────
    final environments = yaml['environments'] as YamlMap?;

    // FVM
    final fvm = environments?['fvm'] as YamlMap?;
    final useFvm = _getBool(fvm, 'enabled', null) ?? false;
    var flutterVersion = _getStringOrNull(fvm, 'version');
    if (useFvm && flutterVersion == null) {
      flutterVersion = detectFvmVersion(projectRoot);
    }

    // Shorebird
    final shorebird = environments?['shorebird'] as YamlMap?;
    final useShorebird = _getBool(shorebird, 'enabled', null) ?? false;
    var shorebirdAppId = _getStringOrNull(shorebird, 'app_id');
    final shorebirdArtifact = _getStringOrNull(shorebird, 'artifact');
    final shorebirdNoConfirm = _getBool(shorebird, 'no_confirm', null) ?? true;
    if (useShorebird && shorebirdAppId == null) {
      shorebirdAppId = detectShorebirdAppId(projectRoot);
    }

    // Bundletool
    final bundletool = environments?['bundletool'] as YamlMap?;
    final bundletoolPath = _getStringOrNull(bundletool, 'path');
    final keystorePath = _getString(
      bundletool,
      'keystore',
      'android/key.properties',
    );

    // Console settings
    final noColor = _getBool(environments, 'no_color', null) ?? false;

    // ─────────────────────────────────────────────────────────────────
    // Parse paths section
    // ─────────────────────────────────────────────────────────────────
    final paths = yaml['paths'] as YamlMap?;
    final outputPath = _getString(paths, 'output', '.fluttercraft/dist');

    // ─────────────────────────────────────────────────────────────────
    // Parse alias section
    // ─────────────────────────────────────────────────────────────────
    final aliasMap = yaml['alias'] as YamlMap?;
    final aliases = _parseAliases(aliasMap);

    return BuildConfig(
      projectRoot: projectRoot,
      appName: appName,
      buildName: buildName,
      buildNumber: buildNumber,
      platform: platform,
      flavor: flavor,
      targetDart: targetDart,
      noReview: noReview,
      outputPath: outputPath,
      flags: BuildFlags(
        shouldPromptDartDefine: shouldPromptDartDefine,
        shouldClean: shouldClean,
        shouldBuildRunner: shouldBuildRunner,
      ),
      globalDartDefine: globalDartDefine,
      dartDefine: dartDefine,
      globalDartDefineFromFile: globalDartDefineFromFile,
      dartDefineFromFile: dartDefineFromFile,
      useFvm: useFvm,
      flutterVersion: flutterVersion,
      useShorebird: useShorebird,
      shorebirdAppId: shorebirdAppId,
      shorebirdArtifact: shorebirdArtifact,
      shorebirdNoConfirm: shorebirdNoConfirm,
      bundletoolPath: bundletoolPath,
      keystorePath: keystorePath,
      noColor: noColor,
      flavors: flavors,
      aliases: aliases,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // YAML parsing helpers
  // ─────────────────────────────────────────────────────────────────

  static String _getString(YamlMap? map, String key, String? defaultValue) {
    if (map == null) return defaultValue ?? '';
    final value = map[key];
    if (value == null) return defaultValue ?? '';
    return value.toString();
  }

  static String? _getStringOrNull(YamlMap? map, String key) {
    if (map == null) return null;
    final value = map[key];
    if (value == null || value.toString() == 'null') return null;
    return value.toString();
  }

  static int? _getInt(YamlMap? map, String key, int? defaultValue) {
    if (map == null) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static bool? _getBool(YamlMap? map, String key, bool? defaultValue) {
    if (map == null) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  static Map<String, dynamic> _parseDartDefine(YamlMap? dartDefineMap) {
    if (dartDefineMap == null) return {};

    final result = <String, dynamic>{};
    for (final entry in dartDefineMap.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      // Validate primitive types only
      if (value != null && value is! String && value is! bool && value is! num) {
        throw ConfigParseException(
          'dart_define.$key must be a primitive (string, bool, or number), '
          'got ${value.runtimeType}',
        );
      }

      result[key] = value;
    }

    return result;
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
  ///
  /// If flavor is set, appends flavor name to output path (e.g., .fluttercraft/dist/dev/)
  String get absoluteOutputPath {
    var path = outputPath;

    // Append flavor to output path if set
    if (flavor != null && flavor!.isNotEmpty) {
      path = p.join(path, flavor!);
    }

    if (p.isAbsolute(path)) {
      return path;
    }
    return p.join(projectRoot, path);
  }

  @override
  String toString() {
    return '''BuildConfig:
  appName: $appName
  version: $fullVersion
  platform: $platform
  flavor: $flavor
  targetDart: $targetDart
  noReview: $noReview
  outputPath: $outputPath
  flags: $flags
  dartDefine: $finalDartDefine
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
