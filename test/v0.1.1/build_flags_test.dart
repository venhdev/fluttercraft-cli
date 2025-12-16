import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_flags.dart';

/// Tests for BuildFlags model in v0.1.1
void main() {
  group('BuildFlags', () {
    group('constructor', () {
      test('creates with default values', () {
        const flags = BuildFlags();

        expect(flags.shouldAddDartDefine, false);
        expect(flags.shouldClean, false);
        expect(flags.shouldBuildRunner, false);
      });

      test('creates with custom values', () {
        const flags = BuildFlags(
          shouldAddDartDefine: true,
          shouldClean: true,
          shouldBuildRunner: true,
        );

        expect(flags.shouldAddDartDefine, true);
        expect(flags.shouldClean, true);
        expect(flags.shouldBuildRunner, true);
      });

      test('creates with mixed values', () {
        const flags = BuildFlags(
          shouldAddDartDefine: true,
          shouldClean: false,
          shouldBuildRunner: true,
        );

        expect(flags.shouldAddDartDefine, true);
        expect(flags.shouldClean, false);
        expect(flags.shouldBuildRunner, true);
      });
    });

    group('defaults static const', () {
      test('defaults has all false values', () {
        expect(BuildFlags.defaults.shouldAddDartDefine, false);
        expect(BuildFlags.defaults.shouldClean, false);
        expect(BuildFlags.defaults.shouldBuildRunner, false);
      });
    });

    group('mergeWith', () {
      test('overrides with non-null values', () {
        const base = BuildFlags(
          shouldAddDartDefine: false,
          shouldClean: false,
          shouldBuildRunner: false,
        );

        final merged = base.mergeWith(
          shouldAddDartDefine: true,
          shouldClean: true,
        );

        expect(merged.shouldAddDartDefine, true); // overridden
        expect(merged.shouldClean, true); // overridden
        expect(merged.shouldBuildRunner, false); // not overridden
      });

      test('keeps original values when override is null', () {
        const base = BuildFlags(
          shouldAddDartDefine: true,
          shouldClean: true,
          shouldBuildRunner: true,
        );

        final merged = base.mergeWith();

        expect(merged.shouldAddDartDefine, true);
        expect(merged.shouldClean, true);
        expect(merged.shouldBuildRunner, true);
      });

      test('can set true to false via override', () {
        const base = BuildFlags(
          shouldAddDartDefine: true,
          shouldClean: true,
          shouldBuildRunner: true,
        );

        final merged = base.mergeWith(
          shouldAddDartDefine: false,
          shouldClean: false,
          shouldBuildRunner: false,
        );

        expect(merged.shouldAddDartDefine, false);
        expect(merged.shouldClean, false);
        expect(merged.shouldBuildRunner, false);
      });

      test('partial override preserves non-overridden values', () {
        const base = BuildFlags(
          shouldAddDartDefine: true,
          shouldClean: false,
          shouldBuildRunner: true,
        );

        final merged = base.mergeWith(shouldClean: true);

        expect(merged.shouldAddDartDefine, true); // preserved
        expect(merged.shouldClean, true); // overridden
        expect(merged.shouldBuildRunner, true); // preserved
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        const flags = BuildFlags(
          shouldAddDartDefine: true,
          shouldClean: false,
          shouldBuildRunner: true,
        );

        final str = flags.toString();

        expect(str, contains('shouldAddDartDefine: true'));
        expect(str, contains('shouldClean: false'));
        expect(str, contains('shouldBuildRunner: true'));
      });
    });
  });
}
