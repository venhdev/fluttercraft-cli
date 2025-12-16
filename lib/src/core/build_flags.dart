/// Build flags configuration
///
/// Extracted from build config to support flavor overrides
class BuildFlags {
  /// Use dart-define (combines global_dart_define + dart_define)
  final bool shouldAddDartDefine;

  /// Run flutter clean before build
  final bool shouldClean;

  /// Run build_runner before build
  final bool shouldBuildRunner;

  const BuildFlags({
    this.shouldAddDartDefine = false,
    this.shouldClean = false,
    this.shouldBuildRunner = false,
  });

  /// Create from default values
  static const BuildFlags defaults = BuildFlags();

  /// Merge with flavor overrides (flavor values take precedence if non-null)
  BuildFlags mergeWith({
    bool? shouldAddDartDefine,
    bool? shouldClean,
    bool? shouldBuildRunner,
  }) {
    return BuildFlags(
      shouldAddDartDefine: shouldAddDartDefine ?? this.shouldAddDartDefine,
      shouldClean: shouldClean ?? this.shouldClean,
      shouldBuildRunner: shouldBuildRunner ?? this.shouldBuildRunner,
    );
  }

  @override
  String toString() {
    return 'BuildFlags(shouldAddDartDefine: $shouldAddDartDefine, shouldClean: $shouldClean, shouldBuildRunner: $shouldBuildRunner)';
  }
}
