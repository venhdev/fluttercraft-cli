# Plan: Enhance dart_define_from_file Validation & Bump Version

The code correctly includes `--dart-define-from-file` when configured, but provides no feedback when the file path is set but the file doesn't exist or when flavor overrides are missing it. Add validation to catch configuration issues early and improve user experience.

## Steps

1. **Add file existence validation** in [build_command.dart](lib/src/commands/build_command.dart#L250-L260): After loading config, check if `buildConfig.finalDartDefineFromFile` is set but file doesn't exist at project root, warn user with file path and suggest fixing config or creating the file.

2. **Add flavor override visibility** in [build_command.dart](lib/src/commands/build_command.dart#L285): When flavor is active, show in console output whether dart_define_from_file was overridden by flavor or inherited from defaults, helping users debug missing config.

3. **Update version** in [pubspec.yaml](pubspec.yaml#L3) and [version.dart](lib/src/version.dart#L3): Bump from `0.2.2` to `0.2.3` for bug fixes (false success detection, command edit validation, dart_define_from_file visibility).

4. **Update CHANGELOG** in [CHANGELOG.md](CHANGELOG.md): Document v0.2.3 changes: fixed Shorebird error detection with exit code 0, added command edit validation for required flags, added dart_define_from_file visibility and validation.

## Further Considerations

1. **Should we auto-create .env file?** If dart_define_from_file is configured but file missing, offer to create empty template with comment explaining usage.

2. **Relative vs absolute paths?** Currently accepts relative paths like `.env` - should we resolve to absolute and show both in logs for clarity?
