import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'build_flags.dart';
import 'flavor_config.dart';
import 'helpers/alias_parser.dart';
import 'helpers/dart_define_parser.dart';
import 'helpers/environment_detectors.dart';
import 'helpers/yaml_helpers.dart';
import 'pubspec_parser.dart';

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
  final String? buildName;
  final int? buildNumber;
  final String platform;
  final String? flavor;
  final String targetDart;
  final List<String> args;

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
    this.buildName,
    this.buildNumber,
    required this.platform,
    this.flavor,
    required this.targetDart,
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
    this.args = const [],
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

  /// Load configuration from fluttercraft.yaml or embedded pubspec.yaml
  ///
  /// Priority chain:
  /// 1. fluttercraft.yaml (if exists) - highest priority
  /// 2. pubspec.yaml → fluttercraft: section (embedded)
  /// 3. Defaults from pubspec.yaml metadata
  ///
  /// Both separate and embedded configs MUST have 'fluttercraft:' root key.
  static Future<BuildConfig> load({
    String? configPath,
    PubspecInfo? pubspecInfo,
    String? projectRoot,
  }) async {
    final root = projectRoot ?? Directory.current.path;

    // Load pubspec info first (always needed)
    if (pubspecInfo == null) {
      final pubspecParser = PubspecParser(projectRoot: root);
      pubspecInfo = await pubspecParser.parse();
    }

    // ═══════════════════════════════════════════════════════════════
    // PRIORITY 1: Explicit configPath (for testing/override)
    // ═══════════════════════════════════════════════════════════════
    if (configPath != null) {
      return _loadFromFile(configPath, root, pubspecInfo);
    }

    // ═══════════════════════════════════════════════════════════════
    // PRIORITY 2: fluttercraft.yaml (separate file - HIGHEST PRIORITY)
    // ═══════════════════════════════════════════════════════════════
    final fluttercraftYamlPath = p.join(root, 'fluttercraft.yaml');
    if (await File(fluttercraftYamlPath).exists()) {
      return _loadFromFile(fluttercraftYamlPath, root, pubspecInfo);
    }

    // ═══════════════════════════════════════════════════════════════
    // PRIORITY 3: pubspec.yaml → fluttercraft: section (embedded)
    // ═══════════════════════════════════════════════════════════════
    final pubspecYamlPath = p.join(root, 'pubspec.yaml');
    if (await File(pubspecYamlPath).exists()) {
      final pubspecContent = await File(pubspecYamlPath).readAsString();
      final pubspecYaml = loadYaml(pubspecContent) as YamlMap?;

      if (pubspecYaml != null && pubspecYaml.containsKey('fluttercraft')) {
        final fluttercraftSection = pubspecYaml['fluttercraft'] as YamlMap?;
        if (fluttercraftSection != null) {
          // Parse embedded config directly
          return _parseNewFormat(
            fluttercraftSection,
            root,
            pubspecInfo: pubspecInfo,
          );
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // PRIORITY 4: No config found - use defaults from pubspec.yaml
    // DO NOT auto-generate any files - just return sensible defaults
    // ═══════════════════════════════════════════════════════════════
    return _createDefaultConfig(root, pubspecInfo);
  }

  /// Load config from file and enforce fluttercraft: root key
  static Future<BuildConfig> _loadFromFile(
    String path,
    String root,
    PubspecInfo? pubspecInfo,
  ) async {
    final content = await File(path).readAsString();
    final yaml = loadYaml(content) as YamlMap?;

    if (yaml == null) {
      throw ConfigParseException('Config file is empty or invalid: $path');
    }

    // Expect 'fluttercraft:' root key (required for all config files)
    if (!yaml.containsKey('fluttercraft')) {
      throw ConfigParseException(
        'Config file must have "fluttercraft:" as root key.\n'
        'Found keys: ${yaml.keys.join(", ")}\n\n'
        'Migration: Run "fluttercraft gen -f" to regenerate config,\n'
        'or manually add "fluttercraft:" root key and indent all content.',
      );
    }

    final fluttercraftSection = yaml['fluttercraft'] as YamlMap;
    return _parseNewFormat(fluttercraftSection, root, pubspecInfo: pubspecInfo);
  }

  /// Create default config when no config file exists
  static BuildConfig _createDefaultConfig(
    String root,
    PubspecInfo? pubspecInfo,
  ) {
    // Return minimal config with pubspec metadata + sensible defaults
    return BuildConfig(
      projectRoot: root,
      appName: pubspecInfo?.name ?? 'app',
      buildName: null, // Let Flutter read from pubspec.yaml
      buildNumber: null,
      platform: 'aab',
      targetDart: 'lib/main.dart',
      outputPath: '.fluttercraft/dist',
      flags: BuildFlags.defaults,
      useFvm: false,
      useShorebird: false,
      shorebirdNoConfirm: true,
      keystorePath: 'android/key.properties',
      args: [],
    );
  }

  /// Parse new YAML format (v0.1.1+)
  static BuildConfig _parseNewFormat(
    YamlMap yaml,
    String projectRoot, {
    PubspecInfo? pubspecInfo,
  }) {
    // ─────────────────────────────────────────────────────────────────
    // Parse build_defaults (base configuration)
    // ─────────────────────────────────────────────────────────────────
    final buildDefaults = yaml['build_defaults'] as YamlMap?;

    // ─────────────────────────────────────────────────────────────────
    // ─────────────────────────────────────────────────────────────────
    // Parse build section (may inherit from build_defaults via YAML anchor)
    // ─────────────────────────────────────────────────────────────────
    final build = yaml['build'] as YamlMap?;

    // ═══════════════════════════════════════════════════════════════
    // DO NOT READ APP METADATA - Let Flutter read from pubspec.yaml
    // ═══════════════════════════════════════════════════════════════
    final appName = pubspecInfo?.name ?? 'app';
    // Set to null so Flutter reads buildName/buildNumber directly from pubspec.yaml
    final String? buildName = null;
    final int? buildNumber = null;

    // ═══════════════════════════════════════════════════════════════
    // READ BUILD SETTINGS FROM YAML (NO APP METADATA)
    // ═══════════════════════════════════════════════════════════════
    var platform = YamlHelpers.getStringOrNull(build, 'platform') ??
        YamlHelpers.getStringOrNull(buildDefaults, 'platform') ??
        // Fallback to old 'type' key if platform not found
        YamlHelpers.getStringOrNull(build, 'type') ??
        YamlHelpers.getStringOrNull(buildDefaults, 'type') ??
        'aab';
        
    final flavor = YamlHelpers.getStringOrNull(build, 'flavor');
    final targetDart = YamlHelpers.getStringOrNull(build, 'target') ??
        YamlHelpers.getStringOrNull(buildDefaults, 'target') ??
        YamlHelpers.getStringOrNull(buildDefaults, 'target') ??
        'lib/main.dart';
    
    // no_review has been removed - use CLI flags (--review, -y) instead
    
    final args = YamlHelpers.getList(build, 'args') ?? 
        YamlHelpers.getList(buildDefaults, 'args') ?? 
        [];

    // ─────────────────────────────────────────────────────────────────
    // Parse flags from build or build_defaults
    // ─────────────────────────────────────────────────────────────────
    final buildFlags = build?['flags'] as YamlMap?;
    final defaultFlags = buildDefaults?['flags'] as YamlMap?;

    var shouldPromptDartDefine = YamlHelpers.getBool(buildFlags, 'should_prompt_dart_define', null) ??
        YamlHelpers.getBool(defaultFlags, 'should_prompt_dart_define', null) ??
        false;
    var shouldClean = YamlHelpers.getBool(buildFlags, 'should_clean', null) ??
        YamlHelpers.getBool(defaultFlags, 'should_clean', null) ??
        false;
    var shouldBuildRunner = YamlHelpers.getBool(buildFlags, 'should_build_runner', null) ??
        YamlHelpers.getBool(defaultFlags, 'should_build_runner', null) ??
        false;

    // ─────────────────────────────────────────────────────────────────
    // Parse dart_define
    // ─────────────────────────────────────────────────────────────────
    final globalDartDefine = DartDefineParser.parse(
      buildDefaults?['global_dart_define'] as YamlMap? ??
          build?['global_dart_define'] as YamlMap?,
    );
    var dartDefine = DartDefineParser.parse(
      build?['dart_define'] as YamlMap? ??
          buildDefaults?['dart_define'] as YamlMap?,
    );

    // ─────────────────────────────────────────────────────────────────
    // Parse dart_define_from_file
    // ─────────────────────────────────────────────────────────────────
    final globalDartDefineFromFile = YamlHelpers.getStringOrNull(buildDefaults, 'dart_define_from_file') ??
        YamlHelpers.getStringOrNull(build, 'dart_define_from_file');
    var dartDefineFromFile = YamlHelpers.getStringOrNull(build, 'dart_define_from_file') ??
        YamlHelpers.getStringOrNull(buildDefaults, 'dart_define_from_file');

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

      // ═══════════════════════════════════════════════════════════════
      // NO VERSION OVERRIDES - Flavors cannot override app metadata
      // ═══════════════════════════════════════════════════════════════

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

      // Append flavor-specific args
      if (flavorConfig.args != null) {
        args.addAll(flavorConfig.args!);
      }

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
    final useFvm = YamlHelpers.getBool(fvm, 'enabled', null) ?? false;
    var flutterVersion = YamlHelpers.getStringOrNull(fvm, 'version');
    if (useFvm && flutterVersion == null) {
      flutterVersion = EnvironmentDetectors.detectFvmVersion(projectRoot);
    }

    // Shorebird
    final shorebird = environments?['shorebird'] as YamlMap?;
    final useShorebird = YamlHelpers.getBool(shorebird, 'enabled', null) ?? false;
    var shorebirdAppId = YamlHelpers.getStringOrNull(shorebird, 'app_id');
    final shorebirdArtifact = YamlHelpers.getStringOrNull(shorebird, 'artifact');
    
    // no_confirm: Pass --no-confirm flag to Shorebird commands
    // (separate from build.no_review which controls fluttercraft's confirmation prompt)
    final shorebirdNoConfirm = YamlHelpers.getBool(shorebird, 'no_confirm', null) ?? true;
    if (useShorebird && shorebirdAppId == null) {
      shorebirdAppId = EnvironmentDetectors.detectShorebirdAppId(projectRoot);
    }

    // Bundletool
    final bundletool = environments?['bundletool'] as YamlMap?;
    final bundletoolPath = YamlHelpers.getStringOrNull(bundletool, 'path');
    final keystorePath = YamlHelpers.getString(
      bundletool,
      'keystore',
      'android/key.properties',
    );

    // Console settings
    final noColor = YamlHelpers.getBool(environments, 'no_color', null) ?? false;

    // ─────────────────────────────────────────────────────────────────
    // Parse paths section
    // ─────────────────────────────────────────────────────────────────
    final paths = yaml['paths'] as YamlMap?;
    final outputPath = YamlHelpers.getString(paths, 'output', '.fluttercraft/dist');

    // ─────────────────────────────────────────────────────────────────
    // Parse alias section
    // ─────────────────────────────────────────────────────────────────
    final aliasMap = yaml['alias'] as YamlMap?;
    final aliases = AliasParser.parse(aliasMap);

    return BuildConfig(
      projectRoot: projectRoot,
      appName: appName,
      buildName: buildName,
      buildNumber: buildNumber,
      platform: platform,
      flavor: flavor,
      targetDart: targetDart,
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
      args: args,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Computed properties
  // ─────────────────────────────────────────────────────────────────

  /// Full version string (e.g., "1.2.3+45") - null if not set (Flutter reads from pubspec.yaml)
  String? get fullVersion => buildName != null && buildNumber != null
      ? '$buildName+$buildNumber'
      : null;

  /// Full app name with version (e.g., "myapp_1.2.3+45")
  String get fullAppName {
    final version = fullVersion ?? 'unknown';
    var name = '${appName}_$version';
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
  outputPath: $outputPath
  flags: $flags
  dartDefine: $finalDartDefine
  args: $args
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
