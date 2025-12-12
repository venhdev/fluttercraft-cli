import 'dart:io';

import 'build_env.dart';
import 'pubspec_parser.dart';

/// Shared runtime context that holds configuration loaded once at startup
/// 
/// This class encapsulates:
/// - BuildEnv (.buildenv configuration)
/// - PubspecInfo (pubspec.yaml data)
/// - Project paths and environment info
/// 
/// Load once with [AppContext.load()] and pass to commands/flows.
class AppContext {
  final BuildEnv buildEnv;
  final PubspecInfo? pubspecInfo;
  final String projectRoot;
  final DateTime loadedAt;
  
  AppContext._({
    required this.buildEnv,
    this.pubspecInfo,
    required this.projectRoot,
    required this.loadedAt,
  });
  
  /// Load context from current directory
  static Future<AppContext> load({String? projectRoot}) async {
    final root = projectRoot ?? Directory.current.path;
    
    // Load buildenv
    final buildEnv = BuildEnv(projectRoot: root);
    await buildEnv.load();
    
    // Load pubspec
    final pubspecParser = PubspecParser(projectRoot: root);
    final pubspecInfo = await pubspecParser.parse();
    
    return AppContext._(
      buildEnv: buildEnv,
      pubspecInfo: pubspecInfo,
      projectRoot: root,
      loadedAt: DateTime.now(),
    );
  }
  
  /// Reload configuration (e.g., after gen-env)
  Future<AppContext> reload() async {
    return AppContext.load(projectRoot: projectRoot);
  }
  
  // ─────────────────────────────────────────────────────────────────
  // Convenience getters (delegate to BuildEnv/PubspecInfo)
  // ─────────────────────────────────────────────────────────────────
  
  /// App name from buildenv or pubspec
  String get appName => buildEnv.appName.isNotEmpty 
      ? buildEnv.appName 
      : (pubspecInfo?.name ?? 'app');
  
  /// Current version from pubspec
  String get version => pubspecInfo?.fullVersion ?? buildEnv.fullVersion;
  
  /// Build type (apk, aab, ipa)
  String get buildType => buildEnv.buildType;
  
  /// Flavor (dev, staging, prod)
  String get flavor => buildEnv.flavor;
  
  /// Output path for artifacts
  String get outputPath => buildEnv.absoluteOutputPath;
  
  /// Whether to use FVM
  bool get useFvm => buildEnv.useFvm;
  
  /// Whether to use Shorebird
  bool get useShorebird => buildEnv.useShorebird;
  
  /// Check if buildenv file exists
  Future<bool> get hasBuildEnv => buildEnv.exists();
  
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
        '  projectRoot: $projectRoot,\n'
        '  loadedAt: $loadedAt\n'
        ')';
  }
}
