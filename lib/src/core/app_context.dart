import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'build_config.dart';
import 'pubspec_parser.dart';

/// Shared runtime context that holds configuration loaded once at startup
///
/// This class encapsulates:
/// - BuildConfig (fluttercraft.yaml configuration)
/// - PubspecInfo (pubspec.yaml data)
/// - Project paths and environment info
///
/// Load once with [AppContext.load()] and pass to commands/flows.
class AppContext {
  final BuildConfig config;
  final PubspecInfo? pubspecInfo;
  final String projectRoot;
  final DateTime loadedAt;
  final bool hasConfigFile;
  final String configSource;

  AppContext._({
    required this.config,
    this.pubspecInfo,
    required this.projectRoot,
    required this.loadedAt,
    required this.hasConfigFile,
    required this.configSource,
  });

  /// Load context from current directory
  static Future<AppContext> load({String? projectRoot}) async {
    final root = projectRoot ?? Directory.current.path;

    // Load pubspec first
    final pubspecParser = PubspecParser(projectRoot: root);
    final pubspecInfo = await pubspecParser.parse();

    // Determine config source for tracking
    final fluttercraftYamlPath = p.join(root, 'fluttercraft.yaml');
    final hasFluttercraftYaml = await File(fluttercraftYamlPath).exists();

    String configSource;
    if (hasFluttercraftYaml) {
      configSource = 'fluttercraft.yaml';
    } else {
      // Check if pubspec has embedded config
      final pubspecYamlPath = p.join(root, 'pubspec.yaml');
      if (await File(pubspecYamlPath).exists()) {
        final content = await File(pubspecYamlPath).readAsString();
        try {
          final yaml = loadYaml(content) as YamlMap?;
          if (yaml?.containsKey('fluttercraft') ?? false) {
            configSource = 'pubspec.yaml (fluttercraft: section)';
          } else {
            configSource = 'defaults (no config found)';
          }
        } catch (e) {
          configSource = 'defaults (no config found)';
        }
      } else {
        configSource = 'defaults (no pubspec.yaml)';
      }
    }

    // Load config (new loader handles priority automatically)
    final config = await BuildConfig.load(
      pubspecInfo: pubspecInfo,
      projectRoot: root,
    );

    return AppContext._(
      config: config,
      pubspecInfo: pubspecInfo,
      projectRoot: root,
      loadedAt: DateTime.now(),
      hasConfigFile: hasFluttercraftYaml,
      configSource: configSource,
    );
  }

  /// Reload configuration
  Future<AppContext> reload() async {
    return AppContext.load(projectRoot: projectRoot);
  }

  // ─────────────────────────────────────────────────────────────────
  // Convenience getters (delegate to BuildConfig/PubspecInfo)
  // ─────────────────────────────────────────────────────────────────

  /// App name from config or pubspec
  String get appName =>
      config.appName.isNotEmpty // appName only used for output paths - keep simple fallback
          ? config.appName
          : (pubspecInfo?.name ?? 'app');

  /// Current version from pubspec or config (null if not set - Flutter reads from pubspec.yaml)
  String? get version => pubspecInfo?.fullVersion ?? config.fullVersion;

  /// Platform (apk, aab, ipa, app)
  String get platform => config.platform;

  /// Flavor (dev, staging, prod)
  String? get flavor => config.flavor;

  /// Output path for artifacts
  String get outputPath => config.absoluteOutputPath;

  /// Whether to use FVM
  bool get useFvm => config.useFvm;

  /// Whether to use Shorebird
  bool get useShorebird => config.useShorebird;

  // ─────────────────────────────────────────────────────────────────
  // Verbose info getters (for info -v command)
  // ─────────────────────────────────────────────────────────────────

  /// FVM Flutter version (from .fvmrc or config)
  String? get flutterVersion => config.flutterVersion;

  /// Shorebird app ID (from shorebird.yaml or config)
  String? get shorebirdAppId => config.shorebirdAppId;

  /// Shorebird artifact type
  String? get shorebirdArtifact => config.shorebirdArtifact;

  /// Shorebird no confirm flag
  bool get shorebirdNoConfirm => config.shorebirdNoConfirm;

  /// Build flags
  bool get shouldClean => config.shouldClean;
  bool get shouldBuildRunner => config.shouldBuildRunner;
  bool get shouldPromptDartDefine => config.shouldPromptDartDefine;

  /// Merged dart defines (global + flavor-specific)
  Map<String, dynamic> get finalDartDefine => config.finalDartDefine;

  /// Dart define from file path (if specified)
  String? get dartDefineFromFile => config.finalDartDefineFromFile;

  /// Target dart file
  String get targetDart => config.targetDart;

  /// Bundletool path
  String? get bundletoolPath => config.bundletoolPath;

  /// Keystore path
  String get keystorePath => config.keystorePath;

  /// Available flavors
  Map<String, dynamic> get flavors => config.flavors;

  /// Command aliases
  Map<String, dynamic> get aliases => config.aliases;

  /// No color setting
  bool get noColor => config.noColor;

  /// Check if pubspec exists
  bool get hasPubspec => pubspecInfo != null;

  /// Get time since context was loaded
  Duration get age => DateTime.now().difference(loadedAt);

  /// Check if context is stale (older than 5 minutes)
  bool get isStale => age.inMinutes > 5;

  @override
  String toString() {
    return 'AppContext(\n'
        '  appName: $appName,\n'
        '  version: ${version ?? "(from pubspec.yaml)"},\n'
        '  platform: $platform,\n'
        '  flavor: $flavor,\n'
        '  useFvm: $useFvm,\n'
        '  useShorebird: $useShorebird,\n'
        '  projectRoot: $projectRoot,\n'
        '  loadedAt: $loadedAt\n'
        ')';
  }
}
