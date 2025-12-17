import 'package:yaml/yaml.dart';

import '../build_config.dart';

/// Parser for dart_define configuration
class DartDefineParser {
  DartDefineParser._();

  /// Parse dart_define map from YAML, validating primitive types only
  static Map<String, dynamic> parse(YamlMap? dartDefineMap) {
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
}
