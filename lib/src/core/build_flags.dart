/// Build flags configuration
///
/// Extracted from build config to support flavor overrides
class BuildFlags {
  /// Prompt user for custom dart-define values during build
  final bool shouldPromptDartDefine;

  /// Run flutter clean before build
  final bool shouldClean;

  /// Run build_runner before build
  final bool shouldBuildRunner;

  const BuildFlags({
    this.shouldPromptDartDefine = false,
    this.shouldClean = false,
    this.shouldBuildRunner = false,
  });

  /// Create from default values
  static const BuildFlags defaults = BuildFlags();

  /// Merge with flavor overrides (flavor values take precedence if non-null)
  BuildFlags mergeWith({
    bool? shouldPromptDartDefine,
    bool? shouldClean,
    bool? shouldBuildRunner,
  }) {
    return BuildFlags(
      shouldPromptDartDefine: shouldPromptDartDefine ?? this.shouldPromptDartDefine,
      shouldClean: shouldClean ?? this.shouldClean,
      shouldBuildRunner: shouldBuildRunner ?? this.shouldBuildRunner,
    );
  }

  @override
  String toString() {
    return 'BuildFlags(shouldPromptDartDefine: $shouldPromptDartDefine, shouldClean: $shouldClean, shouldBuildRunner: $shouldBuildRunner)';
  }
}
