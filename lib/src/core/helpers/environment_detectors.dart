import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Detectors for FVM and Shorebird configurations
class EnvironmentDetectors {
  EnvironmentDetectors._();

  /// Detect FVM version from .fvmrc file
  ///
  /// Reads the .fvmrc JSON file in the project root and extracts the Flutter version.
  /// Also checks .fvm/version file as a fallback.
  /// Returns null if neither file exists or cannot be parsed.
  static String? detectFvmVersion(String projectRoot) {
    try {
      final fvmrcPath = p.join(projectRoot, '.fvmrc');
      final fvmrcFile = File(fvmrcPath);

      if (!fvmrcFile.existsSync()) {
        return null;
      }

      final content = fvmrcFile.readAsStringSync();
      final json = loadYaml(content) as YamlMap?;

      if (json == null) {
        return null;
      }

      final version = json['flutter'];
      return version?.toString();
    } catch (e) {
      // If we can't read or parse .fvmrc, return null
      return null;
    }
  }

  /// Detect Shorebird app_id from shorebird.yaml file
  ///
  /// Reads the shorebird.yaml file in the project root and extracts the app_id.
  /// Returns null if the file doesn't exist or cannot be parsed.
  ///
  /// Note: This is informational only. Actual Shorebird commands read from shorebird.yaml directly.
  static String? detectShorebirdAppId(String projectRoot) {
    try {
      final shorebirdPath = p.join(projectRoot, 'shorebird.yaml');
      final shorebirdFile = File(shorebirdPath);

      if (!shorebirdFile.existsSync()) {
        return null;
      }

      final content = shorebirdFile.readAsStringSync();
      final yaml = loadYaml(content) as YamlMap?;

      if (yaml == null) {
        return null;
      }

      final appId = yaml['app_id'];
      return appId?.toString();
    } catch (e) {
      // If we can't read or parse shorebird.yaml, return null
      return null;
    }
  }
}
