/// Semantic version representation
class SemanticVersion {
  int major;
  int minor;
  int patch;
  int buildNumber;

  SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.buildNumber = 1,
  });

  /// Parse version string (e.g., "1.2.3" or "1.2.3+45")
  factory SemanticVersion.parse(String version) {
    var versionPart = version;
    var buildNumber = 1;

    // Handle build number suffix
    if (version.contains('+')) {
      final parts = version.split('+');
      versionPart = parts[0];
      buildNumber = int.tryParse(parts[1]) ?? 1;
    }

    // Parse major.minor.patch
    final parts = versionPart.split('.');
    return SemanticVersion(
      major: int.tryParse(parts.isNotEmpty ? parts[0] : '1') ?? 1,
      minor: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      patch: int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
      buildNumber: buildNumber,
    );
  }

  /// Get version string without build number (e.g., "1.2.3")
  String get buildName => '$major.$minor.$patch';

  /// Get full version string with build number (e.g., "1.2.3+45")
  String get fullVersion => '$buildName+$buildNumber';

  /// Increment major version (resets minor and patch)
  void incrementMajor() {
    major++;
    minor = 0;
    patch = 0;
  }

  /// Increment minor version (resets patch)
  void incrementMinor() {
    minor++;
    patch = 0;
  }

  /// Increment patch version
  void incrementPatch() {
    patch++;
  }

  /// Increment build number
  void incrementBuildNumber() {
    buildNumber++;
  }

  /// Create a copy of this version
  SemanticVersion copy() {
    return SemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
      buildNumber: buildNumber,
    );
  }

  @override
  String toString() => fullVersion;
}

/// Version bump type
enum VersionBump { none, patch, minor, major }

/// Build number handling type
enum BuildNumberAction { keep, increment, custom }

/// Manages version incrementing and prompts
class VersionManager {
  /// Apply version bump to a semantic version
  SemanticVersion applyBump(SemanticVersion version, VersionBump bump) {
    final newVersion = version.copy();

    switch (bump) {
      case VersionBump.major:
        newVersion.incrementMajor();
        break;
      case VersionBump.minor:
        newVersion.incrementMinor();
        break;
      case VersionBump.patch:
        newVersion.incrementPatch();
        break;
      case VersionBump.none:
        // No change
        break;
    }

    return newVersion;
  }

  /// Apply build number action
  SemanticVersion applyBuildNumber(
    SemanticVersion version,
    BuildNumberAction action, {
    int? customNumber,
  }) {
    final newVersion = version.copy();

    switch (action) {
      case BuildNumberAction.increment:
        newVersion.incrementBuildNumber();
        break;
      case BuildNumberAction.custom:
        if (customNumber != null) {
          newVersion.buildNumber = customNumber;
        }
        break;
      case BuildNumberAction.keep:
        // No change
        break;
    }

    return newVersion;
  }

  /// Get display string for version bump options
  List<String> getBumpOptions(SemanticVersion current) {
    final patchVersion = current.copy()..incrementPatch();
    final minorVersion = current.copy()..incrementMinor();
    final majorVersion = current.copy()..incrementMajor();

    return [
      'No change (keep ${current.buildName})',
      'Patch (+0.0.1) → ${patchVersion.buildName}',
      'Minor (+0.1.0) → ${minorVersion.buildName}',
      'Major (+1.0.0) → ${majorVersion.buildName}',
    ];
  }

  /// Get display string for build number options
  List<String> getBuildNumberOptions(SemanticVersion current) {
    return [
      'Keep current (${current.buildNumber})',
      'Auto-increment (+1) → ${current.buildNumber + 1}',
      'Set custom number',
    ];
  }

  /// Convert choice index to VersionBump
  VersionBump bumpFromChoice(int choice) {
    switch (choice) {
      case 0:
        return VersionBump.none;
      case 1:
        return VersionBump.patch;
      case 2:
        return VersionBump.minor;
      case 3:
        return VersionBump.major;
      default:
        return VersionBump.none;
    }
  }

  /// Convert choice index to BuildNumberAction
  BuildNumberAction buildNumberActionFromChoice(int choice) {
    switch (choice) {
      case 0:
        return BuildNumberAction.keep;
      case 1:
        return BuildNumberAction.increment;
      case 2:
        return BuildNumberAction.custom;
      default:
        return BuildNumberAction.keep;
    }
  }
}
