import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';

/// Tests for no_review (fluttercraft prompt) and shorebirdNoConfirm (Shorebird --no-confirm flag)
/// These are two separate settings that control different confirmation prompts
void main() {
  group('no_review and shorebirdNoConfirm Loading', () {
    test('loads no_review: false from build_defaults correctly', () async {
      final config = await BuildConfig.load(
        configPath: 'test/fixtures/no_review_false_in_defaults.yaml',
        projectRoot: 'test/fixtures',
      );
      
      // no_review should be false (from build_defaults)
      expect(config.noReview, isFalse,
          reason: 'no_review should read false from build_defaults');
      
      // shorebirdNoConfirm should also be false (from environments.shorebird)
      expect(config.shorebirdNoConfirm, isFalse,
          reason: 'shorebirdNoConfirm should read false from environments.shorebird.no_confirm');
    });

    test('loads no_review: true from build_defaults correctly', () async {
      final config = await BuildConfig.load(
        configPath: 'test/fixtures/no_review_true_in_defaults.yaml',
        projectRoot: 'test/fixtures',
      );
      
      // no_review should be true (from build_defaults)
      expect(config.noReview, isTrue,
          reason: 'no_review should read true from build_defaults');
      
      // shorebirdNoConfirm should also be true (from environments.shorebird)
      expect(config.shorebirdNoConfirm, isTrue,
          reason: 'shorebirdNoConfirm should read true from environments.shorebird.no_confirm');
    });

    test('build.no_review overrides build_defaults.no_review', () async {
      // Create a temp config where build overrides defaults
      final config = await BuildConfig.load(
        configPath: 'test/fixtures/no_review_fluttercraft.yaml',
        projectRoot: 'test/fixtures',
      );
      
      // The fixture has no_review: true in build section
      expect(config.noReview, isTrue,
          reason: 'build.no_review should override build_defaults.no_review');
    });

    test('defaults to false when no_review is not specified anywhere', () async {
      final config = await BuildConfig.load(
        configPath: 'test/fixtures/fluttercraft-basic.yaml',
        projectRoot: 'test/fixtures',
      );
      
      expect(config.noReview, isFalse,
          reason: 'no_review should default to false when not specified');
    });

    test('defaults shorebirdNoConfirm to true when not specified', () async {
      final config = await BuildConfig.load(
        configPath: 'test/fixtures/fluttercraft-basic.yaml',
        projectRoot: 'test/fixtures',
      );
      
      expect(config.shorebirdNoConfirm, isTrue,
          reason: 'shorebirdNoConfirm should default to true when not specified');
    });
  });

  group('no_review vs shorebirdNoConfirm Documentation', () {
    test('no_review and shorebirdNoConfirm are independent settings', () {
      // This test documents the difference between these two settings
      
      // no_review: Controls fluttercraft's "Do you want to proceed?" prompt
      // Location: build.no_review or build_defaults.no_review
      // Default: false (show prompt)
      
      // shorebirdNoConfirm: Controls Shorebird's --no-confirm flag
      // Location: environments.shorebird.no_confirm
      // Default: true (skip Shorebird's confirmations)
      
      // They can be set independently:
      // - no_review: false, shorebirdNoConfirm: true = Ask user in fluttercraft, skip Shorebird prompts
      // - no_review: true, shorebirdNoConfirm: false = Skip fluttercraft prompt, allow Shorebird prompts
      // - no_review: true, shorebirdNoConfirm: true = Skip all prompts
      // - no_review: false, shorebirdNoConfirm: false = Show all prompts
      
      expect(true, isTrue, reason: 'This test serves as documentation');
    });
  });
}
