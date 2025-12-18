import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_flags.dart';

/// Tests for BuildFlags model
///
/// Verifies constructor, defaults, merging, and toString.
void main() {
  group('BuildFlags', () {
    group('constructor', () {
      test('creates with default values', () {
        const flags = BuildFlags();

        expect(flags.shouldPromptDartDefine, false);
        expect(flags.shouldClean, false);
        expect(flags.shouldBuildRunner, false);
      });

      test('creates with custom values', () {
        const flags = BuildFlags(
          shouldPromptDartDefine: true,
          shouldClean: true,
          shouldBuildRunner: true,
        );

        expect(flags.shouldPromptDartDefine, true);
        expect(flags.shouldClean, true);
        expect(flags.shouldBuildRunner, true);
      });

      test('creates with mixed values', () {
        const flags = BuildFlags(
          shouldPromptDartDefine: true,
          shouldClean: false,
          shouldBuildRunner: true,
        );

        expect(flags.shouldPromptDartDefine, true);
        expect(flags.shouldClean, false);
        expect(flags.shouldBuildRunner, true);
      });
    });

    group('defaults static const', () {
      test('defaults has all false values', () {
        expect(BuildFlags.defaults.shouldPromptDartDefine, false);
        expect(BuildFlags.defaults.shouldClean, false);
        expect(BuildFlags.defaults.shouldBuildRunner, false);
      });
    });

    group('mergeWith', () {
      test('overrides with non-null values', () {
        const base = BuildFlags(
          shouldPromptDartDefine: false,
          shouldClean: false,
          shouldBuildRunner: false,
        );

        final merged = base.mergeWith(
          shouldPromptDartDefine: true,
          shouldClean: true,
        );

        expect(merged.shouldPromptDartDefine, true); // overridden
        expect(merged.shouldClean, true); // overridden
        expect(merged.shouldBuildRunner, false); // not overridden
      });

      test('keeps original values when override is null', () {
        const base = BuildFlags(
          shouldPromptDartDefine: true,
          shouldClean: true,
          shouldBuildRunner: true,
        );

        final merged = base.mergeWith();

        expect(merged.shouldPromptDartDefine, true);
        expect(merged.shouldClean, true);
        expect(merged.shouldBuildRunner, true);
      });

      test('can set true to false via override', () {
        const base = BuildFlags(
          shouldPromptDartDefine: true,
          shouldClean: true,
          shouldBuildRunner: true,
        );

        final merged = base.mergeWith(
          shouldPromptDartDefine: false,
          shouldClean: false,
          shouldBuildRunner: false,
        );

        expect(merged.shouldPromptDartDefine, false);
        expect(merged.shouldClean, false);
        expect(merged.shouldBuildRunner, false);
      });

      test('partial override preserves non-overridden values', () {
        const base = BuildFlags(
          shouldPromptDartDefine: true,
          shouldClean: false,
          shouldBuildRunner: true,
        );

        final merged = base.mergeWith(shouldClean: true);

        expect(merged.shouldPromptDartDefine, true); // preserved
        expect(merged.shouldClean, true); // overridden
        expect(merged.shouldBuildRunner, true); // preserved
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        const flags = BuildFlags(
          shouldPromptDartDefine: true,
          shouldClean: false,
          shouldBuildRunner: true,
        );

        final str = flags.toString();

        expect(str, contains('shouldPromptDartDefine: true'));
        expect(str, contains('shouldClean: false'));
        expect(str, contains('shouldBuildRunner: true'));
      });
    });
  });
}
