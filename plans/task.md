# Mobile Build CLI - Task Tracker

---

## Phase 1: Project Setup ✅ DONE

- [x] Create Dart console project (using FVM's Dart 3.9.2)
  ```powershell
  cd c:\src\self\flutter-dart\cli\mobile-build-cli
  fvm dart create -t console --force .
  ```
- [x] Edit `pubspec.yaml` with dependencies (args, yaml, path, interact, ansicolor)
- [x] Run `fvm dart pub get`
- [x] Create folder structure:
  - `lib/src/commands/`
  - `lib/src/core/`
  - `lib/src/utils/`

---

## Phase 2: Core Utilities ✅ DONE

- [x] `lib/src/utils/process_runner.dart`
  - [x] Run external commands with `Process.run()`
  - [x] Capture stdout/stderr
  - [x] Handle exit codes
  - [x] Stream output in real-time

- [x] `lib/src/utils/console.dart`
  - [x] Colored text output (success, error, warning, info)
  - [x] Box drawing for configuration display
  - [x] Spinner for long operations

- [x] `lib/src/utils/logger.dart`
  - [x] Log to `dist/logs/build-latest.log`
  - [x] Archive logs with timestamp

---

## Phase 3: Core Logic ✅ DONE

- [x] `lib/src/core/build_env.dart`
  - [x] Load `.buildenv` file
  - [x] Load `buildenv.base` for defaults
  - [x] Merge configurations
  - [x] Save updated `.buildenv`

- [x] `lib/src/core/pubspec_parser.dart`
  - [x] Extract name from pubspec.yaml
  - [x] Extract version (1.2.3+45 format)

- [x] `lib/src/core/version_manager.dart`
  - [x] Parse semantic version
  - [x] Increment version (major/minor/patch)
  - [x] Manage build number

- [x] `lib/src/core/flutter_runner.dart`
  - [x] Execute `flutter build apk/aab/ipa`
  - [x] Execute `flutter clean`
  - [x] Handle FVM prefix
  - [x] Handle Shorebird

- [x] `lib/src/core/artifact_mover.dart`
  - [x] Locate build output
  - [x] Copy to dist folder with naming
  - [x] Handle flavor paths

- [x] `lib/src/core/apk_converter.dart`
  - [x] Find AAB files in OUTPUT_PATH
  - [x] Locate bundletool
  - [x] Read keystore info
  - [x] Run bundletool

---

## Phase 4: Commands ✅ DONE

- [x] `bin/mobile_build_cli.dart` - Entry point with CommandRunner

- [x] `lib/src/commands/build_command.dart` (`mycli build`)
  - [x] Load .buildenv
  - [x] Version bump prompts
  - [x] Build number handling
  - [x] Configuration confirmation
  - [x] Execute build
  - [x] Copy artifacts
  - [x] Show summary

- [x] `lib/src/commands/clean_command.dart` (`mycli clean`)
  - [x] Run flutter clean
  - [x] Delete dist folder
  - [x] Show summary

- [x] `lib/src/commands/gen_env_command.dart` (`mycli gen-env`)
  - [x] Read pubspec.yaml
  - [x] Detect FVM/Shorebird
  - [x] Read buildenv.base
  - [x] Generate .buildenv
  - [x] Display summary

- [x] `lib/src/commands/convert_command.dart` (`mycli convert`)
  - [x] Find AAB files in dist
  - [x] Detect bundletool
  - [x] Read keystore info
  - [x] Run bundletool
  - [x] Output universal APK

---

## Phase 5: Testing & Distribution ✅ DONE

- [x] Test locally
  ```powershell
  fvm dart run bin/mobile_build_cli.dart --help  ✅
  fvm dart test  ✅ (6 tests passed)
  ```

- [x] Compile to native binary
  ```powershell
  fvm dart compile exe bin/mobile_build_cli.dart -o dist/mycli.exe  ✅
  .\dist\mycli.exe --help  ✅
  ```

- [x] Global activation (optional)
  ```powershell
  fvm dart pub global activate --source path .
  mycli --help
  ```

- [x] Documentation (README.md) ✅

---

## 🎉 ALL PHASES COMPLETE!

The CLI is ready to use:
```powershell
.\dist\mycli.exe --help
.\dist\mycli.exe gen-env
.\dist\mycli.exe build
.\dist\mycli.exe clean
.\dist\mycli.exe convert
```

