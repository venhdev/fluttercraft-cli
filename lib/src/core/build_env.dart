import 'dart:io';

import 'package:path/path.dart' as p;

/// Manages .buildenv and buildenv.base configuration files
class BuildEnv {
  final Map<String, String> _config = {};
  final String projectRoot;
  
  /// Path to .buildenv file
  String get buildEnvPath => p.join(projectRoot, 'scripts', '.buildenv');
  
  /// Path to buildenv.base file
  String get buildEnvBasePath => p.join(projectRoot, 'scripts', 'buildenv.base');

  BuildEnv({required this.projectRoot});

  /// Load configuration from buildenv.base and .buildenv
  Future<void> load() async {
    _config.clear();
    
    // Load defaults from buildenv.base first
    await _loadFile(buildEnvBasePath);
    
    // Override with .buildenv values
    await _loadFile(buildEnvPath);
  }

  /// Load a single env file
  Future<void> _loadFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    
    final lines = await file.readAsLines();
    for (final line in lines) {
      // Skip empty lines and comments
      if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
      
      // Parse KEY=VALUE
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        var value = parts.sublist(1).join('=').trim();
        
        // Remove inline comments
        final commentIndex = value.indexOf('#');
        if (commentIndex > 0) {
          value = value.substring(0, commentIndex).trim();
        }
        
        _config[key] = value;
      }
    }
  }

  /// Save configuration to .buildenv
  Future<void> save() async {
    final file = File(buildEnvPath);
    
    // Ensure directory exists
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    // Sort keys and build content
    final sortedKeys = _config.keys.toList()..sort();
    final buffer = StringBuffer();
    
    for (final key in sortedKeys) {
      buffer.writeln('$key=${_config[key]}');
    }
    
    await file.writeAsString(buffer.toString());
  }

  /// Get a configuration value
  String? get(String key) => _config[key];

  /// Get a configuration value with default
  String getOrDefault(String key, String defaultValue) {
    return _config[key] ?? defaultValue;
  }

  /// Set a configuration value
  void set(String key, String value) {
    _config[key] = value;
  }

  /// Check if .buildenv file exists
  Future<bool> exists() async {
    return File(buildEnvPath).exists();
  }

  /// Check if buildenv.base file exists
  Future<bool> baseExists() async {
    return File(buildEnvBasePath).exists();
  }

  /// Get all configuration as a map
  Map<String, String> toMap() => Map.from(_config);

  // ─────────────────────────────────────────────────────────────────
  // Typed Getters
  // ─────────────────────────────────────────────────────────────────

  String get appName => getOrDefault('APPNAME', 'app');
  String get buildName => getOrDefault('BUILD_NAME', '1.0.0');
  String get buildNumber => getOrDefault('BUILD_NUMBER', '1');
  String get buildType => getOrDefault('BUILD_TYPE', 'apk').toLowerCase();
  String get outputPath => getOrDefault('OUTPUT_PATH', 'dist');
  String get envPath => getOrDefault('ENV_PATH', '');
  String get targetDart => getOrDefault('TARGET_DART', 'lib/main.dart');
  String get flavor => getOrDefault('FLAVOR', '');
  
  bool get useFvm => getOrDefault('USE_FVM', 'false').toLowerCase() == 'true';
  String get flutterVersion => getOrDefault('FLUTTER_VERSION', '');
  
  bool get useShorebird => getOrDefault('USE_SHOREBIRD', 'false').toLowerCase() == 'true';
  String get shorebirdArtifact => getOrDefault('SHOREBIRD_ARTIFACT', '');
  bool get shorebirdAutoConfirm => getOrDefault('SHOREBIRD_AUTO_CONFIRM', 'true').toLowerCase() == 'true';
  
  bool get useDartDefine => getOrDefault('USE_DART_DEFINE', 'false').toLowerCase() == 'true';
  bool get needClean => getOrDefault('NEED_CLEAN', 'false').toLowerCase() == 'true';
  bool get needBuildRunner => getOrDefault('NEED_BUILD_RUNNER', 'false').toLowerCase() == 'true';

  // APK Converter settings
  String get bundletoolPath => getOrDefault('BUNDLETOOL_PATH', '');
  String get keyPropertiesPath => getOrDefault('KEY_PROPERTIES_PATH', 'android/key.properties');
  String get keystorePath => getOrDefault('KEYSTORE_PATH', '');

  // ─────────────────────────────────────────────────────────────────
  // Typed Setters
  // ─────────────────────────────────────────────────────────────────

  set appName(String value) => set('APPNAME', value);
  set buildName(String value) => set('BUILD_NAME', value);
  set buildNumber(String value) => set('BUILD_NUMBER', value);
  set buildType(String value) => set('BUILD_TYPE', value);
  set outputPath(String value) => set('OUTPUT_PATH', value);
  set useFvm(bool value) => set('USE_FVM', value.toString());
  set flutterVersion(String value) => set('FLUTTER_VERSION', value);
  set useShorebird(bool value) => set('USE_SHOREBIRD', value.toString());
  set flavor(String value) => set('FLAVOR', value);

  /// Get the full version string (e.g., "1.2.3+45")
  String get fullVersion => '$buildName+$buildNumber';

  /// Get the full app name with version (e.g., "myapp_1.2.3+45")
  String get fullAppName {
    var name = '${appName}_$fullVersion';
    if (useShorebird) {
      name += '.sb.base';
    }
    return name;
  }

  /// Get the absolute output directory path
  String get absoluteOutputPath {
    if (p.isAbsolute(outputPath)) {
      return outputPath;
    }
    return p.join(projectRoot, outputPath);
  }

  @override
  String toString() {
    final buffer = StringBuffer('BuildEnv:\n');
    for (final entry in _config.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    return buffer.toString();
  }
}
