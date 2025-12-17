import 'package:yaml/yaml.dart';

/// YAML parsing helper utilities for BuildConfig
class YamlHelpers {
  YamlHelpers._();

  /// Get string value from YamlMap with default
  static String getString(YamlMap? map, String key, String? defaultValue) {
    if (map == null) return defaultValue ?? '';
    final value = map[key];
    if (value == null) return defaultValue ?? '';
    return value.toString();
  }

  /// Get string value from YamlMap, returns null if not found
  static String? getStringOrNull(YamlMap? map, String key) {
    if (map == null) return null;
    final value = map[key];
    if (value == null || value.toString() == 'null') return null;
    return value.toString();
  }

  /// Get bool value from YamlMap with default
  static bool? getBool(YamlMap? map, String key, bool? defaultValue) {
    if (map == null) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  /// Get list of strings from YamlMap
  static List<String>? getList(YamlMap? map, String key) {
    if (map == null) return null;
    final value = map[key];
    if (value == null) return null;
    
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    
    return [value.toString()];
  }
}
