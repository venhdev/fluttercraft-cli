import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Parsed pubspec.yaml data
class PubspecInfo {
  final String name;
  final String version;
  final String buildName;
  final String buildNumber;

  PubspecInfo({
    required this.name,
    required this.version,
    required this.buildName,
    required this.buildNumber,
  });

  /// Full version string (e.g., "1.2.3+45")
  String get fullVersion => '$buildName+$buildNumber';

  @override
  String toString() => 'PubspecInfo(name: $name, version: $fullVersion)';
}

/// Parser for pubspec.yaml files
class PubspecParser {
  final String projectRoot;

  PubspecParser({required this.projectRoot});

  /// Path to pubspec.yaml
  String get pubspecPath => p.join(projectRoot, 'pubspec.yaml');

  /// Check if pubspec.yaml exists
  Future<bool> exists() async {
    return File(pubspecPath).exists();
  }

  /// Parse pubspec.yaml and extract name and version
  Future<PubspecInfo?> parse() async {
    final file = File(pubspecPath);
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content) as YamlMap;

      // Extract name
      final name = yaml['name']?.toString() ?? 'app';

      // Extract version (e.g., "1.2.3+45" or "1.2.3")
      final versionString = yaml['version']?.toString() ?? '1.0.0+1';

      // Parse version string
      final parsed = _parseVersion(versionString);

      return PubspecInfo(
        name: name,
        version: versionString,
        buildName: parsed.buildName,
        buildNumber: parsed.buildNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse version string into build name and build number
  ({String buildName, String buildNumber}) _parseVersion(String version) {
    // Handle "1.2.3+45" format
    if (version.contains('+')) {
      final parts = version.split('+');
      return (buildName: parts[0], buildNumber: parts[1]);
    }

    // Handle "1.2.3" format (no build number)
    return (buildName: version, buildNumber: '1');
  }

  /// Update version in pubspec.yaml
  Future<bool> updateVersion(String newVersion) async {
    final file = File(pubspecPath);
    if (!await file.exists()) {
      return false;
    }

    try {
      var content = await file.readAsString();

      // Replace version line using regex
      final versionRegex = RegExp(r'^version:\s*.+$', multiLine: true);
      if (versionRegex.hasMatch(content)) {
        content = content.replaceFirst(versionRegex, 'version: $newVersion');
        await file.writeAsString(content);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
