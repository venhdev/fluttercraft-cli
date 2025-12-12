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

## Phase 4: Commands

- [ ] `bin/mycli.dart` - Entry point with CommandRunner

- [ ] `lib/src/commands/build_command.dart` (`mycli build`)
  - [ ] Load .buildenv
  - [ ] Version bump prompts
  - [ ] Build number handling
  - [ ] Configuration confirmation
  - [ ] Execute build
  - [ ] Copy artifacts
  - [ ] Show summary

- [ ] `lib/src/commands/clean_command.dart` (`mycli clean`)
  - [ ] Run flutter clean
  - [ ] Delete dist folder
  - [ ] Show summary

- [ ] `lib/src/commands/gen_env_command.dart` (`mycli gen-env`)
  - [ ] Read pubspec.yaml
  - [ ] Detect FVM/Shorebird
  - [ ] Read buildenv.base
  - [ ] Generate .buildenv
  - [ ] Display summary

- [ ] `lib/src/commands/convert_command.dart` (`mycli convert`)
  - [ ] Find AAB files in dist
  - [ ] Detect bundletool
  - [ ] Read keystore info
  - [ ] Run bundletool
  - [ ] Output universal APK

---

## Phase 5: Testing & Distribution

- [ ] Test locally
  ```powershell
  fvm dart run bin/mycli.dart --help
  fvm dart run bin/mycli.dart gen-env
  fvm dart run bin/mycli.dart build --help
  ```

- [ ] Compile to native binary
  ```powershell
  fvm dart compile exe bin/mycli.dart -o mycli.exe
  ```

- [ ] Global activation (optional)
  ```powershell
  fvm dart pub global activate --source path .
  mycli --help
  ```

- [ ] Documentation (README.md)
