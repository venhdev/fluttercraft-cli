import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:fluttercraft/src/core/artifact_mover.dart';
import 'package:fluttercraft/src/core/build_config.dart';
import 'package:fluttercraft/src/core/build_flags.dart';

void main() {
  group('ArtifactMover', () {
    late ArtifactMover mover;
    late Directory tempDir;
    late BuildConfig config;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('artifact_mover_test');
      mover = ArtifactMover(projectRoot: tempDir.path);
      
      config = BuildConfig(
        projectRoot: tempDir.path,
        appName: 'testapp',
        buildName: '1.0.0',
        buildNumber: 1,
        platform: 'apk',
        targetDart: 'lib/main.dart',
        outputPath: 'dist',
        flags: BuildFlags.defaults,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: 'key.jks',
      );

      // Create output directory
      await Directory(p.join(tempDir.path, 'dist')).create(recursive: true);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('cleanArtifacts removes existing artifacts', () async {
      final artifactPath = p.join(tempDir.path, 'dist', 'testapp_1.0.0+1.apk');
      final artifactFile = File(artifactPath);
      await artifactFile.writeAsString('stale content');
      expect(await artifactFile.exists(), true);

      await mover.cleanArtifacts(config);

      expect(await artifactFile.exists(), false);
    });

    test('cleanArtifacts removes multiple extensions', () async {
      final apkPath = p.join(tempDir.path, 'dist', 'testapp_1.0.0+1.apk');
      final aabPath = p.join(tempDir.path, 'dist', 'testapp_1.0.0+1.aab');
      
      await File(apkPath).writeAsString('apk');
      await File(aabPath).writeAsString('aab');
      
      expect(await File(apkPath).exists(), true);
      expect(await File(aabPath).exists(), true);

      await mover.cleanArtifacts(config);

      expect(await File(apkPath).exists(), false);
      expect(await File(aabPath).exists(), false);
    });

    test('cleanArtifacts ignores non-matching files', () async {
      final otherPath = p.join(tempDir.path, 'dist', 'other.txt');
      await File(otherPath).writeAsString('other');
      
      await mover.cleanArtifacts(config);

      expect(await File(otherPath).exists(), true);
    });
    
    test('fullAppName includes .sb.base suffix when useShorebird is true', () async {
      final sbConfig = BuildConfig(
        projectRoot: tempDir.path,
        appName: 'testapp',
        buildName: '1.0.0',
        buildNumber: 1,
        platform: 'apk',
        targetDart: 'lib/main.dart',
        outputPath: 'dist',
        flags: BuildFlags.defaults,
        useFvm: false,
        useShorebird: true, // Enable Shorebird
        shorebirdNoConfirm: true,
        keystorePath: 'key.jks',
      );
      
      expect(sbConfig.fullAppName, 'testapp_1.0.0+1.sb.base');
      
      final artifactPath = p.join(tempDir.path, 'dist', 'testapp_1.0.0+1.sb.base.apk');
      await File(artifactPath).writeAsString('stale sb content');
      
      await mover.cleanArtifacts(sbConfig);
      expect(await File(artifactPath).exists(), false);
    });
  });
}
