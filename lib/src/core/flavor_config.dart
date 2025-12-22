import 'package:yaml/yaml.dart';

/// Flavor-specific build configuration overrides
///
/// Flavors allow overriding specific build settings without
/// duplicating the entire configuration. Only non-null values
/// are applied as overrides.
class FlavorConfig {
  /// Flavor name (e.g., 'dev', 'staging', 'prod')
  final String name;

  /// Platform override (e.g., 'apk', 'ipa')
  final String? platform;

  /// Flavor-specific dart defines (merged with global_dart_define)
  final Map<String, dynamic> dartDefine;

  /// Flavor-specific dart define from file (overrides global)
  final String? dartDefineFromFile;

  /// Flag overrides (null means use default)
  final bool? shouldPromptDartDefine;
  final bool? shouldClean;
  final bool? shouldBuildRunner;
  
  /// Extra arguments override/append
  final List<String>? args;

  const FlavorConfig({
    required this.name,
    this.platform,
    this.dartDefine = const {},
    this.dartDefineFromFile,
    this.shouldPromptDartDefine,
    this.shouldClean,
    this.shouldBuildRunner,
    this.args,
  });

  /// Parse flavor configuration from YAML
  static FlavorConfig fromYaml(String name, YamlMap yaml) {
    // Parse platform override
    final platform = yaml['platform']?.toString();

    // Parse dart_define
    final dartDefineMap = yaml['dart_define'] as YamlMap?;
    final dartDefine = <String, dynamic>{};
    if (dartDefineMap != null) {
      for (final entry in dartDefineMap.entries) {
        final key = entry.key.toString();
        final value = entry.value;

        // Validate primitive types only
        if (value is! String && value is! bool && value is! num) {
          throw FormatException(
            'dart_define.$key must be a primitive (string, bool, or number), '
            'got ${value.runtimeType}',
          );
        }

        dartDefine[key] = value;
      }
    }

    // Parse flags
    final flags = yaml['flags'] as YamlMap?;
    final shouldPromptDartDefine = _getBoolOrNull(flags, 'should_prompt_dart_define');
    final shouldClean = _getBoolOrNull(flags, 'should_clean');
    final shouldBuildRunner = _getBoolOrNull(flags, 'should_build_runner');

    // Parse dart_define_from_file
    final dartDefineFromFile = yaml['dart_define_from_file']?.toString();

    // Parse args
    List<String>? args;
    final argsValue = yaml['args'];
    if (argsValue != null) {
      if (argsValue is List) {
        args = argsValue.map((e) => e.toString()).toList();
      } else {
        args = [argsValue.toString()];
      }
    }

    return FlavorConfig(
      name: name,
      platform: platform,
      dartDefine: dartDefine,
      dartDefineFromFile: dartDefineFromFile,
      shouldPromptDartDefine: shouldPromptDartDefine,
      shouldClean: shouldClean,
      shouldBuildRunner: shouldBuildRunner,
      args: args,
    );
  }

  static bool? _getBoolOrNull(YamlMap? map, String key) {
    if (map == null) return null;
    final value = map[key];
    if (value == null) return null;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  @override
  String toString() {
    return 'FlavorConfig(name: $name, platform: $platform, '
        'dartDefine: $dartDefine)';
  }
}
