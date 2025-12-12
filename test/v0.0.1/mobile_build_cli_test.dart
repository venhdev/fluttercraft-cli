import 'package:test/test.dart';
import 'package:buildcraft/src/core/version_manager.dart';

void main() {
  group('SemanticVersion', () {
    test('parses version without build number', () {
      final version = SemanticVersion.parse('1.2.3');
      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
      expect(version.buildNumber, 1);
    });

    test('parses version with build number', () {
      final version = SemanticVersion.parse('1.2.3+45');
      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
      expect(version.buildNumber, 45);
    });

    test('increments patch version', () {
      final version = SemanticVersion.parse('1.2.3+5');
      version.incrementPatch();
      expect(version.buildName, '1.2.4');
    });

    test('increments minor version', () {
      final version = SemanticVersion.parse('1.2.3+5');
      version.incrementMinor();
      expect(version.buildName, '1.3.0');
    });

    test('increments major version', () {
      final version = SemanticVersion.parse('1.2.3+5');
      version.incrementMajor();
      expect(version.buildName, '2.0.0');
    });
  });

  group('VersionManager', () {
    test('applies patch bump', () {
      final manager = VersionManager();
      final version = SemanticVersion.parse('1.0.0');
      final bumped = manager.applyBump(version, VersionBump.patch);
      expect(bumped.buildName, '1.0.1');
    });
  });
}
