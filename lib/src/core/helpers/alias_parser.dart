import 'package:yaml/yaml.dart';

import '../build_config.dart';

/// Parser for command alias configuration
class AliasParser {
  AliasParser._();

  /// Parse aliases from YAML configuration
  static Map<String, CommandAlias> parse(YamlMap? aliasMap) {
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
}
