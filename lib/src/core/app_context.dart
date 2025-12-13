import 'dart:io';

import 'build_config.dart';
import 'pubspec_parser.dart';

/// Shared runtime context that holds configuration loaded once at startup
/// 
/// This class encapsulates:
/// - BuildConfig (flutterbuild.yaml configuration)
/// - PubspecInfo (pubspec.yaml data)
/// - Project paths and environment info
/// 
/// Load once with [AppContext.load()] and pass to commands/flows.
class AppContext {
  final BuildConfig config;
  final PubspecInfo? pubspecInfo;
  final String projectRoot;
  final DateTime loadedAt;
  
  AppContext._({
    required this.config,
    this.pubspecInfo,
    required this.projectRoot,
    required this.loadedAt,
  });
  
  /// Load context from current directory
  static Future<AppContext> load({String? projectRoot}) async {
    final root = projectRoot ?? Directory.current.path;
    
    // Load config from flutterbuild.yaml
    BuildConfig config;
    try {
      config = await BuildConfig.load();
    } on ConfigNotFoundException {
      // Create default config if not found
      config = BuildConfig(
        projectRoot: root,
        appName: 'app',
        buildName: '1.0.0',
        buildNumber: 1,
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
    
    // Load pubspec
    final pubspecParser = PubspecParser(projectRoot: root);
    final pubspecInfo = await pubspecParser.parse();
    
    return AppContext._(
      config: config,
      pubspecInfo: pubspecInfo,
      projectRoot: root,
      loadedAt: DateTime.now(),
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
  String get appName => config.appName.isNotEmpty 
      ? config.appName 
      : (pubspecInfo?.name ?? 'app');
  
  /// Current version from pubspec or config
  String get version => pubspecInfo?.fullVersion ?? config.fullVersion;
  
  /// Build type (apk, aab, ipa, app)
  String get buildType => config.buildType;
  
  /// Flavor (dev, staging, prod)
  String? get flavor => config.flavor;
  
  /// Output path for artifacts
  String get outputPath => config.absoluteOutputPath;
  
  /// Whether to use FVM
  bool get useFvm => config.useFvm;
  
  /// Whether to use Shorebird
  bool get useShorebird => config.useShorebird;
  
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
        '  version: $version,\n'
        '  buildType: $buildType,\n'
        '  flavor: $flavor,\n'
        '  useFvm: $useFvm,\n'
        '  useShorebird: $useShorebird,\n'
        '  projectRoot: $projectRoot,\n'
        '  loadedAt: $loadedAt\n'
        ')';
  }
}
