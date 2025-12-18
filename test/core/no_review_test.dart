import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';
import 'package:fluttercraft/src/core/build_flags.dart';
import '../test_helper.dart';

void main() {
  group('No Review Configuration', () {
    test('parses no_review: true from yaml', () async {
      final config = await BuildConfig.load(
        configPath: 'test/fixtures/no_review_fluttercraft.yaml',
        projectRoot: 'test/fixtures',
      );
      expect(config.noReview, isTrue);
    });

    test('defaults no_review to false if missing', () {
       final config = BuildConfig(
        projectRoot: '.',
        appName: 'app',
        buildName: '1.0.0',
        buildNumber: 1,
        buildType: 'apk',
        targetDart: 'lib/main.dart',
        outputPath: 'dist',
        flags: BuildFlags.defaults,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: 'key.properties',
        // noReview defaults to false
      );
      expect(config.noReview, isFalse);
    });

    test('can set noReview manually', () {
      final config = BuildConfig(
        projectRoot: '.',
        appName: 'app',
        buildName: '1.0.0',
        buildNumber: 1,
        buildType: 'apk',
        targetDart: 'lib/main.dart',
        outputPath: 'dist',
        flags: BuildFlags.defaults,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: 'key.properties',
        noReview: true,
      );
      expect(config.noReview, isTrue);
    });
  });
}
